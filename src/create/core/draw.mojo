from window.window import Window
from window.event import Event
from .color import Color


struct Draw(Movable):
    var _win: Window
    var _fill: Color
    var _fill_enabled: Bool
    var _stroke: Color
    var _stroke_width: Int
    var _stroke_enabled: Bool
    var width: Int
    var height: Int

    def __init__(out self, title: String, width: Int, height: Int) raises:
        var fullscreen = width == 0 and height == 0
        self._win = Window(title, width, height, fullscreen)
        self._fill = Color.white()
        self._fill_enabled = True
        self._stroke = Color.black()
        self._stroke_width = 1
        self._stroke_enabled = True
        self.width = self._win.width()
        self.height = self._win.height()

    def is_open(self) -> Bool:
        return self._win.is_open()

    def close(mut self):
        self._win.close()

    def events(mut self) raises -> List[Event]:
        return self._win.events()

    def present(mut self) raises:
        self._win.present()

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
        var w = self.width
        var h = self.height
        var px = self._win.pixels()
        for i in range(w * h):
            var off = i * 4
            px[unsafe_offset=off] = color.r
            px[unsafe_offset=off + 1] = color.g
            px[unsafe_offset=off + 2] = color.b
            px[unsafe_offset=off + 3] = color.a

    def rect(mut self, x: Int, y: Int, w: Int, h: Int) raises:
        var W = self.width
        var H = self.height
        var px = self._win.pixels()
        if self._fill_enabled:
            for row in range(max(y, 0), min(y + h, H)):
                for col in range(max(x, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = self._fill.r
                    px[unsafe_offset=off + 1] = self._fill.g
                    px[unsafe_offset=off + 2] = self._fill.b
                    px[unsafe_offset=off + 3] = self._fill.a
        if self._stroke_enabled:
            var sw = self._stroke_width
            var c = self._stroke
            for row in range(max(y, 0), min(y + sw, H)):
                for col in range(max(x, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(y + h - sw, 0), min(y + h, H)):
                for col in range(max(x, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
            for row in range(max(y + sw, 0), min(y + h - sw, H)):
                for col in range(max(x, 0), min(x + sw, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a
                for col in range(max(x + w - sw, 0), min(x + w, W)):
                    var off = (row * W + col) * 4
                    px[unsafe_offset=off] = c.r; px[unsafe_offset=off + 1] = c.g
                    px[unsafe_offset=off + 2] = c.b; px[unsafe_offset=off + 3] = c.a

    def circle(mut self, cx: Int, cy: Int, r: Int) raises:
        var W = self.width
        var H = self.height
        var x0 = max(cx - r, 0)
        var y0 = max(cy - r, 0)
        var x1 = min(cx + r + 1, W)
        var y1 = min(cy + r + 1, H)
        var r2 = r * r
        var r_inner = r - self._stroke_width
        var r_inner2 = r_inner * r_inner
        var px = self._win.pixels()
        for row in range(y0, y1):
            var dy = row - cy
            for col in range(x0, x1):
                var dx = col - cx
                var d2 = dx * dx + dy * dy
                if d2 <= r2:
                    var off = (row * W + col) * 4
                    if self._fill_enabled and (not self._stroke_enabled or r_inner <= 0 or d2 <= r_inner2):
                        px[unsafe_offset=off] = self._fill.r
                        px[unsafe_offset=off + 1] = self._fill.g
                        px[unsafe_offset=off + 2] = self._fill.b
                        px[unsafe_offset=off + 3] = self._fill.a
                    elif self._stroke_enabled and d2 > r_inner2:
                        px[unsafe_offset=off] = self._stroke.r
                        px[unsafe_offset=off + 1] = self._stroke.g
                        px[unsafe_offset=off + 2] = self._stroke.b
                        px[unsafe_offset=off + 3] = self._stroke.a

    def line(mut self, x0: Int, y0: Int, x1: Int, y1: Int) raises:
        if not self._stroke_enabled:
            return
        var W = self.width
        var H = self.height
        var px = self._win.pixels()
        var c = self._stroke
        var half = self._stroke_width // 2
        var dx = abs(x1 - x0)
        var dy = -abs(y1 - y0)
        var sx = 1 if x0 < x1 else -1
        var sy = 1 if y0 < y1 else -1
        var err = dx + dy
        var x = x0
        var y = y0
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
            if x == x1 and y == y1:
                break
            var e2 = 2 * err
            if e2 >= dy:
                if x == x1:
                    break
                err += dy
                x += sx
            if e2 <= dx:
                if y == y1:
                    break
                err += dx
                y += sy

    def triangle(mut self, x1: Int, y1: Int, x2: Int, y2: Int, x3: Int, y3: Int) raises:
        var W = self.width
        var H = self.height
        var px = self._win.pixels()
        if self._fill_enabled:
            var min_x = max(min(x1, min(x2, x3)), 0)
            var max_x = min(max(x1, max(x2, x3)), W - 1)
            var min_y = max(min(y1, min(y2, y3)), 0)
            var max_y = min(max(y1, max(y2, y3)), H - 1)
            var c = self._fill
            for row in range(min_y, max_y + 1):
                for col in range(min_x, max_x + 1):
                    var d1 = (x2 - x1) * (row - y1) - (y2 - y1) * (col - x1)
                    var d2 = (x3 - x2) * (row - y2) - (y3 - y2) * (col - x2)
                    var d3 = (x1 - x3) * (row - y3) - (y1 - y3) * (col - x3)
                    var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
                    var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
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
