from std.testing import TestSuite, assert_equal, assert_true, assert_almost_equal
from create.math.geometry import Rectangle, Circle, Line, Triangle, overlaps
from create.math.vector2 import Vector2


# Rectangle — x,y is center
def test_rect_bounds() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 6.0)
    assert_equal(r.left(), -5.0)
    assert_equal(r.right(), 5.0)
    assert_equal(r.bottom(), -3.0)
    assert_equal(r.top(), 3.0)


def test_rect_center() raises -> None:
    var r = Rectangle(4.0, 2.0, 10.0, 6.0)
    var c = r.center()
    assert_equal(c.x, 4.0)
    assert_equal(c.y, 2.0)


def test_rect_contains_inside() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_true(r.contains(0.0, 0.0))
    assert_true(r.contains(4.9, 4.9))


def test_rect_contains_outside() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_equal(r.contains(6.0, 0.0), False)
    assert_equal(r.contains(0.0, 6.0), False)


def test_rect_contains_on_edge() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_true(r.contains(5.0, 0.0))
    assert_true(r.contains(0.0, 5.0))


def test_rect_closest_point_outside() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var p = r.closest_point(10.0, 0.0)
    assert_equal(p.x, 5.0)
    assert_equal(p.y, 0.0)


def test_rect_closest_point_inside() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var p = r.closest_point(1.0, 1.0)
    assert_equal(p.x, 1.0)
    assert_equal(p.y, 1.0)


def test_rect_move_to() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    r.move_to(5.0, 5.0)
    assert_equal(r.x, 5.0)
    assert_equal(r.y, 5.0)


def test_rect_translate() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    r.translate(2.0, 3.0)
    assert_equal(r.x, 2.0)
    assert_equal(r.y, 3.0)


# Circle
def test_circle_center() raises -> None:
    var c = Circle(3.0, 4.0, 5.0)
    var ctr = c.center()
    assert_equal(ctr.x, 3.0)
    assert_equal(ctr.y, 4.0)


def test_circle_contains_inside() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    assert_true(c.contains(0.0, 0.0))
    assert_true(c.contains(3.0, 4.0))


def test_circle_contains_outside() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    assert_equal(c.contains(4.0, 4.0), False)


def test_circle_contains_on_edge() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    assert_true(c.contains(5.0, 0.0))


def test_circle_closest_point_outside() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    var p = c.closest_point(10.0, 0.0)
    assert_almost_equal(p.x, 5.0, atol=1e-9)
    assert_almost_equal(p.y, 0.0, atol=1e-9)


def test_circle_closest_point_inside() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    var p = c.closest_point(1.0, 0.0)
    assert_equal(p.x, 1.0)
    assert_equal(p.y, 0.0)


def test_circle_move_to() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    c.move_to(3.0, 4.0)
    assert_equal(c.x, 3.0)
    assert_equal(c.y, 4.0)


def test_circle_translate() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    c.translate(2.0, 3.0)
    assert_equal(c.x, 2.0)
    assert_equal(c.y, 3.0)


# Line
def test_line_length() raises -> None:
    var l = Line(0.0, 0.0, 3.0, 4.0)
    assert_almost_equal(l.length(), 5.0, atol=1e-9)


def test_line_length_sq() raises -> None:
    var l = Line(0.0, 0.0, 3.0, 4.0)
    assert_equal(l.length_sq(), 25.0)


def test_line_closest_point_perpendicular() raises -> None:
    var l = Line(0.0, 0.0, 4.0, 0.0)
    var p = l.closest_point(2.0, 5.0)
    assert_equal(p.x, 2.0)
    assert_equal(p.y, 0.0)


def test_line_closest_point_clamps_past_endpoint() raises -> None:
    var l = Line(0.0, 0.0, 4.0, 0.0)
    var p = l.closest_point(10.0, 3.0)
    assert_equal(p.x, 4.0)
    assert_equal(p.y, 0.0)


