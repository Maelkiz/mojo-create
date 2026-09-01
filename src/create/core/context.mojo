from create.math.vector2 import Vector2


struct Context(Movable):
    var frame_count: Int
    var delta_time: Float64
    var delta_millis: Int
    var width: Int
    var height: Int
    var center: Vector2
    var exit_on_escape: Bool

    def __init__(out self):
        self.frame_count = 0
        self.delta_time = 0.0
        self.delta_millis = 0
        self.width = 0
        self.height = 0
        self.center = (self.width // 2, self.height // 2)
        self.exit_on_escape = True
