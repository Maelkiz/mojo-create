# AGENTS.md — Mojo Create

## Purpose

Mojo Create is a creative coding library for rapid prototyping and interactive graphics, inspired by Processing but built to scale — from sketch to game, prototype to full application. It provides a clean, modular API while taking full advantage of Mojo's performance and language features.

## Design Ethos

Mojo Create follows these principles:

- **Prioritize API intuitiveness.** Avoid non-obvious abbreviations and jargon. Prefer clarity over brevity when naming.
- **Prioritize consumer ergonomics.** Do not sacrifice usability merely to minimize the API surface.
- **Keep the common path simple.** Simple sketches should require minimal ceremony.
- **Keep the architecture modular.** Separate concerns appropriately and minimise coupling between components.
- **Prefer consistency over cleverness.** Similar concepts should behave and be named consistently throughout the API.
- **Make good performance the default.** Users should not need to understand the library's internals or use specialised APIs to get good performance.

The goal is **Processing's ergonomics + clean separation of concerns + Mojo's performance**.

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
| `src/create/core/autoscale.mojo` | `AutoScale` — the `FIT`/`EXTEND`/`OFF` mode constants |
| `src/create/core/style.mojo` | `Style` — fill, stroke, font settings; rebuilt fresh each frame, scoped by `canvas.style()` |
| `src/create/core/text.mojo` | `TextRenderer` — font loading, glyph cache, text layout |
| `src/create/core/font.mojo` | `Font`, `FontWeight`, and the paths of the two packaged Noto faces |
| `src/create/core/align.mojo` | `HAlign` (`LEFT`/`CENTER`/`RIGHT`), `VAlign` (`TOP`/`MIDDLE`/`BOTTOM`) |
| `src/create/core/color.mojo` | `Color` — constants, `hex`/`hsv`/`lerp` factories, `over` compositing |
| `src/create/core/context.mojo` | `Context` — width/height/time/autoscale passed to every frame |
| `src/create/core/time.mojo` | `Time` — frame delta, frame count, elapsed seconds |
| `src/create/core/input.mojo` | `Input` — keyboard state, mouse position/buttons |
| `src/create/core/key.mojo` | `Key` — named keycodes for the `Int` overloads |
| `src/create/core/path.mojo` | `script_dir()` — the directory of the running program, for asset paths |
| `src/create/math/geometry.mojo` | `Rectangle`, `Circle`, `Line`, `Triangle`; `overlaps[A,B]` |
| `src/create/math/matrix.mojo` | Generic `Matrix[rows,cols]` with 2D/3D transform constructors |
| `src/create/math/random.mojo` | `Random` — seeded generator: `float`, `int`, `bool` |
| `src/create/math/util.mojo` | `lerp`, `map`, `norm`, `smoothstep`, `sign`, `fract`, `fmod`, `degrees`, `radians` |
| `src/create/graphics/sprite.mojo` | `Sprite` struct + BMP/PNG/JPEG parsers |
| `src/create/audio/sound.mojo` | `Sound` — decoded PCM + format/channels/freq, `load`/`from_pcm` |
| `src/create/audio/audio.mojo` | `Audio` — playback device, voice lifecycle, `play`/`stop`/`update` |

## Build & Test

```bash
# Run any file
mojo run -I src examples/sketch.mojo

# Pixi shorthand for examples
pixi run create examples/sketch.mojo

# Run all tests
pixi run test
# Equivalent:
for f in $(find tests -name "test_*.mojo" | sort); do SDL_AUDIO_DRIVER=dummy mojo run -I src "$f"; done

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

## Testing

Tests use `std.testing.TestSuite`. Every `tests/**/test_*.mojo` file is a program whose `main`
discovers and runs the `test_*` functions in its own module:

```mojo
from std.testing import TestSuite, assert_equal, assert_true, assert_false