def test_line_closest_point_vector2() raises -> None:
    var l = Line(0.0, 0.0, 4.0, 0.0)
    var p = l.closest_point(Vector2(2.0, 5.0))
    assert_equal(p.x, 2.0)
    assert_equal(p.y, 0.0)


def test_line_midpoint() raises -> None:
    var l = Line(0.0, 0.0, 4.0, 0.0)
    var m = l.midpoint()
    assert_equal(m.x, 2.0)
    assert_equal(m.y, 0.0)


def test_line_move_to_places_midpoint() raises -> None:
    var l = Line(0.0, 0.0, 4.0, 0.0)
    l.move_to(10.0, 10.0)
    assert_almost_equal(l.length(), 4.0, atol=1e-9)
    var m = l.midpoint()
    assert_equal(m.x, 10.0)
    assert_equal(m.y, 10.0)
    assert_equal(l.x0, 8.0)
    assert_equal(l.y0, 10.0)
    assert_equal(l.x1, 12.0)
    assert_equal(l.y1, 10.0)


def test_line_translate() raises -> None:
    var l = Line(0.0, 0.0, 4.0, 0.0)
    l.translate(1.0, 2.0)
    assert_equal(l.x0, 1.0)
    assert_equal(l.y0, 2.0)
    assert_equal(l.x1, 5.0)
    assert_equal(l.y1, 2.0)


def test_line_intersects_crossing() raises -> None:
    var a = Line(0.0, 0.0, 2.0, 2.0)
    var b = Line(0.0, 2.0, 2.0, 0.0)
    assert_true(a.intersects(b))


def test_line_intersects_parallel() raises -> None:
    var a = Line(0.0, 0.0, 2.0, 0.0)
    var b = Line(0.0, 1.0, 2.0, 1.0)
    assert_equal(a.intersects(b), False)


def test_line_intersects_same_line() raises -> None:
    var a = Line(0.0, 0.0, 4.0, 0.0)
    var b = Line(0.0, 0.0, 4.0, 0.0)
    assert_true(a.intersects(b))


def test_line_intersects_partially_overlapping_collinear() raises -> None:
    var a = Line(0.0, 0.0, 4.0, 0.0)
    var b = Line(2.0, 0.0, 6.0, 0.0)
    assert_true(a.intersects(b))


def test_line_intersects_disjoint_collinear() raises -> None:
    var a = Line(0.0, 0.0, 2.0, 0.0)
    var b = Line(3.0, 0.0, 5.0, 0.0)
    assert_equal(a.intersects(b), False)


def test_line_intersects_t_intersection() raises -> None:
    # Endpoint of b sits on interior of a — CCW test detects this as intersection
    var a = Line(0.0, 0.0, 4.0, 0.0)
    var b = Line(2.0, 0.0, 2.0, 2.0)
    assert_true(a.intersects(b))


# Triangle
def test_triangle_center() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    var c = t.center()
    assert_almost_equal(c.x, 3.0, atol=1e-9)
    assert_almost_equal(c.y, 2.0, atol=1e-9)


def test_triangle_contains_inside() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    assert_true(t.contains(3.0, 2.0))


def test_triangle_contains_outside() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    assert_equal(t.contains(0.0, 5.0), False)


def test_triangle_contains_vertex() raises -> None:
    # A vertex of the triangle is on its boundary — should be contained
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    assert_true(t.contains(0.0, 0.0))


def test_triangle_translate() raises -> None:
    var t = Triangle(0.0, 0.0, 2.0, 0.0, 1.0, 2.0)
    t.translate(1.0, 1.0)
    assert_equal(t.x1, 1.0)
    assert_equal(t.y1, 1.0)
    assert_equal(t.x2, 3.0)
    assert_equal(t.y2, 1.0)


