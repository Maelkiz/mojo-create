from std.math import max, min, abs
from window.window import Window
from window.event import Event
from .color import Color
from create.math.geometry import Rectangle, Circle, Line, Triangle


struct Canvas(Movable):
    var _win: Window
    var _fill: Color
    var _fill_enabled: Bool
    var _stroke: Color
    var _stroke_width: Int
    var _stroke_enabled: Bool

    def __init__(out self, title: String, width: Int, height: Int) raises:
        var fullscreen = width == 0 and height == 0
        self._win = Window(title, width, height, fullscreen)
        self._fill = Color.white()
        self._fill_enabled = True
        self._stroke = Color.black()
        self._stroke_width = 1
        self._stroke_enabled = True

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

    def circle(mut self, c: Circle) raises:
        self.circle(c.x, c.y, c.r)

    def line(mut self, l: Line) raises:
        self.line(l.x0, l.y0, l.x1, l.y1)

    def triangle(mut self, t: Triangle) raises:
        self.triangle(t.x1, t.y1, t.x2, t.y2, t.x3, t.y3)