def test_thing_does_what_it_says() raises -> None:
    assert_equal(actual, expected)

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
```

A file reports PASS/FAIL per test and exits non-zero if any failed. `pixi run test` runs under
`set -e`, so the first failing *file* stops the suite — but within a file every test still runs.

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

**Imports:**

- `from create.core import *` — `Program`, `run`, `run_headless`, `Context`, `Time`, `Input`, `MouseButton`, `Key`, `Canvas`, `CanvasState`, `Color`, `HAlign`/`VAlign`, `AutoScale`, `Font`/`FontWeight`, `Sprite`, `Surface`/`MemorySurface`, `script_dir`, plus `Vector2`, `Matrix`, `identity`/`translate`/`rotate`/`scale` and the geometry shapes.
- `from create.math import *` — adds `Vector3`, `Random`, `inverse`/`apply`/`perspective`, the util functions, and a re-export of `std.math` (`sin`, `cos`, `sqrt`, `clamp`, `pi`, `tau`, …).
- `from create.audio import *` — `Sound`, `Audio`.

`Vector3`, `Random` and the util functions are **not** in `create.core`; reach for `create.math` for those.

**A `Program` can own `Program`s.** Multiple screens are not a distinct feature: a root `Program`
holds each screen as a plain field, in the same `update`/`render` shape but *not* implementing the
trait (Mojo has no dynamic trait dispatch, so nothing could hold them polymorphically anyway), and
switches with an int field and an `if`/`elif`:

```mojo
def update(mut self, mut ctx: Context, input: Input) raises:
    if self.scene == MENU:
        self.menu.update(ctx, input)
    else:
        self.game.update(ctx, input)
```

A scene needing a one-shot reset on entry gets a plain method (`enter()`) the parent calls right
before flipping the field; it is not part of `Program` and costs nothing to scenes that don't need
it. See [examples/scenes/src/main.mojo](examples/scenes/src/main.mojo) for a full menu/drawing-surface
pair, including that hook and a deliberately-never-cleared canvas so ink accumulates across frames.

**`Canvas` is a per-frame view, not a persistent object.** The run loop builds a fresh one each frame
over that frame's `Surface` and drops it before presenting — it owns no window and caches no pixel
pointer, which is what makes `run_headless` possible at all. Anything that must survive the frame
boundary lives in `CanvasState` (loaded fonts, letterbox colour), moved in at construction and
back out by `_release`. The transform stack and the style deliberately do **not**: every frame starts
unrotated, untranslated and at the default style, so a missing pop or a forgotten `no_stroke` cannot
leak into the next one. Nothing may hold a `Canvas` across frames; hold the `CanvasState` instead.

Both loops share [frame.mojo](src/create/core/frame.mojo)'s `step` for the frame body, so the windowed
and headless paths cannot drift in what a frame *is*; they differ only in how one gets started (SDL
events and a clock, versus a counter).

**A `Canvas` takes its geometry from the `Viewport` and its extent from the `Surface`**, and the two
can legitimately disagree for one frame. `Window._resize` reallocates the pixel buffer inside
`win.events()`, after the viewport was measured — so a `Surface` must be taken *after* event
processing, and its width and height must come from the window, never from the viewport. A lagging
mapping is one crooked frame; a lying extent is memory corruption, because the extent is baked into
the `Surface` and so defeats the clipping every raster loop otherwise does.

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
- Glyphs and sprites are **not** flipped — only their anchor point is mapped, so `VAlign.TOP`/`VAlign.BOTTOM` still mean the top and bottom of the text box.
- `input.mouse` is delivered in world coordinates, so it can be negative.

**All shapes are center-positioned** (unlike Processing). `canvas.rect((x, y), w, h)` draws a rectangle centered at `(x, y)`, same as `canvas.circle()`, `canvas.sprite()`, etc. `Rectangle.x/y` is the center, not the top-left corner.

`Vector2` has `@implicit` constructors from `Tuple[Float64, Float64]`, `Tuple[Int, Int]` and both mixed pairs, so any `Vector2` position argument accepts a bare tuple: `canvas.rect((0, 0), 100, 100)`, `canvas.circle((-100, 0), 50)`.

**Text and style defaults:** `canvas.font_size(n)`, `font_weight(FontWeight.BOLD)`,
`text_align(HAlign.CENTER, VAlign.MIDDLE)`, then `canvas.text("hi", pos)`. `text_align` is
overloaded on the axis: pass an `HAlign`, a `VAlign`, or both — there is no separate
`text_baseline`, and `VAlign.TOP`/`MIDDLE`/`BOTTOM` are edges of the text box, not typographic
baselines.
`canvas.font(f)` swaps the face. Every frame starts from `Style()`: fill `WHITE`, **stroke `BLACK`
and enabled**, stroke width 1, font size 16, weight `REGULAR`, halign `LEFT`, valign `TOP`.
Stroke-on-by-default is the one that surprises — a `rect` drawn without `no_stroke()` gets a black
outline.

**Alpha:** every pixel write goes through `_blend`, which composites source-over via `Color.over`. A fill, stroke, sprite, glyph, or `background` with `a < 255` blends with what is already there — `canvas.background(Color(0x11, 0x11, 0x11, 24))` fades the previous frame into motion trails. Opaque and fully transparent colors skip the read-back, so the common path costs a raw store.

**Autoscale** keeps the program in its design resolution while the window resizes. `ctx.width`/`height`, `input.mouse`, and all canvas coordinates stay in that design space; `canvas.scale` reports the factor, and font size, stroke width, and sprite size scale with it. `run` turns it on as `FIT`; `create` can set `ctx.autoscale` to either other mode. Three modes:

| `AutoScale` | Behaviour |
|---|---|
| `FIT` (default) | Uniform `min(w, h)` scale, design centred, leftover painted `canvas.letterbox` (default `#222222`) after render, which also clips anything drawn past the design bounds |
| `EXTEND` | Same scale factor as `FIT`, but anchored at the origin with no bars — `ctx.width`/`height` grow so the leftover becomes extra world. A wider window shows more horizontal space, a taller one more vertical |
| `OFF` | No scaling — `ctx.width`/`height` are the window in pixels, so layout must survive any window size on its own |

