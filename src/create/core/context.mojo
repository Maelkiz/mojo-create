from .canvas import Canvas
from .input import Input
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
