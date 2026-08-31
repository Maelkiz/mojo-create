from std.math import max, min, abs
from window.window import Window
from window.event import Event
from .color import Color
from .align import Align
from .font_weight import FontWeight
from .font import Font, FONT_DEFAULT_PATH
from create.math.geometry import Rectangle, Circle, Line, Triangle
from create.math.vector2 import Vector2
from create.math.point import Point
from create.graphics.sprite import Sprite


struct Canvas(Movable):
    var _win: Window
    var _fill: Color
    var _fill_enabled: Bool
    var _stroke: Color
    var _stroke_width: Int
    var _stroke_enabled: Bool
    var _font_size: Int
    var _font_weight: Int
    var _text_align: Int
    var _text_baseline: Int
    var _font: Font

    def __init__(out self, title: String, width: Int, height: Int) raises:
        var fullscreen = width == 0 and height == 0
        self._win = Window(title, width, height, fullscreen)
        self._fill = Color.WHITE
        self._fill_enabled = True
        self._stroke = Color.BLACK
        self._stroke_width = 1
        self._stroke_enabled = True
        self._font_size = 16
        self._font_weight = FontWeight.NORMAL
        self._text_align = Align.LEFT
        self._text_baseline = Align.TOP
        self._font = Font(FONT_DEFAULT_PATH, 16)

    def is_open(self) -> Bool:
        return self._win.is_open()

    def close(mut self):
        self._win.close()

    def events(mut self) raises -> List[Event]:
        return self._win.events()

    def present(mut self) raises:
        self._win.present()

    def ticks(self) raises -> Int:
        return self._win.ticks()

    def fill(mut self, color: Color):
        self._fill = color
        self._fill_enabled = True

    def no_fill(mut self):
        self._fill_enabled = False

    def stroke(mut self, color: Color):
        self._stroke = color
        self._stroke_enabled = True

    def no_stroke(mut self):
        self._stroke_enabled = False

    def stroke_width(mut self, w: Int):
        self._stroke_width = w

    def background(mut self, color: Color) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        for i in range(W * H):
            var off = i * 4
            px[unsafe_offset=off] = color.r
            px[unsafe_offset=off + 1] = color.g
            px[unsafe_offset=off + 2] = color.b
            px[unsafe_offset=off + 3] = color.a

    def rect(mut self, x: Float64, y: Float64, w: Float64, h: Float64) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var x0 = Int(x - w / 2.0)
        var y0 = Int(y - h / 2.0)
        var iw = Int(w)
        var ih = Int(h)
        if self._fill_enabled:
            var c = self._fill
            for row in range(max(y0, 0), min(y0 + ih, H)):
                for col in range(max(x0, 0), min(x0 + iw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r
                    px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b
                    px[unsafe_offset=off + 3] = c.a
        if self._stroke_enabled:
            var sw = self._stroke_width
            var c = self._stroke
            for row in range(max(y0, 0), min(y0 + sw, H)):
                for col in range(max(x0, 0), min(x0 + iw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(y0 + ih - sw, 0), min(y0 + ih, H)):
                for col in range(max(x0, 0), min(x0 + iw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(y0 + sw, 0), min(y0 + ih - sw, H)):
                for col in range(max(x0, 0), min(x0 + sw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
                for col in range(max(x0 + iw - sw, 0), min(x0 + iw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a

    def circle(mut self, cx: Float64, cy: Float64, r: Float64) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var x0 = max(Int(cx - r), 0)
        var y0 = max(Int(cy - r), 0)
        var x1 = min(Int(cx + r) + 1, W)
        var y1 = min(Int(cy + r) + 1, H)
        var r2 = r * r
        var r_inner = r - Float64(self._stroke_width)
        var r_inner2 = r_inner * r_inner
        for row in range(y0, y1):
            var dy = Float64(row) - cy
            for col in range(x0, x1):
                var dx = Float64(col) - cx
                var d2 = dx * dx + dy * dy
                if d2 <= r2:
                    var off = (row * W + col) * 4
                    if self._fill_enabled and (not self._stroke_enabled or r_inner <= 0.0 or d2 <= r_inner2):
                        px[unsafe_offset=off] = self._fill.r
                        px[unsafe_offset=off + 1] = self._fill.g
                        px[unsafe_offset=off + 2] = self._fill.b
                        px[unsafe_offset=off + 3] = self._fill.a
                    elif self._stroke_enabled and d2 > r_inner2:
                        px[unsafe_offset=off] = self._stroke.r
                        px[unsafe_offset=off + 1] = self._stroke.g
                        px[unsafe_offset=off + 2] = self._stroke.b
                        px[unsafe_offset=off + 3] = self._stroke.a

    def line(mut self, x0: Float64, y0: Float64, x1: Float64, y1: Float64) raises:
        if not self._stroke_enabled:
            return
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var c = self._stroke
        var half = self._stroke_width // 2
        var ix0 = Int(x0); var iy0 = Int(y0)
        var ix1 = Int(x1); var iy1 = Int(y1)
        var dx = abs(ix1 - ix0)
        var dy = -abs(iy1 - iy0)
        var sx = 1 if ix0 < ix1 else -1
        var sy = 1 if iy0 < iy1 else -1
        var err = dx + dy
        var x = ix0
        var y = iy0
        while True:
            for ry in range(-half, self._stroke_width - half):
                for rx in range(-half, self._stroke_width - half):
                    var nx = x + rx
                    var ny = y + ry
                    if 0 <= nx < W and 0 <= ny < H:
                        var off = (ny * W + nx) * 4
                        px[unsafe_offset=off] = c.r
                        px[unsafe_offset=off + 1] = c.g
                        px[unsafe_offset=off + 2] = c.b
                        px[unsafe_offset=off + 3] = c.a
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

    def triangle(mut self, x1: Float64, y1: Float64, x2: Float64, y2: Float64, x3: Float64, y3: Float64) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        if self._fill_enabled:
            var min_x = max(Int(min(x1, min(x2, x3))), 0)
            var max_x = min(Int(max(x1, max(x2, x3))), W - 1)
            var min_y = max(Int(min(y1, min(y2, y3))), 0)
            var max_y = min(Int(max(y1, max(y2, y3))), H - 1)
            var c = self._fill
            for row in range(min_y, max_y + 1):
                for col in range(min_x, max_x + 1):
                    var d1 = (x2 - x1) * (Float64(row) - y1) - (y2 - y1) * (Float64(col) - x1)
                    var d2 = (x3 - x2) * (Float64(row) - y2) - (y3 - y2) * (Float64(col) - x2)
                    var d3 = (x1 - x3) * (Float64(row) - y3) - (y1 - y3) * (Float64(col) - x3)
                    var has_neg = (d1 < 0.0) or (d2 < 0.0) or (d3 < 0.0)
                    var has_pos = (d1 > 0.0) or (d2 > 0.0) or (d3 > 0.0)
                    if not (has_neg and has_pos):
                        var off = (row * W + col) * 4
                        px[unsafe_offset=off] = c.r
                        px[unsafe_offset=off + 1] = c.g
                        px[unsafe_offset=off + 2] = c.b
                        px[unsafe_offset=off + 3] = c.a
        if self._stroke_enabled:
            self.line(x1, y1, x2, y2)
            self.line(x2, y2, x3, y3)
            self.line(x3, y3, x1, y1)

    def rect(mut self, x: Int, y: Int, w: Int, h: Int) raises:
        self.rect(Float64(x), Float64(y), Float64(w), Float64(h))

    def circle(mut self, cx: Int, cy: Int, r: Int) raises:
        self.circle(Float64(cx), Float64(cy), Float64(r))

    def line(mut self, x0: Int, y0: Int, x1: Int, y1: Int) raises:
        self.line(Float64(x0), Float64(y0), Float64(x1), Float64(y1))

    def triangle(mut self, x1: Int, y1: Int, x2: Int, y2: Int, x3: Int, y3: Int) raises:
        self.triangle(Float64(x1), Float64(y1), Float64(x2), Float64(y2), Float64(x3), Float64(y3))

    def rect(mut self, r: Rectangle) raises:
        self.rect(r.x, r.y, r.w, r.h)

    def rect(mut self, pos: Point, w: Float64, h: Float64) raises:
        self.rect(pos.x, pos.y, w, h)

    def rect(mut self, pos: Point, size: Vector2) raises:
        self.rect(pos.x, pos.y, size.x, size.y)

    def circle(mut self, c: Circle) raises:
        self.circle(c.x, c.y, c.r)

    def circle(mut self, pos: Point, r: Float64) raises:
        self.circle(pos.x, pos.y, r)

    def circle(mut self, pos: Point, r: Int) raises:
        self.circle(pos.x, pos.y, Float64(r))

    def line(mut self, l: Line) raises:
        self.line(l.x0, l.y0, l.x1, l.y1)

    def line(mut self, start: Point, end: Point) raises:
        self.line(start.x, start.y, end.x, end.y)

    def triangle(mut self, t: Triangle) raises:
        self.triangle(t.x1, t.y1, t.x2, t.y2, t.x3, t.y3)

    def triangle(mut self, a: Point, b: Point, c: Point) raises:
        self.triangle(a.x, a.y, b.x, b.y, c.x, c.y)

    def sprite(mut self, s: Sprite, cx: Int, cy: Int) raises:
        self.sprite(s, Float64(cx), Float64(cy))

    def sprite(mut self, s: Sprite, cx: Float64, cy: Float64) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var sp = s.pixels.unsafe_ptr()
        var x0 = Int(cx) - s.width // 2
        var y0 = Int(cy) - s.height // 2
        for row in range(s.height):
            var dy = y0 + row
            if dy < 0 or dy >= H:
                continue
            for col in range(s.width):
                var dx = x0 + col
                if dx < 0 or dx >= W:
                    continue
                var src_off = (row * s.width + col) * 4
                var sa = sp[unsafe_offset=src_off + 3]
                if sa == 0:
                    continue
                var dst_off = (dy * W + dx) * 4
                if sa == 255:
                    px[unsafe_offset=dst_off] = sp[unsafe_offset=src_off]
                    px[unsafe_offset=dst_off + 1] = sp[unsafe_offset=src_off + 1]
                    px[unsafe_offset=dst_off + 2] = sp[unsafe_offset=src_off + 2]
                    px[unsafe_offset=dst_off + 3] = 255
                else:
                    var a = Int(sa)
                    var ia = 255 - a
                    px[unsafe_offset=dst_off] = UInt8((Int(sp[unsafe_offset=src_off]) * a + Int(px[unsafe_offset=dst_off]) * ia) // 255)
                    px[unsafe_offset=dst_off + 1] = UInt8((Int(sp[unsafe_offset=src_off + 1]) * a + Int(px[unsafe_offset=dst_off + 1]) * ia) // 255)
                    px[unsafe_offset=dst_off + 2] = UInt8((Int(sp[unsafe_offset=src_off + 2]) * a + Int(px[unsafe_offset=dst_off + 2]) * ia) // 255)
                    px[unsafe_offset=dst_off + 3] = 255

    def sprite(mut self, s: Sprite, pos: Point) raises:
        self.sprite(s, pos.x, pos.y)

    def sprite(mut self, s: Sprite, cx: Float64, cy: Float64, w: Int, h: Int) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var sp = s.pixels.unsafe_ptr()
        var x0 = Int(cx) - w // 2
        var y0 = Int(cy) - h // 2
        for row in range(h):
            var dy = y0 + row
            if dy < 0 or dy >= H:
                continue
            var src_row = row * s.height // h
            for col in range(w):
                var dx = x0 + col
                if dx < 0 or dx >= W:
                    continue
                var src_col = col * s.width // w
                var src_off = (src_row * s.width + src_col) * 4
                var sa = sp[unsafe_offset=src_off + 3]
                if sa == 0:
                    continue
                var dst_off = (dy * W + dx) * 4
                if sa == 255:
                    px[unsafe_offset=dst_off] = sp[unsafe_offset=src_off]
                    px[unsafe_offset=dst_off + 1] = sp[unsafe_offset=src_off + 1]
                    px[unsafe_offset=dst_off + 2] = sp[unsafe_offset=src_off + 2]
                    px[unsafe_offset=dst_off + 3] = 255
                else:
                    var a = Int(sa)
                    var ia = 255 - a
                    px[unsafe_offset=dst_off] = UInt8((Int(sp[unsafe_offset=src_off]) * a + Int(px[unsafe_offset=dst_off]) * ia) // 255)
                    px[unsafe_offset=dst_off + 1] = UInt8((Int(sp[unsafe_offset=src_off + 1]) * a + Int(px[unsafe_offset=dst_off + 1]) * ia) // 255)
                    px[unsafe_offset=dst_off + 2] = UInt8((Int(sp[unsafe_offset=src_off + 2]) * a + Int(px[unsafe_offset=dst_off + 2]) * ia) // 255)
                    px[unsafe_offset=dst_off + 3] = 255

    def sprite(mut self, s: Sprite, cx: Int, cy: Int, w: Int, h: Int) raises:
        self.sprite(s, Float64(cx), Float64(cy), w, h)

    def sprite(mut self, s: Sprite, pos: Point, w: Int, h: Int) raises:
        self.sprite(s, pos.x, pos.y, w, h)

    def fontSize(mut self, size: Int):
        self._font_size = size

    def fontWeight(mut self, weight: Int):
        self._font_weight = weight

    def textAlign(mut self, align: Int):
        self._text_align = align

    def textBaseline(mut self, baseline: Int):
        self._text_baseline = baseline

    def text(mut self, s: String, x: Int, y: Int) raises:
        self.text(s, Float64(x), Float64(y))

    def text(mut self, s: String, pos: Point) raises:
        self.text(s, pos.x, pos.y)

    def setFont(mut self, path: String) raises:
        self._font = Font(path, self._font_size)

    def text(mut self, s: String, x: Float64, y: Float64) raises:
        if not self._fill_enabled:
            return
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var size = self._font_size
        var bold = self._font_weight == FontWeight.BOLD
        var c = self._fill
        var cr = Int(c.r); var cg = Int(c.g); var cb = Int(c.b)
        var sp = s.unsafe_ptr()

        # Two-pass: measure total advance for alignment, then render.
        # First pass: measure
        var tw = 0
        for i in range(s.byte_length()):
            var g = self._font.render(Int(sp[unsafe_offset=i]), size, bold)
            tw += g.advance_x

        var draw_x = Int(x)
        var draw_y = Int(y)
        if self._text_align == Align.CENTER:
            draw_x -= tw // 2
        elif self._text_align == Align.RIGHT:
            draw_x -= tw

        var asc  = self._font.ascender
        var desc = self._font.descender
        var baseline_y = draw_y
        if self._text_baseline == Align.TOP:
            baseline_y += asc
        elif self._text_baseline == Align.MIDDLE:
            baseline_y += (asc + desc) // 2
        elif self._text_baseline == Align.BOTTOM:
            baseline_y += desc

        # Second pass: render
        var cx = draw_x
        for i in range(s.byte_length()):
            var g = self._font.render(Int(sp[unsafe_offset=i]), size, bold)
            if g.width > 0 and g.height > 0:
                var glyph_x0 = cx + g.bearing_x
                var glyph_y0 = baseline_y - g.bearing_y
                var gp = g.pixels.unsafe_ptr()
                for row in range(g.height):
                    for col in range(g.width):
                        var alpha = Int(gp[unsafe_offset=row * g.width + col])
                        if alpha == 0:
                            continue
                        var px_x = glyph_x0 + col
                        var px_y = glyph_y0 + row
                        if 0 <= px_x < W and 0 <= px_y < H:
                            var off = (px_y * W + px_x) * 4
                            if alpha == 255:
                                px[unsafe_offset=off]     = c.r
                                px[unsafe_offset=off + 1] = c.g
                                px[unsafe_offset=off + 2] = c.b
                                px[unsafe_offset=off + 3] = c.a
                            else:
                                var ia = 255 - alpha
                                px[unsafe_offset=off]     = UInt8((cr * alpha + Int(px[unsafe_offset=off])     * ia) // 255)
                                px[unsafe_offset=off + 1] = UInt8((cg * alpha + Int(px[unsafe_offset=off + 1]) * ia) // 255)
                                px[unsafe_offset=off + 2] = UInt8((cb * alpha + Int(px[unsafe_offset=off + 2]) * ia) // 255)
                                px[unsafe_offset=off + 3] = c.a
            cx += g.advance_x
