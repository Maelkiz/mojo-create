from std.testing import TestSuite, assert_equal, assert_true, assert_false
from create.core import WindowConfig


def test_explicit_dimensions() raises -> None:
    var c = WindowConfig("Test", 800, 600)
    assert_equal(c.width, 800)
    assert_equal(c.height, 600)
    assert_false(c._fullscreen)


def test_fullscreen_when_zero() raises -> None:
    var c = WindowConfig("Test", 0, 0)
    assert_true(c._fullscreen)


def test_fullscreen_default_args() raises -> None:
    var c = WindowConfig("Test")
    assert_true(c._fullscreen)


def test_title_stored() raises -> None:
    var c = WindowConfig("My Window", 100, 100)
    assert_equal(c.title, "My Window")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
