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
| root | `src/create/__init__.mojo` | The preamble — `from create import *`, the union of every subpackage below |
| `core` | `src/create/core/` | Program trait, run loops, Context, Time, Input, Key, script_dir |
| `render` | `src/create/render/` | Canvas, Surface, Viewport, AutoScale, Style, Color, Font, text layout, raster primitives |
| `math` | `src/create/math/` | Vector2, Vector3, Matrix, geometry shapes, random, util, easing curves and tweens |
| `sprite` | `src/create/sprite/` | Sprite — BMP/PNG/JPEG loading and raw pixel buffer; SpriteAnimation, SpriteAnimator — frame-based animation |
| `audio` | `src/create/audio/` | Sound, Audio — WAV/OGG/FLAC/MP3 loading and playback |
| `_bytes` | `src/create/_bytes.mojo` | Internal leaf — little-endian integer decoding. Imports nothing, re-exported by nothing |

## Key Files

| File | Purpose |
|---|---|
| `src/create/core/program.mojo` | Defines the `Program` trait |
| `src/create/core/run.mojo` | `run[T](title, width, height, fullscreen)` — the windowed entry point |
| `src/create/core/_frame.mojo` | `step[P]` — one frame: update, render, letterbox, release. The one copy, shared by both loops |
| `src/create/core/headless.mojo` | `run_headless[T](width, height, frames, pixel_width, pixel_height)` — same loop, owned buffer, no window |
| `src/create/core/context.mojo` | `Context` — width/height/time/autoscale passed to every frame |
| `src/create/core/time.mojo` | `Time` — frame delta, frame count, elapsed seconds |
| `src/create/core/input.mojo` | `Input` — keyboard state, mouse position/buttons |
| `src/create/core/key.mojo` | `Key` — named keycodes for the `Int` overloads |
| `src/create/core/path.mojo` | `script_dir()` — the directory of the running program, for asset paths |
| `src/create/render/canvas.mojo` | Drawing API: shapes, text, transforms, coordinate helpers |
| `src/create/render/surface.mojo` | `Surface` — a borrowed RGBA framebuffer; `MemorySurface` — one backed by owned memory |
| `src/create/render/_raster.mojo` | Free functions over a `Surface`: blend, fills, lines, triangles, raw-pixel and glyph blits |
| `src/create/render/viewport.mojo` | `Viewport` — the design-space-to-pixel mapping, autoscale arithmetic, base matrix |
| `src/create/render/autoscale.mojo` | `AutoScale` — the `FIT`/`EXTEND`/`OFF` mode constants |
| `src/create/render/_style.mojo` | `Style` — fill, stroke, font settings; rebuilt fresh each frame, scoped by `canvas.style()` |
| `src/create/render/_text.mojo` | `TextRenderer` — font loading, glyph cache, text layout |
| `src/create/render/font.mojo` | `Font`, `FontWeight`, and the paths of the two packaged Noto faces |
| `src/create/render/align.mojo` | `HorizontalAlignment` (`LEFT`/`CENTER`/`RIGHT`), `VerticalAlignment` (`TOP`/`MIDDLE`/`BOTTOM`) |
| `src/create/render/color.mojo` | `Color` — constants, `hex`/`hsv`/`lerp` factories, `over` compositing |
| `src/create/math/geometry.mojo` | `Rectangle`, `Circle`, `Line`, `Triangle`; the `overlaps`/`intersects`/`contains` relation taxonomy (see Terminology) |
| `src/create/math/matrix.mojo` | Generic `Matrix[rows,cols]` with 2D/3D transform constructors |
| `src/create/math/random.mojo` | `Random` — seeded generator: `float`, `int`, `bool` |
| `src/create/math/easing.mojo` | `Easing` — the named curve constants; `ease(curve, t)` — reshape a 0-to-1 fraction |
| `src/create/math/tween.mojo` | `Tween` — the playhead over one value, `start` to `end` over a duration |
| `src/create/math/util.mojo` | `lerp`, `map`, `norm`, `smoothstep`, `sign`, `fract`, `fmod`, `degrees`, `radians` |
| `src/create/sprite/sprite.mojo` | `Sprite` struct + BMP/PNG/JPEG parsers |
| `src/create/sprite/animation.mojo` | `SpriteAnimation` — frame sequence + fps; `from_sheet`, `from_folder` |
| `src/create/sprite/animator.mojo` | `SpriteAnimator` — the playhead over one animation |
| `src/create/audio/sound.mojo` | `Sound` — decoded PCM + format/channels/freq, `load`/`from_pcm` |
| `src/create/audio/audio.mojo` | `Audio` — playback device, voice lifecycle, `play`/`stop`/`update` |
| `src/create/_bytes.mojo` | `le_uint`, `sign_extend_32` — the one byte-assembly loop, shared by the image decoders and the freetype struct readers |

