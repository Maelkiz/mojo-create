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


def test_rect_overlaps_rect_yes() raises -> None:
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var b = Rectangle(4.0, 0.0, 10.0, 10.0)
    assert_true(a.overlaps(b))


def test_rect_overlaps_rect_no() raises -> None:
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var b = Rectangle(20.0, 0.0, 10.0, 10.0)
    assert_equal(a.overlaps(b), False)


def test_rect_overlaps_circle_yes() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var c = Circle(6.0, 0.0, 3.0)
    assert_true(r.overlaps(c))


def test_rect_overlaps_circle_no() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var c = Circle(10.0, 0.0, 1.0)
    assert_equal(r.overlaps(c), False)


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


def test_circle_overlaps_circle_yes() raises -> None:
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(8.0, 0.0, 5.0)
    assert_true(a.overlaps(b))


def test_circle_overlaps_circle_no() raises -> None:
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(12.0, 0.0, 5.0)
    assert_equal(a.overlaps(b), False)


def test_circle_overlaps_rect_yes() raises -> None:
    var c = Circle(6.0, 0.0, 3.0)
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_true(c.overlaps(r))


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
    assert_equal(a.intersects(b), False)


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


def test_triangle_translate() raises -> None:
    var t = Triangle(0.0, 0.0, 2.0, 0.0, 1.0, 2.0)
    t.translate(1.0, 1.0)
    assert_equal(t.x1, 1.0)
    assert_equal(t.y1, 1.0)
    assert_equal(t.x2, 3.0)
    assert_equal(t.y2, 1.0)


def test_triangle_overlaps_yes() raises -> None:
    var a = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, 4.0)
    var b = Triangle(1.0, 0.0, 5.0, 0.0, 3.0, 4.0)
    assert_true(a.overlaps(b))


def test_triangle_overlaps_no() raises -> None:
    var a = Triangle(0.0, 0.0, 2.0, 0.0, 1.0, 2.0)
    var b = Triangle(10.0, 0.0, 12.0, 0.0, 11.0, 2.0)
    assert_equal(a.overlaps(b), False)


# Generic overlaps function
def test_overlaps_circles_yes() raises -> None:
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(8.0, 0.0, 5.0)
    assert_true(overlaps(a, b))


def test_overlaps_circles_no() raises -> None:
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(20.0, 0.0, 5.0)
    assert_equal(overlaps(a, b), False)


def test_rect_touching_edges_overlap() raises -> None:
    # Touching counts as overlap everywhere, matching every contains()
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)    # right=5
    var b = Rectangle(10.0, 0.0, 10.0, 10.0)   # left=5
    assert_true(a.overlaps(b))


def test_rect_overlaps_rect_touching_corner() raises -> None:
    var a = Rectangle(0.0, 0.0, 10.0, 10.0)    # right=5, top=5
    var b = Rectangle(10.0, 10.0, 10.0, 10.0)  # left=5, bottom=5
    assert_true(a.overlaps(b))


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


def test_line_intersects_t_intersection() raises -> None:
    # Endpoint of b sits on interior of a — CCW test detects this as intersection
    var a = Line(0.0, 0.0, 4.0, 0.0)
    var b = Line(2.0, 0.0, 2.0, 2.0)
    assert_true(a.intersects(b))


def test_overlaps_rect_circle_via_generic() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var c = Circle(6.0, 0.0, 3.0)
    assert_true(overlaps(r, c))


def test_overlaps_rect_circle_no_via_generic() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var c = Circle(20.0, 0.0, 3.0)
    assert_equal(overlaps(r, c), False)


def test_circle_overlaps_touching_boundary() raises -> None:
    # Circles touching at exactly one point — dist == r1+r2
    var a = Circle(0.0, 0.0, 5.0)
    var b = Circle(10.0, 0.0, 5.0)
    # dist_sq = 100, (r1+r2)^2 = 100: <=, so overlaps is True
    assert_true(a.overlaps(b))


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


def test_triangle_contains_vertex() raises -> None:
    # A vertex of the triangle is on its boundary — should be contained
    var t = Triangle(0.0, 0.0, 6.0, 0.0, 3.0, 6.0)
    assert_true(t.contains(0.0, 0.0))


# overlaps(a, b), overlaps(b, a) and a.overlaps(b) must all agree — separated,
# overlapping, and exactly-touching configurations for every pair the library
# supports.
def test_overlaps_agree_rect_rect() raises -> None:
    var sep_a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var sep_b = Rectangle(30.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(sep_a, sep_b), False)
    assert_equal(overlaps(sep_a, sep_b), overlaps(sep_b, sep_a))
    assert_equal(overlaps(sep_a, sep_b), sep_a.overlaps(sep_b))

    var ovl_a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var ovl_b = Rectangle(4.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(ovl_a, ovl_b), True)
    assert_equal(overlaps(ovl_a, ovl_b), overlaps(ovl_b, ovl_a))
    assert_equal(overlaps(ovl_a, ovl_b), ovl_a.overlaps(ovl_b))

    var tch_a = Rectangle(0.0, 0.0, 10.0, 10.0)
    var tch_b = Rectangle(10.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(tch_a, tch_b), True)
    assert_equal(overlaps(tch_a, tch_b), overlaps(tch_b, tch_a))
    assert_equal(overlaps(tch_a, tch_b), tch_a.overlaps(tch_b))


