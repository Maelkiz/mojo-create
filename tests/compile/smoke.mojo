# Compile-only smoke check for the pre-commit hook.
#
# NOT run by `pixi run test` — the suite globs `test_*.mojo`, and this file must
# never execute: `run[T]` opens a window and blocks. It is only ever built.
#
# Purpose is to fail fast on consumer-side API drift. Building a program from
# outside the library type-checks the trait surface, `run[T]` instantiation, and
# the Context/Input/Canvas signatures — none of which `mojo precompile` sees.
# Keep it minimal; the examples are the broad gate and run on push.

from create.core import *


@fieldwise_init
struct Smoke(Program):
    var x: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> Smoke:
        ctx.exit_on_escape = True
        return Smoke(0.0)

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        if input.is_key_down("right"):
            self.x += 100.0 * ctx.delta_time

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.WHITE)
        canvas.fill(Color.RED)
        canvas.circle((self.x, 0.0), 20)


def main() raises:
    run[Smoke]("Smoke Test", 320, 240)
