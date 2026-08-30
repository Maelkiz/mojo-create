from .canvas import Canvas
from .color import Color
from .input import Input
from .renderable import Renderable
from .time import Time


struct Context(Movable):
    var _canvas: Canvas
    var input: Input
    var time: Time
    var width: Int
    var height: Int
    var exit_on_escape: Bool

    def __init__(out self, var canvas: Canvas, var input: Input, time: Time, width: Int, height: Int):
        self._canvas = canvas^
        self.input = input^
        self.time = time
        self.width = width
        self.height = height
        self.exit_on_escape = True

    def fill(mut self, color: Color):
        self._canvas._fill = color
        self._canvas._fill_enabled = True

    def no_fill(mut self):
        self._canvas._fill_enabled = False

    def stroke(mut self, color: Color):
        self._canvas._stroke = color
        self._canvas._stroke_enabled = True

    def no_stroke(mut self):
        self._canvas._stroke_enabled = False

    def stroke_width(mut self, w: Int):
        self._canvas._stroke_width = w

    def background(mut self, color: Color) raises:
        var w = self._canvas._win.width()
        var h = self._canvas._win.height()
        var px = self._canvas._win.pixels()
        for i in range(w * h):
            var off = i * 4
            px[unsafe_offset=off] = color.r
            px[unsafe_offset=off + 1] = color.g
            px[unsafe_offset=off + 2] = color.b
            px[unsafe_offset=off + 3] = color.a

    def render[S: Renderable](mut self, shape: S) raises:
        shape.render_to(self._canvas)
