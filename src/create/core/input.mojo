from create.math.vector2 import Vector2
from .key import Key, KeyBits


struct Input(Movable):
    var mouse_x: Int
    var mouse_y: Int
    var mouse: Vector2
    var mouse_pressed: Bool
    var mouse_button: Int
    # This frame's scroll delta — zeroed at the start of every frame, same
    # lifecycle as the just-pressed/just-released key bits.
    var wheel: Vector2
    # World position at the most recent press this frame. Captured at the
    # MouseButtonDown event itself rather than read off `mouse`, because a
    # MouseMoved later in the same frame would otherwise overwrite it before
    # a program ever sees where the click actually started.
    var mouse_press_pos: Vector2
    var _held_keys: KeyBits
    var _just_pressed: KeyBits
    var _just_released: KeyBits
    # Mouse buttons are a handful of small ints (1..5), not the ~500-wide
    # keycode space `KeyBits` is sized for — a plain bitmask is enough.
    var _held_buttons: Int
    var _pressed_buttons: Int
    var _released_buttons: Int

    def __init__(out self):
        self.mouse_x = 0
        self.mouse_y = 0
        self.mouse = Vector2(0, 0)
        self.mouse_pressed = False
        self.mouse_button = 0
        self.wheel = Vector2(0, 0)
        self.mouse_press_pos = Vector2(0, 0)
        self._held_keys = KeyBits()
        self._just_pressed = KeyBits()
        self._just_released = KeyBits()
        self._held_buttons = 0
        self._pressed_buttons = 0
        self._released_buttons = 0

    def _check(self, key: String, bits: KeyBits) -> Bool:
        var k = key.lower()

        # Single printable char — SDL keycode == ASCII for a-z, 0-9, punctuation
        if key.byte_length() == 1:
            return bits.test(ord(k))

        # Modifier keys — bare name matches either side
        if k == "ctrl":
            return bits.test(Key.LEFT_CTRL) or bits.test(Key.RIGHT_CTRL)
        if k == "left_ctrl":
            return bits.test(Key.LEFT_CTRL)
        if k == "right_ctrl":
            return bits.test(Key.RIGHT_CTRL)
        if k == "shift":
            return bits.test(Key.LEFT_SHIFT) or bits.test(Key.RIGHT_SHIFT)
        if k == "left_shift":
            return bits.test(Key.LEFT_SHIFT)
        if k == "right_shift":
            return bits.test(Key.RIGHT_SHIFT)
        if k == "alt":
            return bits.test(Key.LEFT_ALT) or bits.test(Key.RIGHT_ALT)
        if k == "left_alt":
            return bits.test(Key.LEFT_ALT)
        if k == "right_alt":
            return bits.test(Key.RIGHT_ALT)
        if k == "super":
            return bits.test(Key.LEFT_SUPER) or bits.test(Key.RIGHT_SUPER)
        if k == "left_super":
            return bits.test(Key.LEFT_SUPER)
        if k == "right_super":
            return bits.test(Key.RIGHT_SUPER)

        var code = Key.from_name(k)
        if code == -1:
            return False
        return bits.test(code)

    def is_key_down(self, keycode: Int) -> Bool:
        return self._held_keys.test(keycode)

    def is_key_down(self, key: String) -> Bool:
        return self._check(key, self._held_keys)

    def just_pressed(self, keycode: Int) -> Bool:
        return self._just_pressed.test(keycode)

    def just_pressed(self, key: String) -> Bool:
        return self._check(key, self._just_pressed)

    def just_released(self, keycode: Int) -> Bool:
        return self._just_released.test(keycode)

    def just_released(self, key: String) -> Bool:
        return self._check(key, self._just_released)

    def is_mouse_down(self, button: Int = MouseButton.LEFT) -> Bool:
        return (self._held_buttons & (1 << button)) != 0

    def mouse_just_pressed(self, button: Int = MouseButton.LEFT) -> Bool:
        return (self._pressed_buttons & (1 << button)) != 0

    def mouse_just_released(self, button: Int = MouseButton.LEFT) -> Bool:
        return (self._released_buttons & (1 << button)) != 0


struct MouseButton:
    """Names for `is_mouse_down`/`mouse_just_pressed`/`mouse_just_released`.

    Matches SDL's own button numbering, not named after it: `BACK`/`FORWARD`
    are the side thumb buttons (SDL's X1/X2) — named for what a mouse driver
    or browser calls them, not SDL's internal label, since nobody looks at
    their mouse and thinks "that's my X1 button."
    """

    comptime LEFT = 1
    comptime MIDDLE = 2
    comptime RIGHT = 3
    comptime BACK = 4
    comptime FORWARD = 5