## Build & Test

```bash
# Run any file
mojo run -I src examples/sketch.mojo

# Pixi shorthand for examples
pixi run create examples/sketch.mojo

# Run all tests
pixi run test

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
| `.githooks/pre-commit` | Builds `tests/core/test_smoke.mojo` | Constant — does not grow with the repo |
| `.githooks/pre-push` | `mojo precompile src/create`, all example entrypoints in parallel, then the test suite | Grows with the example and test count |

Neither runs until `pixi run setup` has been done in the clone. Both block on breakage — breaking
the core API aborts commits; a library type error, a broken example, or a failing test aborts
pushes. `--no-verify` skips them, and is for WIP checkpoints on a scratch branch that get squashed
before landing, never on `main`.

The two tiers catch different things and neither subsumes the other: building a consumer program
type-checks only the `def` bodies it reaches, so it catches API drift but not a broken library
function nothing calls; `mojo precompile` is the reverse.

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

Rendering is tested for real. [`run_headless`](src/create/core/headless.mojo) drives a program over
an owned `MemorySurface` and hands the buffer back; `MemorySurface.pixel(x, y)` reads one pixel out.
So [tests/render/test_canvas.mojo](tests/render/test_canvas.mojo) asserts on centring, y-up
orientation, alpha compositing, stroke scaling, letterbox bars and sprite blits instead of eyeballing
them, and [tests/core/test_frame.mojo](tests/core/test_frame.mojo) scripts an `Input` and calls `step`
directly to drive click- and key-driven behaviour with no window.

`tests/core/test_smoke.mojo` is both: the pre-commit hook builds it, and `pixi run test` runs it
through `run_headless`. Its `_windowed_entry_point` is never called — `run[T]` opens a window and
blocks — but an uncalled `def` body is still type-checked, so the windowed path stays gated. Keep the
file minimal: it builds on every commit, and its cost must not grow with the example count.

## Code Conventions

**Defining a program:** implement `Program` (`create` + `render`, optional `update`) and pass it to `run[T]`. See [examples/movement/src/main.mojo](examples/movement/src/main.mojo) for the full shape, or [tests/core/test_smoke.mojo](tests/core/test_smoke.mojo) for the minimum. Both are compile-gated, so neither can go stale.

**Imports: `from create import *` is what a program writes.** It is the whole public surface —
everything the subpackages below re-export, in one line. Every example and every test uses it.

The subpackages remain importable on their own, for code that wants a narrower surface than a
program does:

- `from create.core import *` — the run loop and everything a `Program`'s signatures name, which by the closure rule below pulls in most of `render`, `math` and `sprite` too. Read `core/__init__.mojo` for the exact set.
- `from create.render import *` — the drawing stack with no run loop, which is what `run_headless` is built on. Adds `Viewport`.
- `from create.math import *` — adds `Vector3`, `Random`, `Easing`/`ease`/`Tween`, `inverse`/`apply`/`perspective`, the util functions, and a re-export of `std.math` (`sin`, `cos`, `sqrt`, `clamp`, `pi`, `tau`, …).
- `from create.audio import *` — `Sound`, `Audio`.

**The root is a union, the subpackages are closures — two different rules.**
[`create/__init__.mojo`](src/create/__init__.mojo) has no signatures of its own, so it cannot use
the closure rule below; it star-imports all five subpackages instead, which is what makes it exactly
their union and keeps it from drifting as they change. Adding a name there is never right — add it
to the subpackage that owns it and the root picks it up.

**What a module re-exports is a closure rule, not a convenience list.** A module re-exports a
symbol from a lower one exactly when one of its own signatures names that type or the symbol
constructs one for it — `canvas.rectangle` takes a `Rectangle`, `canvas.transform` a `Matrix`, and
`identity`/`translate`/`rotate`/`scale` are how a caller builds that `Matrix`; likewise
`canvas.sprite` takes a `SpriteAnimator`, and `SpriteAnimation` is how a caller builds one. Hence
`Vector3`, `Random`, `Tween`, the util functions and `inverse`/`apply`/`perspective` are absent: no
signature names them. Reach for `create.math` for those.

The rule now applies at two levels. `render/__init__.mojo` closes over `math` and `sprite`;
`core/__init__.mojo` closes over `render` on top of that, because `Program.render` names `Canvas` and
`Context` names `AutoScale`. That is why `from create.core import *` reaches most of `render`,
`math` and `sprite` on its own — and why it read as the default import before the root package
existed. Adding a name to either `__init__.mojo` is not a judgement call — check whether a
signature names it.

**Public surface is exactly what an `__init__.mojo` re-exports, and the compiler enforces it.** A
star import skips `_`-prefixed top-level declarations and reaches nothing a package's
`__init__.mojo` does not list — `le_uint` and `Style` are unreachable through `from create.render
import *` no matter which module defines them. The underscore marks the rest, at two levels:
`_name` for a declaration internal to an otherwise-public module (`_GlyphInfo` beside the exported
`Font`, `_KeyBits` beside `Key`, `_Voice` beside `Audio`), and `_module.mojo` for a whole internal
file — `_raster.mojo`, `_style.mojo`, `_text.mojo`, `_frame.mojo`, `_bytes.mojo`, `_sdl_audio.mojo`,
`_sndfile.mojo` — whose contents then need no individual prefix. Both stay importable by an
explicit path, which is how the tests reach `step`, `blend` and `le_uint` without any of them being
public.

So a new declaration is internal unless it is being added to an `__init__.mojo` in the same breath.
Put it in a `_module.mojo` if the whole file is plumbing; give it a `_name` if it sits in a module
users import from.

**`_bytes` is outside the rule, deliberately.** It is a leaf: it imports nothing, and no
`__init__.mojo` re-exports it. `sprite` and `render` both need to assemble little-endian bytes into
an `Int` and neither may depend on the other, so the one copy of that loop lives at the root where
both can reach it. It is internal plumbing, not public surface — adding it to an `__init__.mojo`
would be wrong, since no user-facing signature names `le_uint` or `sign_extend_32`. `render`
importing it is not a violation of the `render`-never-imports-`core` rule: `_bytes` is not `core`,
and depending on a leaf cannot make a cycle.

**`overlaps` is outside the rule too, the opposite way.** `core` re-exports `Rectangle`, `Circle`
and `Triangle` under the closure rule — `Context`/`Program` name them — but the rule only reaches
symbols a re-exported signature *names or constructs*, and no signature in `core` takes a `Bool` or
builds one, so `overlaps` itself is never pulled in by it. Leaving it out anyway would mean a
program written against `from create.core import *` gets three shapes and no way to test them
against each other, which defeats the point of re-exporting the shapes at all. So `overlaps` is
re-exported from `core` as a deliberate exception, on consumer-ergonomics grounds, not because any
signature forces it. `intersects` and `contains` need no such exception: both are methods on the
shapes themselves (`l.intersects(x)`, `s.contains(x)`), not free functions, so they need no
`__init__.mojo` entry at all — they come along for free with the shape they're called on.

**That edge is nominal.** Outside the re-exports above, `render` names `Sprite` and
`SpriteAnimator` only in `canvas.sprite`'s overloads — no `render` code depends on what those types
contain. `raster.blit_sprite` takes a pixel pointer plus its width and height rather than an image type, so
the rasteriser is written against no layout but its own and the BMP/PNG/JPEG decoders stay out of the
render path entirely. Keep it that way: a new `render` function that needs pixels takes the buffer,
not the type that owns it.

**`render` never imports `core`.** Every edge between them runs one way — `program`, `context`,
`frame`, `run` and `headless` reach into `render`, and nothing comes back. That is what lets
`render` be split off at all, and a package boundary now enforces it: an import the other way is a
cycle, not a style violation. `render` depends only on `math` and `sprite`, so the whole drawing
stack is usable without a run loop, which is what `run_headless` already relies on.

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
boundary lives in `PersistentCanvasState` (loaded fonts, letterbox colour), moved in at
construction and back out by `_release`. The transform stack and the style deliberately do **not**:
every frame starts unrotated, untranslated and at the default style, so a missing pop or a forgotten
`no_stroke` cannot leak into the next one. Nothing may hold a `Canvas` across frames; hold the
`PersistentCanvasState` instead.

Both loops share [_frame.mojo](src/create/core/_frame.mojo)'s `step` for the frame body, so the windowed
and headless paths cannot drift in what a frame *is*; they differ only in how one gets started (SDL
events and a clock, versus a counter).

**A `Canvas` takes its geometry from the `Viewport` and its extent from the `Surface`**, and the two
can legitimately disagree for one frame. `Window._resize` reallocates the pixel buffer inside
`win.events()`, after the viewport was measured — so a `Surface` must be taken *after* event
processing, and its width and height must come from the window, never from the viewport. A lagging
mapping is one crooked frame; a lying extent is memory corruption, because the extent is baked into
the `Surface` and so defeats the clipping every raster loop otherwise does.

**Scope through the guards, never by hand.** `canvas.transform(m)` and `canvas.style()` both return
a `with`-block guard that unwinds on exit; `canvas._push_transform` is the same push without the pop.
Style is the subtler of the two: the bare mutators (`fill`, `no_stroke`, `font_size`, …) called
straight from `render` are the normal path, since the style resets next frame either way — the guard
is for a *helper* that sets style before drawing, whose `no_stroke()` would otherwise apply to
whatever the caller draws next.

```mojo
with canvas.style():
    canvas.no_stroke()
    canvas.fill(Color(220, 80, 80))
    canvas.rectangle(self.pos, 40, 40)
