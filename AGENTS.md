# AGENTS.md — mojo-create

## Purpose

Creative coding / interactive graphics library for Mojo, inspired by Processing but with a deliberately modular design. Rather than a monolithic object holding all responsibilities (drawing, input, timing, state), concerns are split: `Canvas` draws, `Context` holds frame state, `Input` holds user input. Goal is Processing's ergonomics with Mojo's performance and clean separation of concerns.

## Module Layout

| Module | Path | Responsibility |
|---|---|---|
| `core` | `src/create/core/` | Program traits, Canvas, Context, Input, Font, Color |
| `math` | `src/create/math/` | Vector2, Vector3, Matrix, geometry shapes, random, util |
| `graphics` | `src/create/graphics/` | Sprite — BMP/PNG/JPEG loading and raw pixel buffer |

## Key Files

| File | Purpose |
|---|---|
| `src/create/core/program.mojo` | Defines the `Program` trait |
| `src/create/core/run.mojo` | `run[T](title)` / `run[T](title, w, h)` entry-point overloads |
| `src/create/core/canvas.mojo` | Drawing API: shapes, text, transforms, coordinate helpers |
| `src/create/core/context.mojo` | `Context` — width/height/center/time passed to every frame |
| `src/create/core/input.mojo` | `Input` — keyboard state, mouse position/buttons |
| `src/create/math/geometry.mojo` | `Rectangle`, `Circle`, `Line`, `Triangle`; `overlaps[A,B]` |
| `src/create/math/matrix.mojo` | Generic `Matrix[rows,cols]` with 2D/3D transform constructors |
| `src/create/graphics/sprite.mojo` | `Sprite` struct + BMP/PNG/JPEG parsers |

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

# One-time setup (points core.hooksPath at .githooks)
pixi run setup
```

Two git hooks gate the repo; there is no CI, so these are the only automated checks.

| Hook | Runs | Cost |
|---|---|---|
| `.githooks/pre-commit` | Builds `tests/compile/smoke.mojo` | ~1.5s, constant |
| `.githooks/pre-push` | `mojo precompile src/create`, all example entrypoints in parallel, then the test suite | ~16s |

Neither runs until `pixi run setup` has been done in the clone.

The two tiers catch different things and neither subsumes the other. Building a consumer program
type-checks only the `def` bodies it reaches, so it catches API drift — a program using a trait or
method that no longer exists — but not a broken library function nothing calls. `mojo precompile` is
the reverse: it type-checks the whole library and is blind to drift. Hence a smoke build on commit
and both, plus every example, on push.

`tests/compile/smoke.mojo` is built, never run — `run[T]` opens a window and blocks. It sits outside
the `test_*.mojo` glob deliberately so `pixi run test` skips it. Keep it minimal: it runs on every
commit, and its cost must not grow with the example count.

## Code Conventions

**Defining a program:** implement `Program` (`create` + `render`, optional `update`) and pass it to `run[T]`. See [examples/movement/src/main.mojo](examples/movement/src/main.mojo) for the full shape, or [tests/compile/smoke.mojo](tests/compile/smoke.mojo) for the minimum. Both are compile-gated, so neither can go stale.

> Input arrives as the `Input` argument to `update`, **not** via `Context`. `ctx.input` was removed; `Context` has no `input` field.

**Transform scope:**
```mojo
# CORRECT ✓ — use the context manager; transform auto-pops on exit
with canvas.transform(translate(50.0, 50.0)):
    canvas.rect((0, 0), 100, 100)

