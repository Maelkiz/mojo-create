from std.math import min, max, sqrt
from .vector2 import Vector2


def _closest_on_segment(px: Float64, py: Float64, ax: Float64, ay: Float64, bx: Float64, by: Float64) -> Vector2:
    var dx = bx - ax
    var dy = by - ay
    var len_sq = dx * dx + dy * dy
    if len_sq == 0.0:
        return Vector2(ax, ay)
    var t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / len_sq))
    return Vector2(ax + t * dx, ay + t * dy)


def _orientation(ax: Float64, ay: Float64, bx: Float64, by: Float64, cx: Float64, cy: Float64) -> Int:
    var cross = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
    if cross > 0.0:
        return 1
    if cross < 0.0:
        return -1
    return 0


def _point_on_segment(px: Float64, py: Float64, ax: Float64, ay: Float64, bx: Float64, by: Float64) -> Bool:
    var cross = (bx - ax) * (py - ay) - (by - ay) * (px - ax)
    if cross != 0.0:
        return False
    return min(ax, bx) <= px <= max(ax, bx) and min(ay, by) <= py <= max(ay, by)


def _project_range[N: Int](nx: Float64, ny: Float64, pts: InlineArray[Vector2, N]) -> Tuple[Float64, Float64]:
    var lo = nx * pts[0].x + ny * pts[0].y
    var hi = lo
    for i in range(1, N):
        var proj = nx * pts[i].x + ny * pts[i].y
        lo = min(lo, proj)
        hi = max(hi, proj)
    return (lo, hi)


def _ranges_separate[N: Int, M: Int](nx: Float64, ny: Float64, a: InlineArray[Vector2, N], b: InlineArray[Vector2, M]) -> Bool:
    var ra = _project_range(nx, ny, a)
    var rb = _project_range(nx, ny, b)
    return ra[1] < rb[0] or rb[1] < ra[0]


def _polygons_overlap[N: Int, M: Int](a: InlineArray[Vector2, N], b: InlineArray[Vector2, M]) -> Bool:
    # SAT over both polygons' edge normals -- exact for convex polygons.
    # A zero-length edge contributes no normal, so its axis is skipped; its
    # direction is tested instead (needed to separate collinear degenerate
    # polygons), and the world axes are always tested (needed when both
    # polygons collapse to points and contribute no edge axes at all).
    # Testing extra axes is always sound: separation on any axis proves
    # disjointness, and genuinely overlapping shapes separate on none.
    for i in range(N):
        var p0 = a[i]
        var p1 = a[(i + 1) % N]
        var dx = p1.x - p0.x
        var dy = p1.y - p0.y
        if dx == 0.0 and dy == 0.0:
            continue
        if _ranges_separate(-dy, dx, a, b):
            return False
        if _ranges_separate(dx, dy, a, b):
            return False
    for i in range(M):
        var p0 = b[i]
        var p1 = b[(i + 1) % M]
        var dx = p1.x - p0.x
        var dy = p1.y - p0.y
        if dx == 0.0 and dy == 0.0:
            continue
        if _ranges_separate(-dy, dx, a, b):
            return False
        if _ranges_separate(dx, dy, a, b):
            return False
    if _ranges_separate(1.0, 0.0, a, b):
        return False
    if _ranges_separate(0.0, 1.0, a, b):
        return False
    return True


@fieldwise_init
struct Rectangle:
    var x: Float64
    var y: Float64
    var w: Float64
    var h: Float64

    def __init__(out self, x: Int, y: Int, w: Int, h: Int):
        self = Rectangle(Float64(x), Float64(y), Float64(w), Float64(h))

    def __init__(out self, pos: Vector2, w: Float64, h: Float64):
        self = Rectangle(pos.x, pos.y, w, h)

    def __init__(out self, pos: Vector2, w: Int, h: Int):
        self = Rectangle(pos.x, pos.y, Float64(w), Float64(h))

    def __init__(out self, pos: Vector2, size: Vector2):
        self = Rectangle(pos.x, pos.y, size.x, size.y)

    def center(self) -> Vector2:
        return Vector2(self.x, self.y)

    def closest_point(self, px: Float64, py: Float64) -> Vector2:
        return Vector2(max(self.left(), min(px, self.right())),
                     max(self.bottom(), min(py, self.top())))

    def closest_point(self, v: Vector2) -> Vector2:
        return self.closest_point(v.x, v.y)

    def left(self) -> Float64:
        return self.x - self.w / 2.0

    def right(self) -> Float64:
        return self.x + self.w / 2.0

    def bottom(self) -> Float64:
        return self.y - self.h / 2.0

    def top(self) -> Float64:
        return self.y + self.h / 2.0

    def contains(self, px: Float64, py: Float64) -> Bool:
        return self.left() <= px <= self.right() and self.bottom() <= py <= self.top()

    def contains(self, v: Vector2) -> Bool:
        return self.contains(v.x, v.y)

    def move_to(mut self, x: Float64, y: Float64):
        self.x = x; self.y = y

    def move_to(mut self, x: Int, y: Int):
        self.move_to(Float64(x), Float64(y))

    def move_to(mut self, pos: Vector2):
        self.move_to(pos.x, pos.y)

    def translate(mut self, dx: Float64, dy: Float64):
        self.x += dx; self.y += dy

    def translate(mut self, dx: Int, dy: Int):
        self.translate(Float64(dx), Float64(dy))

    def translate(mut self, delta: Vector2):
        self.translate(delta.x, delta.y)

    def _points(self) -> InlineArray[Vector2, 4]:
        return [
            Vector2(self.left(), self.bottom()),
            Vector2(self.right(), self.bottom()),
            Vector2(self.right(), self.top()),
            Vector2(self.left(), self.top()),
        ]


