from create.core import *
from create.math import translate, rotate, scale, pi, tau, cos, sin


@fieldwise_init
struct Transforms(Windowed, Movable, Deinitable):
    var cx: Float64
    var cy: Float64
    var elapsed: Float64
    var mouse_x: Int
    var mouse_y: Int

    @staticmethod
    def create(mut ctx: Context) raises -> Transforms:
        return Transforms(
            cx=Float64(ctx.width) / 2.0,
            cy=Float64(ctx.height) / 2.0,
            elapsed=0.0,
            mouse_x=0,
            mouse_y=0,
        )

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        self.elapsed += ctx.delta_time
        self.mouse_x = input.mouse_x
        self.mouse_y = input.mouse_y

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color(8, 8, 20))

        var planet_angle = self.elapsed * tau / 10.0
        var moon_angle   = self.elapsed * tau / 3.5

        # Solar system: 3 levels of nested transforms
        var sun_hovered: Bool
        with canvas.transform(translate(self.cx, self.cy)):

            # Hit-test sun in local space (origin after the translate)
            var local = canvas.to_local(Float64(self.mouse_x), Float64(self.mouse_y))
            var lx = local[0]; var ly = local[1]
            sun_hovered = lx * lx + ly * ly <= 40.0 * 40.0

            # Sun
            canvas.no_stroke()
            canvas.fill(Color(30, 180, 230) if sun_hovered else Color(230, 180, 20))
            canvas.circle(0.0, 0.0, 40.0)

            # Planet — rotate then translate so it orbits the sun
            with canvas.transform(rotate(planet_angle) @ translate(160.0, 0.0)):

                # Thin orbit guide drawn in planet's frame before further nesting
                canvas.stroke(Color(50, 50, 70))
                canvas.stroke_width(1)
                canvas.no_fill()
                canvas.circle(0.0, 0.0, 45.0)

                canvas.no_stroke()
                canvas.fill(Color(60, 120, 220))
                canvas.circle(0.0, 0.0, 18.0)

                # Moon — orbits the planet
                with canvas.transform(rotate(moon_angle) @ translate(45.0, 0.0)):
                    canvas.fill(Color(170, 170, 170))
                    canvas.circle(0.0, 0.0, 8.0)

        # Spinning rect cluster: same transform pattern, different shape
        var cluster_cx = self.cx * 0.42
        var cluster_cy = self.cy * 1.55

        with canvas.transform(translate(cluster_cx, cluster_cy)):
            canvas.no_stroke()
            canvas.fill(Color(60, 60, 80))
            canvas.circle(0.0, 0.0, 8.0)

            for i in range(6):
                var arm_angle = self.elapsed * 0.9 + Float64(i) * tau / 6.0
                # Arm rotates; rect counter-rotates so it stays axis-aligned in world space
                with canvas.transform(rotate(arm_angle) @ translate(70.0, 0.0) @ rotate(-arm_angle)):
                    var t = (sin(self.elapsed * 2.0 + Float64(i)) + 1.0) / 2.0
                    var r = UInt8(60 + Int(t * 180.0))
                    var b = UInt8(180 - Int(t * 100.0))
                    canvas.fill(Color(r, 80, b))
                    canvas.rect(0.0, 0.0, 36.0, 18.0)

        # Rotating triangle fan 
        var fan_cx = self.cx * 1.58
        var fan_cy = self.cy * 1.55

        with canvas.transform(translate(fan_cx, fan_cy)):
            for i in range(5):
                var a = self.elapsed * 0.6 + Float64(i) * tau / 5.0
                with canvas.transform(rotate(a)):
                    var g = UInt8(100 + Int(Float64(i) * 30.0))
                    canvas.no_stroke()
                    canvas.fill(Color(40, g, 160))
                    canvas.triangle(0.0, 0.0, 60.0, 15.0, 60.0, -15.0)


def main() raises:
    run[Transforms]("Transform Demo", 800, 600)