def test_overlaps_agree_circle_circle() raises -> None:
    var sep_a = Circle(0.0, 0.0, 5.0)
    var sep_b = Circle(20.0, 0.0, 5.0)
    assert_equal(overlaps(sep_a, sep_b), False)
    assert_equal(overlaps(sep_a, sep_b), overlaps(sep_b, sep_a))
    assert_equal(overlaps(sep_a, sep_b), sep_a.overlaps(sep_b))

    var ovl_a = Circle(0.0, 0.0, 5.0)
    var ovl_b = Circle(8.0, 0.0, 5.0)
    assert_equal(overlaps(ovl_a, ovl_b), True)
    assert_equal(overlaps(ovl_a, ovl_b), overlaps(ovl_b, ovl_a))
    assert_equal(overlaps(ovl_a, ovl_b), ovl_a.overlaps(ovl_b))

    var tch_a = Circle(0.0, 0.0, 5.0)
    var tch_b = Circle(10.0, 0.0, 5.0)
    assert_equal(overlaps(tch_a, tch_b), True)
    assert_equal(overlaps(tch_a, tch_b), overlaps(tch_b, tch_a))
    assert_equal(overlaps(tch_a, tch_b), tch_a.overlaps(tch_b))


def test_overlaps_agree_rect_circle() raises -> None:
    var sep_r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var sep_c = Circle(20.0, 0.0, 3.0)
    assert_equal(overlaps(sep_r, sep_c), False)
    assert_equal(overlaps(sep_r, sep_c), overlaps(sep_c, sep_r))
    assert_equal(overlaps(sep_r, sep_c), sep_r.overlaps(sep_c))

    var ovl_r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var ovl_c = Circle(6.0, 0.0, 3.0)
    assert_equal(overlaps(ovl_r, ovl_c), True)
    assert_equal(overlaps(ovl_r, ovl_c), overlaps(ovl_c, ovl_r))
    assert_equal(overlaps(ovl_r, ovl_c), ovl_r.overlaps(ovl_c))

    var tch_r = Rectangle(0.0, 0.0, 10.0, 10.0)
    var tch_c = Circle(8.0, 0.0, 3.0)
    assert_equal(overlaps(tch_r, tch_c), True)
    assert_equal(overlaps(tch_r, tch_c), overlaps(tch_c, tch_r))
    assert_equal(overlaps(tch_r, tch_c), tch_r.overlaps(tch_c))


def test_overlaps_agree_circle_rect() raises -> None:
    var sep_c = Circle(20.0, 0.0, 3.0)
    var sep_r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(sep_c, sep_r), False)
    assert_equal(overlaps(sep_c, sep_r), overlaps(sep_r, sep_c))
    assert_equal(overlaps(sep_c, sep_r), sep_c.overlaps(sep_r))

    var ovl_c = Circle(6.0, 0.0, 3.0)
    var ovl_r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(ovl_c, ovl_r), True)
    assert_equal(overlaps(ovl_c, ovl_r), overlaps(ovl_r, ovl_c))
    assert_equal(overlaps(ovl_c, ovl_r), ovl_c.overlaps(ovl_r))

    var tch_c = Circle(8.0, 0.0, 3.0)
    var tch_r = Rectangle(0.0, 0.0, 10.0, 10.0)
    assert_equal(overlaps(tch_c, tch_r), True)
    assert_equal(overlaps(tch_c, tch_r), overlaps(tch_r, tch_c))
    assert_equal(overlaps(tch_c, tch_r), tch_c.overlaps(tch_r))


def test_overlaps_agree_triangle_triangle() raises -> None:
    var sep_a = Triangle(0.0, 0.0, 2.0, 0.0, 1.0, 2.0)
    var sep_b = Triangle(10.0, 0.0, 12.0, 0.0, 11.0, 2.0)
    assert_equal(overlaps(sep_a, sep_b), False)
    assert_equal(overlaps(sep_a, sep_b), overlaps(sep_b, sep_a))
    assert_equal(overlaps(sep_a, sep_b), sep_a.overlaps(sep_b))

    var ovl_a = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, 4.0)
    var ovl_b = Triangle(1.0, 0.0, 5.0, 0.0, 3.0, 4.0)
    assert_equal(overlaps(ovl_a, ovl_b), True)
    assert_equal(overlaps(ovl_a, ovl_b), overlaps(ovl_b, ovl_a))
    assert_equal(overlaps(ovl_a, ovl_b), ovl_a.overlaps(ovl_b))

    # Mirrored across the shared base edge (0,0)-(4,0)
    var tch_a = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, 4.0)
    var tch_b = Triangle(0.0, 0.0, 4.0, 0.0, 2.0, -4.0)
    assert_equal(overlaps(tch_a, tch_b), True)
    assert_equal(overlaps(tch_a, tch_b), overlaps(tch_b, tch_a))
    assert_equal(overlaps(tch_a, tch_b), tch_a.overlaps(tch_b))


# overlaps[A, B] reads only a's centre and b's surface, so it is asymmetric
# by construction. These configurations overlap with neither shape's centre
# inside the other — the case most likely to expose that asymmetry.
def test_overlaps_symmetric_long_rect_triangle() raises -> None:
    var rect = Rectangle(0.0, 0.0, 20.0, 2.0)
    var tri = Triangle(-1.0, -2.0, 1.0, 0.5, 3.0, -2.0)
    assert_equal(rect.contains(tri.center()), False)
    assert_equal(tri.contains(rect.center()), False)
    assert_equal(overlaps(rect, tri), overlaps(tri, rect))


def test_overlaps_symmetric_circle_triangle() raises -> None:
    var circ = Circle(6.0, -3.0, 2.0)
    var tri = Triangle(7.0, -4.0, 9.0, 2.0, 11.0, -4.0)
    assert_equal(circ.contains(tri.center()), False)
    assert_equal(tri.contains(circ.x, circ.y), False)
    assert_equal(overlaps(circ, tri), overlaps(tri, circ))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
