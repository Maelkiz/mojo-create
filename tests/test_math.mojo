from std.testing import TestSuite, assert_equal
from create.math import lerp, map


def test_lerp_start() raises -> None:
    assert_equal(lerp(0.0, 10.0, 0.0), 0.0)


def test_lerp_end() raises -> None:
    assert_equal(lerp(0.0, 10.0, 1.0), 10.0)


def test_lerp_midpoint() raises -> None:
    assert_equal(lerp(0.0, 10.0, 0.5), 5.0)


def test_lerp_negative_range() raises -> None:
    assert_equal(lerp(-10.0, 10.0, 0.5), 0.0)


def test_map_low() raises -> None:
    assert_equal(map(0.0, 0.0, 10.0, 0.0, 100.0), 0.0)


def test_map_high() raises -> None:
    assert_equal(map(10.0, 0.0, 10.0, 0.0, 100.0), 100.0)


def test_map_midpoint() raises -> None:
    assert_equal(map(5.0, 0.0, 10.0, 0.0, 100.0), 50.0)


def test_map_different_ranges() raises -> None:
    assert_equal(map(1.0, 0.0, 4.0, 0.0, 1.0), 0.25)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
