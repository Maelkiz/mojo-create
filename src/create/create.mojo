from window.window import Window
from window.event import (
    Quit,
    Resized,
    KeyDown,
    KeyUp,
    MouseMoved,
    MouseButtonDown,
    MouseButtonUp,
    MouseWheel,
)

var _win: Optional[Window] = None


def init_window(title: String, width: Int, height: Int) raises:
    _win = Window(title, width, height)


trait Program:
    def setup(mut self):
        pass

    def update(mut self): ...

    def on_key_down(mut self, keycode: Int):
        pass

    def on_key_up(mut self, keycode: Int):
        pass

    def on_mouse_moved(mut self, x: Int, y: Int):
        pass

    def on_mouse_down(mut self, button: Int, x: Int, y: Int):
        pass

    def on_mouse_up(mut self, button: Int, x: Int, y: Int):
        pass

    def on_mouse_wheel(mut self, x: Int, y: Int):
        pass

    def on_resize(mut self, width: Int, height: Int):
        pass


def run[P: Program & Movable](var program: P) raises:
    program.setup()

    while _win.value().is_open():
        for event in _win.value().events():
            if event.isa[Quit]():
                _win.value().close()
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

        program.update()
        _win.value().present()


def draw_background(gray: UInt8) raises:
    var px = _win.value().pixels()
    var total = _win.value().width() * _win.value().height()
    for i in range(total):
        var off = i * 4
        px[unsafe_offset=off] = gray
        px[unsafe_offset=off + 1] = gray
        px[unsafe_offset=off + 2] = gray
        px[unsafe_offset=off + 3] = 255
