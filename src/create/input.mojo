struct Input(Movable):
    var mouse_x: Int
    var mouse_y: Int
    var mouse_pressed: Bool
    var mouse_button: Int
    var _held_keys: List[Int]

    def __init__(out self):
        self.mouse_x = 0
        self.mouse_y = 0
        self.mouse_pressed = False
        self.mouse_button = 0
        self._held_keys = List[Int]()

    def is_key_down(self, keycode: Int) -> Bool:
        for i in range(len(self._held_keys)):
            if self._held_keys[i] == keycode:
                return True
        return False
