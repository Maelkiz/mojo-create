# Test Plan: suite-wide baseline

Phase 0 of the test-hardening effort. This file is the shared reference the four
package plans (`tests/math/`, `tests/graphics/`, `tests/audio/`, `tests/core/`)
score against. It records what the suite is today, the conventions it already
follows, what each source symbol is covered by, the rubric, and the gaps that
sit above any one package.

## Scope

- **In**: the whole of `tests/`, the runner (`pixi run test`), the two git
  hooks, and the mapping from `src/create/**` symbols to test files.
- **Out**: writing any new test. Every package plan proposes work; none of the
  Phase 0–4 commits add test code.

## Baseline

Recorded 2026-09-08 on `main` at `7a343c8`, via
`SDL_AUDIO_DRIVER=dummy mojo run -I src <file>` per file.

**20/20 files pass. 356 test functions, 844 assertions. ~32 s wall for the
full sweep**, essentially all of it Mojo compile time — no single file's own
execution is measurable.

| File | Tests | Asserts | Wall |
|---|---:|---:|---:|
| `audio/test_audio.mojo` | 5 | 8 | ~2 s |
| `audio/test_sound.mojo` | 3 | 9 | ~1 s |
| `core/test_canvas.mojo` | 13 | 40 | ~3 s |
| `core/test_color.mojo` | 43 | 126 | ~2 s |
| `core/test_context.mojo` | 20 | 72 | ~1 s |
| `core/test_frame.mojo` | 2 | 4 | ~2 s |
| `core/test_input.mojo` | 38 | 55 | ~2 s |
| `core/test_raster.mojo` | 18 | 48 | ~1 s |
| `core/test_smoke.mojo` | 1 | 2 | ~2 s |
| `core/test_surface.mojo` | 5 | 10 | ~1 s |
| `core/test_text.mojo` | 7 | 15 | ~2 s |
| `core/test_time.mojo` | 9 | 21 | ~1 s |
| `core/test_viewport.mojo` | 11 | 48 | ~1 s |
| `graphics/test_sprite.mojo` | 16 | 65 | ~1 s |
| `math/test_geometry.mojo` | 47 | 75 | ~2 s |
| `math/test_matrix.mojo` | 21 | 67 | ~2 s |
| `math/test_random.mojo` | 6 | 6 | ~1 s |
| `math/test_util.mojo` | 35 | 45 | ~1 s |
| `math/test_vector2.mojo` | 27 | 52 | ~1 s |
| `math/test_vector3.mojo` | 29 | 76 | ~2 s |

Per-file wall times are dominated by compilation and are only good to ~1 s.
Runtime cost is therefore a function of *file count*, not test count: a new
assertion in an existing file is nearly free; a new file costs ~1–2 s. **Every
package plan should prefer growing existing files over adding new ones**, and
add a file only when the module genuinely has no home.

Source-to-test size, for orientation only — LOC ratio is not a coverage claim:

| Package | src LOC | test LOC |
|---|---:|---:|
| `core` | 2127 | 1745 |
| `math` | 712 | 1163 |
| `graphics` | 225 | 154 |
| `audio` | 348 | 89 |

## Conventions in force

These are de-facto — no document states them, the files simply agree. Package
plans must propose work that conforms, and should flag any file that deviates.

**There *is* a test framework.** Every file ends with:

```mojo
def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
```

`std.testing.TestSuite` discovers every module-level `def test_*`, runs them
all, prints `PASS`/`FAIL` per test with timing, and exits non-zero if any
failed. So the framework isolates failures *within* a file; `set -e` in the
pixi task stops the sweep at the first failing *file*.

Failure output is already good and needs no help:

```
    FAIL [ 0.026 ] test_bad
      At tests/…/test_x.mojo:7:17: AssertionError: `left == right` comparison failed:
         left: 1
        right: 2
```

