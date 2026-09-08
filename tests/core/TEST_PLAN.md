# Test Plan: core

Phase 4. Scores against the rubric in [../TEST_PLAN.md](../TEST_PLAN.md), which
also carries the suite-wide conventions and constraints every item here obeys.

## Scope

- **In**: `src/create/core/` — `canvas`, `raster`, `surface`, `viewport`,
  `context`, `time`, `input`, `key`, `color`, `text`, `font`, `align`, `style`,
  `autoscale`, `frame`, `headless`, `path`, `program`, `run`.
- **Out**: `Matrix`, `Vector2` and the geometry structs as values — those are
  the math plan's. `Sprite` decoding is the graphics plan's; only its *blit*
  through `Canvas`/`raster` is in scope here. `Audio` is the audio plan's, even
  though `test_smoke.mojo` constructs one.

## Current state

2127 src LOC against 1745 test LOC across eleven files — the largest package
and the only one whose untested surface is dominated by a single file
(`canvas.mojo`, 612 LOC, 29% of the package's source).

| File | Tests | Asserts | Wall | What it asserts |
|---|---:|---:|---:|---|
| `test_canvas.mojo` | 13 | 40 | ~3 s | Rendering through `run_headless`: background, centred rect/circle/triangle, y-up, source-over alpha, stroke width scaling, FIT bars vs EXTEND, one rotated rect, a sprite blit, style per-frame and `style()` guard |
| `test_color.mojo` | 43 | 126 | ~2 s | Every ctor, constant, `hex`, `hsv`, `to_hsv`, round-trip, `lerp`, `luminance`, `over` (six cases), `write_to`, `__eq__` |
| `test_context.mojo` | 20 | 72 | ~1 s | All three autoscale modes through `Context`, `to_world` at corners and centre, base-matrix/`to_world` inversion, `design()` including override |
| `test_viewport.mojo` | 11 | 48 | ~1 s | The same arithmetic one level down, plus pillarbox and letterbox bar offsets and `set_design` override |
| `test_input.mojo` | 38 | 55 | ~2 s | `is_key_down`/`just_pressed`/`just_released` on both overloads, every named key, both sides of every modifier, unknown name, initial mouse state |
| `test_raster.mojo` | 18 | 48 | ~1 s | All seven free functions: blend's three alpha branches, `fill_pixels` half-openness and clipping at each edge, line endpoints/thickness/clipping, triangle interior, sprite 1:1 + downscale + transparent-skip + clipping, glyph coverage/zero/clip |
| `test_time.mojo` | 9 | 21 | ~1 s | Zeroed init, seeded first tick, frame counting, delta vs elapsed, zero-length frame, restart |
| `test_text.mojo` | 7 | 15 | ~2 s | `TextRenderer` driven straight onto a `MemorySurface`: lazy load, fallback attempted once, ink-box position per align/baseline, glyph growth with `pixel_scale` |
| `test_frame.mojo` | 2 | 4 | ~2 s | The extent-from-surface / geometry-from-viewport split, using a deliberately mismatched 64×64 viewport in a 200×200 buffer |
| `test_surface.mojo` | 5 | 10 | ~1 s | Zero fill, row-major RGBA offset, write-through, neighbour isolation, dimensions |
| `test_smoke.mojo` | 1 | 2 | ~2 s | The consumer-side build gate; two pixels through `run_headless` |

Three levels are in use, and the split is deliberate and worth preserving:
value-level (`color`, `time`, `key`/`input`, `viewport`), surface-level
(`raster`, `surface`, `text` — build a `MemorySurface`, call the primitive),
and program-level (`canvas`, `frame`, `smoke` — declare a `Program`, run it
through `run_headless`, read pixels back). `test_frame.mojo` is the only file
that calls `step` directly, which is what lets it fabricate the
viewport/surface mismatch a real window produces for one frame.

`test_context.mojo` and `test_viewport.mojo` overlap heavily by design:
the same autoscale arithmetic is asserted at the viewport and again through
`Context`'s forwarding. That is cheap and catches a broken forward, so it is
not counted as duplication below.

## Coverage map

**C** covered, **I** indirect, **U** untested.

| Symbol | | Note |
|---|---|---|
| `surface.Surface` — ctor, `offset`; `MemorySurface` — ctor, `surface`, `pixel` | C | |
| `raster` — `blend`, `fill_all`, `fill_pixels`, `line_pixels`, `fill_triangle`, `blit_sprite`, `blit_glyph` | C | The best-covered module in the package |
| `color` — every ctor, constant, `hex`, `hsv`, `to_hsv`, `lerp`, `luminance`, `over`, `write_to`, `__eq__`/`__ne__` | C | `_channel`, `_linear`, `_mix` reached through them |
| `time.Time` — `__init__`, `_start`, `_tick`, all five public fields | C | |
| `viewport` — `set_design`, `set_size` (all three modes), `scaled`, edges, `to_world`, `base_matrix` | C | |
| `context` — `design`, `_set_viewport`, `left`/`right`/`bottom`/`top`, `to_world`, `_base_matrix` | C | `bottom()` only via the viewport's, not through `Context` |
| `context.quit()` / `Context._quit` | **U** | `run_headless` honours `_quit`, but no test sets it |
| `frame.step` | C | Directly in `test_frame`, indirectly everywhere headless |
| `headless.run_headless` | C | 1-frame, 2-frame, and differing-framebuffer forms all used |
| `input` — `is_key_down`, `just_pressed`, `just_released` (both overloads), `_check` all branches, initial mouse fields | C | |
| `input.mouse_x`/`mouse_y` vs `input.mouse` after a real move | **U** | Only their zeroed initial values are asserted |
| `key.Key.from_name`, `KeyBits.__init__`, `set`, `test`, `_index` (both halves) | C | |
| `key.KeyBits.clear`, `clear_all` | **U** | Written only by `run.mojo` |
| `align.HAlign`/`VAlign` — `__eq__` | I | Built in `test_text._style`, never the subject |
| `align` — `__ne__` | **U** | |
| `style.Style.__init__` and every default | I | Every default is exercised, none is asserted by name |
| `canvas` — `background`, `rect`, `circle`, `line`, `triangle`, `sprite(s, x, y)`, `fill`, `stroke`, `no_stroke`, `stroke_width`, `transform`, `style`, `_release` | C | Float overloads only |
| `canvas.rect` non-uniform path | C | One test: `test_rotation_takes_the_inverse_mapped_path` |
| `canvas.circle` non-uniform path | **U** | The other half of the dual-path split — see G1 |
| `canvas` stroke on `rect` (four-band border) and on `circle` (ring) | **U** | Every shape test calls `no_stroke` first — see G2 |
| `canvas.no_fill` | **U** | Never called in tests or examples; every `fill_enabled == False` branch is dead to the suite |
| `canvas.to_world`, `to_local` | **U** | The documented way to map a mouse position into a transform |
| `canvas.left`/`right`/`bottom`/`top` | I | Delegate to `Viewport`, which is covered |
| `canvas` — all `Int` overloads of `rect`/`circle`/`line`/`triangle` | I | `rect(Int, Int, Int, Int)` in `test_style_does_not_survive_the_frame_boundary` only |
| `canvas` — `Rectangle`/`Circle`/`Line`/`Triangle`/`Vector2` overloads | **U** | Except `circle(Vector2, Int)` in `test_smoke` |
| `canvas.sprite` sized overloads (4) | **U** | The resampling path; only the 1:1 fast path is tested |
| `canvas.text` (3 overloads), `font`, `font_size`, `font_weight`, `text_align`, `text_baseline` | **U** | Text is tested at `TextRenderer`, never through `Canvas` |
| `canvas._uniform`, `_pixel_scale`, `_stroke_width_px`, `_draw_letterbox`, `_push`/`_pop`/`_sync_transform` | I | Reached constantly, never the subject |
| `text.TextRenderer` — `__init__`, `_ensure_font`, `_glyph`, `draw` | C | |
| `text.TextRenderer.set_font` | **U** | Only reachable via `canvas.font`, also untested |
| `font.Font.__init__`, `_set_size`, `render`, `GlyphInfo` | I | Loaded and rendered by `test_text`, never asserted directly |
| `font.Font._set_weight`, `has_glyph`, `FontWeight` constants | **U** | `_set_weight` runs with the default 400 only; `has_glyph` is only reached when a fallback face loaded |
| `program.Program` — `create`, `update`, `render`, default `update`/`render` | C | |
| `program.Program` — all seven `on_*` callbacks | **U** | Dispatched only from `run.mojo` — see G3 |
| `run` — `run`, `_run_loop`, `_process_events`, `_update_dimensions`, `_wait_for_dimensions` | **U** | Type-checked by `test_smoke.mojo`'s uncalled `_windowed_entry_point`, never executed |
| `path.script_dir` | **U** | Not called anywhere in the repo |
| `autoscale.AutoScale` | C | All three modes asserted |

## Rubric scores

**1. Behavioural coverage — 3/5.** Six of eleven modules are thoroughly
covered; the package average is dragged down by one file. `canvas.mojo` is 29%
of the package's source and has 13 tests, and those 13 concentrate on the
geometry conventions (centring, y-up, alpha) rather than on the API surface: of
roughly forty public methods, twelve are called. Everything text-shaped on
`Canvas`, every geometry-struct overload, both coordinate helpers, `no_fill`,
and the resampling sprite blit are untouched.

**2. Boundary coverage — 3/5.** Strong at the raster level, where clipping is
tested against each of the four edges independently, `fill_pixels` is pinned as
half-open, and a wholly-outside rect is asserted to write nothing. Strong in
`time`, which has an explicit zero-length frame. Weak above that: no test draws
a zero-sized or negative-sized shape, a shape larger than the framebuffer, a
1×1 surface, a zero-frame `run_headless`, or an empty string of text. The
autoscale tests use clean 2:1 ratios throughout, so no rounding boundary — the
`+ 0.5` in `_draw_letterbox`'s `cx1`/`cy1`, the one-pixel seam its docstring
names — is ever hit.

**3. Error and invalid input — 1/5.** Same score as `math`, for the same
reason and one worse one. Nothing in `core` raises except through FreeType:
`Font.__init__` raises `"FT_New_Face failed — font not found: " + path`, and no
test provokes it. Below that, the failure mode is not an exception but
out-of-bounds memory: `MemorySurface.pixel(x, y)` computes `(y * width + x) * 4`
and indexes a `List` with no bounds check, and `Surface.offset` is the same
arithmetic. Every raster function clips, so the library never produces such an
offset itself — but a *test* that miscomputes a pixel coordinate reads past the
buffer rather than failing cleanly, which is a failure-clarity problem as much
as a coverage one.

**4. Assertion strength — 4/5.** The best in the repo. Render assertions name
exact pixels and exact colours, and — the part that distinguishes them from
coverage-chasing — most assert a *negative* alongside the positive:
`test_rect_is_centre_positioned` checks the top-left corner is black precisely
because that is where a Processing-style rect would have landed;
`test_positive_y_draws_above_centre` checks both row 20 and row 80, so a
y-down mapping cannot pass; `test_circle_is_centred_and_radial` checks the
bounding-box corner, so a circle rasterised as a square fails. The comments
state which alternative implementation each assertion excludes, which is the
standard the rest of the suite should be held to. The point off is
`test_text.mojo`, which asserts relative ink-box movement (centre is left of
left-align) rather than absolute position — necessary, since glyph metrics are
the font's, but it means a uniformly-offset layout passes.

**5. Isolation — 4/5.** Every test builds its own `Context`, `MemorySurface` or
program; nothing shares state. `run_headless` supplies synthetic 16 ms frames
and empty input, so results depend only on the program. Two dependencies
remain, both real: `test_canvas.mojo` loads `tests/fixtures/test_2x2.bmp` by a
relative path and so fails unless the suite is run from the repo root (the
suite-wide CWD defect, gap G3 in the Phase 0 plan), and `test_text.mojo`
depends on the packaged font files and on `libfreetype.so.6` being present.

**6. Runtime cost — 3/5.** ~18 s of the suite's ~32 s, and the whole package is
compile-bound rather than execution-bound: `test_surface.mojo` (5 tests) and
`test_color.mojo` (43 tests) both cost ~1–2 s. Adding tests to an existing file
is therefore nearly free, and adding a *file* costs ~1 s of compile. This
should shape the proposals below: prefer new tests in existing files.

**7. Failure clarity — 4/5.** `assert_equal` on `Color` prints both sides
through `write_to`, so a wrong pixel reports `Color(255, 0, 0, 255)` against
`Color(0, 0, 0, 255)` — readable. What it does not report is *which* pixel:
`test_background_fills_every_pixel` asserts inside a nested loop over 256
pixels with no message, so a single wrong pixel gives a colour mismatch and no
coordinate. The same applies to the `for row in range(47, 53)` loop in
`test_stroke_width_scales_to_pixels`.

## Gaps, ranked by risk × likelihood

**G1 — `circle`'s non-uniform path is untested, and it is one of two
independent implementations.** `rect` and `circle` each branch on `_uniform()`
into a fast axis-aligned raster and a per-pixel inverse-mapped raster, written
separately, roughly 35 lines each. `rect`'s slow path has exactly one test
(`test_rotation_takes_the_inverse_mapped_path`); `circle`'s has none. Since
`_uniform()` is false under any rotation, shear or non-uniform scale, the
untested branch is the one every rotated sketch takes. The two paths are also
never checked against each other, so they can disagree silently — and they use
different inner-radius arithmetic (`pr_inner` in stroke *pixels*, `r_inner` in
stroke *world units*), which is exactly the kind of asymmetry a cross-path test
exists to catch.

**G2 — no test draws a stroke on a shape.** Every shape test in
`test_canvas.mojo` opens with `no_stroke()`. So `rect`'s four `fill_pixels`
border bands, `circle`'s `d2 > pr_inner2` ring, the `in_inner` test in both
slow paths, and `triangle`'s three edge lines have never run — even though
`stroke_enabled` defaults to `True`, meaning **the default style is the
untested one**. A sketch that draws `canvas.rect(...)` with no style calls at
all takes a path the suite does not cover.

**G3 — `no_fill` is called nowhere in the repository's tests.** Every
`fill_enabled == False` branch is dead to the suite: the four in `rect`/`circle`
(two per path), the one in `triangle`, and the early return in `text`. This is
the mirror image of G2, and the two together mean only one of the four
fill/stroke combinations is exercised.

**G4 — frame-edge input semantics are structurally untestable.**
`just_pressed`/`just_released` are *edges*: they are true for one frame because
`_process_events` clears both `KeyBits` at the top of each iteration, and that
clearing exists only in `run.mojo`'s windowed loop. `run_headless` constructs
one empty `Input` and passes the same never-changing value to every frame, so
no headless test can observe an edge decaying. The current tests set
`input._just_pressed` directly and assert the getter reads it back — which
tests `KeyBits.test`, not the edge. Closing this needs a seam, not a test; see
W7. Consequences: `KeyBits.clear`/`clear_all` are untested, and all seven
`Program.on_*` callbacks are untested because `_process_events` is their only
dispatcher.

**G5 — text is untested through `Canvas`.** `TextRenderer.draw` is covered
directly, but the layer between it and a program is not: `canvas.text` maps the
anchor through `_transform`, computes `_pixel_scale()`, and returns early under
`no_fill`; `canvas.font_size`/`font_weight`/`text_align`/`text_baseline` write
into the per-frame `Style`; `canvas.font` moves a `Font` into `CanvasState`,
which is the only path by which a font survives a frame boundary. None of that
runs. `Font._set_weight` — 25 lines of FreeType MM-var arithmetic that silently
`return`s if `FT_Get_MM_Var` fails — only ever runs with the default weight
400, so its variable-axis path has never executed at all.

**G6 — `_pixel_scale()`'s fallback is undocumented by any test.** Under a
non-uniform transform there is no single world-units-per-pixel factor, so it
returns `self.scale` — the autoscale factor, ignoring the user transform
entirely. That means stroke width, font size and sprite extents do *not* follow
a rotation or a non-uniform scale. This is a deliberate, documented choice and
it is invisible: nothing states it, so nothing would notice it changing.

**G7 — the `Canvas` seam has no regression test.** Two constraints hold the
headless path open: `Canvas` must keep exactly one parameter, and `canvas.mojo`
must not import `window`. Both are documented at length in AGENTS.md, both have
been violated once before, and neither is asserted. A violation of the first
breaks every program at compile time (loud); a violation of the second breaks
`run_headless` at link time in whatever file imports it next (less loud).

**G8 — no test asserts on a shape drawn out of bounds.** The letterbox doubles
as the clip for anything drawn past the design edges — that is why
`_draw_letterbox` runs *after* `render` rather than before. The bars are tested
on an empty frame (`FitBars` draws only a background), so the clipping half of
that dual role is unproven.

## Proposed work

Ordered, commit-sized. Each leaves the suite green. Every item lands in an
existing file except W8; `test_smoke.mojo` is not touched by any of them.

**W1 — Assert the stroke on every shape.** `test_canvas.mojo`. One program per
shape drawing with fill and stroke in contrasting colours, asserting stroke
colour on the border band and fill colour well inside it: for `rect`, one pixel
on each of the four bands (they are four separate `fill_pixels` calls, so a
single-corner assertion would miss three); for `circle`, a pixel just inside
the radius and one just inside `pr_inner`; for `triangle`, a pixel on an edge.
Closes G2, the largest untested branch count in the package.

**W2 — Assert `no_fill`.** `test_canvas.mojo`. Draw a stroked rect and a
stroked circle under `no_fill()` over a known background, and assert the
interior is still the background colour while the border is the stroke. With
W1 this covers all four fill/stroke combinations. Closes G3.

**W3 — Cover `circle` under rotation, and check the two paths agree.**
`test_canvas.mojo`. Two tests:

1. A circle drawn under `rotate(pi / 4.0)` — a rotation makes `_uniform()`
   false, so this is the only way into the slow path — asserting the same
   radial pattern the axis-aligned test asserts. A circle is rotation-invariant,
   so the *expected pixels are identical* to `test_circle_is_centred_and_radial`,
   which makes this a genuine cross-path equivalence check rather than a
   restatement of the implementation.
2. A rect drawn under `rotate(pi / 2.0)` against the same rect with `w` and `h`
   swapped drawn with no transform. A quarter turn fails `_uniform()`
   (`m[0, 1]` and `m[1, 0]` are non-zero) yet is an exact axis-aligned result,
   so the two paths must produce the same pixels. Assert a handful of interior
   and exterior points on both buffers.

Closes G1. Do this early: it is the highest-value item here, because it is the
only proposal that can catch a disagreement *between* implementations rather
than a deviation from a hand-computed expectation.

**W4 — Cover text through `Canvas`.** `test_canvas.mojo`. A program that calls
`canvas.fill`, `canvas.font_size`, `canvas.text_align`, `canvas.text_baseline`
and `canvas.text("Hi", 0.0, 0.0)`, asserting that ink exists in the expected
half of the buffer — use the `_ink_box` helper's approach from
`test_text.mojo`, not exact glyph pixels, so the assertion survives a font
update. Then a second test asserting `no_fill()` suppresses text entirely (the
early return), and a third asserting a `font_size` change moves the ink box's
extent. Do not assert absolute glyph shapes. Closes most of G5.

**W5 — Cover `to_world` and `to_local`.** `test_canvas.mojo`, in a `render`
body since `Canvas` is reachable nowhere else. Inside
`with canvas.transform(translate(10.0, 20.0))`, assert `to_local(10.0, 20.0)`
is the origin and `to_world(0.0, 0.0)` is `(10, 20)`; then round-trip an
arbitrary point through both under a composed rotate-then-translate. These
deal in world units only — never pixels — which is the property that
distinguishes them from `Viewport.to_world` and the thing worth pinning.
Assert through a mutable accumulator on the program struct, or by drawing a
1×1 rect at the mapped point and asserting the pixel; prefer the former.

**W6 — Pin `_pixel_scale`'s non-uniform fallback.** `test_canvas.mojo`. Draw a
3-unit stroked line under a non-uniform `scale(3.0, 1.0)` in a design smaller
than the framebuffer, and assert the thickness matches the autoscale factor
rather than 3× it. One test, and it converts an invisible design choice into a
stated one. Closes G6.

**W7 — Give the edge semantics a testable seam.** Source change plus tests.
The clearing that makes `just_pressed` an edge lives in `_process_events`,
which needs a window. Extract it into a method on `Input` — `_new_frame()`,
say — called by `_process_events` at the point the two `clear_all()` calls sit
now. That is a pure refactor of the windowed loop, adds nothing to `Canvas`,
and touches no signature `test_smoke.mojo` builds. Then in `test_input.mojo`:
set a held key and a just-pressed key, call `_new_frame()`, and assert the held
key survives while the edge does not. Also covers `KeyBits.clear` and
`clear_all` directly. Closes the testable half of G4; the `on_*` callbacks stay
untestable and should be stated as such rather than worked around.

**W8 — Add `test_canvas_overlays.mojo` for out-of-bounds clipping.** The one
new file proposed. A program under `FIT` that draws a large rect covering the
whole framebuffer, asserting the bar region is the letterbox colour and not the
rect's — proving the post-render letterbox clips rather than merely fills.
Add the sized `sprite` overload here too: blit a fixture sprite at 4× its
natural size and assert the nearest-neighbour block boundaries, which is the
`_pixel_scale` multiply in the sized overload and the resampling branch in
`blit_sprite` as reached through `Canvas`. Closes G8 and the sprite half of the
coverage map. Justify the new file on runtime grounds: `test_canvas.mojo` is
already the slowest in the package at ~3 s, and these tests use larger buffers.

**W9 — Assert the geometry-struct overloads compile and dispatch.**
`test_canvas.mojo`. One program that draws each of `rect(Rectangle)`,
`circle(Circle)`, `line(Line)`, `triangle(Triangle)`, and the `Vector2` forms,
each at a distinct location in a distinct colour, with one pixel asserted per
shape. These are one-line forwards, so the value is dispatch and argument order
— that `rect(Rectangle(x, y, w, h))` centres on `(x, y)` like the float form,
not on a corner — not the raster. Keep it to a single program and a single
test to hold the compile cost down.

**W10 — Add coordinates to loop assertions.** `test_canvas.mojo`,
`test_raster.mojo`. Where an assertion sits inside a `for` loop, pass a message
naming the pixel: `assert_equal(m.pixel(x, y), want, "pixel " + String(x) +
"," + String(y))`. Cheap, and it is the difference between "a colour was wrong"
and "row 51 was wrong". Addresses the failure-clarity point above.

**W11 — Assert `ctx.quit()` stops the loop.** `test_context.mojo` or
`test_canvas.mojo`. A program whose `update` calls `ctx.quit()` on frame 2,
run for 5 frames, drawing its frame number as a colour — the buffer must show
frame 2's colour, proving `run_headless` broke out. Covers the one public
`Context` method with no test and the `if ctx._quit: break` in the loop.

**W12 — Assert the `Style` defaults by name.** `test_canvas.mojo` or a short
addition to `test_text.mojo`. `Style()` is the state every frame starts in and
every default is load-bearing (`stroke_enabled = True` is why G2 matters). Nine
assertions in one test, stating the contract rather than leaving it implied by
the tests that happen to depend on it.

**W13 — Guard the headless seam with a compile-level assertion.**
`test_canvas.mojo`. Declare a `def _takes_a_bare_canvas(mut canvas: Canvas)`
that is never called: an uncalled `def` body is still type-checked, so a second
parameter on `Canvas` fails this file rather than only failing user code. This
is the same trick `test_smoke.mojo::_windowed_entry_point` uses, applied to the
one-parameter constraint. It costs nothing at runtime and it must live outside
`test_smoke.mojo`, whose cost is fixed. Partially closes G7; the "no `window`
import" half stays a review-time constraint, since a test cannot assert the
absence of an import.

## Out of scope / untestable

**`run.mojo` — the entire windowed loop.** `run` opens an SDL window and blocks
until it closes, so nothing in `_run_loop`, `_process_events`,
`_update_dimensions` or `_wait_for_dimensions` can execute in a test. What
stands in for it:

- `tests/core/test_smoke.mojo::_windowed_entry_point` calls `run[Smoke]` inside
  a `def` that is never invoked. The body is still type-checked, so the
  windowed instantiation of `run[P]`, the `Program` trait surface, and the
  `Context`/`Input`/`Canvas` signatures cannot drift without breaking a build.
  The pre-commit hook builds exactly this file on every commit, which is why
  **its cost must not grow** — no item above adds to it.
- `frame.mojo::step` is the one copy of what a frame *is*, shared by both
  loops, and it is directly tested. So the two paths cannot disagree about the
  frame body; they differ only in how a frame is started.
- `mojo precompile` on pre-push type-checks the library, including the parts of
  `run.mojo` no consumer reaches.

What that leaves genuinely unprotected, and what should be understood as
accepted risk rather than a gap to close: the SDL event dispatch itself, the
`exit_on_escape` check, the window-resize ordering (a `Surface` taken after
events, its extent from the window), the fullscreen `(1, 1)` bogus-resize
pump, and the seven `Program.on_*` callbacks. All are behaviours only a real
window produces.

**Also out of scope:**

- `path.script_dir()` — reads `argv()[0]`, which under the test runner is the
  test binary. Testable in principle, worthless in practice, and nothing in the
  repo calls it.
- `Font`'s FreeType offset arithmetic (`_FACE_SIZE`, `_SIZE_METRICS`, the
  MM-var axis walk). These are ABI constants; a test would restate them. The
  meaningful assertion is that glyphs come out with sane metrics, which
  `test_text.mojo` already makes indirectly.
- Exact glyph pixel values anywhere. Font rendering is FreeType's and version-
  dependent; assert ink extents and relative positions, never bitmaps.
- Performance of the `_uniform()` fast paths. The split exists for speed, but
  the suite has no timing harness and should not grow one — the fast path is
  covered as *correctness* by W3's equivalence tests.
- Introducing a test framework, a runner, or coverage tooling. `std.testing`'s
  `TestSuite` is the framework; `pixi run test` is the runner.