@fieldwise_init
struct Circle:
    var x: Float64
    var y: Float64
    var r: Float64

    def __init__(out self, x: Int, y: Int, r: Int):
        self = Circle(Float64(x), Float64(y), Float64(r))

    def __init__(out self, pos: Vector2, r: Float64):
        self = Circle(pos.x, pos.y, r)

    def __init__(out self, pos: Vector2, r: Int):
        self = Circle(pos.x, pos.y, Float64(r))

    def center(self) -> Vector2:
        return Vector2(self.x, self.y)

    def closest_point(self, px: Float64, py: Float64) -> Vector2:
        var dx = px - self.x
        var dy = py - self.y
        var dist_sq = dx * dx + dy * dy
        if dist_sq == 0.0 or dist_sq <= self.r * self.r:
            return Vector2(px, py)
        var dist = sqrt(dist_sq)
        return Vector2(self.x + dx / dist * self.r, self.y + dy / dist * self.r)

    def closest_point(self, v: Vector2) -> Vector2:
        return self.closest_point(v.x, v.y)

    def contains(self, px: Float64, py: Float64) -> Bool:
        var dx = px - self.x
        var dy = py - self.y
        return dx * dx + dy * dy <= self.r * self.r

    def contains(self, v: Vector2) -> Bool:
        return self.contains(v.x, v.y)

    def move_to(mut self, x: Float64, y: Float64):
        self.x = x; self.y = y

    def move_to(mut self, x: Int, y: Int):
        self.move_to(Float64(x), Float64(y))

    def move_to(mut self, pos: Vector2):
        self.move_to(pos.x, pos.y)

    def translate(mut self, dx: Float64, dy: Float64):
        self.x += dx; self.y += dy

    def translate(mut self, dx: Int, dy: Int):
        self.translate(Float64(dx), Float64(dy))

    def translate(mut self, delta: Vector2):
        self.translate(delta.x, delta.y)