**Naming.** File `test_<module>.mojo`, mirroring the source module one-for-one,
under `tests/<package>/`. Test functions are `def test_<behaviour>() raises ->
None:` — full sentences, not abbreviations (`test_fit_letterboxes_wider_window`,
`test_style_does_not_survive_the_frame_boundary`). Helpers take a leading
underscore (`_filled`, `_design`, `_tone`, `_ink_box`) so discovery skips them.
Both the `test_` file prefix and the `test_` function prefix are load-bearing.

**Assertions.** From `std.testing`, in this proportion: `assert_equal` (636),
`assert_almost_equal` (125, always with an explicit `atol`), `assert_true`
(105), `assert_false` (8). No custom matchers. Shared multi-assert predicates
are written as plain `_assert_*` helpers (`_assert_base_round_trips` in
`test_viewport.mojo` and `test_context.mojo`) rather than as framework
extensions.

**Assets are located by a repo-relative literal path** — `Sprite.load(
"tests/fixtures/test_2x2.bmp")`, 7 sites across `test_sprite.mojo` and
`test_canvas.mojo`. This is a real defect, see Gaps.

**Headless rendering is asserted for real.** The model is
`tests/core/test_canvas.mojo`: declare a minimal `@fieldwise_init struct X(
Program)` next to the test that uses it, drive it with
`run_headless[X](design_w, design_h, frames=1, pixel_width=…, pixel_height=…)`,
and read pixels back with `MemorySurface.pixel(x, y)`, comparing against a
`Color`. Time is synthetic (16 ms/frame) and input is empty, so results are
deterministic. Pass a `pixel_*` shape different from the design size whenever
autoscale, letterboxing or stroke scaling is under test — a 1:1 mapping has no
scale factor and no bars. Any proposed render assertion must use this path.

**Below the program level**, `tests/core/test_raster.mojo` and
`test_surface.mojo` build a `MemorySurface` directly and call the free raster
functions, so raster behaviour is unit-tested without a `Program` at all.
`test_text.mojo` goes one level up, driving `TextRenderer.draw` over a
`MemorySurface` and reducing the result to an ink bounding box (`_ink_box`) so
alignment can be asserted without pinning exact glyph rasterisation.

**Audio is not stubbed.** `test_audio.mojo` constructs a real `Audio()` against
SDL's `dummy` driver, which the pixi task exports globally. No fake device, no
mock. `Sound` under test is synthesised in-process with `Sound.from_pcm`, so no
audio file is read.

## Coverage map

Legend — **C** the symbol is the subject of at least one assertion; **I**
indirect, executed on the way to some other assertion but not itself asserted;
**U** untested, never executed by the suite.

### core

