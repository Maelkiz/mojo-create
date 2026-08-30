from create.core.color import Color


struct Sprite(Movable):
    var pixels: List[UInt8]
    var width: Int
    var height: Int

    def __init__(out self, width: Int, height: Int, pixels: List[UInt8]):
        self.width = width
        self.height = height
        self.pixels = pixels

    @staticmethod
    def solid(width: Int, height: Int, color: Color) -> Sprite:
        var pixels = List[UInt8](length=width * height * 4, fill=0)
        var ptr = pixels.unsafe_ptr()
        for i in range(width * height):
            var off = i * 4
            ptr[unsafe_offset=off] = color.r
            ptr[unsafe_offset=off + 1] = color.g
            ptr[unsafe_offset=off + 2] = color.b
            ptr[unsafe_offset=off + 3] = color.a
        return Sprite(width, height, pixels^)

    @staticmethod
    def from_rgba(width: Int, height: Int, data: List[UInt8]) -> Sprite:
        return Sprite(width, height, data)
