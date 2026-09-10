from create.graphics.sprite import Sprite


struct SpriteAnimation(Movable):
    """An ordered sequence of frames and the rate they play at.

    A `SpriteAnimation` is the asset, not the playhead -- it holds the frames
    and how fast they are meant to run, and never mutates. `SpriteAnimator`
    walks it. The rate lives here because it is a property of the artwork: a
    run cycle and an idle cycle are drawn for different speeds.

    Frames are cut into owned `Sprite`s at construction, so a sheet or a folder
    is paid for once and every draw afterwards is a plain blit.

    Hold one as an `ArcPointer[SpriteAnimation]` field, like a `Sound`, so
    several animators can share the frame buffers by refcount instead of
    copying them.
    """

    var frames: List[Sprite]
    var fps: Float64

    def __init__(out self, var frames: List[Sprite], fps: Float64 = 12.0) raises:
        """Build an animation from frames already in memory.

        Raises on an empty frame list: an animation with no frames has no valid
        frame index, so every consumer would have to guard against it.
        """
        if len(frames) == 0:
            raise Error("SpriteAnimation needs at least one frame")
        if fps <= 0.0:
            raise Error("SpriteAnimation fps must be positive, got " + String(fps))
        self.frames = frames^
        self.fps = fps

    def count(self) -> Int:
        """The number of frames."""
        return len(self.frames)

    def frame_duration(self) -> Float64:
        """Seconds each frame is held."""
        return 1.0 / self.fps

    @staticmethod
    def from_sheet(
        sheet: Sprite,
        frame_width: Int,
        frame_height: Int,
        start: Int = 0,
        count: Int = 0,
        fps: Float64 = 12.0,
    ) raises -> SpriteAnimation:
        """Cut frames out of a sprite sheet, left to right then top to bottom.

        Cells are numbered row-major from zero, so one sheet holding idle on
        row 0 and run on row 1 yields two animations without a sheet type:

        ```mojo
        var idle = SpriteAnimation.from_sheet(sheet, 32, 32, start=0, count=4)
        var run = SpriteAnimation.from_sheet(sheet, 32, 32, start=4, count=6)
        ```

        `count = 0` means every remaining cell. Raises when the sheet is not a
        whole number of cells wide or tall, or when the window runs past the
        last cell -- a silently truncated animation is harder to notice than a
        failed load.
        """
        if frame_width <= 0 or frame_height <= 0:
            raise Error(
                "frame size must be positive, got "
                + String(frame_width)
                + "x"
                + String(frame_height)
            )
        if sheet.width % frame_width != 0 or sheet.height % frame_height != 0:
            raise Error(
                "sheet "
                + String(sheet.width)
                + "x"
                + String(sheet.height)
                + " is not a whole number of "
                + String(frame_width)
                + "x"
                + String(frame_height)
                + " frames"
            )
        var cols = sheet.width // frame_width
        var total = cols * (sheet.height // frame_height)
        if start < 0 or start >= total:
            raise Error(
                "start "
                + String(start)
                + " is outside the sheet's "
                + String(total)
                + " frames"
            )
        var take = total - start if count == 0 else count
        if take <= 0 or start + take > total:
            raise Error(
                "frames "
                + String(start)
                + ".."
                + String(start + take)
                + " run past the sheet's "
                + String(total)
                + " frames"
            )

        var frames = List[Sprite]()
        for index in range(start, start + take):
            frames.append(
                SpriteAnimation._cut(
                    sheet,
                    (index % cols) * frame_width,
                    (index // cols) * frame_height,
                    frame_width,
                    frame_height,
                )
            )
        return SpriteAnimation(frames^, fps)

    @staticmethod
    def _cut(sheet: Sprite, x: Int, y: Int, w: Int, h: Int) -> Sprite:
        """Copy one w x h cell at (x, y) out of the sheet, RGBA row by row."""
        var frame = Sprite(w, h)
        var src = sheet.pixels.unsafe_ptr()
        var dst = frame.pixels.unsafe_ptr()
        for row in range(h):
            var s = ((y + row) * sheet.width + x) * 4
            var d = row * w * 4
            for i in range(w * 4):
                dst[unsafe_offset=d + i] = src[unsafe_offset=s + i]
        return frame^