| Symbol / module | Test file | |
|---|---|---|
| `align.mojo` — `HAlign`, `VAlign`, `__eq__`/`__ne__` | `test_text.mojo` (`_style`) | I |
| `autoscale.mojo` — `AutoScale.OFF`/`FIT`/`EXTEND` | `test_context`, `test_viewport`, `test_canvas` | C |
| `canvas.mojo` — `background`, `rect`, `circle`, `line`, `triangle`, `sprite`, `fill`, `stroke`, `no_stroke`, `stroke_width`, `transform`, `style` | `test_canvas.mojo` | C |
| `canvas.mojo` — `_draw_letterbox`, `_pixel_scale`, `_uniform`, `_stroke_width_px`, `_push`/`_pop`/`_sync_transform`, `_release` | `test_canvas.mojo` | I |
| `canvas.mojo` — `to_world`, `to_local` | — | **U** |
| `canvas.mojo` — `left`, `right`, `bottom`, `top` | — | **U** |
| `canvas.mojo` — `no_fill` | — | **U** |
| `canvas.mojo` — `text` (×3), `font`, `font_size`, `font_weight`, `text_align`, `text_baseline` | — | **U** |
| `canvas.mojo` — `Int` overloads of `rect`/`circle`/`line`/`triangle`; `Vector2`/`Rectangle`/`Circle`/`Line`/`Triangle` overloads; `sprite` w/h overloads | — | **U** |
| `color.mojo` — every ctor, constant, `hex`, `hsv`, `to_hsv`, `lerp`, `luminance`, `over`, `write_to`, `__eq__` | `test_color.mojo` | C |
| `context.mojo` — `design`, `_set_viewport`, `left`/`right`/`top`, `to_world`, `_base_matrix` | `test_context.mojo` | C |
| `context.mojo` — `bottom`, `quit`, `exit_on_escape` | — | **U** |
| `font.mojo` — `Font.__init__`, `_set_size`, `render`, `GlyphInfo` | `test_text.mojo` | I |
| `font.mojo` — `_set_weight`, `has_glyph`, `FontWeight` constants, `_read_u32`/`_read_i32`/`_read_ptr` | — | **U** |
| `frame.mojo` — `step` | `test_frame.mojo` + all headless tests | C |
| `headless.mojo` — `run_headless` | `test_canvas`, `test_smoke`, `test_frame` | C |
| `input.mojo` — `is_key_down`, `just_pressed`, `just_released` (both overloads), mouse fields | `test_input.mojo` | C |
| `key.mojo` — `Key.from_name`, `KeyBits.set`/`test` | `test_input.mojo` | C |
| `key.mojo` — `KeyBits.clear`, `clear_all` | — | **U** |
| `path.mojo` — `script_dir` | — | **U** |
| `program.mojo` — `Program` trait, default `update`/`render`/`on_*` | `test_smoke`, `test_canvas` | I (callbacks **U**) |
| `raster.mojo` — `blend`, `fill_all`, `fill_pixels`, `line_pixels`, `fill_triangle`, `blit_sprite`, `blit_glyph` | `test_raster.mojo` | C |
| `run.mojo` — `run`, `_run_loop`, `_process_events`, `_update_dimensions`, `_wait_for_dimensions` | — | **U** (see Untestable) |
| `style.mojo` — `Style.__init__` and defaults | `test_text.mojo`, `test_canvas.mojo` | C (defaults I) |
| `surface.mojo` — `Surface`, `offset`, `MemorySurface`, `surface`, `pixel` | `test_surface.mojo` | C |
| `text.mojo` — `TextRenderer.draw`, `_ensure_font`, `_glyph`, `set_font` | `test_text.mojo` | C |
| `time.mojo` — `_start`, `_tick`, `delta`, `delta_millis`, `elapsed`, `frame_count` | `test_time.mojo` | C |
| `viewport.mojo` — `set_design`, `set_size`, edges, `base_matrix`, `to_world`, `scaled` | `test_viewport.mojo` | C |

### math

| Symbol / module | Test file | |
|---|---|---|
| `vector2.mojo` — all ctors, operators, `mag`, `normalize`, `dot`, `dist`, `lerp`, `write_to` | `test_vector2.mojo` | C |
| `vector2.mojo` — `Tuple[Int, Float64]` / `Tuple[Float64, Int]` ctors | — | **U** |
| `vector3.mojo` — all ctors, operators, `cross`, `dot`, `dist`, `lerp`, `write_to` | `test_vector3.mojo` | C |
| `vector3.mojo` — the 5 mixed-`Tuple` ctors | — | **U** |
| `matrix.mojo` — `identity`, `__matmul__`, `transposed`, `translate`, `rotate`, `scale`, `perspective`, `apply`, `inverse` | `test_matrix.mojo` | C |
| `matrix.mojo` — `apply` 4×4 overload, `write_to`, `__init__(copy:)` | — | **U** |
| `geometry.mojo` — `Rectangle`, `Circle`, `Line`, `Triangle`, `overlaps[A,B]`, `Convex` | `test_geometry.mojo` | C |
| `geometry.mojo` — `Triangle._separates`, `Circle.overlaps(Rectangle)` direct | — | I |
| `random.mojo` — `float`, `float(lo,hi)`, `int`, `bool`, seeding | `test_random.mojo` | C |
| `random.mojo` — default (entropy) ctor, `_rotl`/`_next` | — | I / **U** |
| `util.mojo` — all 9 functions | `test_util.mojo` | C |

### graphics

