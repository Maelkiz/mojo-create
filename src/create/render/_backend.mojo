from std.collections import Dict
from std.math import max, min, abs

from create.math.matrix import Matrix, inverse, apply as mat_apply

from ._command import (
    CMD_CLEAR,
    CMD_RECT,
    CMD_CIRCLE,
    CMD_LINE,
    CMD_TRIANGLE,
    CMD_SPRITE,
    CMD_TEXT,
    CMD_LETTERBOX,
    DrawCommand,
)
from ._raster import (
    blend,
    blit_sprite,
    fill_all,
    fill_pixels,
    fill_triangle,
    line_pixels,
)
from ._style import Style
from .surface import Surface
from ._text import TextRenderer

comptime BACKEND_CPU = 0
comptime BACKEND_GPU = 1


def uniform(m: Matrix[3, 3]) -> Bool:
    """True when `m` is an axis-aligned uniform scale plus a translation — a
    rect stays a rect, a circle stays a circle.

    The base mapping alone qualifies (it scales by `s` and `-s`), so plain
    drawing keeps the integer raster paths even under autoscale. Only
    rotation, shear, and non-uniform scales fall through to the per-pixel
    inverse mapping.
    """
    return (
        m[0, 1] == 0.0
        and m[1, 0] == 0.0
        and m[2, 0] == 0.0
        and m[2, 1] == 0.0
        and m[2, 2] == 1.0
        and abs(m[0, 0]) == abs(m[1, 1])
    )


def pixel_scale(m: Matrix[3, 3], fallback: Float64) -> Float64:
    """Pixels per world unit along `m`.

    Stroke width, font size and sprite extents are authored in world units but
    rasterised in pixels, so they all scale by this. `fallback` is the frame's
    autoscale factor, used when `m` is not uniform and no single factor exists.
    """
    if uniform(m):
        return abs(m[0, 0])
    return fallback


def stroke_width_px(style: Style, m: Matrix[3, 3], fallback: Float64) -> Int:
    """Stroke width in framebuffer pixels, never thinner than one."""
    return max(
        Int(Float64(style.stroke_width) * pixel_scale(m, fallback) + 0.5), 1
    )


def device_bounds(
    m: Matrix[3, 3],
    lx0: Float64,
    ly0: Float64,
    lx1: Float64,
    ly1: Float64,
    width: Int,
    height: Int,
) -> Tuple[Int, Int, Int, Int]:
    """Device-space scan bounds for the local box `[lx0, lx1] x [ly0, ly1]`.

    Returns `(x_min, y_min, x_max, y_max)`, half-open on the maxima and
    clipped to `width` x `height`. The bounds come from the four *corners*,
    not the edge midpoints: under a rotation the midpoints are no longer the
    extremes, and scanning between them clips the shape.
    """
    var p0 = mat_apply(m, lx0, ly0)
    var p1 = mat_apply(m, lx1, ly0)
    var p2 = mat_apply(m, lx1, ly1)
    var p3 = mat_apply(m, lx0, ly1)
    var x_min = max(Int(min(min(p0[0], p1[0]), min(p2[0], p3[0]))), 0)
    var x_max = min(Int(max(max(p0[0], p1[0]), max(p2[0], p3[0]))) + 1, width)
    var y_min = max(Int(min(min(p0[1], p1[1]), min(p2[1], p3[1]))), 0)
    var y_max = min(Int(max(max(p0[1], p1[1]), max(p2[1], p3[1]))) + 1, height)
    return (x_min, y_min, x_max, y_max)


struct _Image(Movable):
    """A sprite's pixels, owned by the backend.

    Interned on the first draw of a given sprite and kept until the cache is
    dropped, so the command buffer carries an id rather than a borrow of
    program-owned memory. The GL backend will key a texture the same way.
    """

    var pixels: List[UInt8]
    var width: Int
    var height: Int

    def __init__(out self, var pixels: List[UInt8], width: Int, height: Int):
        self.pixels = pixels^
        self.width = width
        self.height = height


