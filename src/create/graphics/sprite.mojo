from create.core.color import Color


def _read_u16(data: List[UInt8], off: Int) -> Int:
    return Int(data[off]) | (Int(data[off + 1]) << 8)


def _read_i32(data: List[UInt8], off: Int) -> Int:
    var v = Int(data[off]) | (Int(data[off + 1]) << 8) | (Int(data[off + 2]) << 16) | (Int(data[off + 3]) << 24)
    if v >= 0x80000000:
        return v - 0x100000000
    return v


def _read_u32(data: List[UInt8], off: Int) -> Int:
    return Int(data[off]) | (Int(data[off + 1]) << 8) | (Int(data[off + 2]) << 16) | (Int(data[off + 3]) << 24)


struct Sprite(Movable):
    var pixels: List[UInt8]
    var width: Int
    var height: Int

    def __init__(out self, width: Int, height: Int):
        self.width = width
        self.height = height
        self.pixels = List[UInt8](length=width * height * 4, fill=0)

    @staticmethod
    def solid(width: Int, height: Int, color: Color) -> Sprite:
        var s = Sprite(width, height)
        var ptr = s.pixels.unsafe_ptr()
        for i in range(width * height):
            var off = i * 4
            ptr[unsafe_offset=off] = color.r
            ptr[unsafe_offset=off + 1] = color.g
            ptr[unsafe_offset=off + 2] = color.b
            ptr[unsafe_offset=off + 3] = color.a
        return s^

    @staticmethod
    def from_rgba(width: Int, height: Int, data: List[UInt8]) -> Sprite:
        var s = Sprite(width, height)
        var src = data.unsafe_ptr()
        var dst = s.pixels.unsafe_ptr()
        for i in range(width * height * 4):
            dst[unsafe_offset=i] = src[unsafe_offset=i]
        return s^

    @staticmethod
    def load(path: String) raises -> Sprite:
        """Load a BMP file. Supports 24-bit (BGR) and 32-bit (BGRA) uncompressed BMPs."""
        with open(path, "r") as f:
            var data = f.read_bytes()

            if len(data) < 54:
                raise Error("BMP file too small: " + path)
            if data[0] != 66 or data[1] != 77:  # "BM"
                raise Error("Not a BMP file: " + path)

            var pixel_offset = _read_u32(data, 10)
            var dib_size = _read_u32(data, 14)
            if dib_size < 40:
                raise Error("Unsupported BMP DIB header: " + path)

            var w = _read_i32(data, 18)
            var raw_h = _read_i32(data, 22)
            var top_down = raw_h < 0
            var h = -raw_h if top_down else raw_h
            var bpp = _read_u16(data, 28)
            var compression = _read_u32(data, 30)

            if bpp != 24 and bpp != 32:
                raise Error("BMP must be 24-bit or 32-bit, got: " + path)
            if compression != 0 and compression != 3:
                raise Error("Compressed BMP not supported: " + path)

            var s = Sprite(w, h)
            var dst = s.pixels.unsafe_ptr()

            if bpp == 24:
                var row_stride = ((w * 3 + 3) // 4) * 4
                for row in range(h):
                    var src_row = (h - 1 - row) if not top_down else row
                    var src_base = pixel_offset + src_row * row_stride
                    for col in range(w):
                        var src = src_base + col * 3
                        var d = (row * w + col) * 4
                        dst[unsafe_offset=d] = data[src + 2]      # R
                        dst[unsafe_offset=d + 1] = data[src + 1]  # G
                        dst[unsafe_offset=d + 2] = data[src]      # B
                        dst[unsafe_offset=d + 3] = 255
            else:  # 32-bit
                for row in range(h):
                    var src_row = (h - 1 - row) if not top_down else row
                    var src_base = pixel_offset + src_row * w * 4
                    for col in range(w):
                        var src = src_base + col * 4
                        var d = (row * w + col) * 4
                        dst[unsafe_offset=d] = data[src + 2]      # R
                        dst[unsafe_offset=d + 1] = data[src + 1]  # G
                        dst[unsafe_offset=d + 2] = data[src]      # B
                        dst[unsafe_offset=d + 3] = data[src + 3]  # A

            return s^
