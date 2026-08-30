struct Input(Movable):
    var mouse_x: Int
    var mouse_y: Int
    var mouse_pressed: Bool
    var mouse_button: Int
    var case_sensitive: Bool 
    var _held_keys: List[Int]

    def __init__(out self):
        self.mouse_x = 0
        self.mouse_y = 0
        self.mouse_pressed = False
        self.mouse_button = 0
        self._held_keys = List[Int]()
        self.case_sensitive = True

    def is_key_down(self, keycode: Int) -> Bool:
        for i in range(len(self._held_keys)):
            if self._held_keys[i] == keycode:
                return True
        return False

    def is_key_down(self, key: String) -> Bool:
        # Single printable char — SDL keycode == ASCII for a-z, 0-9, punctuation
        if key.byte_length() == 1:
            if self.case_sensitive:
                return self.is_key_down(ord(key))
            else: 
                return self.is_key_down(ord(key.lower())) or self.is_key_down(ord(key.upper()))

        var k = key.lower()

        # Modifier keys — bare name matches either side
        if k == "ctrl":         return self.is_key_down(1073742048) or self.is_key_down(1073742052)
        if k == "left_ctrl":    return self.is_key_down(1073742048)
        if k == "right_ctrl":   return self.is_key_down(1073742052)
        if k == "shift":        return self.is_key_down(1073742049) or self.is_key_down(1073742053)
        if k == "left_shift":   return self.is_key_down(1073742049)
        if k == "right_shift":  return self.is_key_down(1073742053)
        if k == "alt":          return self.is_key_down(1073742050) or self.is_key_down(1073742054)
        if k == "left_alt":     return self.is_key_down(1073742050)
        if k == "right_alt":    return self.is_key_down(1073742054)
        if k == "super":        return self.is_key_down(1073742051) or self.is_key_down(1073742055)
        if k == "left_super":   return self.is_key_down(1073742051)
        if k == "right_super":  return self.is_key_down(1073742055)

        # Arrow keys
        if k == "up":    return self.is_key_down(1073741906)
        if k == "down":  return self.is_key_down(1073741905)
        if k == "left":  return self.is_key_down(1073741904)
        if k == "right": return self.is_key_down(1073741903)

        # Navigation
        if k == "insert":    return self.is_key_down(1073741897)
        if k == "home":      return self.is_key_down(1073741898)
        if k == "page_up":   return self.is_key_down(1073741899)
        if k == "page_down": return self.is_key_down(1073741902)
        if k == "end":       return self.is_key_down(1073741901)

        # Common keys
        if k == "enter":     return self.is_key_down(13)
        if k == "escape":    return self.is_key_down(27)
        if k == "backspace": return self.is_key_down(8)
        if k == "tab":       return self.is_key_down(9)
        if k == "space":     return self.is_key_down(32)
        if k == "delete":    return self.is_key_down(127)
        if k == "caps_lock": return self.is_key_down(1073741881)

        # Function keys
        if k == "f1":  return self.is_key_down(1073741882)
        if k == "f2":  return self.is_key_down(1073741883)
        if k == "f3":  return self.is_key_down(1073741884)
        if k == "f4":  return self.is_key_down(1073741885)
        if k == "f5":  return self.is_key_down(1073741886)
        if k == "f6":  return self.is_key_down(1073741887)
        if k == "f7":  return self.is_key_down(1073741888)
        if k == "f8":  return self.is_key_down(1073741889)
        if k == "f9":  return self.is_key_down(1073741890)
        if k == "f10": return self.is_key_down(1073741891)
        if k == "f11": return self.is_key_down(1073741892)
        if k == "f12": return self.is_key_down(1073741893)

        return False
