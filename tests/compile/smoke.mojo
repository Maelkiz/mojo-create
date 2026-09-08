# Compile-only smoke check for the pre-commit hook.
#
# NOT run by `pixi run test` — the suite globs `test_*.mojo`, and this file must
# never execute: `run[T]` opens a window and blocks. It is only ever built.
#
# Purpose is to fail fast on consumer-side API drift. Building a program from
# outside the library type-checks the trait surface, `run[T]` instantiation, and
# the Context/Input/Canvas signatures — none of which `mojo precompile` sees.
# Keep it minimal; the examples are the broad gate and run on push.

from std.memory import ArcPointer

from create.core import *
from create.audio import Audio, Sound


@fieldwise_init
struct Smoke(Program):
    var x: Float64
    var audio: Audio

    @staticmethod
    def create(mut ctx: Context) raises -> Smoke:
        ctx.exit_on_escape = True
        return Smoke(0.0, Audio())

    def update(mut self, mut ctx: Context, input: Input) raises:
        self.audio.update()
        if input.is_key_down("right"):
            self.x += 100.0 * ctx.time.delta
        if input.just_pressed("space"):
            _ = self.audio.play(ArcPointer(Sound.from_pcm(List[Int16](length=1, fill=0))))

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.WHITE)
        canvas.fill(Color.RED)
        canvas.circle((self.x, 0.0), 20)


def main() raises:
    run[Smoke]("Smoke Test", 320, 240)
