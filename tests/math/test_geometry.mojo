from std.testing import TestSuite, assert_equal, assert_true, assert_almost_equal
from create.math.geometry import Rectangle, Circle, Line, Triangle, overlaps
from create.math.vector2 import Vector2


# Rectangle — x,y is center
def test_rect_bounds() raises -> None:
    var r = Rectangle(0.0, 0.0, 10.0, 6.0)
    assert_equal(r.left(), -5.0)
    assert_equal(r.right(), 5.0)
    assert_equal(r.top(), -3.0)
    assert_equal(r.bottom(), 3.0)


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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
