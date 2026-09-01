from std.testing import TestSuite, assert_equal, assert_true
from create.core.input import Input


def test_initial_mouse_position() raises -> None:
    var input = Input()
    assert_equal(input.mouse_x, 0)
    assert_equal(input.mouse_y, 0)
    assert_equal(input.mouse.x, 0.0)
    assert_equal(input.mouse.y, 0.0)


def test_initial_mouse_not_pressed() raises -> None:
    var input = Input()
    assert_equal(input.mouse_pressed, False)


def test_no_keys_down_initially() raises -> None:
    var input = Input()
    assert_equal(input.is_key_down(65), False)
    assert_equal(input.is_key_down("a"), False)


def test_is_key_down_by_keycode() raises -> None:
    var input = Input()
    input._held_keys.append(65)
    assert_true(input.is_key_down(65))
    assert_equal(input.is_key_down(66), False)


def test_is_key_down_by_string() raises -> None:
    var input = Input()
    input._held_keys.append(ord("a"))
    assert_true(input.is_key_down("a"))
    assert_equal(input.is_key_down("b"), False)


def test_is_key_down_case_insensitive() raises -> None:
    var input = Input()
    input._held_keys.append(ord("z"))
    assert_true(input.is_key_down("Z"))


def test_just_pressed_keycode() raises -> None:
    var input = Input()
    input._just_pressed.append(65)
    assert_true(input.just_pressed(65))
    assert_equal(input.just_pressed(66), False)


def test_just_pressed_string() raises -> None:
    var input = Input()
    input._just_pressed.append(ord("w"))
    assert_true(input.just_pressed("w"))


def test_just_released_keycode() raises -> None:
    var input = Input()
    input._just_released.append(65)
    assert_true(input.just_released(65))
    assert_equal(input.just_released(66), False)


def test_just_released_string() raises -> None:
    var input = Input()
    input._just_released.append(ord("s"))
    assert_true(input.just_released("s"))


def test_multiple_keys_held() raises -> None:
    var input = Input()
    input._held_keys.append(ord("a"))
    input._held_keys.append(ord("d"))
    assert_true(input.is_key_down("a"))
    assert_true(input.is_key_down("d"))
    assert_equal(input.is_key_down("w"), False)


def test_named_key_escape() raises -> None:
    var input = Input()
    input._held_keys.append(27)
    assert_true(input.is_key_down("escape"))


def test_named_key_space() raises -> None:
    var input = Input()
    input._held_keys.append(32)
    assert_true(input.is_key_down("space"))


def test_named_key_enter() raises -> None:
    var input = Input()
    input._held_keys.append(13)
    assert_true(input.is_key_down("enter"))


def test_named_key_arrow_up() raises -> None:
    var input = Input()
    input._held_keys.append(1073741906)
    assert_true(input.is_key_down("up"))


def test_named_key_ctrl_both_sides() raises -> None:
    var input = Input()
    input._held_keys.append(1073742048)  # left ctrl
    assert_true(input.is_key_down("ctrl"))
    input._held_keys = List[Int]()
    input._held_keys.append(1073742052)  # right ctrl
    assert_true(input.is_key_down("ctrl"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
