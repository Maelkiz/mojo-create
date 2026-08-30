from std.math import min, max, sqrt


def _ccw(ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int) -> Bool:
    return (cy - ay) * (bx - ax) > (by - ay) * (cx - ax)


def _project_min(nx: Int, ny: Int, ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int) -> Int:
    return min(nx * ax + ny * ay, min(nx * bx + ny * by, nx * cx + ny * cy))


def _project_max(nx: Int, ny: Int, ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int) -> Int:
    return max(nx * ax + ny * ay, max(nx * bx + ny * by, nx * cx + ny * cy))


@fieldwise_init
struct Rectangle:
    var x: Int
    var y: Int
    var w: Int
    var h: Int

    def left(self) -> Int:
        return self.x - self.w // 2

    def right(self) -> Int:
        return self.x + self.w // 2

    def top(self) -> Int:
        return self.y - self.h // 2

    def bottom(self) -> Int:
        return self.y + self.h // 2

    def contains(self, px: Int, py: Int) -> Bool:
        return self.left() <= px <= self.right() and self.top() <= py <= self.bottom()

    def overlaps(self, other: Rectangle) -> Bool:
        return (self.left() < other.right() and self.right() > other.left() and
                self.top() < other.bottom() and self.bottom() > other.top())

    def overlaps(self, c: Circle) -> Bool:
        var nearest_x = max(self.left(), min(c.x, self.right()))
        var nearest_y = max(self.top(), min(c.y, self.bottom()))
        var dx = c.x - nearest_x
        var dy = c.y - nearest_y
        return dx * dx + dy * dy <= c.r * c.r


@fieldwise_init
struct Circle:
    var x: Int
    var y: Int
    var r: Int

    def contains(self, px: Int, py: Int) -> Bool:
        var dx = px - self.x
        var dy = py - self.y
        return dx * dx + dy * dy <= self.r * self.r

    def overlaps(self, other: Circle) -> Bool:
        var dx = self.x - other.x
        var dy = self.y - other.y
        var rsum = self.r + other.r
        return dx * dx + dy * dy <= rsum * rsum

    def overlaps(self, r: Rectangle) -> Bool:
        return r.overlaps(self)


@fieldwise_init
struct Line:
    var x0: Int
    var y0: Int
    var x1: Int
    var y1: Int

    def length_sq(self) -> Int:
        var dx = self.x1 - self.x0
        var dy = self.y1 - self.y0
        return dx * dx + dy * dy

    def length(self) -> Float64:
        return sqrt(Float64(self.length_sq()))

    def intersects(self, other: Line) -> Bool:
        return (_ccw(self.x0, self.y0, other.x0, other.y0, other.x1, other.y1) !=
                _ccw(self.x1, self.y1, other.x0, other.y0, other.x1, other.y1) and
                _ccw(self.x0, self.y0, self.x1, self.y1, other.x0, other.y0) !=
                _ccw(self.x0, self.y0, self.x1, self.y1, other.x1, other.y1))


@fieldwise_init
struct Triangle:
    var x1: Int
    var y1: Int
    var x2: Int
    var y2: Int
    var x3: Int
    var y3: Int

    def contains(self, px: Int, py: Int) -> Bool:
        var d1 = (self.x2 - self.x1) * (py - self.y1) - (self.y2 - self.y1) * (px - self.x1)
        var d2 = (self.x3 - self.x2) * (py - self.y2) - (self.y3 - self.y2) * (px - self.x2)
        var d3 = (self.x1 - self.x3) * (py - self.y3) - (self.y1 - self.y3) * (px - self.x3)
        var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
        var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
        return not (has_neg and has_pos)

    def _separates(self, nx: Int, ny: Int, other: Triangle) -> Bool:
        var min1 = _project_min(nx, ny, self.x1, self.y1, self.x2, self.y2, self.x3, self.y3)
        var max1 = _project_max(nx, ny, self.x1, self.y1, self.x2, self.y2, self.x3, self.y3)
        var min2 = _project_min(nx, ny, other.x1, other.y1, other.x2, other.y2, other.x3, other.y3)
        var max2 = _project_max(nx, ny, other.x1, other.y1, other.x2, other.y2, other.x3, other.y3)
        return max1 < min2 or max2 < min1

    def overlaps(self, other: Triangle) -> Bool:
        # SAT — 6 edge normals (3 per triangle)
        if self._separates(-(self.y2 - self.y1), self.x2 - self.x1, other): return False
        if self._separates(-(self.y3 - self.y2), self.x3 - self.x2, other): return False
        if self._separates(-(self.y1 - self.y3), self.x1 - self.x3, other): return False
        if self._separates(-(other.y2 - other.y1), other.x2 - other.x1, other): return False
        if self._separates(-(other.y3 - other.y2), other.x3 - other.x2, other): return False
        if self._separates(-(other.y1 - other.y3), other.x1 - other.x3, other): return False
        return True
