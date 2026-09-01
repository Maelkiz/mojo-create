from std.testing import TestSuite, assert_equal, assert_almost_equal
from create.math.vector3 import Vector3


def test_init_float() raises -> None:
    var v = Vector3(1.0, 2.0, 3.0)
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 2.0)
    assert_equal(v.z, 3.0)


def test_init_int() raises -> None:
    var v = Vector3(1, 2, 3)
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 2.0)
    assert_equal(v.z, 3.0)


def test_init_tuple_float() raises -> None:
    var v: Vector3 = (1.5, 2.5, 3.5)
    assert_equal(v.x, 1.5)
    assert_equal(v.y, 2.5)
    assert_equal(v.z, 3.5)


def test_init_tuple_int() raises -> None:
    var v: Vector3 = (1, 2, 3)
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 2.0)
    assert_equal(v.z, 3.0)


def test_zero() raises -> None:
    var v = Vector3.zero()
    assert_equal(v.x, 0.0)
    assert_equal(v.y, 0.0)
    assert_equal(v.z, 0.0)


def test_one() raises -> None:
    var v = Vector3.one()
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 1.0)
    assert_equal(v.z, 1.0)


def test_add() raises -> None:
    var c = Vector3(1.0, 2.0, 3.0) + Vector3(4.0, 5.0, 6.0)
    assert_equal(c.x, 5.0)
    assert_equal(c.y, 7.0)
    assert_equal(c.z, 9.0)


def test_sub() raises -> None:
    var c = Vector3(4.0, 5.0, 6.0) - Vector3(1.0, 2.0, 3.0)
    assert_equal(c.x, 3.0)
    assert_equal(c.y, 3.0)
    assert_equal(c.z, 3.0)


def test_mul_scalar() raises -> None:
    var v = Vector3(1.0, 2.0, 3.0) * 2.0
    assert_equal(v.x, 2.0)
    assert_equal(v.y, 4.0)
    assert_equal(v.z, 6.0)


def test_div_scalar() raises -> None:
    var v = Vector3(2.0, 4.0, 6.0) / 2.0
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 2.0)
    assert_equal(v.z, 3.0)


def test_neg() raises -> None:
    var v = -Vector3(1.0, -2.0, 3.0)
    assert_equal(v.x, -1.0)
    assert_equal(v.y, 2.0)
    assert_equal(v.z, -3.0)


def test_iadd() raises -> None:
    var v = Vector3(1.0, 2.0, 3.0)
    v += Vector3(1.0, 1.0, 1.0)
    assert_equal(v.x, 2.0)
    assert_equal(v.y, 3.0)
    assert_equal(v.z, 4.0)


def test_isub() raises -> None:
    var v = Vector3(3.0, 3.0, 3.0)
    v -= Vector3(1.0, 2.0, 3.0)
    assert_equal(v.x, 2.0)
    assert_equal(v.y, 1.0)
    assert_equal(v.z, 0.0)


def test_imul() raises -> None:
    var v = Vector3(1.0, 2.0, 3.0)
    v *= 3.0
    assert_equal(v.x, 3.0)
    assert_equal(v.y, 6.0)
    assert_equal(v.z, 9.0)


def test_idiv() raises -> None:
    var v = Vector3(3.0, 6.0, 9.0)
    v /= 3.0
    assert_equal(v.x, 1.0)
    assert_equal(v.y, 2.0)
    assert_equal(v.z, 3.0)


def test_eq() raises -> None:
    assert_equal(Vector3(1.0, 2.0, 3.0) == Vector3(1.0, 2.0, 3.0), True)
    assert_equal(Vector3(1.0, 2.0, 3.0) == Vector3(1.0, 2.0, 4.0), False)


def test_ne() raises -> None:
    assert_equal(Vector3(1.0, 2.0, 3.0) != Vector3(1.0, 2.0, 4.0), True)
    assert_equal(Vector3(1.0, 2.0, 3.0) != Vector3(1.0, 2.0, 3.0), False)


def test_mag() raises -> None:
    assert_almost_equal(Vector3(1.0, 2.0, 2.0).mag(), 3.0, atol=1e-9)
    assert_equal(Vector3(0.0, 0.0, 0.0).mag(), 0.0)


def test_mag_sq() raises -> None:
    assert_equal(Vector3(1.0, 2.0, 2.0).mag_sq(), 9.0)


def test_normalize() raises -> None:
    var n = Vector3(1.0, 2.0, 2.0).normalize()
    assert_almost_equal(n.x, 1.0 / 3.0, atol=1e-9)
    assert_almost_equal(n.y, 2.0 / 3.0, atol=1e-9)
    assert_almost_equal(n.z, 2.0 / 3.0, atol=1e-9)


def test_dot_perpendicular() raises -> None:
    assert_equal(Vector3(1.0, 0.0, 0.0).dot(Vector3(0.0, 1.0, 0.0)), 0.0)


def test_dot_values() raises -> None:
    assert_equal(Vector3(1.0, 2.0, 3.0).dot(Vector3(4.0, 5.0, 6.0)), 32.0)


def test_cross_basis_vectors() raises -> None:
    # x × y = z
    var c = Vector3(1.0, 0.0, 0.0).cross(Vector3(0.0, 1.0, 0.0))
    assert_equal(c.x, 0.0)
    assert_equal(c.y, 0.0)
    assert_equal(c.z, 1.0)


def test_cross_anticommutative() raises -> None:
    var a = Vector3(1.0, 2.0, 3.0)
    var b = Vector3(4.0, 5.0, 6.0)
    var ab = a.cross(b)
    var neg_ba = -(b.cross(a))
    assert_almost_equal(ab.x, neg_ba.x, atol=1e-9)
    assert_almost_equal(ab.y, neg_ba.y, atol=1e-9)
    assert_almost_equal(ab.z, neg_ba.z, atol=1e-9)


def test_dist() raises -> None:
    assert_almost_equal(Vector3(0.0, 0.0, 0.0).dist(Vector3(1.0, 2.0, 2.0)), 3.0, atol=1e-9)


def test_dist_sq() raises -> None:
    assert_equal(Vector3(0.0, 0.0, 0.0).dist_sq(Vector3(1.0, 2.0, 2.0)), 9.0)


def test_lerp_endpoints() raises -> None:
    var a = Vector3(0.0, 0.0, 0.0)
    var b = Vector3(2.0, 4.0, 6.0)
    var r0 = a.lerp(b, 0.0)
    assert_equal(r0.x, 0.0)
    assert_equal(r0.y, 0.0)
    assert_equal(r0.z, 0.0)
    var r1 = a.lerp(b, 1.0)
    assert_equal(r1.x, 2.0)
    assert_equal(r1.y, 4.0)
    assert_equal(r1.z, 6.0)


def test_lerp_midpoint() raises -> None:
    var r = Vector3(0.0, 0.0, 0.0).lerp(Vector3(2.0, 4.0, 6.0), 0.5)
    assert_equal(r.x, 1.0)
    assert_equal(r.y, 2.0)
    assert_equal(r.z, 3.0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
