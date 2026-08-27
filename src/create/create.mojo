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


@fieldwise_init
struct WindowConfig(ImplicitlyCopyable, Movable):
    var title: String
    var width: Int
    var height: Int


struct Canvas(Movable):
    var _win: Window
    var _fill_r: UInt8
    var _fill_g: UInt8
    var _fill_b: UInt8

    def __init__(out self, config: WindowConfig) raises:
        self._win = Window(config.title, config.width, config.height)
        self._fill_r = 0
        self._fill_g = 0
        self._fill_b = 0

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

    def fill(mut self, gray: UInt8):
        self.fill(gray, gray, gray)

    def fill(mut self, r: UInt8, g: UInt8, b: UInt8):
        self._fill_r = r
        self._fill_g = g
        self._fill_b = b

    def rect(mut self, x: Int, y: Int, w: Int, h: Int) raises:
        var W = self.width()
        var H = self.height()
        var x0 = max(x, 0)
        var y0 = max(y, 0)
        var x1 = min(x + w, W)
        var y1 = min(y + h, H)
        var px = self._win.pixels()
        for row in range(y0, y1):
            for col in range(x0, x1):
                var off = (row * W + col) * 4
                px[unsafe_offset=off] = self._fill_r
                px[unsafe_offset=off + 1] = self._fill_g
                px[unsafe_offset=off + 2] = self._fill_b
                px[unsafe_offset=off + 3] = 255

    def background(mut self, gray: UInt8) raises:
        self.background(gray, gray, gray)

    def background(mut self, r: UInt8, g: UInt8, b: UInt8) raises:
        var w = self.width()
        var h = self.height()
        var px = self._win.pixels()
        for i in range(w * h):
            var off = i * 4
            px[unsafe_offset=off] = r
            px[unsafe_offset=off + 1] = g
            px[unsafe_offset=off + 2] = b
            px[unsafe_offset=off + 3] = 255


trait Program:
    def settings(mut self) -> WindowConfig: ...

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
    var canvas = Canvas(program.settings())
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


