from .canvas import Canvas
from .time import Time
from create.math.vector2 import Vector2


struct Context(Movable):
    var _canvas: Canvas
    var time: Time
    var width: Int
    var height: Int
    var center: Vector2
    var exit_on_escape: Bool

    def __init__(out self, var canvas: Canvas, time: Time, width: Int, height: Int):
        self._canvas = canvas^
        self.time = time
        self.width = width
        self.height = height
        self.center = Vector2(width // 2, height // 2)
        self.exit_on_escape = True
