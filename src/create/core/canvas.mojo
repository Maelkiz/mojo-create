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
from create.math.matrix import Matrix, identity, inverse, apply as mat_apply
from create.graphics.sprite import Sprite


struct TransformGuard[origin: Origin[mut=True]](Movable):
    var _canvas: Pointer[Canvas, Self.origin]

    def __init__(out self, ref [Self.origin] canvas: Canvas):
        self._canvas = Pointer[Canvas, Self.origin](to=canvas)

    def __enter__(mut self):
        pass

    def __exit__(mut self):
        self._canvas[]._pop_transform()


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
    var _transform: Matrix[3, 3]
    var _transform_inv: Matrix[3, 3]
    var _transform_stack: List[Matrix[3, 3]]

    def __init__(out self, title: String, width: Int, height: Int) raises:
        var fullscreen = width == 0 and height == 0
        self._win = Window(title, width, height, fullscreen)
        self._fill = Color.WHITE
        self._fill_enabled = True
        self._stroke = Color.BLACK
        self._stroke_width = 1
        self._stroke_enabled = True
        self._font_size = 16
        self._font_weight = FontWeight.REGULAR
        self._text_align = Align.LEFT
        self._text_baseline = Align.TOP
        self._font = Font(FONT_DEFAULT_PATH, 16)
        self._transform = identity[3]()
        self._transform_inv = identity[3]()
        self._transform_stack = List[Matrix[3, 3]]()

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

    def transform(mut self, m: Matrix[3, 3]) -> TransformGuard[origin_of(self)]:
        self._push_transform(m)
        return TransformGuard[origin_of(self)](self)

    def _push_transform(mut self, m: Matrix[3, 3]):
        self._transform_stack.append(self._transform)
        self._transform = m @ self._transform
        self._transform_inv = inverse(self._transform)

    def _pop_transform(mut self):
        if len(self._transform_stack) > 0:
            self._transform = self._transform_stack.pop()
            self._transform_inv = inverse(self._transform)

    def to_world(self, x: Float64, y: Float64) -> Tuple[Float64, Float64]:
        return mat_apply(self._transform, x, y)

    def to_local(self, x: Float64, y: Float64) -> Tuple[Float64, Float64]:
        return mat_apply(self._transform_inv, x, y)

    def _line_pixels(mut self, x0: Float64, y0: Float64, x1: Float64, y1: Float64) raises:
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
        var lx0 = x - w / 2.0
        var ly0 = y - h / 2.0
        var lx1 = x + w / 2.0
        var ly1 = y + h / 2.0

        if len(self._transform_stack) == 0:
            var x0 = Int(lx0)
            var y0 = Int(ly0)
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
        else:
            var c0 = mat_apply(self._transform, lx0, ly0)
            var c1 = mat_apply(self._transform, lx1, ly0)
            var c2 = mat_apply(self._transform, lx1, ly1)
            var c3 = mat_apply(self._transform, lx0, ly1)
            var sx_min = max(Int(min(min(c0[0], c1[0]), min(c2[0], c3[0]))), 0)
            var sx_max = min(Int(max(max(c0[0], c1[0]), max(c2[0], c3[0]))) + 1, W)
            var sy_min = max(Int(min(min(c0[1], c1[1]), min(c2[1], c3[1]))), 0)
            var sy_max = min(Int(max(max(c0[1], c1[1]), max(c2[1], c3[1]))) + 1, H)
            var sw_f = Float64(self._stroke_width)
            for row in range(sy_min, sy_max):
                for col in range(sx_min, sx_max):
                    var local = mat_apply(self._transform_inv, Float64(col), Float64(row))
                    var lx = local[0]
                    var ly = local[1]
                    if lx < lx0 or lx > lx1 or ly < ly0 or ly > ly1:
                        continue
                    var off = (row * W + col) * 4
                    var in_inner = lx >= lx0 + sw_f and lx <= lx1 - sw_f and ly >= ly0 + sw_f and ly <= ly1 - sw_f
                    if self._fill_enabled and (not self._stroke_enabled or in_inner):
                        px[unsafe_offset=off] = self._fill.r
                        px[unsafe_offset=off + 1] = self._fill.g
                        px[unsafe_offset=off + 2] = self._fill.b
                        px[unsafe_offset=off + 3] = self._fill.a
                    elif self._stroke_enabled and not in_inner:
                        px[unsafe_offset=off] = self._stroke.r
                        px[unsafe_offset=off + 1] = self._stroke.g
                        px[unsafe_offset=off + 2] = self._stroke.b
                        px[unsafe_offset=off + 3] = self._stroke.a

    def circle(mut self, cx: Float64, cy: Float64, r: Float64) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var r2 = r * r
        var r_inner = r - Float64(self._stroke_width)
        var r_inner2 = r_inner * r_inner

        if len(self._transform_stack) == 0:
            var x0 = max(Int(cx - r), 0)
            var y0 = max(Int(cy - r), 0)
            var x1 = min(Int(cx + r) + 1, W)
            var y1 = min(Int(cy + r) + 1, H)
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
        else:
            var p0 = mat_apply(self._transform, cx - r, cy)
            var p1 = mat_apply(self._transform, cx + r, cy)
            var p2 = mat_apply(self._transform, cx, cy - r)
            var p3 = mat_apply(self._transform, cx, cy + r)
            var sx_min = max(Int(min(min(p0[0], p1[0]), min(p2[0], p3[0]))), 0)
            var sx_max = min(Int(max(max(p0[0], p1[0]), max(p2[0], p3[0]))) + 1, W)
            var sy_min = max(Int(min(min(p0[1], p1[1]), min(p2[1], p3[1]))), 0)
            var sy_max = min(Int(max(max(p0[1], p1[1]), max(p2[1], p3[1]))) + 1, H)
            for row in range(sy_min, sy_max):
                for col in range(sx_min, sx_max):
                    var local = mat_apply(self._transform_inv, Float64(col), Float64(row))
                    var dx = local[0] - cx
                    var dy = local[1] - cy
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
        var sx0 = x0; var sy0 = y0; var sx1 = x1; var sy1 = y1
        if len(self._transform_stack) > 0:
            var p0 = mat_apply(self._transform, x0, y0)
            var p1 = mat_apply(self._transform, x1, y1)
            sx0 = p0[0]; sy0 = p0[1]; sx1 = p1[0]; sy1 = p1[1]
        self._line_pixels(sx0, sy0, sx1, sy1)

    def triangle(mut self, x1: Float64, y1: Float64, x2: Float64, y2: Float64, x3: Float64, y3: Float64) raises:
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var sx1 = x1; var sy1 = y1
        var sx2 = x2; var sy2 = y2
        var sx3 = x3; var sy3 = y3
        if len(self._transform_stack) > 0:
            var p1 = mat_apply(self._transform, x1, y1)
            var p2 = mat_apply(self._transform, x2, y2)
            var p3 = mat_apply(self._transform, x3, y3)
            sx1 = p1[0]; sy1 = p1[1]
            sx2 = p2[0]; sy2 = p2[1]
            sx3 = p3[0]; sy3 = p3[1]
        if self._fill_enabled:
            var min_x = max(Int(min(sx1, min(sx2, sx3))), 0)
            var max_x = min(Int(max(sx1, max(sx2, sx3))), W - 1)
            var min_y = max(Int(min(sy1, min(sy2, sy3))), 0)
            var max_y = min(Int(max(sy1, max(sy2, sy3))), H - 1)
            var c = self._fill
            for row in range(min_y, max_y + 1):
                for col in range(min_x, max_x + 1):
                    var d1 = (sx2 - sx1) * (Float64(row) - sy1) - (sy2 - sy1) * (Float64(col) - sx1)
                    var d2 = (sx3 - sx2) * (Float64(row) - sy2) - (sy3 - sy2) * (Float64(col) - sx2)
                    var d3 = (sx1 - sx3) * (Float64(row) - sy3) - (sy1 - sy3) * (Float64(col) - sx3)
                    var has_neg = (d1 < 0.0) or (d2 < 0.0) or (d3 < 0.0)
                    var has_pos = (d1 > 0.0) or (d2 > 0.0) or (d3 > 0.0)
                    if not (has_neg and has_pos):
                        var off = (row * W + col) * 4
                        px[unsafe_offset=off] = c.r
                        px[unsafe_offset=off + 1] = c.g
                        px[unsafe_offset=off + 2] = c.b
                        px[unsafe_offset=off + 3] = c.a
        if self._stroke_enabled:
            self._line_pixels(sx1, sy1, sx2, sy2)
            self._line_pixels(sx2, sy2, sx3, sy3)
            self._line_pixels(sx3, sy3, sx1, sy1)

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
        var tx = x; var ty = y
        if len(self._transform_stack) > 0:
            var p = mat_apply(self._transform, x, y)
            tx = p[0]; ty = p[1]
        var W = self._win.width()
        var H = self._win.height()
        var px = self._win.pixels()
        var size = self._font_size
        self._font._set_weight(self._font_weight)
        var c = self._fill
        var cr = Int(c.r); var cg = Int(c.g); var cb = Int(c.b)

        # Two-pass: measure total advance for alignment, then render.
        # First pass: measure (iterate codepoints for correct Unicode handling)
        var tw = 0
        for cp in s.codepoints():
            var g = self._font.render(Int(cp), size)
            tw += g.advance_x

        var draw_x = Int(tx)
        var draw_y = Int(ty)
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
        for cp in s.codepoints():
            var g = self._font.render(Int(cp), size)
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