def test_triangle_move_to() raises -> None:
    # Triangle with center (1.5, 1.0); move center to (4.5, 4.0)
    var t = Triangle(0.0, 0.0, 3.0, 0.0, 1.5, 3.0)
    t.move_to(4.5, 4.0)
    assert_almost_equal(t.x1, 3.0, atol=1e-9)
    assert_almost_equal(t.y1, 3.0, atol=1e-9)
    assert_almost_equal(t.x2, 6.0, atol=1e-9)
    assert_almost_equal(t.y2, 3.0, atol=1e-9)
    assert_almost_equal(t.x3, 4.5, atol=1e-9)
    assert_almost_equal(t.y3, 6.0, atol=1e-9)


def test_rect_contains_vector2() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var inside = Vector2(2.0, 2.0)
    var outside = Vector2(8.0, 0.0)
    assert_true(r.contains(inside))
    assert_equal(r.contains(outside), False)


def test_circle_contains_vector2() raises -> None:
    var c = Circle(0.0, 0.0, 5.0)
    var inside = Vector2(3.0, 4.0)
    var outside = Vector2(4.0, 4.0)
    assert_true(c.contains(inside))
    assert_equal(c.contains(outside), False)


# overlaps() — one exact overload per unordered shape pair. Every case below
# checks both orderings agree, since that agreement is the property a hand-
# written overload per pair buys over a single generic algorithm.
def test_overlaps_rect_rect_yes() raises -> None:
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var b = Rectangle(4.0, 0.0, 10.0, 10.0)
    assert_true(overlaps(a, b))
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_rect_rect_no() raises -> None:
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var b = Rectangle(20.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(a, b), False)
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_rect_rect_touching_edge() raises -> None:
    # Touching counts as overlap everywhere, matching every contains()
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)    # right=5
    var b = Rectangle(10.0, 0.0, 10.0, 10.0)   # left=5
    assert_true(overlaps(a, b))


def test_overlaps_rect_rect_touching_corner() raises -> None:
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)    # right=5, top=5
    var b = Rectangle(10.0, 10.0, 10.0, 10.0)  # left=5, bottom=5
    assert_true(overlaps(a, b))


def test_overlaps_circle_circle_yes() raises -> None:
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(8.0, 0.0, 5.0)
    assert_true(overlaps(a, b))
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_circle_circle_no() raises -> None:
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(20.0, 0.0, 5.0)
    assert_equal(overlaps(a, b), False)
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_circle_circle_touching_boundary() raises -> None:
    # Circles touching at exactly one point — dist == r1+r2
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(10.0, 0.0, 5.0)
    # dist_sq = 100, (r1+r2)^2 = 100: <=, so overlaps is True
    assert_true(overlaps(a, b))


def test_overlaps_rect_circle_yes() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var c = Circle(6.0, 0.0, 3.0)
    assert_true(overlaps(r, c))
    assert_equal(overlaps(r, c), overlaps(c, r))


def test_overlaps_rect_circle_no() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var c = Circle(10.0, 0.0, 1.0)
    assert_equal(overlaps(r, c), False)
    assert_equal(overlaps(r, c), overlaps(c, r))


def test_overlaps_rect_circle_touching_boundary() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)   # right=5
    var c = Circle(8.0, 0.0, 3.0)             # left edge at 5
    assert_true(overlaps(r, c))
    assert_equal(overlaps(r, c), overlaps(c, r))


def test_overlaps_rect_circle_regression_far_corner() raises -> None:
    # A long thin rectangle whose centre is far from the circle's nearest
    # corner: overlaps(a, b) reads only a's centre distance to b's nearest
    # point, so under the old generic (a.contains(b.closest_point(a.center)))
    # this pair gave a false negative depending on argument order. The
    # specialized overload here is exact regardless of which shape is a/b.
    var r = Rectangle(0.0, 0.0, 100.0, 2.0)     # x in [-50, 50], y in [-1, 1]
    var c = Circle(30.0, -20.0, 20.5)           # nearest rect point (30, -1)
    assert_true(overlaps(r, c))
    assert_equal(overlaps(r, c), overlaps(c, r))


def test_overlaps_circle_triangle_yes() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    var c = Circle(3.0, 2.0, 1.0)   # centre inside the triangle
    assert_true(overlaps(c, t))
    assert_equal(overlaps(c, t), overlaps(t, c))


