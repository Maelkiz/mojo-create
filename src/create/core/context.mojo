from std.math import min
from create.math.matrix import Matrix, scale as mat_scale, translate as mat_translate
from .autoscale import AutoScale


struct Context(Movable):
    var frame_count: Int
    var delta_time: Float64
    var delta_millis: Int
    var width: Int
    var height: Int
    var exit_on_escape: Bool
    var autoscale: Int
    var scale: Float64
    var _design_w: Int
    var _design_h: Int
    var _pixel_w: Int
    var _pixel_h: Int
    var _offset_x: Float64
    var _offset_y: Float64
    var _quit: Bool

    def __init__(out self):
        self.frame_count = 0
        self.delta_time = 0.0
        self.delta_millis = 0
        self.width = 0
        self.height = 0
        self.exit_on_escape = True
        self.autoscale = AutoScale.OFF
        self.scale = 1.0
        self._design_w = 0
        self._design_h = 0
        self._pixel_w = 0
        self._pixel_h = 0
        self._offset_x = 0.0
        self._offset_y = 0.0
        self._quit = False

    def _set_viewport(mut self, pixel_w: Int, pixel_h: Int):
        """Recompute the design-space mapping for a framebuffer of this size.

        With autoscale on, the program keeps the resolution it was authored
        against and the content is scaled to fit inside the window — so a
        sketch built for 800x600 looks the same on any screen. Both modes
        derive the same uniform factor and differ only in what happens to the
        window area the design does not cover: `FIT` centres the design and
        leaves letterbox bars, `EXTEND` anchors it at the origin and grows the
        design size to fill the frame, so the leftover becomes extra world.
        """
        self._pixel_w = pixel_w
        self._pixel_h = pixel_h
        if (
            self.autoscale != AutoScale.OFF
            and self._design_w > 1
            and self._design_h > 1
        ):
            self.scale = min(
                Float64(pixel_w) / Float64(self._design_w),
                Float64(pixel_h) / Float64(self._design_h),
            )
            if self.autoscale == AutoScale.EXTEND:
                # The axis that constrained the scale divides back out to its
                # design size; the other one gains the slack as world space.
                self.width = Int(Float64(pixel_w) / self.scale + 0.5)
                self.height = Int(Float64(pixel_h) / self.scale + 0.5)
                self._offset_x = 0.0
                self._offset_y = 0.0
            else:
                self.width = self._design_w
                self.height = self._design_h
                self._offset_x = (
                    Float64(pixel_w) - Float64(self._design_w) * self.scale
                ) / 2.0
                self._offset_y = (
                    Float64(pixel_h) - Float64(self._design_h) * self.scale
                ) / 2.0
        else:
            self.width = pixel_w
            self.height = pixel_h
            self.scale = 1.0
            self._offset_x = 0.0
            self._offset_y = 0.0

    def left(self) -> Float64:
        """World x of the left edge — negative, since the origin is centred."""
        return -Float64(self.width) / 2.0

    def right(self) -> Float64:
        return Float64(self.width) / 2.0

    def bottom(self) -> Float64:
        """World y of the bottom edge — negative, since y grows upward."""
        return -Float64(self.height) / 2.0

    def top(self) -> Float64:
        return Float64(self.height) / 2.0

    def _base_matrix(self) -> Matrix[3, 3]:
        """The world-to-pixel mapping: origin centred, y up.

        Anchoring on the framebuffer centre covers all three autoscale modes
        at once — `_offset_x + scale * width / 2` equals `pixel_w / 2` for
        `OFF`, `FIT` and `EXTEND` alike — and avoids the rounding `EXTEND`
        introduces when it stores the extended size as an Int.
        """
        return mat_translate(
            Float64(self._pixel_w) / 2.0, Float64(self._pixel_h) / 2.0
        ) @ mat_scale(self.scale, -self.scale)

    def to_world(self, x: Float64, y: Float64) -> Tuple[Float64, Float64]:
        """Map a window pixel position into world space.

        The inverse of `_base_matrix`, done in arithmetic: pointer positions
        reach the program in the same space it draws in.
        """
        return (
            (x - Float64(self._pixel_w) / 2.0) / self.scale,
            (Float64(self._pixel_h) / 2.0 - y) / self.scale,
        )

    def quit(mut self):
        """Ask the run loop to stop after the current frame.

        Unwinds normally, so the window tears down cleanly and program
        destructors run — unlike `std.sys.exit`, which aborts the process.
        """
        self._quit = True
