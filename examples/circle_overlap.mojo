from create import *


@fieldwise_init
struct App(Program, Movable, Deinitable):
    def window(self) -> WindowConfig:
        return WindowConfig("Circle Overlap")

    def update(mut self, mut c: Canvas) raises:
        var radius = 100
        var cx = c.width // 2
        var cy = c.height // 2
        var dx = c.mouse_x - cx
        var dy = c.mouse_y - cy

        var overlaps = dx * dx + dy * dy < (radius * 2) * (radius * 2)
        
        var bg_col = Color(40, 40, 60) if overlaps else Color(20, 20, 30)

        c.background(bg_col)
        c.no_stroke()
        c.fill(Color(220, 60, 60))
        c.circle(cx, cy, radius)
        c.fill(Color(60, 120, 220))
        c.circle(c.mouse_x, c.mouse_y, radius)


def main() raises:
    run(App())
