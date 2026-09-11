struct HAlign(Equatable, Copyable, ImplicitlyCopyable, Movable):
    var value: Int

    comptime LEFT   = HAlign(0)
    comptime CENTER = HAlign(1)
    comptime RIGHT  = HAlign(2)

    def __init__(out self, value: Int):
        self.value = value

    def __eq__(self, other: HAlign) -> Bool:
        return self.value == other.value

    def __ne__(self, other: HAlign) -> Bool:
        return self.value != other.value


struct VAlign(Equatable, Copyable, ImplicitlyCopyable, Movable):
    var value: Int

    comptime TOP    = VAlign(0)
    comptime MIDDLE = VAlign(1)
    comptime BOTTOM = VAlign(2)

    def __init__(out self, value: Int):
        self.value = value

    def __eq__(self, other: VAlign) -> Bool:
        return self.value == other.value

    def __ne__(self, other: VAlign) -> Bool:
        return self.value != other.value