@fieldwise_init
struct Line:
    var x0: Float64
    var y0: Float64
    var x1: Float64
    var y1: Float64

    def __init__(out self, x0: Int, y0: Int, x1: Int, y1: Int):
        self = Line(Float64(x0), Float64(y0), Float64(x1), Float64(y1))

    def __init__(out self, start: Vector2, end: Vector2):
        self = Line(start.x, start.y, end.x, end.y)

    def length_sq(self) -> Float64:
        var dx = self.x1 - self.x0
        var dy = self.y1 - self.y0
        return dx * dx + dy * dy

    def length(self) -> Float64:
        return sqrt(self.length_sq())

    def intersects(self, other: Line) -> Bool:
        var o1 = _orientation(self.x0, self.y0, self.x1, self.y1, other.x0, other.y0)
        var o2 = _orientation(self.x0, self.y0, self.x1, self.y1, other.x1, other.y1)
        var o3 = _orientation(other.x0, other.y0, other.x1, other.y1, self.x0, self.y0)
        var o4 = _orientation(other.x0, other.y0, other.x1, other.y1, self.x1, self.y1)

        if o1 != 0 and o2 != 0 and o1 != o2 and o3 != 0 and o4 != 0 and o3 != o4:
            return True
        # Collinear arms -- inclusive: touching or overlapping counts.
        if o1 == 0 and _point_on_segment(other.x0, other.y0, self.x0, self.y0, self.x1, self.y1):
            return True
        if o2 == 0 and _point_on_segment(other.x1, other.y1, self.x0, self.y0, self.x1, self.y1):
            return True
        if o3 == 0 and _point_on_segment(self.x0, self.y0, other.x0, other.y0, other.x1, other.y1):
            return True
        if o4 == 0 and _point_on_segment(self.x1, self.y1, other.x0, other.y0, other.x1, other.y1):
            return True
        return False

    # `l.intersects(x)` is the line-as-subject relation -- asymmetric, unlike
    # `overlaps`, because a `Line` has no interior and cannot be an operand of
    # a symmetric region test. Point and Line are exact by construction; a
    # region is tested by the cheapest exact method for that shape --
    # `Circle` via `closest_point`-then-`contains` (exact only because a
    # circle's containment is radial from its centre), `Rectangle` and
    # `Triangle` via endpoint containment (covers a segment wholly inside,
    # which no edge test would catch) plus their edges as `Line`s.
    def intersects(self, px: Float64, py: Float64) -> Bool:
        return _point_on_segment(px, py, self.x0, self.y0, self.x1, self.y1)

    def intersects(self, v: Vector2) -> Bool:
        return self.intersects(v.x, v.y)

    def intersects(self, c: Circle) -> Bool:
        var closest = self.closest_point(c.x, c.y)
        return c.contains(closest)

    def intersects(self, r: Rectangle) -> Bool:
        if r.contains(self.x0, self.y0) or r.contains(self.x1, self.y1):
            return True
        var pts = r._points()
        for i in range(4):
            var edge = Line(pts[i], pts[(i + 1) % 4])
            if self.intersects(edge):
                return True
        return False

    def intersects(self, t: Triangle) -> Bool:
        if t.contains(self.x0, self.y0) or t.contains(self.x1, self.y1):
            return True
        var pts = t._points()
        for i in range(3):
            var edge = Line(pts[i], pts[(i + 1) % 3])
            if self.intersects(edge):
                return True
        return False

    def closest_point(self, px: Float64, py: Float64) -> Vector2:
        return _closest_on_segment(px, py, self.x0, self.y0, self.x1, self.y1)

    def closest_point(self, v: Vector2) -> Vector2:
        return self.closest_point(v.x, v.y)

    def midpoint(self) -> Vector2:
        return Vector2((self.x0 + self.x1) / 2.0, (self.y0 + self.y1) / 2.0)

    def move_to(mut self, x: Float64, y: Float64):
        var m = self.midpoint()
        var dx = x - m.x; var dy = y - m.y
        self.x0 += dx; self.y0 += dy
        self.x1 += dx; self.y1 += dy

    def move_to(mut self, x: Int, y: Int):
        self.move_to(Float64(x), Float64(y))

    def move_to(mut self, pos: Vector2):
        self.move_to(pos.x, pos.y)

    def translate(mut self, dx: Float64, dy: Float64):
        self.x0 += dx; self.y0 += dy
        self.x1 += dx; self.y1 += dy

    def translate(mut self, dx: Int, dy: Int):
        self.translate(Float64(dx), Float64(dy))

    def translate(mut self, delta: Vector2):
        self.translate(delta.x, delta.y)


