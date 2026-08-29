from std.testing import TestSuite, assert_true, assert_equal
from create.math import Random


def test_float_in_unit_interval() raises -> None:
    var rng = Random(42)
    for _ in range(1000):
        var v = rng.float()
        assert_true(v >= 0.0 and v <= 1.0)


def test_float_range() raises -> None:
    var rng = Random(1)
    for _ in range(1000):
        var v = rng.float(5.0, 10.0)
        assert_true(v >= 5.0 and v <= 10.0)


def test_int_range() raises -> None:
    var rng = Random(7)
    for _ in range(1000):
        var v = rng.int(3, 8)
        assert_true(v >= 3 and v < 8)


def test_bool() raises -> None:
    var rng = Random(99)
    var true_count = 0
    for _ in range(1000):
        if rng.bool():
            true_count += 1
    assert_true(true_count > 400 and true_count < 600)


def test_deterministic_seed() raises -> None:
    var a = Random(12345)
    var b = Random(12345)
    assert_equal(a.float(), b.float())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
