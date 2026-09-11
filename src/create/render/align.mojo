struct HorizontalAlignment(Equatable, Copyable, ImplicitlyCopyable, Movable):
    var value: Int

    comptime LEFT   = HorizontalAlignment(0)
    comptime CENTER = HorizontalAlignment(1)
    comptime RIGHT  = HorizontalAlignment(2)

    def __init__(out self, value: Int):
        self.value = value

    def __eq__(self, other: HorizontalAlignment) -> Bool:
        return self.value == other.value

    def __ne__(self, other: HorizontalAlignment) -> Bool:
        return self.value != other.value


struct VerticalAlignment(Equatable, Copyable, ImplicitlyCopyable, Movable):
    var value: Int

    comptime TOP    = VerticalAlignment(0)
    comptime MIDDLE = VerticalAlignment(1)
    comptime BOTTOM = VerticalAlignment(2)

    def __init__(out self, value: Int):
        self.value = value

    def __eq__(self, other: VerticalAlignment) -> Bool:
        return self.value == other.value

    def __ne__(self, other: VerticalAlignment) -> Bool:
        return self.value != other.value