```

**Coordinate system is not Processing's.** The origin is the **middle** of the design area and **y grows upward**. World `x` runs `[-width/2, +width/2]`, `y` runs `[-height/2, +height/2]`; `(0, 0)` is the centre of the screen and negative `y` is below it.

`Context` and `Canvas` both expose `left()`, `right()`, `bottom()`, `top()` as the edges — use those rather than `width`/`height` arithmetic, and note `left()` and `bottom()` are negative. `Rectangle.top()` is `y + h/2`.

Consequences worth internalising:

- `rotate(angle)` turns **counter-clockwise**, the mathematical convention.
- Downward motion is negative: gravity is a negative `vel_y`, a jump is positive. See [examples/movement/src/player.mojo](examples/movement/src/player.mojo).
- Glyphs and sprites are **not** flipped — only their anchor point is mapped.
- `input.mouse` is delivered in world coordinates, so it can be negative.

**All shapes are center-positioned** (unlike Processing). `canvas.rectangle((x, y), w, h)` draws a rectangle centered at `(x, y)`, same as `canvas.circle()`, `canvas.sprite()`, etc. `Rectangle.x/y` is the center, not the top-left corner. Position arguments are `Vector2`, whose tuple constructors are `@implicit`, so a bare tuple works everywhere one is taken.

**Style defaults are not blank:** every frame starts from `Style()`, which has **stroke `BLACK` and
enabled** — a `rectangle` drawn without `no_stroke()` gets an outline nobody asked for. The rest of the
defaults are in [_style.mojo](src/create/render/_style.mojo).

**Autoscale** keeps the program in its design resolution while the window resizes. `ctx.width`/`height`, `input.mouse`, and all canvas coordinates stay in that design space; `canvas.scale` reports the factor, and font size, stroke width, and sprite size scale with it. Three modes — `FIT` (default), `EXTEND`, `OFF` — documented in [autoscale.mojo](src/create/render/autoscale.mojo), with the launch-mode matrix on `run`. `ctx.design(w, h, mode)` pins the space from inside `create`. See [examples/autoscale.mojo](examples/autoscale.mojo), which cycles all three modes on space.

The design size is a property of the program, not of the display: it is whatever `run` was passed, unchanged by a resize or by fullscreen. Under `EXTEND` the *reported* size grows with the window, so layout must anchor to the origin or to `ctx.left()`/`right()`/`bottom()`/`top()` rather than hardcoded design coordinates.

`Input._set_mouse(x, y)` is the single writer of `mouse`, `mouse_x` and `mouse_y`, and every event
arm in `run.mojo` that carries a pointer position goes through it — writing the fields directly
desynchronises the `Vector2` from the `Int` pair. A new event that reports a position calls
`_set_mouse` and adds only what is genuinely its own — `mouse_press_pos` on a press, say.

**Parameter vs. field:** a resource the run loop *feeds* the program every frame (`Context`, `Input`, `Canvas`) stays a parameter; a resource the program *drives* on its own schedule (`Sprite`, `Font`, `Sound`, `Audio`, `SpriteAnimator`) is a field the program owns and constructs in `create`. This is why adding audio required zero changes to `Program`, `Context`, or `run.mojo` — `Audio` is just another field, like `Sprite`.

**What earns its own parameter** is decided by *who writes it*, not by who feeds it — feeding alone doesn't distinguish anything, since `Time` is fed every frame and is a field on `Context`.

| | Loop writes | Program writes | Shape |
|---|---|---|---|
| `Context` (and its `Time`) | yes | yes | `mut` parameter |
| `Canvas` | yes | yes | `mut` parameter |
| `Input` | yes | **no** | read-only parameter |

`Input` is the only one the program never writes, hence a read-only argument rather than a field on the `mut` `Context` — reasoning in the [`Input` docstring](src/create/core/input.mojo). `ctx.time` shows the cost of the alternative: the program never writes it either, but `ctx.time.frame_count = 99` compiles.

**Per-frame obligations.** Three fields the program owns need ticking from `update`, and nothing
enforces it:

- `audio.update()` — SDL never reports a finished stream, so skipping it stalls a loop after its
  first buffer drains and leaks one-shot voice slots forever. See
  [audio.mojo](src/create/audio/audio.mojo) and [examples/audio/src/main.mojo](examples/audio/src/main.mojo).
- `animator.update(ctx.time.delta)` — the playhead only advances here. See
  [animator.mojo](src/create/sprite/animator.mojo) and [examples/animation/src/main.mojo](examples/animation/src/main.mojo).
- `tween.update(ctx.time.delta)` — same shape and same failure: a tween never ticked sits at its
  `start` forever. See [tween.mojo](src/create/math/tween.mojo) and [examples/tween.mojo](examples/tween.mojo),
  which also cycles the easing curves against one shared playhead.

Both an animation and a sound are shared assets, held as `ArcPointer` fields (`from std.memory
import ArcPointer`) so several entities or voices share one buffer by refcount instead of copying
it. The biggest trap in the animation API is documented on
[`SpriteAnimator.use`](src/create/sprite/animator.mojo) — read it before driving an animator.

## Critical Gotchas

1. **`-I src` is required for every `mojo run`.** Without it, `from create import *` fails with a module-not-found error. All pixi tasks include it; bare `mojo run` calls must add it manually.

2. **Paths resolve against the CWD, not the source file.** The packaged font is loaded as the literal
   relative path `defaults/fonts/NotoSans.ttf` ([font.mojo](src/create/render/font.mojo), used by
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

4. **Two origin limits in this Mojo version shape the API.** Neither `MutableAnyOrigin` nor
   `ImmutableOrigin` is a known declaration, and `ref [o["element"]]` fails with `'ImmOrigin' is not
   subscriptable`. Consequences, each documented where it bites:

   - `Canvas` must keep exactly one parameter, and a framebuffer is swapped by rebuilding the
     `Canvas`, never by handing the existing one a new `Surface` — see the
     [`Canvas` docstring](src/create/render/canvas.mojo) for the aliasing error that shape produces.
     Adding a second parameter breaks every program in the repo at once.
   - Nothing can return a reference to a `List` element, so `SpriteAnimation` has **no `frame()`
     accessor** — see its [docstring](src/create/sprite/animation.mojo) and
     [`canvas.sprite`](src/create/render/canvas.mojo). Index inline at the use site.

   Don't retry either shape.

5. **An uncalled overload is compiled by nothing.** A library build only type-checks the `def`
   bodies it reaches, so an overload nothing calls is checked by no build. The program in
   [tests/render/test_canvas.mojo](tests/render/test_canvas.mojo) draws through all six of
   `canvas.sprite`'s animator overloads for this reason — extend it when adding another. This is
   the general reason the repo gates on consumer programs as well as on `mojo precompile`.

## Terminology

Concepts that span files. Every type's own surface — methods, constants, factories — is in its
docstring; this table is not an API reference and must not grow into one.

| Term | Meaning |
|---|---|
| `Program` | Full interactive program: `create` + `update` + `render`. No event callbacks — input arrives as `update`'s `Input` parameter |
| World space | The coordinate space programs draw in — origin centred, y up (see Coordinate system above). `Canvas` maps it to framebuffer pixels through a single base matrix built by `Viewport.base_matrix()` |
| Design resolution | The size passed to `run` (default 1280x720, or pinned by `ctx.design()`) — the space a program is authored in, and the factor `ctx.autoscale` scales by. See Autoscale above |
| `Surface` | A borrowed RGBA framebuffer: pixel pointer plus width and height. Deliberately a plain value, not a trait — it is the seam between the raster loops and wherever the memory came from, an SDL window or a `MemorySurface` |
| `Viewport` | The design-space-to-pixel mapping: design size, autoscale mode, scale factor, offsets, base matrix. Owns no window and no pixels, so it is pure arithmetic; `Context` forwards to it |
| `PersistentCanvasState` | What survives the frame boundary — loaded fonts, letterbox colour — moved into each frame's `Canvas` and back out again. Style is *not* in it: `Canvas` is reachable only from `render`, so nothing could seed a style outside a frame, and carrying one forward would preserve only a forgotten setting |
| `TransformGuard` / `StyleGuard` | RAII wrappers from `canvas.transform(m)` and `canvas.style()` — pop the matrix, restore the style, on scope exit |
| Asset vs. playhead | `SpriteAnimation` and `Sound` are immutable artwork, shared by `ArcPointer`; `SpriteAnimator` and an `Audio` voice are one entity's position in it. The rate (`fps`) belongs to the asset, not the playhead |
| `Easing` / `Tween` | An `Easing` is the *shape* of a motion — a pure function of a 0-to-1 fraction, so `ease(curve, t)` needs no state. A `Tween` is a playhead that walks that fraction over a duration and reads out a value. A tween has no shared asset to split off the way an animation does: its whole definition is four numbers, so each entity owns its own |
| `overlaps` / `intersects` / `contains` | The three geometry relations in [geometry.mojo](src/create/math/geometry.mojo), and they don't overlap in role. `overlaps(a, b)` is a free function, symmetric between two regions (`Rectangle`/`Circle`/`Triangle`). `l.intersects(x)` is a method on `Line` only, asymmetric — `Line` has no interior, so it can only ever be the subject, never an operand of a symmetric test. `s.contains(x)` is a method on the containing region, also asymmetric. A `Line` is never a region: it has no `overlaps` overload and no `center()`/`area()` |

## Do

- Use `@fieldwise_init` on program structs to auto-generate `__init__` from fields.
- Use `pixi run test` before committing.
- Use `canvas.background(Color.X)` as the first call in `render` to clear the frame.
- Use `canvas.to_local`/`to_world` to move a position between world space and the current transform's frame — neither deals in pixels, and both take two `Float64`, so pass `input.mouse.x, input.mouse.y`.
- Use `script_dir()` for every asset path; a bare relative path resolves against the CWD.

## Don't

- Don't use `alias` it has been depricated in favor of `comptime`
- Don't use `UnsafePointer` it has been depricated in favor of `Pointer`
- Don't use `fn` it has been removed — `error: 'fn' has been removed; use 'def' instead`
- Don't hold a raw `Pointer` to `Canvas` outside `TransformGuard`/`StyleGuard` — use origin-tracked references.
- Don't name new test files without the `test_` prefix — the test runner won't pick them up.
- Don't add a second parameter to `Canvas`, and don't import `window` from `canvas.mojo` — see Gotcha 4.