@fieldwise_init
struct Triangle:
    var x1: Float64
    var y1: Float64
    var x2: Float64
    var y2: Float64
    var x3: Float64
    var y3: Float64

    def __init__(out self, x1: Int, y1: Int, x2: Int, y2: Int, x3: Int, y3: Int):
        self = Triangle(Float64(x1), Float64(y1), Float64(x2), Float64(y2),
                        Float64(x3), Float64(y3))

    def __init__(out self, a: Vector2, b: Vector2, c: Vector2):
        self = Triangle(a.x, a.y, b.x, b.y, c.x, c.y)

    def center(self) -> Vector2:
        return Vector2((self.x1 + self.x2 + self.x3) / 3.0,
                     (self.y1 + self.y2 + self.y3) / 3.0)

    def closest_point(self, px: Float64, py: Float64) -> Vector2:
        if self.contains(px, py):
            return Vector2(px, py)
        var p1 = _closest_on_segment(px, py, self.x1, self.y1, self.x2, self.y2)
        var p2 = _closest_on_segment(px, py, self.x2, self.y2, self.x3, self.y3)
        var p3 = _closest_on_segment(px, py, self.x3, self.y3, self.x1, self.y1)
        var d1 = (p1.x - px) * (p1.x - px) + (p1.y - py) * (p1.y - py)
        var d2 = (p2.x - px) * (p2.x - px) + (p2.y - py) * (p2.y - py)
        var d3 = (p3.x - px) * (p3.x - px) + (p3.y - py) * (p3.y - py)
        if d1 <= d2 and d1 <= d3: return p1
        if d2 <= d3: return p2
        return p3

    def closest_point(self, v: Vector2) -> Vector2:
        return self.closest_point(v.x, v.y)

    def contains(self, v: Vector2) -> Bool:
        return self.contains(v.x, v.y)

    def contains(self, px: Float64, py: Float64) -> Bool:
        var signed_area2 = (self.x2 - self.x1) * (self.y3 - self.y1) - (self.y2 - self.y1) * (self.x3 - self.x1)
        if signed_area2 == 0.0:
            # Degenerate hull: a segment (or a point). Contained iff on the
            # longest edge -- the other two edges are contained within it.
            var len12 = (self.x2 - self.x1) * (self.x2 - self.x1) + (self.y2 - self.y1) * (self.y2 - self.y1)
            var len23 = (self.x3 - self.x2) * (self.x3 - self.x2) + (self.y3 - self.y2) * (self.y3 - self.y2)
            var len31 = (self.x1 - self.x3) * (self.x1 - self.x3) + (self.y1 - self.y3) * (self.y1 - self.y3)
            if len12 >= len23 and len12 >= len31:
                return _point_on_segment(px, py, self.x1, self.y1, self.x2, self.y2)
            if len23 >= len31:
                return _point_on_segment(px, py, self.x2, self.y2, self.x3, self.y3)
            return _point_on_segment(px, py, self.x3, self.y3, self.x1, self.y1)
        var d1 = (self.x2 - self.x1) * (py - self.y1) - (self.y2 - self.y1) * (px - self.x1)
        var d2 = (self.x3 - self.x2) * (py - self.y2) - (self.y3 - self.y2) * (px - self.x2)
        var d3 = (self.x1 - self.x3) * (py - self.y3) - (self.y1 - self.y3) * (px - self.x3)
        var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
        var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
        return not (has_neg and has_pos)

    def move_to(mut self, x: Float64, y: Float64):
        var c = self.center()
        var dx = x - c.x; var dy = y - c.y
        self.x1 += dx; self.y1 += dy
        self.x2 += dx; self.y2 += dy
        self.x3 += dx; self.y3 += dy

    def move_to(mut self, x: Int, y: Int):
        self.move_to(Float64(x), Float64(y))

    def move_to(mut self, pos: Vector2):
        self.move_to(pos.x, pos.y)

    def translate(mut self, dx: Float64, dy: Float64):
        self.x1 += dx; self.y1 += dy
        self.x2 += dx; self.y2 += dy
        self.x3 += dx; self.y3 += dy

    def translate(mut self, dx: Int, dy: Int):
        self.translate(Float64(dx), Float64(dy))

    def translate(mut self, delta: Vector2):
        self.translate(delta.x, delta.y)

    def _points(self) -> InlineArray[Vector2, 3]:
        return [
            Vector2(self.x1, self.y1),
            Vector2(self.x2, self.y2),
            Vector2(self.x3, self.y3),
        ]


# `overlaps(a, b)` is the whole overlap-testing surface: one specialized,
# exact overload per unordered shape pair, so a symmetric relation reads as
# a symmetric call. Each pair picks the cheapest exact test for that
# combination rather than routing through a single generic algorithm --
# `Circle` vs. anything else is a `closest_point`-then-`contains` check
# (exact only because a circle's containment is radial from its centre),
# and any pair of straight-edged shapes is SAT over `_polygons_overlap`.
def overlaps(a: Rectangle, b: Rectangle) -> Bool:
    return (a.left() <= b.right() and a.right() >= b.left() and
            a.bottom() <= b.top() and a.top() >= b.bottom())


def overlaps(a: Circle, b: Circle) -> Bool:
    var dx = a.x - b.x
    var dy = a.y - b.y
    var rsum = a.r + b.r
    return dx * dx + dy * dy <= rsum * rsum


def overlaps(a: Circle, b: Rectangle) -> Bool:
    return a.contains(b.closest_point(a.x, a.y))


def overlaps(a: Rectangle, b: Circle) -> Bool:
    return overlaps(b, a)


def overlaps(a: Circle, b: Triangle) -> Bool:
    return a.contains(b.closest_point(a.x, a.y))


def overlaps(a: Triangle, b: Circle) -> Bool:
    return overlaps(b, a)


def overlaps(a: Rectangle, b: Triangle) -> Bool:
    return _polygons_overlap(a._points(), b._points())


def overlaps(a: Triangle, b: Rectangle) -> Bool:
    return overlaps(b, a)


def overlaps(a: Triangle, b: Triangle) -> Bool:
    return _polygons_overlap(a._points(), b._points())
