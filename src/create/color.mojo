struct Color(ImplicitlyCopyable, Movable):
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    def __init__(out self, r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

    def __init__(out self, gray: UInt8):
        self.r = gray
        self.g = gray
        self.b = gray
        self.a = 255

    @staticmethod
    def black() -> Color:
        return Color(0)

    @staticmethod
    def white() -> Color:
        return Color(255)

    @staticmethod
    def red() -> Color:
        return Color(255, 0, 0)

    @staticmethod
    def green() -> Color:
        return Color(0, 255, 0)

    @staticmethod
    def blue() -> Color:
        return Color(0, 0, 255)
