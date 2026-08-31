def _in_list(keycode: Int, list: List[Int]) -> Bool:
    for i in range(len(list)):
        if list[i] == keycode:
            return True
    return False


struct Input(Movable):
    var mouse_x: Int
    var mouse_y: Int
    var mouse_pressed: Bool
    var mouse_button: Int
    var _held_keys: List[Int]
    var _just_pressed: List[Int]
    var _just_released: List[Int]

    def __init__(out self):
        self.mouse_x = 0
        self.mouse_y = 0
        self.mouse_pressed = False
        self.mouse_button = 0
        self._held_keys = List[Int]()
        self._just_pressed = List[Int]()
        self._just_released = List[Int]()

    def _check(self, key: String, list: List[Int]) -> Bool:
        var k = key.lower()
        
        # Single printable char — SDL keycode == ASCII for a-z, 0-9, punctuation
        if key.byte_length() == 1:
            return _in_list(ord(key), list)

        # Modifier keys — bare name matches either side
        if k == "ctrl":         return _in_list(1073742048, list) or _in_list(1073742052, list)
        if k == "left_ctrl":    return _in_list(1073742048, list)
        if k == "right_ctrl":   return _in_list(1073742052, list)
        if k == "shift":        return _in_list(1073742049, list) or _in_list(1073742053, list)
        if k == "left_shift":   return _in_list(1073742049, list)
        if k == "right_shift":  return _in_list(1073742053, list)
        if k == "alt":          return _in_list(1073742050, list) or _in_list(1073742054, list)
        if k == "left_alt":     return _in_list(1073742050, list)
        if k == "right_alt":    return _in_list(1073742054, list)
        if k == "super":        return _in_list(1073742051, list) or _in_list(1073742055, list)
        if k == "left_super":   return _in_list(1073742051, list)
        if k == "right_super":  return _in_list(1073742055, list)

        # Arrow keys
        if k == "up":    return _in_list(1073741906, list)
        if k == "down":  return _in_list(1073741905, list)
        if k == "left":  return _in_list(1073741904, list)
        if k == "right": return _in_list(1073741903, list)

        # Navigation
        if k == "insert":    return _in_list(1073741897, list)
        if k == "home":      return _in_list(1073741898, list)
        if k == "page_up":   return _in_list(1073741899, list)
        if k == "page_down": return _in_list(1073741902, list)
        if k == "end":       return _in_list(1073741901, list)

        # Common keys
        if k == "enter":     return _in_list(13, list)
        if k == "escape":    return _in_list(27, list)
        if k == "backspace": return _in_list(8, list)
        if k == "tab":       return _in_list(9, list)
        if k == "space":     return _in_list(32, list)
        if k == "delete":    return _in_list(127, list)
        if k == "caps_lock": return _in_list(1073741881, list)

        # Function keys
        if k == "f1":  return _in_list(1073741882, list)
        if k == "f2":  return _in_list(1073741883, list)
        if k == "f3":  return _in_list(1073741884, list)
        if k == "f4":  return _in_list(1073741885, list)
        if k == "f5":  return _in_list(1073741886, list)
        if k == "f6":  return _in_list(1073741887, list)
        if k == "f7":  return _in_list(1073741888, list)
        if k == "f8":  return _in_list(1073741889, list)
        if k == "f9":  return _in_list(1073741890, list)
        if k == "f10": return _in_list(1073741891, list)
        if k == "f11": return _in_list(1073741892, list)
        if k == "f12": return _in_list(1073741893, list)

        return False

    def is_key_down(self, keycode: Int) -> Bool:
        return _in_list(keycode, self._held_keys)

    def is_key_down(self, key: String) -> Bool:
        return self._check(key, self._held_keys)

    def just_pressed(self, keycode: Int) -> Bool:
        return _in_list(keycode, self._just_pressed)

    def just_pressed(self, key: String) -> Bool:
        return self._check(key, self._just_pressed)

    def just_released(self, keycode: Int) -> Bool:
        return _in_list(keycode, self._just_released)

    def just_released(self, key: String) -> Bool:
        return self._check(key, self._just_released)
