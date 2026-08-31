from std.math import sqrt


struct Vector3(Writable, Copyable, ImplicitlyCopyable, Movable):
    var x: Float64
    var y: Float64
    var z: Float64

    def __init__(out self, x: Float64, y: Float64, z: Float64):
        self.x = x
        self.y = y
        self.z = z

    @staticmethod
    def zero() -> Vector3:
        return Vector3(0.0, 0.0, 0.0)

    @staticmethod
    def one() -> Vector3:
        return Vector3(1.0, 1.0, 1.0)

    def __add__(self, other: Vector3) -> Vector3:
        return Vector3(self.x + other.x, self.y + other.y, self.z + other.z)

    def __sub__(self, other: Vector3) -> Vector3:
        return Vector3(self.x - other.x, self.y - other.y, self.z - other.z)

    def __mul__(self, s: Float64) -> Vector3:
        return Vector3(self.x * s, self.y * s, self.z * s)

    def __truediv__(self, s: Float64) -> Vector3:
        return Vector3(self.x / s, self.y / s, self.z / s)

    def __neg__(self) -> Vector3:
        return Vector3(-self.x, -self.y, -self.z)

    def __iadd__(mut self, other: Vector3):
        self.x += other.x
        self.y += other.y
        self.z += other.z

    def __isub__(mut self, other: Vector3):
        self.x -= other.x
        self.y -= other.y
        self.z -= other.z

    def __imul__(mut self, s: Float64):
        self.x *= s
        self.y *= s
        self.z *= s

    def __itruediv__(mut self, s: Float64):
        self.x /= s
        self.y /= s
        self.z /= s

    def __eq__(self, other: Vector3) -> Bool:
        return self.x == other.x and self.y == other.y and self.z == other.z

    def __ne__(self, other: Vector3) -> Bool:
        return not (self == other)

    def write_to[W: Writer](self, mut writer: W):
        writer.write("Vector3(", self.x, ", ", self.y, ", ", self.z, ")")

    def mag(self) -> Float64:
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

    def mag_sq(self) -> Float64:
        return self.x * self.x + self.y * self.y + self.z * self.z

    def normalize(self) -> Vector3:
        var m = self.mag()
        return Vector3(self.x / m, self.y / m, self.z / m)

    def dot(self, other: Vector3) -> Float64:
        return self.x * other.x + self.y * other.y + self.z * other.z

    def cross(self, other: Vector3) -> Vector3:
        return Vector3(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        )

    def dist(self, other: Vector3) -> Float64:
        return (self - other).mag()

    def dist_sq(self, other: Vector3) -> Float64:
        return (self - other).mag_sq()

    def lerp(self, other: Vector3, t: Float64) -> Vector3:
        return Vector3(
            self.x + (other.x - self.x) * t,
            self.y + (other.y - self.y) * t,
            self.z + (other.z - self.z) * t,
        )