# WRONG ✗ — manually pushing without guaranteed pop
canvas._push_transform(m)
```

**All shapes are center-positioned** (unlike Processing). `canvas.rect((x, y), w, h)` draws a rectangle centered at `(x, y)`, same as `canvas.circle()`, `canvas.sprite()`, etc. This matches Unity/Godot conventions. `Rectangle.x/y` is the center, not the top-left corner.

**Alpha:** every pixel write goes through `_blend`, which composites source-over via `Color.over`. A fill, stroke, sprite, glyph, or `background` with `a < 255` blends with what is already there — `canvas.background(Color(0x11, 0x11, 0x11, 24))` fades the previous frame into motion trails. Opaque and fully transparent colors skip the read-back, so the common path costs a raw store.

**Autoscale:** set `ctx.autoscale` in `create` to keep the program in the resolution passed to `run` while the window resizes. `ctx.width`/`height`/`center`, `input.mouse`, and all canvas coordinates stay in that design space; `canvas.scale` reports the factor, and font size, stroke width, and sprite size scale with it. Three modes:

| `AutoScale` | Behaviour |
|---|---|
| `OFF` (default) | No scaling — `ctx.width`/`height` are the window in pixels |
| `FIT` | Uniform `min(w, h)` scale, design centred, leftover painted `canvas.letterbox` (default `#222222`) after render, which also clips anything drawn past the design bounds |
| `EXTEND` | Same scale factor as `FIT`, but anchored at the origin with no bars — `ctx.width`/`height` grow so the leftover becomes extra world. A wider window shows more horizontal space, a taller one more vertical |

Under `EXTEND`, `ctx.width`/`height` change with the window, so layout must anchor to `ctx.center` or the edges rather than hardcoded design coordinates. See [examples/autoscale.mojo](examples/autoscale.mojo), which toggles between the two modes on space.

**Key strings:** pass lowercase strings to `input.is_key_down()` / `input.just_pressed()` / `input.just_released()` — single char (`"a"`) or named key (`"up"`, `"ctrl"`, `"shift"`). Each also has an `Int` keycode overload.

## Critical Gotchas

1. **`-I src` is required for every `mojo run`.** Without it, `from create.core import *` fails with a module-not-found error. All pixi tasks include it; bare `mojo run` calls must add it manually.

2. **`run[T]("title")` with no size opens fullscreen** — SDL fires a bogus `(1, 1)` `Resized` event before reporting real dimensions. `_wait_for_dimensions` pumps events until width > 1 and height > 1. Do not pass `(0, 0)` directly to `run`.

3. **Hooks block on breakage.** `pre-commit` builds `tests/compile/smoke.mojo`; `pre-push` type-checks the library, builds every example, then runs the test suite. Breaking the core API aborts commits; a library type error, a broken example, or a failing test aborts pushes. Don't commit broken. `--no-verify` (it skips both hooks) is for WIP checkpoints on a scratch branch that get squashed or amended before landing — never on `main`.

4. **Tests are plain Mojo programs, not a test framework.** Each `test_*.mojo` file calls `assert` directly and terminates. There is no `unittest` module or runner. `pixi run test` aborts on first non-zero exit (`set -e`), so a failing file stops the suite.

## Terminology

| Term | Meaning |
|---|---|
| `Program` | Full interactive program: update + render + event callbacks |
| `Context` | Per-frame state bag: `ctx.width`, `ctx.height`, `ctx.center`, `ctx.delta_time` (Float64, seconds), `ctx.delta_millis` (Int), `ctx.frame_count` (Int), `ctx.exit_on_escape`, `ctx.autoscale` (`AutoScale.OFF`/`FIT`/`EXTEND`), `ctx.scale`, `ctx.quit()` |
| Design resolution | The size passed to `run` — the coordinate space a program is authored in, and the factor `ctx.autoscale` scales by. Fixed under `AutoScale.FIT`; under `EXTEND` the reported size grows with the window |
| `TransformGuard` | RAII wrapper from `canvas.transform(m)` — pops the matrix on scope exit |
| `Convex` | Trait for SAT collision: implement `center()`, `closest_point()`, `contains()` |

## Do

- Use `@fieldwise_init` on program structs to auto-generate `__init__` from fields.
- Use `pixi run test` before committing.
- Use `canvas.background(Color.X)` as the first call in `render` to clear the frame.
- Use `canvas.to_world()` / `canvas.to_local()` when mapping between screen and transformed coordinates.

## Don't

- Don't use `alias` it has been depricated in favor of `comptime`
- Don't use `UnsafePointer` it has been depricated in favor of `Pointer`
- Don't hold a raw `Pointer` to `Canvas` outside `TransformGuard` — use origin-tracked references.
- Don't name new test files without the `test_` prefix — the test runner won't pick them up.
