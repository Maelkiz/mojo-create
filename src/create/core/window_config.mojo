struct WindowConfig(ImplicitlyCopyable, Movable):
    var title: String
    var width: Int
    var height: Int
    var _fullscreen: Bool

    def __init__(out self, title: String, width: Int = 0, height: Int = 0):
        self.title = title
        self.width = width
        self.height = height
        self._fullscreen = width == 0 and height == 0
