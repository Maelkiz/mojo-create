# AGENTS.md — mojo-create

## Purpose

Creative coding / interactive graphics library for Mojo, inspired by Processing but with a deliberately modular design. Rather than a monolithic object holding all responsibilities (drawing, input, timing, state), concerns are split: `Canvas` draws, `Context` holds frame state, `Input` holds user input. Goal is Processing's ergonomics with Mojo's performance and clean separation of concerns.

## Module Layout

| Module | Path | Responsibility |
|---|---|---|
| `core` | `src/create/core/` | Program traits, Canvas, Context, Input, Font, Color, Time |
| `math` | `src/create/math/` | Vector2, Vector3, Matrix, geometry shapes, random, util |
| `graphics` | `src/create/graphics/` | Sprite — BMP/PNG/JPEG loading and raw pixel buffer |

## Key Files

| File | Lines | Purpose |
|---|---|---|
| `src/create/core/program.mojo` | ~60 | Defines `NonInteractable`, `Headless`, `Windowed` traits |
| `src/create/core/run.mojo` | ~185 | `run[T](title)` / `run[T](title, w, h)` entry-point overloads |
| `src/create/core/canvas.mojo` | ~570 | Drawing API: shapes, text, transforms, coordinate helpers |
| `src/create/core/context.mojo` | ~20 | `Context` — width/height/center/time passed to every frame |
| `src/create/core/input.mojo` | ~106 | `Input` — keyboard state, mouse position/buttons |
| `src/create/math/geometry.mojo` | ~290 | `Rectangle`, `Circle`, `Line`, `Triangle`; `overlaps[A,B]` |
| `src/create/math/matrix.mojo` | ~150 | Generic `Matrix[rows,cols]` with 2D/3D transform constructors |
| `src/create/graphics/sprite.mojo` | ~225 | `Sprite` struct + BMP/PNG/JPEG parsers |

## Build & Test

```bash
# Run any file (always pass -I src)
mojo run -I src examples/sketch.mojo

# Pixi shorthand for examples
pixi run create examples/sketch.mojo

# Run all tests
pixi run test
# Equivalent:
for f in $(find tests -name "test_*.mojo" | sort); do mojo run -I src "$f"; done

# Run a single test file
mojo run -I src tests/math/test_vector2.mojo

# One-time setup (installs git hooks)
pixi run setup
```

## Code Conventions

**Defining a program:**
```mojo
# CORRECT ✓ — import everything, use @fieldwise_init, implement required methods
from create.core import *

@fieldwise_init
struct App(Windowed, Movable, Deinitable):
    var x: Float64

    @staticmethod
    def create(mut ctx: Context) raises -> App:
        return App(0.0)

    def update(mut self, mut ctx: Context, mut input: Input) raises:
        if input.key_down("right"):
            self.x += 5.0

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.WHITE)
        canvas.circle((self.x, 200.0), 30)

def main() raises:
    run[App]("Demo", 800, 600)

# WRONG ✗ — accessing input via ctx (was removed)
def update(mut self, mut ctx: Context) raises:
    if ctx.input.key_down("right"): ...  # ctx has no .input field
```

**Transform scope:**
```mojo
# CORRECT ✓ — use the context manager; transform auto-pops on exit
with canvas.transform(translate(50.0, 50.0)):
    canvas.rect((0, 0), 100, 100)

# WRONG ✗ — manually pushing without guaranteed pop
canvas._push_transform(m)
```

**All shapes are center-positioned** (unlike Processing). `canvas.rect((x, y), w, h)` draws a rectangle centered at `(x, y)`, same as `canvas.circle()`, `canvas.sprite()`, etc. This matches Unity/Godot conventions. `Rectangle.x/y` is the center, not the top-left corner.

**Key strings:** pass lowercase strings to `input.key_down()` / `input.key_just_pressed()` — single char (`"a"`) or named key (`"up"`, `"ctrl"`, `"shift"`).

## Critical Gotchas

1. **`-I src` is required for every `mojo run`.** Without it, `from create.core import *` fails with a module-not-found error. All pixi tasks include it; bare `mojo run` calls must add it manually.

2. **`run[T]("title")` with no size opens fullscreen** — SDL fires a bogus `(1, 1)` `Resized` event before reporting real dimensions. `_wait_for_dimensions` pumps events until width > 1 and height > 1. Do not pass `(0, 0)` directly to `run`.

3. **Pre-commit hook compiles `examples/sketch.mojo`.** Breaking that file aborts all commits. Edit it with care or temporarily skip with `git commit --no-verify` (only when intentionally broken during refactor).

4. **Tests are plain Mojo programs, not a test framework.** Each `test_*.mojo` file calls `assert` directly and terminates. There is no `unittest` module or runner. `pixi run test` aborts on first non-zero exit (`set -e`), so a failing file stops the suite.

5. **`Headless` programs still open a window.** The headless loop skips `render`/`present` but SDL is initialized and a window is created for the event pump. There is no truly windowless mode.

## Terminology

| Term | Meaning |
|---|---|
| `NonInteractable` | Windowed program with render but no Input (background animations, screen savers) |
| `Headless` | Program with update+input but no render — window hidden; used for simulation |
| `Windowed` | Full interactive program: update + render + event callbacks |
| `Context` | Per-frame state bag: `ctx.width`, `ctx.height`, `ctx.center`, `ctx.time`, `ctx.exit_on_escape` |
| `Time` | Struct on `ctx.time`: `delta_time` (Float64, seconds), `delta_millis` (Int), `frame_count` (Int) |
| `TransformGuard` | RAII wrapper from `canvas.transform(m)` — pops the matrix on scope exit |
| `Convex` | Trait for SAT collision: implement `center()`, `closest_point()`, `contains()` |

## Do

- Use `@fieldwise_init` on program structs to auto-generate `__init__` from fields.
- Use `pixi run test` before committing.
- Use `canvas.background(Color.X)` as the first call in `render` to clear the frame.
- Use `canvas.to_world()` / `canvas.to_local()` when mapping between screen and transformed coordinates.
- Add `Movable` and `Deinitable` to every program struct (required by all three traits).

## Don't

- Don't run `mojo run` without `-I src` — module imports will fail.
- Don't hold a raw `Pointer` to `Canvas` outside `TransformGuard` — use origin-tracked references.
- Don't name new test files without the `test_` prefix — the test runner won't pick them up.
- Don't implement `render` on a `Headless` struct — the trait has no `render` method and the loop never calls it.