def test_overlaps_circle_triangle_no() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    var c = Circle(100.0, 100.0, 1.0)
    assert_equal(overlaps(c, t), False)
    assert_equal(overlaps(c, t), overlaps(t, c))


def test_overlaps_circle_triangle_edge_only() raises -> None:
    # Circle's centre is outside the triangle; only the circle's rim reaches it.
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    var c = Circle(3.0, -2.0, 2.5)
    assert_true(overlaps(c, t))
    assert_equal(overlaps(c, t), overlaps(t, c))


def test_overlaps_rect_triangle_yes() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    var r = Rectangle(3.0, 2.0, 2.0, 2.0)   # centre inside the triangle
    assert_true(overlaps(r, t))
    assert_equal(overlaps(r, t), overlaps(t, r))


def test_overlaps_rect_triangle_no() raises -> None:
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    var r = Rectangle(100.0, 100.0, 2.0, 2.0)
    assert_equal(overlaps(r, t), False)
    assert_equal(overlaps(r, t), overlaps(t, r))


def test_overlaps_rect_triangle_edge_only() raises -> None:
    # Neither shape's centre lies inside the other — a config a purely
    # centre-based generic test would get wrong.
    var rect = Rectangle(0.0, 0.0, 20.0, 2.0)
    var tri = Triangle(-1.0, -2.0, 1.0, 0.5, 3.0, -2.0)
    assert_equal(rect.contains(tri.center()), False)
    assert_equal(tri.contains(rect.center()), False)
    assert_true(overlaps(rect, tri))
    assert_equal(overlaps(rect, tri), overlaps(tri, rect))


def test_overlaps_triangle_triangle_yes() raises -> None:
    var a = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, 4.0)
    var b = Triangle(1.0, 0.0, 5.0, 0.0, 3.0, 4.0)
    assert_true(overlaps(a, b))
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_triangle_triangle_no() raises -> None:
    var a = Triangle(0.0, 0.0, 2.0, 0.0, 1.0, 2.0)
    var b = Triangle(10.0, 0.0, 12.0, 0.0, 11.0, 2.0)
    assert_equal(overlaps(a, b), False)
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_triangle_triangle_touching_edge() raises -> None:
    # Mirrored across the shared base edge (0,0)-(4,0)
    var a = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, 4.0)
    var b = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, -4.0)
    assert_true(overlaps(a, b))
    assert_equal(overlaps(a, b), overlaps(b, a))


def test_overlaps_circle_triangle_symmetric_edge_case() raises -> None:
    var circ = Circle(6.0, -3.0, 2.0)
    var tri = Triangle(7.0, -4.0, 9.0, 2.0, 11.0, -4.0)
    assert_equal(circ.contains(tri.center()), False)
    assert_equal(tri.contains(circ.x, circ.y), False)
    assert_equal(overlaps(circ, tri), overlaps(tri, circ))


# Degenerate geometry
def test_line_zero_length() raises -> None:
    var l = Line(2.0, 3.0, 2.0, 3.0)
    assert_equal(l.length(), 0.0)
    assert_equal(l.length_sq(), 0.0)


def test_line_zero_length_intersects_when_on_segment() raises -> None:
    var l = Line(2.0, 3.0, 2.0, 3.0)
    var crossing = Line(0.0, 0.0, 4.0, 4.0)
    assert_equal(l.intersects(crossing), False)
    var touching = Line(2.0, 3.0, 5.0, 6.0)
    assert_true(l.intersects(touching))
    var far = Line(10.0, 10.0, 20.0, 20.0)
    assert_equal(l.intersects(far), False)


def test_circle_zero_radius_contains_only_center() raises -> None:
    var c = Circle(3.0, 4.0, 0.0)
    assert_true(c.contains(3.0, 4.0))
    assert_equal(c.contains(3.001, 4.0), False)


