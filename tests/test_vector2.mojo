from std.testing import TestSuite, assert_equal, assert_almost_equal
from create.math import Vector2


def test_init() raises -> None:
    var v = Vector2(3.0, 4.0)
    assert_equal(v.x, 3.0)
    assert_equal(v.y, 4.0)


def test_zero() raises -> None:
    var v = Vector2.zero()
    assert_equal(v.x, 0.0)
    assert_equal(v.y, 0.0)


def test_one() raises -> None:
    var v = Vector2.one()
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 1.0)


def test_add() raises -> None:
    var a = Vector2(1.0, 2.0)
    var b = Vector2(3.0, 4.0)
    var c = a + b
    assert_equal(c.x, 4.0)
    assert_equal(c.y, 6.0)


def test_sub() raises -> None:
    var a = Vector2(5.0, 3.0)
    var b = Vector2(2.0, 1.0)
    var c = a - b
    assert_equal(c.x, 3.0)
    assert_equal(c.y, 2.0)


def test_mul_scalar() raises -> None:
    var v = Vector2(2.0, 3.0) * 4.0
    assert_equal(v.x, 8.0)
    assert_equal(v.y, 12.0)


def test_div_scalar() raises -> None:
    var v = Vector2(6.0, 4.0) / 2.0
    assert_equal(v.x, 3.0)
    assert_equal(v.y, 2.0)


def test_neg() raises -> None:
    var v = -Vector2(1.0, -2.0)
    assert_equal(v.x, -1.0)
    assert_equal(v.y, 2.0)


def test_iadd() raises -> None:
    var v = Vector2(1.0, 2.0)
    v += Vector2(3.0, 4.0)
    assert_equal(v.x, 4.0)
    assert_equal(v.y, 6.0)


def test_isub() raises -> None:
    var v = Vector2(5.0, 3.0)
    v -= Vector2(2.0, 1.0)
    assert_equal(v.x, 3.0)
    assert_equal(v.y, 2.0)


def test_imul() raises -> None:
    var v = Vector2(2.0, 3.0)
    v *= 4.0
    assert_equal(v.x, 8.0)
    assert_equal(v.y, 12.0)


def test_idiv() raises -> None:
    var v = Vector2(6.0, 4.0)
    v /= 2.0
    assert_equal(v.x, 3.0)
    assert_equal(v.y, 2.0)


def test_eq() raises -> None:
    assert_equal(Vector2(1.0, 2.0) == Vector2(1.0, 2.0), True)
    assert_equal(Vector2(1.0, 2.0) == Vector2(1.0, 3.0), False)


def test_ne() raises -> None:
    assert_equal(Vector2(1.0, 2.0) != Vector2(1.0, 3.0), True)
    assert_equal(Vector2(1.0, 2.0) != Vector2(1.0, 2.0), False)


def test_mag() raises -> None:
    assert_equal(Vector2(3.0, 4.0).mag(), 5.0)
    assert_equal(Vector2(0.0, 0.0).mag(), 0.0)


def test_mag_sq() raises -> None:
    assert_equal(Vector2(3.0, 4.0).mag_sq(), 25.0)


def test_normalize() raises -> None:
    var n = Vector2(3.0, 4.0).normalize()
    assert_almost_equal(n.x, 0.6, atol=1e-9)
    assert_almost_equal(n.y, 0.8, atol=1e-9)


def test_dot() raises -> None:
    assert_equal(Vector2(1.0, 0.0).dot(Vector2(0.0, 1.0)), 0.0)
    assert_equal(Vector2(1.0, 0.0).dot(Vector2(1.0, 0.0)), 1.0)
    assert_equal(Vector2(2.0, 3.0).dot(Vector2(4.0, 5.0)), 23.0)


def test_dist() raises -> None:
    assert_equal(Vector2(0.0, 0.0).dist(Vector2(3.0, 4.0)), 5.0)
    assert_equal(Vector2(1.0, 1.0).dist(Vector2(1.0, 1.0)), 0.0)


def test_dist_sq() raises -> None:
    assert_equal(Vector2(0.0, 0.0).dist_sq(Vector2(3.0, 4.0)), 25.0)


def test_lerp_start() raises -> None:
    var r = Vector2(0.0, 0.0).lerp(Vector2(10.0, 20.0), 0.0)
    assert_equal(r.x, 0.0)
    assert_equal(r.y, 0.0)


def test_lerp_end() raises -> None:
    var r = Vector2(0.0, 0.0).lerp(Vector2(10.0, 20.0), 1.0)
    assert_equal(r.x, 10.0)
    assert_equal(r.y, 20.0)


def test_lerp_midpoint() raises -> None:
    var r = Vector2(0.0, 0.0).lerp(Vector2(10.0, 20.0), 0.5)
    assert_equal(r.x, 5.0)
    assert_equal(r.y, 10.0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