**Design resolution comes from the `run` arguments, not from the window.** `FIT` is the default
because `OFF` punishes the obvious way to write a program: coordinates laid out against the size the
author had, silently rearranged on any other display. The design size is therefore a property of the
program, not of the display — `run[T](title, w, h)` seeds both the window and the design space, but
they are independent afterwards, and the design space keeps what the caller asked for even when SDL
hands back something else. So `run[App]("T", 1000, 1000, fullscreen=True)` means *author at
1000x1000, present fullscreen*. Defaulting to `FIT` also keeps both jobs of the `run` size live:
under `OFF` the design resolution is unused, so `run("T", 1280, 720, fullscreen=True)` would ignore
the numbers entirely.

| call | `FIT` (default) / `EXTEND` | `AutoScale.OFF` |
|---|---|---|
| `run("T", 1000, 1000)` | design 1000x1000, scaled to the window | 1000x1000 window, world = window |
| `run("T", 1000, 1000, fullscreen=True)` | design 1000x1000, scaled to the monitor | fullscreen, world = monitor pixels |
| `run("T", fullscreen=True)` | design 1280x720 (the default), scaled to the monitor | fullscreen, world = monitor pixels |

`ctx.design(w, h, mode=AutoScale.FIT)` overrides the `run` size from inside `create`, for a program
that pins its own coordinate space no matter how it is launched. It recomputes the mapping on the
spot, so `ctx.width`/`height` and the edge helpers are correct for the rest of `create` rather than
one frame later.

Under `EXTEND`, `ctx.width`/`height` change with the window, so layout must anchor to the origin or to `ctx.left()`/`right()`/`bottom()`/`top()` rather than hardcoded design coordinates. See [examples/autoscale.mojo](examples/autoscale.mojo), which cycles all three modes on space.