| Symbol | Test file | |
|---|---|---|
| `Sprite.__init__`, `solid`, `from_rgba`, `resize` | `test_sprite.mojo` | C |
| `Sprite.load(path)` — BMP branch | `test_sprite.mojo` | C |
| `Sprite.load(path)` — PNG, JPEG branches | `test_sprite.mojo` | C (dimensions only) |
| `Sprite.load(path, w, h)` | `test_sprite.mojo` | C |
| `_load_png`, `_load_jpeg` | via `load` | I |
| `_extension`, `_jpeg_dimensions`, `_read_u16`/`_read_i32`/`_read_u32`, `_u32_at_inline` | — | I |
| Every `raise` path — too-small file, bad magic, unsupported DIB, non-24/32-bit, compressed BMP, unknown extension | — | **U** |

### audio

| Symbol | Test file | |
|---|---|---|
| `Audio.play`, `stop`, `stop_all`, `pause`, `resume`, `is_playing`, id generation counting | `test_audio.mojo` | C |
| `Audio.update`, `set_volume`, `_free_slot`, `__deinit__`, `Voice.reset` | — | **U** |
| `Sound.from_pcm` | `test_sound.mojo` | C |
| `Sound.load` (WAV/OGG/FLAC/MP3) | — | **U** — no audio fixture exists |
| `_sdl_audio.mojo` — `open_device_stream`, `put_data`, `resume`/`pause_stream`, `destroy_stream` | via `Audio` | I |
| `_sdl_audio.mojo` — `load_wav`, `set_gain`, `available`, `clear_stream`, `get_error`, `quit` | — | **U** |
| `_sndfile.mojo` — `SndFile.load` | — | **U** |

## Rubric

Each package plan scores its package on these seven axes, **1–5**, with a
one-paragraph justification per axis naming specific files. The point of a
score is to rank work, not to grade the author.

| # | Axis | 1 | 5 |
|---|---|---|---|
| 1 | **Behavioural coverage** | Most public symbols in the **U** column above | Every public symbol is the subject of an assertion |
| 2 | **Boundary coverage** | Only mid-range values | Zero, empty, one, off-by-one, clipped-at-every-edge, and the exact-touch case are each asserted |
| 3 | **Error & invalid input** | No `raise` path asserted | Every `raise` in the module has a test that provokes it |
| 4 | **Assertion strength** | Asserts a call did not crash, or asserts only a length/dimension | Asserts the exact value the contract promises, so a wrong implementation fails |
| 5 | **Isolation & determinism** | Depends on CWD, wall-clock, real hardware, or another test's leftovers | Self-contained: constructs its own inputs, deterministic run to run and machine to machine |
| 6 | **Runtime cost** | Adds files or loops that materially grow the ~32 s sweep | Grows existing files; new files earn their ~1–2 s |
| 7 | **Failure clarity** | A failure names a pixel index or a raw number with no way to tell what broke | The test name states the contract and the assertion's `left`/`right` shows the violation directly |

**Axis 4 is the one to weigh hardest.** The suite's headline number — 844
assertions — is not evidence of much on its own; the question every package
plan must answer per module is *could the implementation be wrong while these
tests still pass?* `test_sprite.mojo`'s PNG and JPEG tests are the clearest
example: they assert the decoded dimensions and nothing about the pixels.

## Suite-level gaps

Ranked by risk. These belong to no single package; they are fixed here or in a
follow-up, not inside a package plan.

1. **Tests only pass from the repo root.** Seven asset loads use the literal
   path `tests/fixtures/…` / `tests/assets/…`. Run `test_sprite.mojo` from any
   other directory and 6 of its 16 tests fail with `Failed to open file
   'tests/fixtures/test_2x2.bmp'`. The library already ships the fix —
   `create.core.path.script_dir()`, itself untested — so a test helper that
   resolves fixtures relative to the script would close this and give
   `script_dir` its first coverage at the same time.
2. **The sweep stops at the first failing file.** `set -e` in the `test` task
   means one broken file hides the state of every file sorted after it. The
   framework already isolates failures within a file; only the shell loop
   throws that away. Collecting failures and reporting all of them at the end
   would cost nothing and make a red suite diagnosable in one run. Note the
   trade-off: `pre-push` wants a fast abort, so any change should keep the
   non-zero exit.
