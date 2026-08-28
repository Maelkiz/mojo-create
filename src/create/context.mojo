from .draw import Draw
from .input import Input
from .time import Time


@fieldwise_init
struct Context(Movable):
    var draw: Draw
    var input: Input
    var time: Time
    var width: Int
    var height: Int