**Key strings:** pass lowercase strings to `input.is_key_down()` / `input.just_pressed()` / `input.just_released()` — single char (`"a"`) or named key (`"up"`, `"ctrl"`, `"shift"`). Each also has an `Int` keycode overload, for which `Key` names the codes.

**Mouse buttons:** `input.is_mouse_down()` / `input.mouse_just_pressed()` / `input.mouse_just_released()` take a button number, defaulting to `MouseButton.LEFT` so the common case needs no argument. `MouseButton` (`LEFT`/`MIDDLE`/`RIGHT`/`BACK`/`FORWARD`) names the rest — prefer it over the raw int, since the numbering isn't obvious (`RIGHT` is 3, not 2). Values match SDL's numbering, but `BACK`/`FORWARD` are named for the side thumb buttons' actual job (SDL calls them X1/X2), not SDL's internal label. `input.wheel` is this frame's scroll delta, zeroed every frame like the key edge bits. `input.mouse_press_pos` is the world position at the most recent press this frame — captured at the press event itself, so it doesn't drift if the mouse keeps moving before the frame ends.

`Program` has no input callbacks — `update`'s `input` parameter is the only input surface, and it is complete: every window event either updates a field on `Input` or is otherwise already reflected in `Context` (`ctx.width`/`height` refresh every frame, so a resize needs no separate notification). This is also what makes input scriptable in a test: `Input` is a plain struct, so `run_headless` or a direct `step(...)` call can fill it in and drive click- or key-driven behaviour without a window — see [tests/core/test_frame.mojo](tests/core/test_frame.mojo).

**Parameter vs. field:** a resource the run loop *feeds* the program every frame (`Context`, `Input`, `Canvas`) stays a parameter; a resource the program *drives* on its own schedule (`Sprite`, `Font`, `Sound`, `Audio`) is a field the program owns and constructs in `create`. This is why adding audio required zero changes to `Program`, `Context`, or `run.mojo` — `Audio` is just another field, like `Sprite`.

**What earns its own parameter** is decided by *who writes it*, not by who feeds it — feeding alone doesn't distinguish anything, since `Time` is fed every frame and is a field on `Context`.

| | Loop writes | Program writes | Shape |
|---|---|---|---|
| `Context` (and its `Time`) | yes | yes | `mut` parameter |
| `Canvas` | yes | yes | `mut` parameter |
| `Input` | yes | **no** | read-only parameter |

`Input` is the only one the program never writes, and that is exactly why it stays out of `Context`: `ctx` must be `mut` for `quit()` and `autoscale`, so anything living on it inherits that mutability. As a separate argument, `input` is borrowed read-only and the one-way flow is enforced by the compiler. (`ctx.time` is the case that shows the cost — the program never writes it either, but `ctx.time.frame_count = 99` compiles.)

**Audio:** construct `Audio()` once in `create`, hold it as a field, and call `audio.update()` once per frame from `update` — SDL never tells `Audio` a stream finished on its own, so skipping `update()` stalls a loop after its first buffer drains and leaks one-shot voice slots forever. Hold `Sound`s as `ArcPointer[Sound]` fields (`from std.memory import ArcPointer`): `audio.play` takes an `ArcPointer[Sound]` for *every* voice, looping or one-shot, so a voice shares the PCM buffer (refcount bump) instead of copying it. `play` returns a voice id for `stop`/`pause`/`resume`/`is_playing`; ids are generation-counted so a stale id from a finished/recycled slot can't affect a later voice. See [examples/audio/src/main.mojo](examples/audio/src/main.mojo).

## Critical Gotchas

1. **`-I src` is required for every `mojo run`.** Without it, `from create.core import *` fails with a module-not-found error. All pixi tasks include it; bare `mojo run` calls must add it manually.

