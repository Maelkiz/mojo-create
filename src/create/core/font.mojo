from std.ffi import _DLHandle
from std.math import abs
from .color import Color

comptime FONT_DEFAULT_PATH = "defaults/fonts/NotoSans.ttf"

# FT_FaceRec offsets
comptime _FACE_GLYPH = 152
comptime _FACE_SIZE  = 160  # FT_Size* pointer

# FT_SizeRec: face(8) + generic(16) = metrics at offset 24
# FT_Size_Metrics: x_ppem(2)+y_ppem(2)+pad(4)+x_scale(8)+y_scale(8) = ascender at +24, descender at +32
comptime _SIZE_METRICS   = 24
comptime _METRICS_ASC    = 24
comptime _METRICS_DESC   = 32

# FT_GlyphSlotRec offsets
comptime _GLYPH_ADVANCE  = 128  # FT_Vector: x = first FT_Pos (8 bytes)
comptime _GLYPH_BITMAP   = 152  # FT_Bitmap struct
comptime _GLYPH_BMP_LEFT = 192  # FT_Int (signed, 4 bytes)
comptime _GLYPH_BMP_TOP  = 196  # FT_Int (signed, 4 bytes)

# FT_Bitmap field offsets (relative to bitmap start)
comptime _BMP_ROWS   = 0
comptime _BMP_WIDTH  = 4
comptime _BMP_PITCH  = 8
comptime _BMP_BUFFER = 16

comptime _FT_LOAD_DEFAULT       = 0
comptime _FT_RENDER_MODE_NORMAL = 0


def _read_u32(addr: Int) raises -> Int:
    var buf = InlineArray[UInt8, 4](fill=0)
    _ = _DLHandle("libc.so.6").call["memcpy", Int](buf.unsafe_ptr(), addr, 4)
    return Int(buf[0]) | (Int(buf[1]) << 8) | (Int(buf[2]) << 16) | (Int(buf[3]) << 24)


def _read_i32(addr: Int) raises -> Int:
    var v = _read_u32(addr)
    return v - 0x100000000 if v >= 0x80000000 else v


def _read_ptr(addr: Int) raises -> Int:
    var buf = InlineArray[UInt8, 8](fill=0)
    _ = _DLHandle("libc.so.6").call["memcpy", Int](buf.unsafe_ptr(), addr, 8)
    var v: Int = 0
    for i in range(8):
        v |= Int(buf[i]) << (i * 8)
    return v


struct GlyphInfo(Movable):
    var pixels: List[UInt8]   # 8-bit grayscale alpha, row-major
    var width: Int
    var height: Int
    var bearing_x: Int        # horizontal offset from pen to glyph left edge
    var bearing_y: Int        # vertical offset from baseline to glyph top
    var advance_x: Int        # horizontal pen advance in pixels

    def __init__(out self, width: Int, height: Int,
                 bearing_x: Int, bearing_y: Int, advance_x: Int):
        self.pixels = List[UInt8](length=width * height, fill=0)
        self.width = width
        self.height = height
        self.bearing_x = bearing_x
        self.bearing_y = bearing_y
        self.advance_x = advance_x


struct Font(Movable):
    var _lib: Int       # FT_Library opaque pointer
    var _face: Int      # FT_Face opaque pointer
    var _size: Int      # last set pixel height
    var ascender: Int   # pixels above baseline (positive)
    var descender: Int  # pixels below baseline (negative)

    def __init__(out self, path: String, size: Int) raises:
        var ft = _DLHandle("libfreetype.so.6")

        var lib_buf = InlineArray[UInt8, 8](fill=0)
        if ft.call["FT_Init_FreeType", Int32](lib_buf.unsafe_ptr()) != 0:
            raise Error("FT_Init_FreeType failed")
        self._lib = _read_ptr(Int(lib_buf.unsafe_ptr()))

        var face_buf = InlineArray[UInt8, 8](fill=0)
        if ft.call["FT_New_Face", Int32](
            self._lib, path.unsafe_ptr(), Int(0), face_buf.unsafe_ptr()
        ) != 0:
            _ = ft.call["FT_Done_FreeType", Int32](self._lib)
            raise Error("FT_New_Face failed — font not found: " + path)
        self._face = _read_ptr(Int(face_buf.unsafe_ptr()))
        self._size = 0
        self.ascender = 0
        self.descender = 0
        self._set_size(ft, size)

    def _set_size(mut self, ft: _DLHandle, size: Int) raises:
        if size == self._size:
            return
        _ = ft.call["FT_Set_Pixel_Sizes", Int32](self._face, UInt32(0), UInt32(size))
        self._size = size
        var size_ptr = _read_ptr(self._face + _FACE_SIZE)
        var m = size_ptr + _SIZE_METRICS
        self.ascender  = _read_ptr(m + _METRICS_ASC)  >> 6
        self.descender = _read_ptr(m + _METRICS_DESC) >> 6

    def render(mut self, codepoint: Int, size: Int, bold: Bool) raises -> GlyphInfo:
        var ft = _DLHandle("libfreetype.so.6")
        self._set_size(ft, size)

        # Load outlines first so embolden can thicken before rasterising
        if ft.call["FT_Load_Char", Int32](
            self._face, codepoint, Int32(_FT_LOAD_DEFAULT)
        ) != 0:
            return GlyphInfo(0, 0, 0, 0, size)

        var glyph = _read_ptr(self._face + _FACE_GLYPH)

        if bold:
            ft.call["FT_GlyphSlot_Embolden"](glyph)

        if ft.call["FT_Render_Glyph", Int32](glyph, Int32(_FT_RENDER_MODE_NORMAL)) != 0:
            return GlyphInfo(0, 0, 0, 0, size)

        # Re-read after embolden may have reallocated the slot
        glyph = _read_ptr(self._face + _FACE_GLYPH)
        var bmp = glyph + _GLYPH_BITMAP

        var rows      = _read_u32(bmp + _BMP_ROWS)
        var width     = _read_u32(bmp + _BMP_WIDTH)
        var pitch     = _read_i32(bmp + _BMP_PITCH)
        var buf_ptr   = _read_ptr(bmp + _BMP_BUFFER)
        var bmp_left  = _read_i32(glyph + _GLYPH_BMP_LEFT)
        var bmp_top   = _read_i32(glyph + _GLYPH_BMP_TOP)
        var advance_x = _read_ptr(glyph + _GLYPH_ADVANCE) >> 6  # 26.6 fixed-point

        var g = GlyphInfo(width, rows, bmp_left, bmp_top, advance_x)
        if buf_ptr != 0 and width > 0 and rows > 0:
            var stride = abs(pitch)
            var libc = _DLHandle("libc.so.6")
            for row in range(rows):
                _ = libc.call["memcpy", Int](
                    Int(g.pixels.unsafe_ptr()) + row * width,
                    buf_ptr + row * stride,
                    width,
                )
        return g^
