from window.window import Window
from window.event import (
    Event,
    Quit,
    Resized,
    KeyDown,
    KeyUp,
    MouseMoved,
    MouseButtonDown,
    MouseButtonUp,
    MouseWheel,
)


struct Color(ImplicitlyCopyable, Movable):
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    def __init__(out self, r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

    def __init__(out self, gray: UInt8):
        self.r = gray
        self.g = gray
        self.b = gray
        self.a = 255

    @staticmethod
    def black() -> Color:
        return Color(0)

    @staticmethod
    def white() -> Color:
        return Color(255)

    @staticmethod
    def red() -> Color:
        return Color(255, 0, 0)

    @staticmethod
    def green() -> Color:
        return Color(0, 255, 0)

    @staticmethod
    def blue() -> Color:
        return Color(0, 0, 255)


struct WindowConfig(ImplicitlyCopyable, Movable):
    var title: String
    var width: Int
    var height: Int
    var _fullscreen: Bool

    def __init__(out self, title: String, width: Int = 0, height: Int = 0):
        self.title = title
        self.width = width
        self.height = height
        self._fullscreen = width == 0 and height == 0


struct Canvas(Movable):
    var _win: Window
    var _fill: Color
    var _fill_enabled: Bool
    var _stroke: Color
    var _stroke_width: Int
    var _stroke_enabled: Bool

    def __init__(out self, config: WindowConfig) raises:
        self._win = Window(config.title, config.width, config.height)
        if config._fullscreen:
            self._win.set_fullscreen(True)
        self._fill = Color.white()
        self._fill_enabled = True
        self._stroke = Color.black()
        self._stroke_width = 1
        self._stroke_enabled = True

    def is_open(self) -> Bool:
        return self._win.is_open()

    def close(mut self):
        self._win.close()

    def width(self) -> Int:
        return self._win.width()

    def height(self) -> Int:
        return self._win.height()

    def events(mut self) raises -> List[Event]:
        return self._win.events()

    def present(mut self) raises:
        self._win.present()

    def fill(mut self, color: Color):
        self._fill = color
        self._fill_enabled = True

    def no_fill(mut self):
        self._fill_enabled = False

    def stroke(mut self, color: Color):
        self._stroke = color
        self._stroke_enabled = True

    def no_stroke(mut self):
        self._stroke_enabled = False

    def stroke_width(mut self, w: Int):
        self._stroke_width = w

    def rect(mut self, x: Int, y: Int, w: Int, h: Int) raises:
        var W = self.width()
        var H = self.height()
        var px = self._win.pixels()
        if self._fill_enabled:
            for row in range(max(y, 0), min(y + h, H)):
                for col in range(max(x, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = self._fill.r
                    px[unsafe_offset=off + 1] = self._fill.g
                    px[unsafe_offset=off + 2] = self._fill.b
                    px[unsafe_offset=off + 3] = self._fill.a
        if self._stroke_enabled:
            var sw = self._stroke_width
            var c = self._stroke
            for row in range(max(y, 0), min(y + sw, H)):
                for col in range(max(x, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(y + h - sw, 0), min(y + h, H)):
                for col in range(max(x, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(y + sw, 0), min(y + h - sw, H)):
                for col in range(max(x, 0), min(x + sw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
                for col in range(max(x + w - sw, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a

    def circle(mut self, cx: Int, cy: Int, r: Int) raises:
        var W = self.width()
        var H = self.height()
        var x0 = max(cx - r, 0)
        var y0 = max(cy - r, 0)
        var x1 = min(cx + r + 1, W)
        var y1 = min(cy + r + 1, H)
        var r2 = r * r
        var r_inner = r - self._stroke_width
        var r_inner2 = r_inner * r_inner
        var px = self._win.pixels()
        for row in range(y0, y1):
            var dy = row - cy
            for col in range(x0, x1):
                var dx = col - cx
                var d2 = dx * dx + dy * dy
                if d2 <= r2:
                    var off = (row * W + col) * 4
                    if self._fill_enabled and (not self._stroke_enabled or r_inner <= 0 or d2 <= r_inner2):
                        px[unsafe_offset=off] = self._fill.r
                        px[unsafe_offset=off + 1] = self._fill.g
                        px[unsafe_offset=off + 2] = self._fill.b
                        px[unsafe_offset=off + 3] = self._fill.a
                    elif self._stroke_enabled and d2 > r_inner2:
                        px[unsafe_offset=off] = self._stroke.r
                        px[unsafe_offset=off + 1] = self._stroke.g
                        px[unsafe_offset=off + 2] = self._stroke.b
                        px[unsafe_offset=off + 3] = self._stroke.a

    def background(mut self, color: Color) raises:
        var w = self.width()
        var h = self.height()
        var px = self._win.pixels()
        for i in range(w * h):
            var off = i * 4
            px[unsafe_offset=off] = color.r
            px[unsafe_offset=off + 1] = color.g
            px[unsafe_offset=off + 2] = color.b
            px[unsafe_offset=off + 3] = color.a


trait Program:
    def window(self) -> WindowConfig: ...

    def setup(mut self) raises:
        pass

    def update(mut self, mut canvas: Canvas) raises: ...

    def on_key_down(mut self, keycode: Int) raises:
        pass

    def on_key_up(mut self, keycode: Int) raises:
        pass

    def on_mouse_moved(mut self, x: Int, y: Int) raises:
        pass

    def on_mouse_down(mut self, button: Int, x: Int, y: Int) raises:
        pass

    def on_mouse_up(mut self, button: Int, x: Int, y: Int) raises:
        pass

    def on_mouse_wheel(mut self, x: Int, y: Int) raises:
        pass

    def on_resize(mut self, width: Int, height: Int) raises:
        pass


def run[P: Program & Movable & Deinitable](var program: P) raises:
    var canvas = Canvas(program.window())
    program.setup()

    while canvas.is_open():
        var events = canvas.events()
        for event in events:
            if event.isa[Quit]():
                canvas.close()
            elif event.isa[KeyDown]():
                program.on_key_down(event[KeyDown].keycode)
            elif event.isa[KeyUp]():
                program.on_key_up(event[KeyUp].keycode)
            elif event.isa[MouseMoved]():
                var e = event[MouseMoved]
                program.on_mouse_moved(e.x, e.y)
            elif event.isa[MouseButtonDown]():
                var e = event[MouseButtonDown]
                program.on_mouse_down(e.button, e.x, e.y)
            elif event.isa[MouseButtonUp]():
                var e = event[MouseButtonUp]
                program.on_mouse_up(e.button, e.x, e.y)
            elif event.isa[MouseWheel]():
                var e = event[MouseWheel]
                program.on_mouse_wheel(e.x, e.y)
            elif event.isa[Resized]():
                var e = event[Resized]
                program.on_resize(e.width, e.height)

        program.update(canvas)
        canvas.present()


