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


def test_mouse_button_initial() raises -> None:
    var input = Input()
    assert_equal(input.mouse_button, 0)


def test_named_key_shift_both_sides() raises -> None:
    var input = Input()
    input._held_keys.append(1073742049)  # left shift
    assert_true(input.is_key_down("shift"))
    input._held_keys = List[Int]()
    input._held_keys.append(1073742053)  # right shift
    assert_true(input.is_key_down("shift"))


def test_named_key_left_shift_specific() raises -> None:
    var input = Input()
    input._held_keys.append(1073742049)
    assert_true(input.is_key_down("left_shift"))
    assert_equal(input.is_key_down("right_shift"), False)


def test_named_key_alt_both_sides() raises -> None:
    var input = Input()
    input._held_keys.append(1073742050)  # left alt
    assert_true(input.is_key_down("alt"))
    input._held_keys = List[Int]()
    input._held_keys.append(1073742054)  # right alt
    assert_true(input.is_key_down("alt"))


def test_named_key_super_both_sides() raises -> None:
    var input = Input()
    input._held_keys.append(1073742051)  # left super
    assert_true(input.is_key_down("super"))
    input._held_keys = List[Int]()
    input._held_keys.append(1073742055)  # right super
    assert_true(input.is_key_down("super"))


def test_named_key_arrow_down() raises -> None:
    var input = Input()
    input._held_keys.append(1073741905)
    assert_true(input.is_key_down("down"))


def test_named_key_arrow_left() raises -> None:
    var input = Input()
    input._held_keys.append(1073741904)
    assert_true(input.is_key_down("left"))


def test_named_key_arrow_right() raises -> None:
    var input = Input()
    input._held_keys.append(1073741903)
    assert_true(input.is_key_down("right"))


def test_named_key_home() raises -> None:
    var input = Input()
    input._held_keys.append(1073741898)
    assert_true(input.is_key_down("home"))


def test_named_key_end() raises -> None:
    var input = Input()
    input._held_keys.append(1073741901)
    assert_true(input.is_key_down("end"))


def test_named_key_page_up() raises -> None:
    var input = Input()
    input._held_keys.append(1073741899)
    assert_true(input.is_key_down("page_up"))


def test_named_key_page_down() raises -> None:
    var input = Input()
    input._held_keys.append(1073741902)
    assert_true(input.is_key_down("page_down"))


def test_named_key_insert() raises -> None:
    var input = Input()
    input._held_keys.append(1073741897)
    assert_true(input.is_key_down("insert"))


def test_named_key_backspace() raises -> None:
    var input = Input()
    input._held_keys.append(8)
    assert_true(input.is_key_down("backspace"))


def test_named_key_tab() raises -> None:
    var input = Input()
    input._held_keys.append(9)
    assert_true(input.is_key_down("tab"))


def test_named_key_delete() raises -> None:
    var input = Input()
    input._held_keys.append(127)
    assert_true(input.is_key_down("delete"))


def test_named_key_caps_lock() raises -> None:
    var input = Input()
    input._held_keys.append(1073741881)
    assert_true(input.is_key_down("caps_lock"))


def test_named_key_f1() raises -> None:
    var input = Input()
    input._held_keys.append(1073741882)
    assert_true(input.is_key_down("f1"))


def test_named_key_f12() raises -> None:
    var input = Input()
    input._held_keys.append(1073741893)
    assert_true(input.is_key_down("f12"))


def test_just_pressed_named_key() raises -> None:
    var input = Input()
    input._just_pressed.append(27)
    assert_true(input.just_pressed("escape"))
    assert_equal(input.just_pressed("space"), False)


def test_just_released_named_key() raises -> None:
    var input = Input()
    input._just_released.append(32)
    assert_true(input.just_released("space"))
    assert_equal(input.just_released("escape"), False)


def test_unknown_named_key_returns_false() raises -> None:
    var input = Input()
    input._held_keys.append(65)
    assert_equal(input.is_key_down("nonexistent_key"), False)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
