struct Point(Writable, Copyable, ImplicitlyCopyable, Movable):
    var x: Float64
    var y: Float64

    def __init__(out self, x: Float64, y: Float64):
        self.x = x
        self.y = y

    def __init__(out self, x: Int, y: Int):
        self.x = Float64(x)
        self.y = Float64(y)

    @implicit
    def __init__(out self, t: Tuple[Float64, Float64]):
        self.x = t[0]
        self.y = t[1]

    @implicit
    def __init__(out self, t: Tuple[Int, Int]):
        self.x = Float64(t[0])
        self.y = Float64(t[1])

    def __eq__(self, other: Point) -> Bool:
        return self.x == other.x and self.y == other.y

    def __ne__(self, other: Point) -> Bool:
        return not (self == other)

    def write_to[W: Writer](self, mut writer: W):
        writer.write("Point(", self.x, ", ", self.y, ")")
