"""Mojo Create — a creative coding library for rapid prototyping and
interactive graphics.

`from create import *` is the import a program needs. It brings in the whole
public surface: the `Program` trait and the run loops, `Canvas` and the drawing
types, the vector and matrix maths, sprites, audio, and a re-export of
`std.math` so `sin`, `cos` and `pi` are there without a second import.

```mojo
from create import *


@fieldwise_init
struct Sketch(Program):
    var angle: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> Self:
        return Self(0.0)

    def update(mut self, mut ctx: Context, input: Input) raises:
        self.angle += ctx.time.delta

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.circle((100 * cos(self.angle), 100 * sin(self.angle)), 20)


def main() raises:
    run[Sketch]("Sketch", 1280, 720)
```

The subpackages stay importable on their own — `from create.render import *`
gives the drawing stack with no run loop, which is what `run_headless` is built
on — so this module is a convenience, not a layer.

**What this module re-exports is the union of the subpackages, not a closure.**
The subpackages each re-export a symbol from a lower one exactly when one of
their own signatures names it; that rule is what keeps `Vector3` and `Random`
out of `create.core`. The root has no signatures of its own, so it needs a
different rule: it re-exports everything public, and a star import of each
subpackage is how it stays that way. A name added to `math/__init__.mojo`
appears here with no second edit, so the two cannot drift apart.

The stars widen nothing on their own. A star import skips `_`-prefixed
declarations and reaches only what a package's `__init__.mojo` lists, so
`_raster`'s `blend`, `_bytes`'s `le_uint` and `font.mojo`'s `_GlyphInfo` stay
internal here exactly as they are one level down.
"""

from create.core import *
from create.math import *
from create.render import *
from create.sprite import *
from create.audio import *