2. **Paths resolve against the CWD, not the source file.** The packaged font is loaded as the literal
   relative path `defaults/fonts/NotoSans.ttf` ([font.mojo](src/create/core/font.mojo), used by
   `TextRenderer._ensure_font`), so **`canvas.text()` only works when the process CWD is the repo
   root.** Run from anywhere else and every text draw raises:

   ```
   FT_New_Face failed — font not found: defaults/fonts/NotoSans.ttf
   ```

   The same applies to your own assets: use `script_dir()` (`from create.core import script_dir`),
   which returns the directory part of `argv[0]` — the `.mojo` file under `mojo run`, the binary
   under `mojo build` —

   ```mojo
   var sprite = Sprite.load(script_dir() + "/../assets/sprite.jpeg", 120, 120)
   var chime = ArcPointer(Sound.load(script_dir() + "/../assets/chime.wav"))
   ```

   Every example does this. Tests reach fixtures both ways — `tests/fixtures/...` relative to the
   root, or `script_dir() + "/../fixtures/"` — so the suite must be run from the root either way,
   which `pixi run test` guarantees.

3. **A window does not report its real size immediately.** In fullscreen SDL fires a bogus `(1, 1)` `Resized` before reporting real dimensions, so `_wait_for_dimensions` pumps events until width > 1 and height > 1. On Wayland the fullscreen transition is asynchronous on top of that: `run[T]("t", 1000, 1000, fullscreen=True)` reports the requested 1000x1000 for frame 1 and the display size from frame 2 on. The run loop refreshes dimensions every frame, so this self-corrects — but don't cache pixel dimensions from `create` or the first frame.

4. **Hooks block on breakage.** Breaking the core API aborts commits; a library type error, a broken example, or a failing test aborts pushes. `--no-verify` skips both hooks — it is for WIP checkpoints on a scratch branch that get squashed or amended before landing, never on `main`.

5. **`Canvas` must keep exactly one parameter.** `Program.render(self, mut canvas: Canvas)` relies on
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

## Terminology

