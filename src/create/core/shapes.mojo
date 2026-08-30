from std.math import max, min, abs
from .canvas import Canvas
from .renderable import Renderable
from .color import Color



@fieldwise_init
struct Rect(Renderable):
    var x: Int
    var y: Int
    var w: Int
    var h: Int

    def render_to(self, mut canvas: Canvas) raises:
        var W = canvas._win.width()
        var H = canvas._win.height()
        var px = canvas._win.pixels()
        if canvas._fill_enabled:
            var c = canvas._fill
            for row in range(max(self.y, 0), min(self.y + self.h, H)):
                for col in range(max(self.x, 0), min(self.x + self.w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r
                    px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b
                    px[unsafe_offset=off + 3] = c.a
        if canvas._stroke_enabled:
            var sw = canvas._stroke_width
            var c = canvas._stroke
            for row in range(max(self.y, 0), min(self.y + sw, H)):
                for col in range(max(self.x, 0), min(self.x + self.w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(self.y + self.h - sw, 0), min(self.y + self.h, H)):
                for col in range(max(self.x, 0), min(self.x + self.w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(self.y + sw, 0), min(self.y + self.h - sw, H)):
                for col in range(max(self.x, 0), min(self.x + sw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
                for col in range(max(self.x + self.w - sw, 0), min(self.x + self.w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a


@fieldwise_init
struct Circle(Renderable):
    var cx: Int
    var cy: Int
    var r: Int

    def render_to(self, mut canvas: Canvas) raises:
        var W = canvas._win.width()
        var H = canvas._win.height()
        var x0 = max(self.cx - self.r, 0)
        var y0 = max(self.cy - self.r, 0)
        var x1 = min(self.cx + self.r + 1, W)
        var y1 = min(self.cy + self.r + 1, H)
        var r2 = self.r * self.r
        var r_inner = self.r - canvas._stroke_width
        var r_inner2 = r_inner * r_inner
        var px = canvas._win.pixels()
        for row in range(y0, y1):
            var dy = row - self.cy
            for col in range(x0, x1):
                var dx = col - self.cx
                var d2 = dx * dx + dy * dy
                if d2 <= r2:
                    var off = (row * W + col) * 4
                    if canvas._fill_enabled and (not canvas._stroke_enabled or r_inner <= 0 or d2 <= r_inner2):
                        px[unsafe_offset=off] = canvas._fill.r
                        px[unsafe_offset=off + 1] = canvas._fill.g
                        px[unsafe_offset=off + 2] = canvas._fill.b
                        px[unsafe_offset=off + 3] = canvas._fill.a
                    elif canvas._stroke_enabled and d2 > r_inner2:
                        px[unsafe_offset=off] = canvas._stroke.r
                        px[unsafe_offset=off + 1] = canvas._stroke.g
                        px[unsafe_offset=off + 2] = canvas._stroke.b
                        px[unsafe_offset=off + 3] = canvas._stroke.a


@fieldwise_init
struct Line(Renderable):
    var x0: Int
    var y0: Int
    var x1: Int
    var y1: Int

    def render_to(self, mut canvas: Canvas) raises:
        if not canvas._stroke_enabled:
            return
        var W = canvas._win.width()
        var H = canvas._win.height()
        var px = canvas._win.pixels()
        var c = canvas._stroke
        var half = canvas._stroke_width // 2
        var dx = abs(self.x1 - self.x0)
        var dy = -abs(self.y1 - self.y0)
        var sx = 1 if self.x0 < self.x1 else -1
        var sy = 1 if self.y0 < self.y1 else -1
        var err = dx + dy
        var x = self.x0
        var y = self.y0
        while True:
            for ry in range(-half, canvas._stroke_width - half):
                for rx in range(-half, canvas._stroke_width - half):
                    var nx = x + rx
                    var ny = y + ry
                    if 0 <= nx < W and 0 <= ny < H:
                        var off = (ny * W + nx) * 4
                        px[unsafe_offset=off] = c.r
                        px[unsafe_offset=off + 1] = c.g
                        px[unsafe_offset=off + 2] = c.b
                        px[unsafe_offset=off + 3] = c.a
            if x == self.x1 and y == self.y1:
                break
            var e2 = 2 * err
            if e2 >= dy:
                if x == self.x1:
                    break
                err += dy
                x += sx
            if e2 <= dx:
                if y == self.y1:
                    break
                err += dx
                y += sy


@fieldwise_init
struct Triangle(Renderable):
    var x1: Int
    var y1: Int
    var x2: Int
    var y2: Int
    var x3: Int
    var y3: Int

    def render_to(self, mut canvas: Canvas) raises:
        var W = canvas._win.width()
        var H = canvas._win.height()
        var px = canvas._win.pixels()
        if canvas._fill_enabled:
            var min_x = max(min(self.x1, min(self.x2, self.x3)), 0)
            var max_x = min(max(self.x1, max(self.x2, self.x3)), W - 1)
            var min_y = max(min(self.y1, min(self.y2, self.y3)), 0)
            var max_y = min(max(self.y1, max(self.y2, self.y3)), H - 1)
            var c = canvas._fill
            for row in range(min_y, max_y + 1):
                for col in range(min_x, max_x + 1):
                    var d1 = (self.x2 - self.x1) * (row - self.y1) - (self.y2 - self.y1) * (col - self.x1)
                    var d2 = (self.x3 - self.x2) * (row - self.y2) - (self.y3 - self.y2) * (col - self.x2)
                    var d3 = (self.x1 - self.x3) * (row - self.y3) - (self.y1 - self.y3) * (col - self.x3)
                    var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
                    var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
                    if not (has_neg and has_pos):
                        var off = (row * W + col) * 4
                        px[unsafe_offset=off] = c.r
                        px[unsafe_offset=off + 1] = c.g
                        px[unsafe_offset=off + 2] = c.b
                        px[unsafe_offset=off + 3] = c.a
        if canvas._stroke_enabled:
            Line(self.x1, self.y1, self.x2, self.y2).render_to(canvas)
            Line(self.x2, self.y2, self.x3, self.y3).render_to(canvas)
            Line(self.x3, self.y3, self.x1, self.y1).render_to(canvas)
