# AGENTS.md — mojo-create

## Purpose

Creative coding / interactive graphics library for Mojo, inspired by Processing but with a deliberately modular design. Rather than a monolithic object holding all responsibilities (drawing, input, timing, state), concerns are split: `Canvas` draws, `Context` holds frame state, `Input` holds user input. Goal is Processing's ergonomics with Mojo's performance and clean separation of concerns.

## Module Layout

| Module | Path | Responsibility |
|---|---|---|
| `core` | `src/create/core/` | Program trait, run loops, Canvas, Surface, Viewport, Context, Time, Input, Font, Color |
| `math` | `src/create/math/` | Vector2, Vector3, Matrix, geometry shapes, random, util |
| `graphics` | `src/create/graphics/` | Sprite — BMP/PNG/JPEG loading and raw pixel buffer |
| `audio` | `src/create/audio/` | Sound, Audio — WAV/OGG/FLAC/MP3 loading and playback |

## Key Files

| File | Purpose |
|---|---|
| `src/create/core/program.mojo` | Defines the `Program` trait |
| `src/create/core/run.mojo` | `run[T](title, width, height, fullscreen)` — the windowed entry point |
| `src/create/core/frame.mojo` | `step[P]` — one frame: update, render, letterbox, release. The one copy, shared by both loops |
| `src/create/core/headless.mojo` | `run_headless[T](width, height, frames, pixel_width, pixel_height)` — same loop, owned buffer, no window |
| `src/create/core/canvas.mojo` | Drawing API: shapes, text, transforms, coordinate helpers |
| `src/create/core/surface.mojo` | `Surface` — a borrowed RGBA framebuffer; `MemorySurface` — one backed by owned memory |
| `src/create/core/raster.mojo` | Free functions over a `Surface`: blend, fills, lines, triangles, sprite and glyph blits |
| `src/create/core/viewport.mojo` | `Viewport` — the design-space-to-pixel mapping, autoscale arithmetic, base matrix |
| `src/create/core/style.mojo` | `Style` — fill, stroke, font settings; rebuilt fresh each frame, scoped by `canvas.style()` |
| `src/create/core/text.mojo` | `TextRenderer` — font loading, glyph cache, text layout |
| `src/create/core/context.mojo` | `Context` — width/height/center/time passed to every frame |
| `src/create/core/time.mojo` | `Time` — frame delta, frame count, elapsed seconds |
| `src/create/core/input.mojo` | `Input` — keyboard state, mouse position/buttons |
| `src/create/math/geometry.mojo` | `Rectangle`, `Circle`, `Line`, `Triangle`; `overlaps[A,B]` |
| `src/create/math/matrix.mojo` | Generic `Matrix[rows,cols]` with 2D/3D transform constructors |
| `src/create/graphics/sprite.mojo` | `Sprite` struct + BMP/PNG/JPEG parsers |
| `src/create/audio/sound.mojo` | `Sound` — decoded PCM + format/channels/freq, `load`/`from_pcm` |
| `src/create/audio/audio.mojo` | `Audio` — playback device, voice lifecycle, `play`/`stop`/`update` |

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

# Type-check the whole library without running anything (output goes to build/, gitignored)
pixi run precompile