| Term | Meaning |
|---|---|
| `Program` | Full interactive program: `create` + `update` + `render`. No event callbacks — input arrives as `update`'s `Input` parameter |
| `Context` | Per-frame state bag: `ctx.width`, `ctx.height`, `ctx.left()`/`right()`/`bottom()`/`top()`, `ctx.time`, `ctx.exit_on_escape`, `ctx.autoscale` (`AutoScale.FIT` default/`EXTEND`/`OFF`), `ctx.design(w, h, mode)`, `ctx.scale`, `ctx.quit()` |
| `Time` | Frame timing, owned by `Context` and ticked by the run loop: `ctx.time.delta` (Float64, seconds since last frame), `ctx.time.delta_millis` (Int), `ctx.time.elapsed` (Float64, seconds since the first frame), `ctx.time.elapsed_millis` (Int), `ctx.time.frame_count` (Int, 1 during the first `update`) |
| World space | The coordinate space programs draw in: origin centred, y up, extent `ctx.width` x `ctx.height`. `Canvas` maps it to framebuffer pixels through a single base matrix built by `Viewport.base_matrix()` |
| Design resolution | The size passed to `run` (default 1280x720, or pinned by `ctx.design()`) — the coordinate space a program is authored in, and the factor `ctx.autoscale` scales by. Independent of the window: unchanged by a resize or by fullscreen. Fixed under `AutoScale.FIT`; under `EXTEND` the reported size grows with the window |
| `Surface` | A borrowed RGBA framebuffer: pixel pointer plus width and height. Deliberately a plain value, not a trait — it is the seam between the raster loops and wherever the memory came from, an SDL window or a `MemorySurface` |
| `Viewport` | The design-space-to-pixel mapping: design size, autoscale mode, scale factor, offsets, base matrix. Owns no window and no pixels, so it is pure arithmetic; `Context` forwards to it |
| `CanvasState` | What survives the frame boundary — loaded fonts, letterbox colour — moved into each frame's `Canvas` and back out again. Style is *not* in it: `Canvas` is reachable only from `render`, so nothing could seed a style outside a frame, and carrying one forward would preserve only a forgotten setting |
| `TransformGuard` | RAII wrapper from `canvas.transform(m)` — pops the matrix on scope exit |
| `StyleGuard` | RAII wrapper from `canvas.style()` — restores fill, stroke and font settings on scope exit |
| `Color` | `Color(r, g, b, a=255)` or `Color(gray)`; factories `Color.hex(0x336699)`, `Color.hsv(h, s, v)`, `Color.lerp(a, b, t)`; constants `BLACK`/`WHITE`/`DARK_GRAY`/`GRAY`/`LIGHT_GRAY`/`RED`/`GREEN`/`BLUE`/`CYAN`/`MAGENTA`/`YELLOW`/`ORANGE`; queries `.luminance()`, `.to_hsv()`, `.over(dst)` |
| `HAlign` / `VAlign` | Text anchoring, set through the overloaded `canvas.text_align`: `HAlign.LEFT`/`CENTER`/`RIGHT`, `VAlign.TOP`/`MIDDLE`/`BOTTOM`. Stored on `Style` as `text_halign`/`text_valign` |
| `Font` / `FontWeight` | Packaged Noto faces, lazily loaded on first text draw, with a symbols fallback for missing glyphs; weights `THIN`/`LIGHT`/`REGULAR`/`MEDIUM`/`BOLD`/`BLACK` |
| `Key` / `MouseButton` | Named codes for the `Int` overloads of the `Input` queries |
| `Convex` | Trait for SAT collision: implement `center()`, `closest_point()`, `contains()` |
| `Matrix` | Generic `Matrix[rows, cols]` plus free functions `identity`, `inverse`, `apply`, `translate`, `rotate`, `scale`, `perspective` |
| `Random` | Seeded generator: `Random()` or `Random(seed)`, then `.float()`, `.float(lo, hi)`, `.int(lo, hi)`, `.bool()` |
| `Sprite` | Pixel buffer: `Sprite.load(path)` or `Sprite.load(path, w, h)` (BMP/PNG/JPEG, detected by extension), `Sprite.solid(w, h, r, g, b, a)`, `Sprite.from_rgba(w, h, data)`, `.resize(w, h)` |
| `Sound` | Decoded PCM audio + format/channels/freq; loaded via `Sound.load(path)` or synthesized via `Sound.from_pcm(samples)` |
| `Audio` | Program-owned playback device: `play`/`stop`/`stop_all`/`pause`/`resume`/`is_playing`/`set_volume`, plus `update()` (call once per frame) |

## Do

- Use `@fieldwise_init` on program structs to auto-generate `__init__` from fields.
- Use `pixi run test` before committing.
- Use `canvas.background(Color.X)` as the first call in `render` to clear the frame.
- Use `canvas.to_local(x, y)` to map a world position into the frame of the current transform, and `canvas.to_world(x, y)` for the reverse. Both take two `Float64` and return a `Tuple[Float64, Float64]` — there is no `Vector2` overload, so pass `input.mouse.x, input.mouse.y`. Neither deals in pixels.
- Use `script_dir()` for every asset path; a bare relative path resolves against the CWD.

## Don't

- Don't use `alias` it has been depricated in favor of `comptime`
- Don't use `UnsafePointer` it has been depricated in favor of `Pointer`
- Don't use `fn` it has been removed — `error: 'fn' has been removed; use 'def' instead`
- Don't hold a raw `Pointer` to `Canvas` outside `TransformGuard`/`StyleGuard` — use origin-tracked references.
- Don't name new test files without the `test_` prefix — the test runner won't pick them up.
- Don't add a second parameter to `Canvas`, and don't import `window` from `canvas.mojo` — see Gotcha 5.
