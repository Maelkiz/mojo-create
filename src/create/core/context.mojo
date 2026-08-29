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

    def __init__(out self, var canvas: Canvas, var input: Input, time: Time, width: Int, height: Int):
        self._canvas = canvas^
        self.input = input^
        self.time = time
        self.width = width
        self.height = height

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

    def render[S: Renderable](mut self, shape: S) raises:
        shape.render_to(self._canvas)