# One-time setup (points core.hooksPath at .githooks)
pixi run setup
```

Two git hooks gate the repo; there is no CI, so these are the only automated checks.

| Hook | Runs | Cost |
|---|---|---|
| `.githooks/pre-commit` | Builds `tests/core/test_smoke.mojo` | ~1.5s, constant |
| `.githooks/pre-push` | `mojo precompile src/create`, all example entrypoints in parallel, then the test suite | ~16s |

Neither runs until `pixi run setup` has been done in the clone.

The two tiers catch different things and neither subsumes the other. Building a consumer program
type-checks only the `def` bodies it reaches, so it catches API drift — a program using a trait or
method that no longer exists — but not a broken library function nothing calls. `mojo precompile` is
the reverse: it type-checks the whole library and is blind to drift. Hence a smoke build on commit
and both, plus every example, on push.

Rendering is tested for real. `run_headless[T]` runs the same sequence as `run` — `create`, then
`update` and `render` per frame, letterbox after — over an owned `MemorySurface`, with synthetic 16ms
frames and empty input, and hands the buffer back. `MemorySurface.pixel(x, y)` reads one pixel out, so
[tests/core/test_canvas.mojo](tests/core/test_canvas.mojo) asserts on centring, y-up orientation,
alpha compositing, stroke scaling, letterbox bars and sprite blits instead of eyeballing them. Pass
`pixel_width`/`pixel_height` to give the framebuffer a different shape from the design size — a 1:1
mapping has no scale factor and no bars, so autoscale is untestable without it.

`tests/core/test_smoke.mojo` is both: the pre-commit hook builds it, and `pixi run test` runs it
through `run_headless`. Its `_windowed_entry_point` is never called — `run[T]` opens a window and
blocks — but an uncalled `def` body is still type-checked, so the windowed path stays gated. Keep the
file minimal: it builds on every commit, and its cost must not grow with the example count.

## Code Conventions

**Defining a program:** implement `Program` (`create` + `render`, optional `update`) and pass it to `run[T]`. See [examples/movement/src/main.mojo](examples/movement/src/main.mojo) for the full shape, or [tests/core/test_smoke.mojo](tests/core/test_smoke.mojo) for the minimum. Both are compile-gated, so neither can go stale.

> Input arrives as the `Input` argument to `update`, **not** via `Context`. `ctx.input` was removed; `Context` has no `input` field.

**`Canvas` is a per-frame view, not a persistent object.** The run loop builds a fresh one each frame
over that frame's `Surface` and drops it before presenting — it owns no window and caches no pixel
pointer, which is what makes `run_headless` possible at all. Anything that must survive the frame
boundary lives in `CanvasState` (loaded fonts, letterbox colour), moved in at construction and
back out by `_release`. The transform stack and the style deliberately do **not**: every frame starts
unrotated, untranslated and at the default style, so a missing pop or a forgotten `no_stroke` cannot
leak into the next one.

Style is per-frame because nothing can usefully set it otherwise: `Canvas` is reachable only from
`render`, so no program can seed a style in `create`, and every `render` sets what it draws with
anyway. Carrying it forward would preserve nothing but the mistakes — a `render` that sets fill inside
a branch would otherwise inherit the last frame that took the other branch.

Both loops share [frame.mojo](src/create/core/frame.mojo)'s `step` for the frame body, so the windowed
and headless paths cannot drift in what a frame *is*; they differ only in how one gets started (SDL
events and a clock, versus a counter).

**A `Canvas` takes its geometry from the `Viewport` and its extent from the `Surface`**, and the two
can legitimately disagree for one frame. `Window._resize` reallocates the pixel buffer inside
`win.events()`, after the viewport was measured — so a `Surface` must be taken *after* event
processing, and its width and height must come from the window, never from the viewport. A lagging
mapping is one crooked frame; a lying extent is memory corruption, because the extent is baked into
the `Surface` and so defeats the clipping every raster loop otherwise does.

Nothing may hold a `Canvas` across frames; hold the `CanvasState` instead.

**Transform scope:**
```mojo
# CORRECT ✓ — use the context manager; transform auto-pops on exit
with canvas.transform(translate(50.0, 50.0)):
    canvas.rect((0, 0), 100, 100)

# WRONG ✗ — manually pushing without guaranteed pop
canvas._push_transform(m)
```

**Style scope:** `fill`/`stroke`/`stroke_width`/`no_fill`/`no_stroke`/`font_size` and friends are bare
mutators, and calling them straight from `render` is the normal path — the style resets next frame
either way. `canvas.style()` is for the *callee*: a helper that sets style before drawing leaks it to
whatever the caller draws next, which the guard scopes away.

```mojo
# In a draw helper — restores the caller's fill, stroke and font on exit
with canvas.style():
    canvas.no_stroke()
    canvas.fill(Color(220, 80, 80))
    canvas.rect(self.pos, 40, 40)
