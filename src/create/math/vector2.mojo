from std.math import sqrt


struct Vector2(Copyable, ImplicitlyCopyable, Movable, Writable):
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

    @implicit
    def __init__(out self, t: Tuple[Int, Float64]):
        self.x = Float64(t[0])
        self.y = t[1]

    @implicit
    def __init__(out self, t: Tuple[Float64, Int]):
        self.x = t[0]
        self.y = Float64(t[1])

    @staticmethod
    def zero() -> Vector2:
        return Vector2(0.0, 0.0)

    @staticmethod
    def one() -> Vector2:
        return Vector2(1.0, 1.0)

    def __add__(self, other: Vector2) -> Vector2:
        return Vector2(self.x + other.x, self.y + other.y)

    def __sub__(self, other: Vector2) -> Vector2:
        return Vector2(self.x - other.x, self.y - other.y)

    def __mul__(self, s: Float64) -> Vector2:
        return Vector2(self.x * s, self.y * s)

    def __truediv__(self, s: Float64) -> Vector2:
        return Vector2(self.x / s, self.y / s)

    def __neg__(self) -> Vector2:
        return Vector2(-self.x, -self.y)

    def __iadd__(mut self, other: Vector2):
        self.x += other.x
        self.y += other.y

    def __isub__(mut self, other: Vector2):
        self.x -= other.x
        self.y -= other.y

    def __imul__(mut self, s: Float64):
        self.x *= s
        self.y *= s

    def __itruediv__(mut self, s: Float64):
        self.x /= s
        self.y /= s

    def __eq__(self, other: Vector2) -> Bool:
        return self.x == other.x and self.y == other.y

    def __ne__(self, other: Vector2) -> Bool:
        return not (self == other)

    def write_to[W: Writer](self, mut writer: W):
        writer.write("Vector2(", self.x, ", ", self.y, ")")

    def mag(self) -> Float64:
        return sqrt(self.x * self.x + self.y * self.y)

    def mag_sq(self) -> Float64:
        return self.x * self.x + self.y * self.y

    def normalize(self) -> Vector2:
        var m = self.mag()
        return Vector2(self.x / m, self.y / m)

    def dot(self, other: Vector2) -> Float64:
        return self.x * other.x + self.y * other.y

    def dist(self, other: Vector2) -> Float64:
        return (self - other).mag()

    def dist_sq(self, other: Vector2) -> Float64:
        return (self - other).mag_sq()

    def lerp(self, other: Vector2, t: Float64) -> Vector2:
        return Vector2(
            self.x + (other.x - self.x) * t, self.y + (other.y - self.y) * t
        )
