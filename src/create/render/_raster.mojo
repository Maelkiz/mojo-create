from std.math import max, min, abs
from std.sys import is_big_endian

from .color import Color
from .font import _GlyphInfo
from .surface import Surface


def blend[o: Origin[mut=True]](s: Surface[o], off: Int, c: Color):
    """Composite one color into the framebuffer at `off`, source-over.

    Fully opaque and fully transparent colors skip the read-back, so the
    common case costs no more than a raw store; `Color.over` owns the mixing.
    """
    if c.a == 0:
        return
    var px = s.px
    if c.a == 255:
        px[unsafe_offset=off] = c.r
        px[unsafe_offset=off + 1] = c.g
        px[unsafe_offset=off + 2] = c.b
        px[unsafe_offset=off + 3] = 255
        return
    var out = c.over(
        Color(
            px[unsafe_offset=off],
            px[unsafe_offset=off + 1],
            px[unsafe_offset=off + 2],
            px[unsafe_offset=off + 3],
        )
    )
    px[unsafe_offset=off] = out.r
    px[unsafe_offset=off + 1] = out.g
    px[unsafe_offset=off + 2] = out.b
    px[unsafe_offset=off + 3] = out.a


def _packed(c: Color) -> UInt32:
    """`c` as one word whose bytes land in the framebuffer's r, g, b, a order.

    Composed by endianness rather than assumed: a 32-bit store writes the low
    byte to the lowest address on a little-endian target and to the highest on
    a big-endian one, while the framebuffer is r, g, b, a ascending either way.
    """

    comptime if is_big_endian():
        return (
            (UInt32(c.r) << 24)
            | (UInt32(c.g) << 16)
            | (UInt32(c.b) << 8)
            | UInt32(c.a)
        )
    return (
        UInt32(c.r)
        | (UInt32(c.g) << 8)
        | (UInt32(c.b) << 16)
        | (UInt32(c.a) << 24)
    )


def _word_aligned[o: Origin[mut=True]](s: Surface[o]) -> Bool:
    """Whether whole pixels can be stored a word at a time.

    Every pixel sits at a multiple of four bytes from the base, so the base
    settles it for the entire buffer. Both framebuffers in the repo satisfy
    this — a `List[UInt8]` and an SDL window buffer are each malloc-aligned —
    but neither guarantees it by contract, and a 32-bit store through a
    misaligned pointer is undefined, not merely slow.
    """
    return Int(s.px) % 4 == 0