```

`Style` is a plain value, so each guard carries its own snapshot and nesting needs no stack.

**Coordinate system is Unity-style, not Processing-style.** The origin is the **middle** of the design area and **y grows upward**. World `x` runs `[-width/2, +width/2]`, `y` runs `[-height/2, +height/2]`; `(0, 0)` is the centre of the screen and negative `y` is below it.

`Context` and `Canvas` both expose `left()`, `right()`, `bottom()`, `top()` as the edges — use those rather than `width`/`height` arithmetic, and note `left()` and `bottom()` are negative. `Rectangle.top()` is `y + h/2`.

Consequences worth internalising:

- `rotate(angle)` turns **counter-clockwise**, the mathematical convention.
- Downward motion is negative: gravity is a negative `vel_y`, a jump is positive. See [examples/movement/src/player.mojo](examples/movement/src/player.mojo).
- Glyphs and sprites are **not** flipped — only their anchor point is mapped, so `Align.TOP`/`BOTTOM` still mean the top and bottom of the text box.
- `input.mouse` and the `on_mouse_*` callbacks deliver world coordinates, so they can be negative.

**All shapes are center-positioned** (unlike Processing). `canvas.rect((x, y), w, h)` draws a rectangle centered at `(x, y)`, same as `canvas.circle()`, `canvas.sprite()`, etc. `Rectangle.x/y` is the center, not the top-left corner.

**Alpha:** every pixel write goes through `_blend`, which composites source-over via `Color.over`. A fill, stroke, sprite, glyph, or `background` with `a < 255` blends with what is already there — `canvas.background(Color(0x11, 0x11, 0x11, 24))` fades the previous frame into motion trails. Opaque and fully transparent colors skip the read-back, so the common path costs a raw store.

**Autoscale** keeps the program in its design resolution while the window resizes. `ctx.width`/`height`, `input.mouse`, and all canvas coordinates stay in that design space; `canvas.scale` reports the factor, and font size, stroke width, and sprite size scale with it. `run` turns it on as `FIT`; `create` can set `ctx.autoscale` to either other mode. Three modes:

| `AutoScale` | Behaviour |
|---|---|
| `FIT` (default) | Uniform `min(w, h)` scale, design centred, leftover painted `canvas.letterbox` (default `#222222`) after render, which also clips anything drawn past the design bounds |
| `EXTEND` | Same scale factor as `FIT`, but anchored at the origin with no bars — `ctx.width`/`height` grow so the leftover becomes extra world. A wider window shows more horizontal space, a taller one more vertical |
| `OFF` | No scaling — `ctx.width`/`height` are the window in pixels, so layout must survive any window size on its own |

`FIT` is the default because `OFF` punishes the obvious way to write a program: coordinates laid out
against the size the author had, silently rearranged on any other display. It also makes both jobs of
the `run` size live — under `OFF` the design resolution is unused, so `run("T", 1280, 720,
fullscreen=True)` would ignore the numbers entirely.

**Design resolution comes from the `run` arguments, not from the window.** `run[T](title, w, h)` sets
both, but the two are independent afterwards: `w`/`h` are the space the program is authored in, and
they are seeded from what the caller asked for even when SDL hands back something else. So
`run[App]("T", 1000, 1000, fullscreen=True)` means *author at 1000x1000, present fullscreen* — the
design space is a property of the program, not of whichever monitor it lands on.

| call | `FIT` (default) / `EXTEND` | `AutoScale.OFF` |
|---|---|---|
| `run("T", 1000, 1000)` | design 1000x1000, scaled to the window | 1000x1000 window, world = window |
| `run("T", 1000, 1000, fullscreen=True)` | design 1000x1000, scaled to the monitor | fullscreen, world = monitor pixels |
| `run("T", fullscreen=True)` | design 1280x720 (the default), scaled to the monitor | fullscreen, world = monitor pixels |

Under `OFF` the design size is unused and the world is simply the window — in a fullscreen window as
much as in a sized one.

`ctx.design(w, h, mode=AutoScale.FIT)` overrides the `run` size from inside `create`, for a program
that pins its own coordinate space no matter how it is launched. It recomputes the mapping on the
spot, so `ctx.width`/`height` and the edge helpers are correct for the rest of `create` rather than
one frame later.

Under `EXTEND`, `ctx.width`/`height` change with the window, so layout must anchor to the origin or to `ctx.left()`/`right()`/`bottom()`/`top()` rather than hardcoded design coordinates. See [examples/autoscale.mojo](examples/autoscale.mojo), which cycles all three modes on space.

**Key strings:** pass lowercase strings to `input.is_key_down()` / `input.just_pressed()` / `input.just_released()` — single char (`"a"`) or named key (`"up"`, `"ctrl"`, `"shift"`). Each also has an `Int` keycode overload.

**Mouse buttons:** `input.is_mouse_down()` / `input.mouse_just_pressed()` / `input.mouse_just_released()` take a button number (`1` = left, the default, so the common case needs no argument). `input.wheel` is this frame's scroll delta, zeroed every frame like the key edge bits. `input.mouse_press_pos` is the world position at the most recent press this frame — captured at the press event itself, so it doesn't drift if the mouse keeps moving before the frame ends.

