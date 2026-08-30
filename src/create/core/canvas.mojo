from window.window import Window
from window.event import Event
from .color import Color
from .renderable import Renderable


struct Canvas(Movable):
    var _win: Window
    var _fill: Color
    var _fill_enabled: Bool
    var _stroke: Color
    var _stroke_width: Int
    var _stroke_enabled: Bool

    def __init__(out self, title: String, width: Int, height: Int) raises:
        var fullscreen = width == 0 and height == 0
        self._win = Window(title, width, height, fullscreen)
        self._fill = Color.white()
        self._fill_enabled = True
        self._stroke = Color.black()
        self._stroke_width = 1
        self._stroke_enabled = True

    def is_open(self) -> Bool:
        return self._win.is_open()

    def close(mut self):
        self._win.close()

    def events(mut self) raises -> List[Event]:
        return self._win.events()

    def present(mut self) raises:
        self._win.present()

    def ticks(self) raises -> Int:
        return self._win.ticks()

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

    def background(mut self, color: Color) raises:
        var w = self._win.width()
        var h = self._win.height()
        var px = self._win.pixels()
        for i in range(w * h):
            var off = i * 4
            px[unsafe_offset=off] = color.r
            px[unsafe_offset=off + 1] = color.g
            px[unsafe_offset=off + 2] = color.b
            px[unsafe_offset=off + 3] = color.a

    def draw[S: Renderable](mut self, shape: S) raises:
        shape.render_to(self)
