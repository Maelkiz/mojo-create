from .color import Color


struct Surface[origin: Origin[mut=True]](Copyable, ImplicitlyCopyable, Movable):
    """A borrowed RGBA framebuffer: a pixel pointer plus its dimensions.

    Deliberately a plain value rather than a trait. Every raster loop needs
    exactly these three things, and nothing here knows where the memory came
    from — an SDL window, an owned `MemorySurface`, or anything else that can
    hand out a row-major RGBA buffer.
    """

    var px: Pointer[UInt8, Self.origin]
    var width: Int
    var height: Int

    def __init__(
        out self, px: Pointer[UInt8, Self.origin], width: Int, height: Int
    ):
        self.px = px
        self.width = width
        self.height = height

    def offset(self, x: Int, y: Int) -> Int:
        """Byte offset of pixel `(x, y)` — row-major, four bytes per pixel."""
        return (y * self.width + x) * 4


struct MemorySurface(Movable):
    """An RGBA framebuffer backed by owned memory, for rendering without a
    window.

    Holds the pixels so a `Surface` can borrow them; `pixel` reads one back so
    a test can assert on what was drawn.
    """

    var data: List[UInt8]
    var width: Int
    var height: Int

    def __init__(out self, width: Int, height: Int):
        self.width = width
        self.height = height
        self.data = List[UInt8](length=width * height * 4, fill=0)

    def surface(mut self) -> Surface[origin_of(self.data)]:
        """Borrow this buffer as a `Surface` for the raster primitives."""
        return Surface(self.data.unsafe_ptr(), self.width, self.height)

    def pixel(self, x: Int, y: Int) -> Color:
        var off = (y * self.width + x) * 4
        return Color(
            self.data[off],
            self.data[off + 1],
            self.data[off + 2],
            self.data[off + 3],
        )