`Program` has no input callbacks — `update`'s `input` parameter is the only input surface, and it is complete: every window event either updates a field on `Input` or is otherwise already reflected in `Context` (`ctx.width`/`height` refresh every frame, so a resize needs no separate notification). This is also what makes input scriptable in a test: `Input` is a plain struct, so `run_headless` or a direct `step(...)` call can fill it in and drive click- or key-driven behaviour without a window — see [tests/core/test_frame.mojo](tests/core/test_frame.mojo).

**Parameter vs. field:** a resource the run loop *feeds* the program every frame (`Context`, `Input`, `Canvas`) stays a parameter; a resource the program *drives* on its own schedule (`Sprite`, `Font`, `Sound`, `Audio`) is a field the program owns and constructs in `create`. This is why adding audio required zero changes to `Program`, `Context`, or `run.mojo` — `Audio` is just another field, like `Sprite`.

**What earns its own parameter** is decided by *who writes it*, not by who feeds it — feeding alone doesn't distinguish anything, since `Time` is fed every frame and is a field on `Context`.

| | Loop writes | Program writes | Shape |
|---|---|---|---|
| `Context` (and its `Time`) | yes | yes | `mut` parameter |
| `Canvas` | yes | yes | `mut` parameter |
| `Input` | yes | **no** | read-only parameter |

`Input` is the only one the program never writes, and that is exactly why it stays out of `Context`: `ctx` must be `mut` for `quit()` and `autoscale`, so anything living on it inherits that mutability. As a separate argument, `input` is borrowed read-only and the one-way flow is enforced by the compiler. (`ctx.time` is the case that shows the cost — the program never writes it either, but `ctx.time.frame_count = 99` compiles.)

Second reason, smaller but real: `Input` is constructed *after* `P.create(ctx)` in `run.mojo`, so `create` cannot read a fabricated input state. A zeroed `Time` is honest (`frame_count == 0`); a zeroed `Input` would report the mouse at `(0, 0)` — screen centre in this coordinate system, not a corner.

**Audio:** construct `Audio()` once in `create`, hold it as a field, and call `audio.update()` once per frame from `update` — SDL never tells `Audio` a stream finished on its own, so skipping `update()` stalls a loop after its first buffer drains and leaks one-shot voice slots forever. Hold `Sound`s as `ArcPointer[Sound]` fields (`from std.memory import ArcPointer`) — `audio.play(sound, loop=True)` takes an `ArcPointer[Sound]` so a looping voice shares the PCM buffer (refcount bump) instead of copying it. `play` returns a voice id for `stop`/`pause`/`resume`/`is_playing`; ids are generation-counted so a stale id from a finished/recycled slot can't affect a later voice. See [examples/audio/src/main.mojo](examples/audio/src/main.mojo).

## Critical Gotchas

1. **`-I src` is required for every `mojo run`.** Without it, `from create.core import *` fails with a module-not-found error. All pixi tasks include it; bare `mojo run` calls must add it manually.

2. **A window does not report its real size immediately.** In fullscreen SDL fires a bogus `(1, 1)` `Resized` before reporting real dimensions, so `_wait_for_dimensions` pumps events until width > 1 and height > 1. On Wayland the fullscreen transition is asynchronous on top of that: `run[T]("t", 1000, 1000, fullscreen=True)` reports the requested 1000x1000 for frame 1 and the display size from frame 2 on. The run loop refreshes dimensions every frame, so this self-corrects — but don't cache pixel dimensions from `create` or the first frame.

3. **Hooks block on breakage.** `pre-commit` builds `tests/core/test_smoke.mojo`; `pre-push` type-checks the library, builds every example, then runs the test suite. Breaking the core API aborts commits; a library type error, a broken example, or a failing test aborts pushes. Don't commit broken. `--no-verify` (it skips both hooks) is for WIP checkpoints on a scratch branch that get squashed or amended before landing — never on `main`.

