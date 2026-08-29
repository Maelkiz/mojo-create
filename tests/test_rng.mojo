from std.testing import TestSuite, assert_true, assert_equal
from create.math import RNG


def test_float_in_unit_interval() raises -> None:
    var rng = RNG(42)
    for _ in range(1000):
        var v = rng.random()
        assert_true(v >= 0.0 and v <= 1.0)


def test_float_range() raises -> None:
    var rng = RNG(1)
    for _ in range(1000):
        var v = rng.random(5.0, 10.0)
        assert_true(v >= 5.0 and v <= 10.0)


def test_int_range() raises -> None:
    var rng = RNG(7)
    for _ in range(1000):
        var v = rng.random(3, 8)
        assert_true(v >= 3 and v < 8)


def test_deterministic_seed() raises -> None:
    var a = RNG(12345)
    var b = RNG(12345)
    assert_equal(a.random(), b.random())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
