from std.testing import TestSuite, assert_equal
from create.core import Color


def test_rgba_constructor() raises -> None:
    var c = Color(10, 20, 30, 40)
    assert_equal(c.r, UInt8(10))
    assert_equal(c.g, UInt8(20))
    assert_equal(c.b, UInt8(30))
    assert_equal(c.a, UInt8(40))


def test_rgba_default_alpha() raises -> None:
    var c = Color(1, 2, 3)
    assert_equal(c.a, UInt8(255))


def test_gray_constructor() raises -> None:
    var c = Color(UInt8(128))
    assert_equal(c.r, UInt8(128))
    assert_equal(c.g, UInt8(128))
    assert_equal(c.b, UInt8(128))
    assert_equal(c.a, UInt8(255))


def test_black() raises -> None:
    var c = Color.BLACK
    assert_equal(c.r, UInt8(0))
    assert_equal(c.g, UInt8(0))
    assert_equal(c.b, UInt8(0))
    assert_equal(c.a, UInt8(255))


def test_white() raises -> None:
    var c = Color.WHITE
    assert_equal(c.r, UInt8(255))
    assert_equal(c.g, UInt8(255))
    assert_equal(c.b, UInt8(255))
    assert_equal(c.a, UInt8(255))


def test_red() raises -> None:
    var c = Color.RED
    assert_equal(c.r, UInt8(255))
    assert_equal(c.g, UInt8(0))
    assert_equal(c.b, UInt8(0))


def test_green() raises -> None:
    var c = Color.GREEN
    assert_equal(c.r, UInt8(0))
    assert_equal(c.g, UInt8(255))
    assert_equal(c.b, UInt8(0))


def test_blue() raises -> None:
    var c = Color.BLUE
    assert_equal(c.r, UInt8(0))
    assert_equal(c.g, UInt8(0))
    assert_equal(c.b, UInt8(255))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