4. **`Canvas` must keep exactly one parameter.** `Program.render(self, mut canvas: Canvas)` relies on
   `Canvas[origin]` having a single inferred parameter so user code can write a bare `Canvas`. Adding a
   second breaks every program in the repo at once.

   This is also why the framebuffer is refreshed by rebuilding the `Canvas` rather than by handing it
   a new `Surface`. That was tried and does not work: `Canvas`'s type embeds the window's pixel origin,
   so a call like `canvas._sync(Surface(win.pixels(), ...))` gives the call site a second mutable path
   to the same window and the compiler rejects it —

   ```
   error: aliasing values passed mutably to 'self' argument and passed mutably to 's' argument in '_sync' call
   ```

   Origin erasure would sidestep it, but `MutableAnyOrigin` is not a known declaration in this Mojo
   version. Constructing a fresh `Canvas` takes `out self`, so there is no existing borrow to alias
   against. Don't retry the `_sync` shape.

5. **Tests are plain Mojo programs, not a test framework.** Each `test_*.mojo` file calls `assert` directly and terminates. There is no `unittest` module or runner. `pixi run test` aborts on first non-zero exit (`set -e`), so a failing file stops the suite.

## Terminology

| Term | Meaning |
|---|---|
| `Program` | Full interactive program: update + render + event callbacks |
| `Context` | Per-frame state bag: `ctx.width`, `ctx.height`, `ctx.left()`/`right()`/`bottom()`/`top()`, `ctx.time`, `ctx.exit_on_escape`, `ctx.autoscale` (`AutoScale.FIT` default/`EXTEND`/`OFF`), `ctx.design(w, h, mode)`, `ctx.scale`, `ctx.quit()` |
| `Time` | Frame timing, owned by `Context` and ticked by the run loop: `ctx.time.delta` (Float64, seconds since last frame), `ctx.time.delta_millis` (Int), `ctx.time.elapsed` (Float64, seconds since the first frame), `ctx.time.frame_count` (Int, 1 during the first `update`) |
| World space | The coordinate space programs draw in: origin centred, y up, extent `ctx.width` x `ctx.height`. `Canvas` maps it to framebuffer pixels through a single base matrix built by `Viewport.base_matrix()` |
| Design resolution | The size passed to `run` (default 1280x720, or pinned by `ctx.design()`) — the coordinate space a program is authored in, and the factor `ctx.autoscale` scales by. Independent of the window: unchanged by a resize or by fullscreen. Fixed under `AutoScale.FIT`; under `EXTEND` the reported size grows with the window |
| `Surface` | A borrowed RGBA framebuffer: pixel pointer plus width and height. Deliberately a plain value, not a trait — it is the seam between the raster loops and wherever the memory came from, an SDL window or a `MemorySurface` |
| `Viewport` | The design-space-to-pixel mapping: design size, autoscale mode, scale factor, offsets, base matrix. Owns no window and no pixels, so it is pure arithmetic; `Context` forwards to it |
| `CanvasState` | What survives the frame boundary — loaded fonts, letterbox colour — moved into each frame's `Canvas` and back out again. Style is *not* in it: it is rebuilt per frame |
| `TransformGuard` | RAII wrapper from `canvas.transform(m)` — pops the matrix on scope exit |
| `StyleGuard` | RAII wrapper from `canvas.style()` — restores fill, stroke and font settings on scope exit |
| `Convex` | Trait for SAT collision: implement `center()`, `closest_point()`, `contains()` |
| `Sound` | Decoded PCM audio + format/channels/freq; loaded via `Sound.load(path)` or synthesized via `Sound.from_pcm(samples)` |
| `Audio` | Program-owned playback device: `play`/`stop`/`stop_all`/`pause`/`resume`/`is_playing`/`set_volume`, plus `update()` (call once per frame) |

## Do

- Use `@fieldwise_init` on program structs to auto-generate `__init__` from fields.
- Use `pixi run test` before committing.
- Use `canvas.background(Color.X)` as the first call in `render` to clear the frame.
- Use `canvas.to_local()` to map a world position (such as `input.mouse`) into the frame of the current transform, and `canvas.to_world()` for the reverse. Neither deals in pixels.

## Don't

- Don't use `alias` it has been depricated in favor of `comptime`
- Don't use `UnsafePointer` it has been depricated in favor of `Pointer`
- Don't use `fn` it has been removed — `error: 'fn' has been removed; use 'def' instead`
- Don't hold a raw `Pointer` to `Canvas` outside `TransformGuard`/`StyleGuard` — use origin-tracked references.
- Don't name new test files without the `test_` prefix — the test runner won't pick them up.
- Don't add a second parameter to `Canvas`, and don't import `window` from `canvas.mojo` — both undo the seam `run_headless` sits in.
