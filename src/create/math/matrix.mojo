from std.math import sin, cos, tan, abs, min, max


struct Matrix[rows: Int, cols: Int](Writable, Copyable, ImplicitlyCopyable, Movable):
    var data: Array[Float64, Self.rows * Self.cols]

    def __init__(out self):
        self.data = Array[Float64, Self.rows * Self.cols](fill=0.0)

    def __init__(out self, *, copy: Self):
        self.data = Array[Float64, Self.rows * Self.cols](copy=copy.data)

    def __getitem__(self, r: Int, c: Int) -> Float64:
        return self.data[r * Self.cols + c]

    def __setitem__(mut self, r: Int, c: Int, val: Float64):
        self.data[r * Self.cols + c] = val

    def __matmul__[P: Int](self, rhs: Matrix[Self.cols, P]) -> Matrix[Self.rows, P]:
        var result = Matrix[Self.rows, P]()
        for r in range(Self.rows):
            for p in range(P):
                var s = 0.0
                for k in range(Self.cols):
                    s += self[r, k] * rhs[k, p]
                result[r, p] = s
        return result^

    def transposed(self) -> Matrix[Self.cols, Self.rows]:
        var result = Matrix[Self.cols, Self.rows]()
        for r in range(Self.rows):
            for c in range(Self.cols):
                result[c, r] = self[r, c]
        return result^

    def write_to[W: Writer](self, mut writer: W):
        writer.write("Matrix[", Self.rows, "x", Self.cols, "](")
        for r in range(Self.rows):
            if r > 0:
                writer.write(", ")
            writer.write("[")
            for c in range(Self.cols):
                if c > 0:
                    writer.write(", ")
                writer.write(self[r, c])
            writer.write("]")
        writer.write(")")


def identity[N: Int]() -> Matrix[N, N]:
    var m = Matrix[N, N]()
    comptime for i in range(N):
        m[i, i] = 1.0
    return m^


def translate(dx: Float64, dy: Float64) -> Matrix[3, 3]:
    var m = identity[3]()
    m[0, 2] = dx
    m[1, 2] = dy
    return m^


def rotate(angle: Float64) -> Matrix[3, 3]:
    var m = identity[3]()
    var c = cos(angle)
    var s = sin(angle)
    m[0, 0] = c
    m[0, 1] = -s
    m[1, 0] = s
    m[1, 1] = c
    return m^


def scale(sx: Float64, sy: Float64) -> Matrix[3, 3]:
    var m = identity[3]()
    m[0, 0] = sx
    m[1, 1] = sy
    return m^


def scale(s: Float64) -> Matrix[3, 3]:
    return scale(s, s)


def perspective(fov: Float64, aspect: Float64, near: Float64, far: Float64) -> Matrix[4, 4]:
    var m = Matrix[4, 4]()
    var f = 1.0 / tan(fov / 2.0)
    m[0, 0] = f / aspect
    m[1, 1] = f
    m[2, 2] = (far + near) / (near - far)
    m[2, 3] = (2.0 * far * near) / (near - far)
    m[3, 2] = -1.0
    return m^


def apply(m: Matrix[3, 3], x: Float64, y: Float64) -> Tuple[Float64, Float64]:
    var ox = m[0, 0] * x + m[0, 1] * y + m[0, 2]
    var oy = m[1, 0] * x + m[1, 1] * y + m[1, 2]
    var ow = m[2, 0] * x + m[2, 1] * y + m[2, 2]
    return (ox / ow, oy / ow)


def apply(m: Matrix[4, 4], x: Float64, y: Float64, z: Float64) -> Tuple[Float64, Float64, Float64]:
    var ox = m[0, 0] * x + m[0, 1] * y + m[0, 2] * z + m[0, 3]
    var oy = m[1, 0] * x + m[1, 1] * y + m[1, 2] * z + m[1, 3]
    var oz = m[2, 0] * x + m[2, 1] * y + m[2, 2] * z + m[2, 3]
    var ow = m[3, 0] * x + m[3, 1] * y + m[3, 2] * z + m[3, 3]
    return (ox / ow, oy / ow, oz / ow)


def inverse[N: Int](m: Matrix[N, N]) -> Matrix[N, N]:
    var aug = Matrix[N, N * 2]()
    for r in range(N):
        for c in range(N):
            aug[r, c] = m[r, c]
        aug[r, N + r] = 1.0

    for col in range(N):
        var max_val = abs(aug[col, col])
        var max_row = col
        for r in range(col + 1, N):
            var v = abs(aug[r, col])
            if v > max_val:
                max_val = v
                max_row = r

        for c in range(N * 2):
            var tmp = aug[col, c]
            aug[col, c] = aug[max_row, c]
            aug[max_row, c] = tmp

        var pivot = aug[col, col]
        for c in range(N * 2):
            aug[col, c] /= pivot

        for r in range(N):
            if r != col:
                var factor = aug[r, col]
                for c in range(N * 2):
                    aug[r, c] -= factor * aug[col, c]

    var result = Matrix[N, N]()
    for r in range(N):
        for c in range(N):
            result[r, c] = aug[r, N + c]
    return result^