3. **No CI.** The two git hooks are the only automated gate, and they run only
   in a clone where `pixi run setup` has been done. Nothing verifies a push
   from a fresh clone, and `--no-verify` bypasses both.
4. **No coverage tooling.** The map above was assembled by reading imports and
   call sites. Nothing detects a symbol falling out of coverage, so this map
   goes stale silently the moment a new public method lands.
5. **Runtime is compile-bound.** ~32 s for 356 tests, near-100% compilation.
   This caps how much the suite can grow before it stops being run casually,
   and is the reason axis 6 exists.
6. **No `raise`-path testing anywhere in the suite.** Not one of the 844
   assertions provokes an error. `assert_raises` is unused. The malformed-input
   behaviour of `Sprite.load` and `Font.__init__` is entirely unverified.

## Deliverables of the remaining phases

Each writes one `TEST_PLAN.md` into its own test directory, using the template
below, scoring against the rubric above.

| Phase | Report | Why this order |
|---|---|---|
| 1 | `tests/math/TEST_PLAN.md` | Smallest risk, best existing coverage — calibrates the rubric |
| 2 | `tests/graphics/TEST_PLAN.md` | One module, decoders with a clear assertion-strength problem |
| 3 | `tests/audio/TEST_PLAN.md` | Largest src-to-test gap |
| 4 | `tests/core/TEST_PLAN.md` | Largest surface; benefits from a rubric already exercised three times |

### Report template

```markdown
# Test Plan: <package>

## Scope
## Current State           <- files, what each asserts, runtime
## Coverage Map            <- symbol -> covered/indirect/untested
## Rubric Scores           <- against the Phase 0 rubric, with justification
## Gaps                    <- ranked by risk x likelihood
## Proposed Work           <- ordered, commit-sized items; each names the
                              target file, the behaviour, and the assertion
## Out of Scope / Untestable
```

Proposed-work items follow the repo's commit granularity: one item = one
cohesive commit that leaves the suite green. Prefer many small items over few
large ones.

### Constraints every package plan inherits

- Do not propose a new test framework or runner. `TestSuite` is the framework.
- Do not propose expanding `tests/core/test_smoke.mojo`. The pre-commit hook
  builds it on every commit and its cost must stay constant.
- Repo style: `comptime` not `alias`, `def` not `fn`, `Pointer` not
  `UnsafePointer`, `-I src` on every `mojo run`.
- Never propose a second parameter on `Canvas`, or importing `window` into
  `canvas.mojo` — both break the seam `run_headless` depends on.
- Render assertions go through `run_headless` + `MemorySurface.pixel`, never
  through visual inspection.
- Prefer adding to an existing file; a new file costs ~1–2 s of sweep time.

## Out of scope / untestable

- **`run.mojo`.** Opens an SDL window and blocks in a loop driven by real
  events and a real clock. Nothing in it can be asserted headlessly. What
  stands in for it: `tests/core/test_smoke.mojo` contains
  `_windowed_entry_point`, never called, whose body instantiates `run[Smoke]`
  — the pre-commit hook builds the file on every commit, so the windowed path
  stays type-checked even though it is never executed. The gate is
  *compilation*, not behaviour. `frame.mojo`'s `step` is shared with
  `run_headless`, so the per-frame body *is* tested; only the event pump, the
  clock, and window-size negotiation are not.
- **Real audio output.** Under `SDL_AUDIO_DRIVER=dummy` there is no device to
  observe, so whether a sample is audible is unverifiable. Voice *bookkeeping*
  is fully testable and is where the audio plan should aim.
- **Actual glyph rasterisation.** `test_text.mojo` deliberately asserts on an
  ink bounding box rather than on glyph bitmaps, since those depend on the
  FreeType build. Keep it that way.
- **The hooks themselves.** `.githooks/pre-commit` and `pre-push` are shell,
  and nothing tests them.
