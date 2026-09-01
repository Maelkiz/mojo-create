from std.math import min
from create.math.vector2 import Vector2


struct Context(Movable):
    var frame_count: Int
    var delta_time: Float64
    var delta_millis: Int
    var width: Int
    var height: Int
    var center: Vector2
    var exit_on_escape: Bool
    var autoscale: Bool
    var scale: Float64
    var _design_w: Int
    var _design_h: Int
    var _offset_x: Float64
    var _offset_y: Float64
    var _quit: Bool

    def __init__(out self):
        self.frame_count = 0
        self.delta_time = 0.0
        self.delta_millis = 0
        self.width = 0
        self.height = 0
        self.center = (self.width // 2, self.height // 2)
        self.exit_on_escape = True
        self.autoscale = False
        self.scale = 1.0
        self._design_w = 0
        self._design_h = 0
        self._offset_x = 0.0
        self._offset_y = 0.0
        self._quit = False

    def _set_viewport(mut self, pixel_w: Int, pixel_h: Int):
        """Recompute the design-space mapping for a framebuffer of this size.

        With autoscale on, the program keeps the resolution it was authored
        against and the content is scaled to fit inside the window, centred —
        so a sketch built for 800x600 looks the same on any screen, with
        letterbox bars taking up the leftover.
        """
        if self.autoscale and self._design_w > 1 and self._design_h > 1:
            self.width = self._design_w
            self.height = self._design_h
            self.scale = min(
                Float64(pixel_w) / Float64(self._design_w),
                Float64(pixel_h) / Float64(self._design_h),
            )
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
        self.center = Vector2(self.width // 2, self.height // 2)

    def to_design(self, x: Float64, y: Float64) -> Tuple[Float64, Float64]:
        """Map a window pixel position into design space.

        The identity when `autoscale` is off, so callers need no branch.
        """
        return ((x - self._offset_x) / self.scale, (y - self._offset_y) / self.scale)

    def quit(mut self):
        """Ask the run loop to stop after the current frame.

        Unwinds normally, so the window tears down cleanly and program
        destructors run — unlike `std.sys.exit`, which aborts the process.
        """
        self._quit = True
