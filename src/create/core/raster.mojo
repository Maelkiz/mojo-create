from std.math import max, min, abs
from .color import Color
from .font import GlyphInfo
from .surface import Surface
from create.graphics.sprite import Sprite


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


def fill_all[o: Origin[mut=True]](s: Surface[o], c: Color):
    """Composite `c` over every pixel — the whole frame, no clipping needed."""
    for i in range(s.width * s.height):
        blend(s, i * 4, c)


def fill_pixels[
    o: Origin[mut=True]
](s: Surface[o], x0: Int, y0: Int, x1: Int, y1: Int, c: Color):
    """Fill the half-open device-space rect `[x0, x1) x [y0, y1)`, clipped."""
    var W = s.width
    for row in range(max(y0, 0), min(y1, s.height)):
        for col in range(max(x0, 0), min(x1, W)):
            blend(s, (row * W + col) * 4, c)


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
    o: Origin[mut=True]
](s: Surface[o], sprite: Sprite, x0: Int, y0: Int, dw: Int, dh: Int):
    """Blit `sprite` into the device rect at `(x0, y0)` sized `dw` x `dh`.

    Nearest-neighbour: rotation and shear are not resampled, so the caller
    maps the anchor and hands over an axis-aligned destination. A 1:1 blit
    skips the source-index division rather than relying on it cancelling.
    """
    var W = s.width
    var H = s.height
    var sp = sprite.pixels.unsafe_ptr()
    var one_to_one = dw == sprite.width and dh == sprite.height
    for row in range(dh):
        var dy = y0 + row
        if dy < 0 or dy >= H:
            continue
        var src_row = row if one_to_one else row * sprite.height // dh
        for col in range(dw):
            var dx = x0 + col
            if dx < 0 or dx >= W:
                continue
            var src_col = col if one_to_one else col * sprite.width // dw
            var src_off = (src_row * sprite.width + src_col) * 4
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
](s: Surface[o], g: GlyphInfo, x0: Int, y0: Int, c: Color):
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