def test_circle_zero_radius_overlaps() raises -> None:
    var c = Circle(3.0, 4.0, 0.0)
    var covering = Circle(3.0, 4.0, 1.0)
    assert_true(overlaps(c, covering))
    var far = Circle(10.0, 10.0, 1.0)
    assert_equal(overlaps(c, far), False)


def test_circle_zero_radius_closest_point_is_center() raises -> None:
    var c = Circle(3.0, 4.0, 0.0)
    var p = c.closest_point(10.0, 4.0)
    assert_equal(p.x, 3.0)
    assert_equal(p.y, 4.0)


def test_triangle_collinear_vertices_contains() raises -> None:
    # Two coincident vertices plus a third: zero area, all three collinear.
    var t = Triangle(0.0, 0.0, 0.0, 0.0, 4.0, 0.0)
    assert_true(t.contains(0.0, 0.0))
    assert_true(t.contains(2.0, 0.0))
    # Off the shared line entirely — not contained
    assert_equal(t.contains(2.0, 1.0), False)


def test_triangle_collinear_vertices_closest_point_reaches_zero_length_edge() raises -> None:
    # The (0,0)-(0,0) edge has len_sq == 0, exercising _closest_on_segment's
    # explicit zero-length branch (otherwise unreached by any other test).
    var t = Triangle(0.0, 0.0, 0.0, 0.0, 4.0, 0.0)
    var p = t.closest_point(2.0, 5.0)
    assert_equal(p.x, 2.0)
    assert_equal(p.y, 0.0)


def test_triangle_collinear_vertices_overlaps() raises -> None:
    var t = Triangle(0.0, 0.0, 0.0, 0.0, 4.0, 0.0)
    var covering = Rectangle(2.0, 0.0, 2.0, 2.0)
    assert_equal(overlaps(t, covering), overlaps(covering, t))
    assert_true(overlaps(t, covering))


def test_triangle_distinct_collinear_vertices_rejects_off_segment_point() raises -> None:
    # Three distinct collinear vertices along y = x. (50, 50) sits on that
    # infinite line but far outside the segment -- must not be "contained".
    var t = Triangle(0.0, 0.0, 1.0, 1.0, 2.0, 2.0)
    assert_equal(t.contains(50.0, 50.0), False)


def test_triangle_distinct_collinear_vertices_contains_hull_point() raises -> None:
    var t = Triangle(0.0, 0.0, 1.0, 1.0, 2.0, 2.0)
    assert_true(t.contains(1.0, 1.0))


def test_triangle_fully_degenerate_point() raises -> None:
    var t = Triangle(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    assert_true(t.contains(0.0, 0.0))
    assert_equal(t.contains(1.0, 0.0), False)


def test_overlaps_circle_distinct_collinear_triangle_far_away() raises -> None:
    var t = Triangle(0.0, 0.0, 1.0, 1.0, 2.0, 2.0)
    var c = Circle(50.0, 50.0, 1.0)
    assert_equal(overlaps(c, t), False)


def test_overlaps_zero_width_rect_and_far_triangle() raises -> None:
    var r = Rectangle(0.0, 0.0, 0.0, 4.0)
    var t = Triangle(10.0, 0.0, 12.0, 2.0, 12.0, -2.0)
    assert_equal(overlaps(r, t), False)


def test_overlaps_disjoint_collinear_degenerate_rects() raises -> None:
    var a = Rectangle(0.0, 0.0, 0.0, 4.0)
    var b = Rectangle(0.0, 10.0, 0.0, 4.0)
    assert_equal(overlaps(a, b), False)


def test_overlaps_collapsed_points_at_different_positions() raises -> None:
    var a = Rectangle(0.0, 0.0, 0.0, 0.0)
    var b = Rectangle(5.0, 5.0, 0.0, 0.0)
    assert_equal(overlaps(a, b), False)


def test_overlaps_collapsed_point_inside_triangle() raises -> None:
    var point = Rectangle(1.0, 1.0, 0.0, 0.0)
    var t = Triangle(0.0, 0.0, 4.0, 0.0, 0.0, 4.0)
    assert_true(overlaps(point, t))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
