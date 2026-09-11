struct HorizontalAlignment(Equatable, Copyable, ImplicitlyCopyable, Movable):
    """Which edge of the text box `canvas.text`'s position names horizontally.

    A separate type from `VerticalAlignment` so `canvas.text_align` can be
    overloaded on the axis: pass either one alone to set just that axis, or
    both together.
    """

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
    """Which edge of the text box `canvas.text`'s position names vertically.

    Edges of the box, not typographic baselines — there is no separate
    `text_baseline`. `TOP` and `BOTTOM` mean the visual top and bottom even
    though y grows upward, because glyphs are not flipped by the coordinate
    system; only their anchor point is mapped.
    """

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