struct Backend(Movable):
    """Where a frame's recorded commands become pixels.

    One struct with a runtime branch on `kind` rather than a trait: Mojo 1.0
    has no dynamic trait dispatch, so a trait in type position would form an
    inert `AnyTrait[T]` that nothing converts into.

    This is what survives the frame boundary. Fonts and glyph masks already
    had to — reloading a face every frame would be absurd — and GPU resources
    join them for exactly the same reason, so the backend is the natural owner
    of both.
    """

    var kind: Int
    var text: TextRenderer
    var images: Dict[Int, _Image]
    var commands: List[DrawCommand]
    """The frame being recorded.

    The buffer lives here rather than travelling out of `Canvas` because a
    `Tuple` of move-only values cannot be unpacked in this Mojo version — see
    `present`, which is also where the buffer is reset. Keeping it means the
    allocation is reused frame to frame instead of being rebuilt per frame.
    """

    def __init__(out self, kind: Int = BACKEND_CPU):
        self.kind = kind
        self.text = TextRenderer()
        self.images = Dict[Int, _Image]()
        self.commands = List[DrawCommand]()

    def record(mut self, var c: DrawCommand):
        """Append one draw to the frame being recorded."""
        self.commands.append(c^)

    def present[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], scale: Float64) raises:
        """Draw the recorded frame onto `s` and start a new recording.

        The buffer is moved out and back rather than iterated in place: replay
        needs `self` mutably (the glyph cache and the image cache both fill in
        as it runs), which it cannot have while borrowing a field of `self`.
        Moving it back keeps its capacity for the next frame.
        """
        var cmds = self.commands^
        self.commands = List[DrawCommand]()
        self.replay(s, cmds, scale)
        cmds.clear()
        self.commands = cmds^

    def intern_image[
        so: Origin
    ](
        mut self, key: Int, src: Pointer[UInt8, so], width: Int, height: Int
    ) -> Int:
        """Return a backend id for the `width` x `height` RGBA buffer at `src`.

        Copies on first sight and returns the cached id thereafter, so a sprite
        drawn every frame is copied once. `key` must be stable for the life of
        the image — a `Sprite`'s identity, not its pixel address, which could
        be reused after a free.

        Called while recording rather than at replay, which is what keeps a
        borrow of caller-owned memory out of the command buffer.
        """
        if key in self.images:
            return key
        var buf = List[UInt8](length=width * height * 4, fill=0)
        for i in range(width * height * 4):
            buf[i] = src[unsafe_offset=i]
        self.images[key] = _Image(buf^, width, height)
        return key

    def replay[
        o: Origin[mut=True]
    ](
        mut self, s: Surface[o], cmds: List[DrawCommand], scale: Float64
    ) raises:
        """Draw `cmds` onto `s`, in order.

        `scale` is the frame's autoscale factor — the fallback pixel scale for
        commands whose transform is not uniform. It is constant for a frame, so
        it travels here rather than on every command.
        """
        for ref c in cmds:
            self._one(s, c, scale)

    def _one[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64) raises:
        if c.kind == CMD_CLEAR:
            fill_all(s, c.style.fill)
        elif c.kind == CMD_RECT:
            self._rect(s, c, scale)
        elif c.kind == CMD_CIRCLE:
            self._circle(s, c, scale)
        elif c.kind == CMD_LINE:
            self._line(s, c, scale)
        elif c.kind == CMD_TRIANGLE:
            self._triangle(s, c, scale)
        elif c.kind == CMD_SPRITE:
            self._sprite(s, c, scale)
        elif c.kind == CMD_TEXT:
            self._text(s, c, scale)
        elif c.kind == CMD_LETTERBOX:
            self._letterbox(s, c)

    def _rect[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64):
        var W = s.width
        var m = c.transform
        var x = c.geom[0]
        var y = c.geom[1]
        var lx0 = x - c.geom[2] / 2.0
        var ly0 = y - c.geom[3] / 2.0
        var lx1 = x + c.geom[2] / 2.0
        var ly1 = y + c.geom[3] / 2.0

        if uniform(m):
            # Axis-aligned: map the two opposite corners and order them, since
            # the y flip in the base mapping sends the smaller world y to the
            # larger pixel row.
            var p0 = mat_apply(m, lx0, ly0)
            var p1 = mat_apply(m, lx1, ly1)
            var x0 = Int(min(p0[0], p1[0]))
            var y0 = Int(min(p0[1], p1[1]))
            var iw = Int(abs(p1[0] - p0[0]))
            var ih = Int(abs(p1[1] - p0[1]))
            if c.style.fill_enabled:
                fill_pixels(s, x0, y0, x0 + iw, y0 + ih, c.style.fill)
            if c.style.stroke_enabled:
                var sw = stroke_width_px(c.style, m, scale)
                var sc = c.style.stroke
                fill_pixels(s, x0, y0, x0 + iw, y0 + sw, sc)
                fill_pixels(s, x0, y0 + ih - sw, x0 + iw, y0 + ih, sc)
                fill_pixels(s, x0, y0 + sw, x0 + sw, y0 + ih - sw, sc)
                fill_pixels(s, x0 + iw - sw, y0 + sw, x0 + iw, y0 + ih - sw, sc)
        else:
            var minv = inverse(m)
            var b = device_bounds(m, lx0, ly0, lx1, ly1, s.width, s.height)
            var sw_f = Float64(c.style.stroke_width)
            for row in range(b[1], b[3]):
                for col in range(b[0], b[2]):
                    var local = mat_apply(minv, Float64(col), Float64(row))
                    var lx = local[0]
                    var ly = local[1]
                    if lx < lx0 or lx > lx1 or ly < ly0 or ly > ly1:
                        continue
                    var off = (row * W + col) * 4
                    var in_inner = (
                        lx >= lx0 + sw_f
                        and lx <= lx1 - sw_f
                        and ly >= ly0 + sw_f
                        and ly <= ly1 - sw_f
                    )
                    if c.style.fill_enabled and (
                        not c.style.stroke_enabled or in_inner
                    ):
                        blend(s, off, c.style.fill)
                    elif c.style.stroke_enabled and not in_inner:
                        blend(s, off, c.style.stroke)

    def _circle[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64):
        var W = s.width
        var H = s.height
        var m = c.transform
        var cx = c.geom[0]
        var cy = c.geom[1]
        var r = c.geom[2]
        var r2 = r * r
        var r_inner = r - Float64(c.style.stroke_width)
        var r_inner2 = r_inner * r_inner

        if uniform(m):
            # A uniform scale keeps a circle a circle, so it stays a distance
            # test — just in pixels rather than world units.
            var p = mat_apply(m, cx, cy)
            var pcx = p[0]
            var pcy = p[1]
            var pr = r * pixel_scale(m, scale)
            var pr2 = pr * pr
            var pr_inner = pr - Float64(stroke_width_px(c.style, m, scale))
            var pr_inner2 = pr_inner * pr_inner
            var x0 = max(Int(pcx - pr), 0)
            var y0 = max(Int(pcy - pr), 0)
            var x1 = min(Int(pcx + pr) + 1, W)
            var y1 = min(Int(pcy + pr) + 1, H)
            for row in range(y0, y1):
                var dy = Float64(row) - pcy
                for col in range(x0, x1):
                    var dx = Float64(col) - pcx
                    var d2 = dx * dx + dy * dy
                    if d2 <= pr2:
                        var off = (row * W + col) * 4
                        if c.style.fill_enabled and (
                            not c.style.stroke_enabled
                            or pr_inner <= 0.0
                            or d2 <= pr_inner2
                        ):
                            blend(s, off, c.style.fill)
                        elif c.style.stroke_enabled and d2 > pr_inner2:
                            blend(s, off, c.style.stroke)
        else:
            var minv = inverse(m)
            var b = device_bounds(m, cx - r, cy - r, cx + r, cy + r, W, H)
            for row in range(b[1], b[3]):
                for col in range(b[0], b[2]):
                    var local = mat_apply(minv, Float64(col), Float64(row))
                    var dx = local[0] - cx
                    var dy = local[1] - cy
                    var d2 = dx * dx + dy * dy
                    if d2 <= r2:
                        var off = (row * W + col) * 4
                        if c.style.fill_enabled and (
                            not c.style.stroke_enabled
                            or r_inner <= 0.0
                            or d2 <= r_inner2
                        ):
                            blend(s, off, c.style.fill)
                        elif c.style.stroke_enabled and d2 > r_inner2:
                            blend(s, off, c.style.stroke)

    def _line[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64):
        if not c.style.stroke_enabled:
            return
        var m = c.transform
        var p0 = mat_apply(m, c.geom[0], c.geom[1])
        var p1 = mat_apply(m, c.geom[2], c.geom[3])
        line_pixels(
            s,
            p0[0],
            p0[1],
            p1[0],
            p1[1],
            c.style.stroke,
            stroke_width_px(c.style, m, scale),
        )

    def _triangle[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64):
        var m = c.transform
        var p1 = mat_apply(m, c.geom[0], c.geom[1])
        var p2 = mat_apply(m, c.geom[2], c.geom[3])
        var p3 = mat_apply(m, c.geom[4], c.geom[5])
        if c.style.fill_enabled:
            fill_triangle(
                s, p1[0], p1[1], p2[0], p2[1], p3[0], p3[1], c.style.fill
            )
        if c.style.stroke_enabled:
            var sw = stroke_width_px(c.style, m, scale)
            var sc = c.style.stroke
            line_pixels(s, p1[0], p1[1], p2[0], p2[1], sc, sw)
            line_pixels(s, p2[0], p2[1], p3[0], p3[1], sc, sw)
            line_pixels(s, p3[0], p3[1], p1[0], p1[1], sc, sw)

    def _sprite[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64) raises:
        if c.image not in self.images:
            return
        var m = c.transform
        var p = mat_apply(m, c.geom[0], c.geom[1])
        var sf = pixel_scale(m, scale)
        var dw = max(Int(c.geom[2] * sf + 0.5), 1)
        var dh = max(Int(c.geom[3] * sf + 0.5), 1)
        # Bound by reference so the pixels stay in the cache rather than being
        # copied out of it once per draw.
        ref img = self.images[c.image]
        blit_sprite(
            s,
            img.pixels.unsafe_ptr(),
            img.width,
            img.height,
            Int(p[0]) - dw // 2,
            Int(p[1]) - dh // 2,
            dw,
            dh,
        )

    def _text[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand, scale: Float64) raises:
        if not c.style.fill_enabled:
            return
        var m = c.transform
        # Only the anchor is mapped — the layout itself happens in pixel space.
        var p = mat_apply(m, c.geom[0], c.geom[1])
        self.text.draw(
            s, c.text, p[0], p[1], c.style, pixel_scale(m, scale)
        )

    def _letterbox[
        o: Origin[mut=True]
    ](mut self, s: Surface[o], c: DrawCommand):
        var W = s.width
        var H = s.height
        var cx0 = Int(c.geom[0])
        var cy0 = Int(c.geom[1])
        var cx1 = Int(c.geom[2])
        var cy1 = Int(c.geom[3])
        var col = c.style.fill
        if cy0 > 0:
            fill_pixels(s, 0, 0, W, cy0, col)
        if cy1 < H:
            fill_pixels(s, 0, cy1, W, H, col)
        if cx0 > 0:
            fill_pixels(s, 0, cy0, cx0, cy1, col)
        if cx1 < W:
            fill_pixels(s, cx1, cy0, W, cy1, col)