def fill_span[o: Origin[mut=True]](s: Surface[o], off: Int, count: Int, c: Color):
    """Composite `count` consecutive pixels starting at byte offset `off`.

    The caller has already clipped to the surface and worked out the covered
    run; this does no bounds checking of its own. An opaque fill is one word
    per pixel, not four bytes, and the alpha test is hoisted out of the loop
    rather than left to `blend` — together worth ~4x on a run of any length.
    Both branches then process four pixels (16 bytes) at a time through
    `SIMD`, for another ~4x: the opaque path is a vector splat of the packed
    word, and the alpha path widens both source and destination to `uint32`
    lanes, computes `(src*a + dst*ia) // 255` across all sixteen bytes at
    once, and narrows back. The source vector's alpha lane carries `255`
    rather than `c.a`, which is what makes one blend formula correct for
    both the colour lanes and the alpha lane — see
    `test_fill_span_alpha_matches_over_exhaustively`. A tail of fewer than
    four pixels falls back to the scalar loop. Every rasteriser that
    produces a horizontal run of pixels goes through this one loop; none of
    this may be re-open-coded at a call site.
    """
    if c.a == 0:
        return
    var px = s.px
    if c.a == 255 and _word_aligned(s):
        var w = px.unsafe_bitcast[UInt32]()
        var v = _packed(c)
        var i0 = off // 4
        var vv = SIMD[DType.uint32, 4](v, v, v, v)
        var i = 0
        while i + 4 <= count:
            w.unsafe_store[width=4](offset=i0 + i, val=vv)
            i += 4
        while i < count:
            w[unsafe_offset=i0 + i] = v
            i += 1
        return
    if c.a == 255:
        for i in range(count):
            var o2 = off + i * 4
            px[unsafe_offset=o2] = c.r
            px[unsafe_offset=o2 + 1] = c.g
            px[unsafe_offset=o2 + 2] = c.b
            px[unsafe_offset=o2 + 3] = 255
        return
    var a = UInt32(c.a)
    var ia = UInt32(255 - Int(c.a))
    var a4 = SIMD[DType.uint32, 16](a)
    var ia4 = SIMD[DType.uint32, 16](ia)
    var one_px = SIMD[DType.uint8, 4](c.r, c.g, c.b, 255)
    var two_px = one_px.join(one_px)
    var src4 = two_px.join(two_px).cast[DType.uint32]()
    var i = 0
    while i + 4 <= count:
        var o2 = off + i * 4
        var dst = px.unsafe_load[width=16](offset=o2).cast[DType.uint32]()
        var out = ((src4 * a4 + dst * ia4) // 255).cast[DType.uint8]()
        px.unsafe_store[width=16](offset=o2, val=out)
        i += 4
    while i < count:
        var o2 = off + i * 4
        var out = c.over(
            Color(
                px[unsafe_offset=o2],
                px[unsafe_offset=o2 + 1],
                px[unsafe_offset=o2 + 2],
                px[unsafe_offset=o2 + 3],
            )
        )
        px[unsafe_offset=o2] = out.r
        px[unsafe_offset=o2 + 1] = out.g
        px[unsafe_offset=o2 + 2] = out.b
        px[unsafe_offset=o2 + 3] = out.a
        i += 1


def fill_all[o: Origin[mut=True]](s: Surface[o], c: Color):
    """Composite `c` over every pixel — the whole frame, no clipping needed."""
    fill_span(s, 0, s.width * s.height, c)


def fill_pixels[
    o: Origin[mut=True]
](s: Surface[o], x0: Int, y0: Int, x1: Int, y1: Int, c: Color):
    """Fill the half-open device-space rect `[x0, x1) x [y0, y1)`, clipped.

    Clipped once for the whole rect, then one `fill_span` per row.
    """
    if c.a == 0:
        return
    var W = s.width
    var r0 = max(y0, 0)
    var r1 = min(y1, s.height)
    var c0 = max(x0, 0)
    var c1 = min(x1, W)
    if c1 <= c0:
        return
    for row in range(r0, r1):
        fill_span(s, (row * W + c0) * 4, c1 - c0, c)


def line_pixels[
    o: Origin[mut=True]
](
    s: Surface[o],
    x0: Float64,
    y0: Float64,
    x1: Float64,
    y1: Float64,
    c: Color,
    stroke_width: Int,
):
    """Bresenham line in device space, `stroke_width` pixels thick."""
    var W = s.width
    var H = s.height
    var sw = stroke_width
    var half = sw // 2
    var ix0 = Int(x0)
    var iy0 = Int(y0)
    var ix1 = Int(x1)
    var iy1 = Int(y1)
    var dx = abs(ix1 - ix0)
    var dy = -abs(iy1 - iy0)
    var sx = 1 if ix0 < ix1 else -1
    var sy = 1 if iy0 < iy1 else -1
    var err = dx + dy
    var x = ix0
    var y = iy0
    while True:
        for ry in range(-half, sw - half):
            for rx in range(-half, sw - half):
                var nx = x + rx
                var ny = y + ry
                if 0 <= nx < W and 0 <= ny < H:
                    blend(s, (ny * W + nx) * 4, c)
        if x == ix1 and y == iy1:
            break
        var e2 = 2 * err
        if e2 >= dy:
            if x == ix1:
                break
            err += dy
            x += sx
        if e2 <= dx:
            if y == iy1:
                break
            err += dx
            y += sy


def fill_triangle[
    o: Origin[mut=True]
](
    s: Surface[o],
    x1: Float64,
    y1: Float64,
    x2: Float64,
    y2: Float64,
    x3: Float64,
    y3: Float64,
    c: Color,
):
    """Fill a device-space triangle by the half-plane sign test."""
    var W = s.width
    var H = s.height
    var min_x = max(Int(min(x1, min(x2, x3))), 0)
    var max_x = min(Int(max(x1, max(x2, x3))), W - 1)
    var min_y = max(Int(min(y1, min(y2, y3))), 0)
    var max_y = min(Int(max(y1, max(y2, y3))), H - 1)
    for row in range(min_y, max_y + 1):
        for col in range(min_x, max_x + 1):
            var d1 = (x2 - x1) * (Float64(row) - y1) - (y2 - y1) * (
                Float64(col) - x1
            )
            var d2 = (x3 - x2) * (Float64(row) - y2) - (y3 - y2) * (
                Float64(col) - x2
            )
            var d3 = (x1 - x3) * (Float64(row) - y3) - (y1 - y3) * (
                Float64(col) - x3
            )
            var has_neg = (d1 < 0.0) or (d2 < 0.0) or (d3 < 0.0)
            var has_pos = (d1 > 0.0) or (d2 > 0.0) or (d3 > 0.0)
            if not (has_neg and has_pos):
                blend(s, (row * W + col) * 4, c)


def blit_sprite[
    o: Origin[mut=True], so: Origin
](
    s: Surface[o],
    src: Pointer[UInt8, so],
    sw: Int,
    sh: Int,
    x0: Int,
    y0: Int,
    dw: Int,
    dh: Int,
):
    """Blit the `sw` x `sh` RGBA buffer at `src` into the device rect at
    `(x0, y0)` sized `dw` x `dh`.

    Takes a bare pixel view rather than an image type, for the same reason
    `Surface` is a plain value: nothing here needs to know where the pixels
    came from.

    Nearest-neighbour: rotation and shear are not resampled, so the caller
    maps the anchor and hands over an axis-aligned destination. A 1:1 blit
    skips the source-index division rather than relying on it cancelling.
    """
    var W = s.width
    var H = s.height
    var sp = src
    var one_to_one = dw == sw and dh == sh
    for row in range(dh):
        var dy = y0 + row
        if dy < 0 or dy >= H:
            continue
        var src_row = row if one_to_one else row * sh // dh
        for col in range(dw):
            var dx = x0 + col
            if dx < 0 or dx >= W:
                continue
            var src_col = col if one_to_one else col * sw // dw
            var src_off = (src_row * sw + src_col) * 4
            var sa = sp[unsafe_offset=src_off + 3]
            if sa == 0:
                continue
            blend(
                s,
                (dy * W + dx) * 4,
                Color(
                    sp[unsafe_offset=src_off],
                    sp[unsafe_offset=src_off + 1],
                    sp[unsafe_offset=src_off + 2],
                    sa,
                ),
            )


def blit_glyph[
    o: Origin[mut=True]
](s: Surface[o], g: _GlyphInfo, x0: Int, y0: Int, c: Color):
    """Composite a glyph's coverage mask at `(x0, y0)` in `c`.

    Coverage scales the fill's alpha, so antialiasing and a translucent fill
    compose rather than one overriding the other.
    """
    var W = s.width
    var H = s.height
    var ca = Int(c.a)
    var gp = g.pixels.unsafe_ptr()
    for row in range(g.height):
        var py = y0 + row
        if py < 0 or py >= H:
            continue
        for col in range(g.width):
            var cov = Int(gp[unsafe_offset=row * g.width + col])
            if cov == 0:
                continue
            var px_x = x0 + col
            if px_x < 0 or px_x >= W:
                continue
            blend(
                s,
                (py * W + px_x) * 4,
                Color(c.r, c.g, c.b, UInt8(cov * ca // 255)),
            )
