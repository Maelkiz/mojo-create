# Test Plan: graphics

Phase 2. Scores against the rubric in [../TEST_PLAN.md](../TEST_PLAN.md), which
also carries the suite-wide conventions and constraints every item here obeys.

## Scope

- **In**: `src/create/graphics/sprite.mojo` — the `Sprite` buffer, its
  constructors (`solid`, `from_rgba`), `resize`, both `load` overloads, and the
  three decode paths (BMP inline, PNG via libpng, JPEG via libjpeg-turbo).
- **Out**: `raster.blit_sprite`, which draws a `Sprite` onto a `Surface` — that
  is core's, and is already well covered in `tests/core/test_raster.mojo`. This
  plan covers the *integration* seam (`canvas.sprite` of a decoded file) only
  where it verifies decode correctness.

## Current state

225 src LOC against 154 test LOC in one file — the thinnest ratio in the repo
after audio, and the package where assertion strength diverges most sharply
between the parts.

| File | Tests | Asserts | Wall |
|---|---:|---:|---:|
| `test_sprite.mojo` | 16 | 65 | ~1 s |

What it asserts, by area:

- **Buffer construction (7 tests).** Strong. `solid` is checked per channel at
  three colours and at 1×1; `from_rgba` round-trips a two-pixel buffer byte for
  byte, including a non-255 alpha. These would fail on a channel swap.
- **BMP decode (3 tests).** Strong. `test_load_bmp_pixels` asserts all four
  pixels of the fixture per channel, which pins bottom-up row order *and* the
  BGR→RGB swap simultaneously; `test_load_bmp_alpha_channel` pins the
  synthesised `a = 255`.
- **PNG and JPEG decode (2 tests).** Weak — see G1. Dimensions and buffer
  length only.
- **`resize` (5 tests).** Weak — see G3. Dimensions are asserted; the only
  colour assertion is on a *uniform* sprite.

Fixtures available, and what each is:

| Path | Actually | Exercises |
|---|---|---|
| `tests/fixtures/test_2x2.bmp` | 2×2, 24-bit, bottom-up, `BI_RGB`, DIB size 40, 70 bytes | The 24-bit BMP branch, its 4-byte row padding (2 px × 3 B = 6 B → 8 B), bottom-up row flip |
| `tests/assets/sprite.png` | 500×500, 8-bit **RGB**, non-interlaced, 97 KB | `_load_png` on an opaque image |
| `tests/assets/sprite.jpeg` | 500×500, baseline, 3-component, 21 KB | `_load_jpeg` and `_jpeg_dimensions` on an SOF0 stream |

**There is exactly one BMP fixture and it covers exactly one BMP variant.** No
fixture anywhere in the repo carries an alpha channel through a decoder.

## Coverage map

**C** covered, **I** indirect, **U** untested.

| Symbol / branch | | Note |
|---|---|---|
| `Sprite.__init__(w, h)` | C | Via every other constructor |
| `Sprite.solid` | C | Per channel, three colours, 1×1 |
| `Sprite.from_rgba` | C | Byte-exact round-trip |
| `Sprite.from_rgba` with `len(data) < w*h*4` | **U** | Unchecked pointer copy — see G4 |
| `Sprite.resize` | C | Dimensions only; sampling unverified — G3 |
| `Sprite.resize` to or from a zero dimension | **U** | |
| `Sprite.load(path)` | C | |
| `Sprite.load(path, w, h)` | C | Dimensions only |
| `Sprite._extension` | I | Never the subject; last-dot and separator behaviour unverified — G5 |
| BMP: 24-bit, bottom-up, padded rows | C | The fixture |
| BMP: **32-bit branch** (lines 212–222) | **U** | No 32-bit fixture exists |
| BMP: **top-down** (negative height) | **U** | No fixture with `raw_h < 0` |
| BMP: `compression == 3` (`BI_BITFIELDS`) accepted | **U** | Accepted but channel masks ignored — G6 |
| BMP: DIB header larger than 40 | **U** | Only the exact-40 case exists |
| BMP raises: too small, bad magic, DIB < 40, bpp ∉ {24,32}, compressed | **U** | Five `raise` sites, none provoked |
| `_load_png` | C | Dimensions and length only — G1 |
| `_load_png` raises: begin-read failure, finish-read failure | **U** | |
| PNG with an alpha channel | **U** | No such fixture |
| `_load_jpeg` | C | Dimensions and length only — G1 |
| `_load_jpeg` raises: init failure, decode failure | **U** | |
| `_jpeg_dimensions` — SOF0 path | I | Reached via `load`, never asserted directly |
| `_jpeg_dimensions` raises: non-marker byte, no SOF found | **U** | |
| `_jpeg_dimensions` — progressive (SOF2) and the other 11 accepted markers | **U** | |
| `_read_u16`, `_read_u32` | I | |
| `_read_i32` — the sign-extension branch (`v >= 0x80000000`) | **U** | Only reachable via a top-down BMP |
| `_u32_at_inline` | I | |
| Canvas integration — `canvas.sprite` of a decoded BMP | C | `tests/core/test_canvas.mojo::test_sprite_blits_unflipped` |
| Canvas integration — PNG or JPEG | **U** | |

## Rubric scores

**1. Behavioural coverage — 3/5.** Every public symbol is called by at least
one test, so nothing is unvisited at the API level. But the *branches* inside
`load` are half-covered: of the BMP decoder's two pixel-format branches and two
row-order branches, one of each is exercised. The 32-bit path — eleven lines
including the only place a decoded alpha channel is read from a file — has
never run.

**2. Boundary coverage — 3/5.** Present and deliberate in places: `1×1` solid,
`resize` to `1×1`, `resize` upscale as well as downscale, and the BMP fixture's
width of 2 happens to force the row-padding path. Absent for the dimensions
that matter to a decoder: no zero-dimension sprite, no odd-vs-even width beyond
the one fixture, no image large enough to cross a buffer boundary, and no
truncated file.

**3. Error and invalid input — 1/5.** `sprite.mojo` contains **nine `raise`
sites** — five in the BMP branch, two in `_load_png`, two in `_load_jpeg`, plus
two in `_jpeg_dimensions`. Not one is provoked by a test. There is also no test
for the nonexistent-file case, which `open` raises. This is the package where
the suite-wide absence of `assert_raises` costs the most, because `load` is the
one function in the library that routinely receives data the program did not
produce.

**4. Assertion strength — 2/5.** Split down the middle. The BMP pixel test and
`from_rgba` round-trip are model assertions — byte-exact, per channel, and a
transposition fails them. The PNG and JPEG tests are the opposite:

```mojo
def test_load_png() raises -> None:
    var s = Sprite.load("tests/assets/sprite.png")
    assert_equal(s.width, 500)
    assert_equal(s.height, 500)
    assert_equal(len(s.pixels), 500 * 500 * 4)
```

Width and height come from the file header before any pixel is decoded, and the
buffer length is `w * h * 4` by construction in `Sprite.__init__`. **A decoder
that returned an all-zero buffer, or swapped R and B, or wrote garbage, passes
both tests unchanged.** Two of the three decode paths in the package are, in
substance, untested. `test_from_rgba_size_mismatch_uses_data` is a second
instance: it passes exactly 4 bytes for a 1×1 sprite, which is not a mismatch,
and then asserts only `len(s.pixels) == 4` — a value fixed by the constructor.

**5. Isolation and determinism — 2/5.** Decoding is deterministic, but this is
the package hit hardest by the suite-wide CWD defect: **6 of 16 tests fail when
run from anywhere but the repo root**, because all five asset loads use literal
`tests/…` paths. It also has the suite's only external-library dependencies —
`libpng16.so` and `libturbojpeg.so` are opened by name via `_DLHandle` at decode
time, so a pixi environment missing either turns a decode test into a load
failure rather than a decode failure.

**6. Runtime cost — 4/5.** ~1 s, one file. The two 500×500 assets mean ~500 k
pixels decoded per run, which is not currently visible against compile time.
Worth keeping in mind: new fixtures should be small, and the ones proposed below
are all ≤ 4×4.

**7. Failure clarity — 3/5.** Test names are clear and the per-channel BMP
assertions localise well. Two names actively mislead: `test_from_rgba_size_
mismatch_uses_data` tests no mismatch, and `test_resize_preserves_color` cannot
detect a colour that failed to be preserved, because the source is uniform.

## Gaps, ranked by risk × likelihood

**G1 — PNG and JPEG decode are asserted only on dimensions, so neither is
really tested.** Both assertions are satisfied before a pixel is written.
Concretely unverified: whether `_load_png`'s `PNG_FORMAT_RGBA` (`img[20] = 3`)
produces R,G,B,A in that byte order; whether `_load_jpeg`'s `TJPF_RGBA`
(`Int32(7)`) does; whether either fills alpha with 255 for a source without
one; whether row order is top-down for both. A red/blue swap in either decoder
is invisible to the current suite, and it is the single most likely decoder bug
because BMP genuinely *is* BGR while PNG and JPEG are not — the file already
contains one deliberate swap, twenty lines from two that must not swap.

**G2 — the 32-bit BMP branch has never executed, and it is the only file-decode
path in the library that reads an alpha channel from disk.** Lines 212–222 are
a separate loop with its own stride arithmetic (`w * 4`, no padding — correct,
since 32-bit rows are always 4-aligned) and its own channel mapping including
`dst[d+3] = data[src+3]`. Nothing has ever run it. A 2×2 32-bit BMP fixture is
70-odd bytes and closes this outright.

**G3 — `resize` is verified for dimensions but not for sampling.**
`test_resize_preserves_color` resizes a `Sprite.solid` and asserts the colour
survived — which it would under *any* index arithmetic, including one that
reads pixel 0 for every destination. The nearest-neighbour mapping
(`src_row = row * height // new_h`) is therefore unproven, as is the
downscale-drops-the-right-pixels behaviour. Note that `raster.blit_sprite`'s
own nearest-neighbour downscale *is* properly tested in
`tests/core/test_raster.mojo`; `Sprite.resize` is a second, independent copy of
that arithmetic, and it is the untested one.

**G4 — `from_rgba` reads `w * h * 4` bytes from the caller's list through a raw
pointer with no length check.** `Sprite.from_rgba(100, 100, some_4_byte_list)`
reads 40 000 bytes out of bounds. The test named for this case does not test
it. Whether the fix is a bounds check, a `raise`, or a documented precondition
is a design decision — but the current state is that neither the code nor the
tests state a contract.

**G5 — `_extension` uses the *last* dot in the whole path and is unaware of
path separators.** `assets/v1.2/image` yields the extension `2/image`;
`sprite.png.bak` yields `bak`. Both fall through to the BMP branch and fail with
a BMP error message about a file that is not a BMP, which is a confusing
diagnostic rather than a crash. Dispatch is on extension, never on content, so a
correctly-formed PNG named `.bmp` reports "Not a BMP file".

**G6 — `compression == 3` is accepted but its channel masks are ignored.** A
`BI_BITFIELDS` BMP declares per-channel masks in the header; the decoder skips
straight to the fixed BGRA layout. For the common case where the masks *are*
BGRA this is right; for any other mask layout it silently produces wrong
colours. Accepting the compression value without reading the masks it implies
is the risky half of the choice.

**G7 — `_jpeg_dimensions` is a hand-rolled marker walk with two untested raise
paths and no test for any marker but SOF0.** It accepts 12 SOF markers and has
been proven against one. It also assumes every marker it steps over carries a
2-byte length, which is untrue for the standalone markers (`0x01`, `0xD0`–
`0xD7`); a stream containing one desynchronises the walk and raises "expected
marker byte" on valid data. Low likelihood before the entropy-coded segment,
but wholly unguarded.

**G8 — no test asserts the nonexistent-file or truncated-file behaviour.** The
most ordinary failure a user of `Sprite.load` will hit — a wrong path — has no
test. A truncated BMP is worse than a raise: `pixel_offset + src_row *
row_stride + col * 3` indexes `data` past its end, since the header's declared
dimensions are trusted without checking that the pixel array is actually
present.

## Proposed work

Ordered, commit-sized. Each leaves the suite green. All additions go into the
existing `test_sprite.mojo` except where noted; new *fixtures* are needed and
are called out per item.

**W1 — Assert PNG and JPEG pixels, not dimensions.** `test_sprite.mojo`, plus
two new fixtures: a 2×2 PNG and a 2×2 JPEG with four distinct, well-separated
colours (e.g. pure red, green, blue, white) laid out in the same arrangement as
the existing BMP fixture. Assert every channel of every pixel. For JPEG, assert
with a tolerance — it is lossy, so pick colours far enough apart that a ±16
band still distinguishes a channel swap from correct output. This single item
closes G1 and is the highest-value change in the package: it takes two of the
three decode paths from nominally-covered to actually-covered.

**W2 — A 32-bit BMP fixture and its pixel assertions.** New fixture
`tests/fixtures/test_2x2_32bit.bmp`, 2×2, `BI_RGB`, with **four different alpha
values** (e.g. 0, 85, 170, 255) so the alpha column is read from the file rather
than synthesised. Assert all four channels of all four pixels. Closes G2 and
gives the library its first end-to-end test of decoded alpha.

**W3 — A top-down BMP fixture.** New fixture with a negative height field,
same pixel content as `test_2x2.bmp`, asserting the decoded result is
*identical* to the bottom-up fixture's. This is the assertion that proves the
row flip is applied in one case and not the other, and it is the only way to
reach `_read_i32`'s sign-extension branch.

**W4 — Provoke every BMP raise.** `test_sprite.mojo`, using `assert_raises` and
small fixtures built in-process where possible. Five cases: a file under 54
bytes, a file with the right size but the wrong magic, a DIB size below 40, a
bpp of 8 or 16, and a compression value of 1 (`BI_RLE8`). Assert the message,
not just that something raised, so a test cannot pass by raising for the wrong
reason. Add the nonexistent-path case here too (G8). This takes rubric axis 3
from 1 to a genuine score.

**W5 — Prove `resize`'s sampling.** `test_sprite.mojo`. Build a 4×4 sprite with
sixteen *distinct* colours via `from_rgba`, downscale to 2×2, and assert each
destination pixel equals the specific source pixel nearest-neighbour selects.
Then upscale 2×2 → 4×4 and assert the block replication. Closes G3 and fixes
`test_resize_preserves_color`'s false confidence — that test should be kept but
renamed to say what it actually checks (that a uniform sprite stays uniform).

**W6 — State the `from_rgba` length contract.** `test_sprite.mojo`. Decide
first: bounds-check and raise, or document the precondition. Then assert it.
The existing `test_from_rgba_size_mismatch_uses_data` should be renamed and
rewritten in the same commit — it is currently named for a case it does not
construct. Do not write a test that passes a short list to the current
implementation; that is an out-of-bounds read and the test would be undefined
behaviour, not a test.

**W7 — Cover `_extension` directly.** `test_sprite.mojo`. It is a
`@staticmethod` and callable from a test. Assert: a plain `.png`, an uppercase
`.PNG` (the `| 32` lowercasing), no dot at all, a trailing dot, a dot in a
directory component with no extension on the file, and a double extension.
Decide what the last two should return; the test encodes the decision. Closes
G5 at its source rather than through `load`.

**W8 — Cover `_jpeg_dimensions` directly with synthetic byte lists.**
`test_sprite.mojo`. It takes a `List[UInt8]`, so no fixture file is needed:
build minimal marker streams in-process. Assert an SOF0 stream's dimensions, an
SOF2 (progressive) stream's dimensions, a stream with no SOF (raises), and a
stream whose second byte is not `0xFF` (raises). Cheap, fast, and closes most
of G7 without touching the filesystem.

**W9 — Canvas integration for PNG and JPEG.** `tests/core/test_canvas.mojo`
(this one belongs in core's file, next to `test_sprite_blits_unflipped`). Blit
the 2×2 PNG fixture from W1 through `canvas.sprite` and assert the on-surface
pixels, so the decode-to-screen path is proven for a format other than BMP.
One test, not three — the raster path is shared and already covered.

**W10 — Zero and degenerate dimensions.** `test_sprite.mojo`. `Sprite(0, 0)`,
`resize` to a zero dimension, and `resize` *from* a zero-width sprite — the
last currently computes an offset into an empty buffer. Assert the decided
contract. Lower priority than W1–W6 but it is the remaining unguarded arithmetic
in the file.

**W11 — Document the `BI_BITFIELDS` decision.** `test_sprite.mojo` plus a
source comment. Either read the masks and assert a non-BGRA `BI_BITFIELDS`
fixture decodes correctly, or narrow the acceptance to `compression == 0` and
assert that `compression == 3` now raises. Both are defensible; silently
accepting and ignoring is not. This is last because it is the only item that
requires a source change before the test can be written.

## Out of scope / untestable

- **libpng and libjpeg-turbo internals.** `_load_png` and `_load_jpeg` are thin
  FFI shims; their job is to pass the right format constants and buffer, and
  W1's pixel assertions verify exactly that. Do not test the libraries.
- **The `_load_png` / `_load_jpeg` failure raises.** Provoking them means
  handing libpng a buffer it rejects mid-decode, which in practice means a
  deliberately corrupted fixture whose behaviour depends on the library version.
  The `_jpeg_dimensions` raises (W8) are the testable half; these two are not
  worth the fixture fragility.
- **Interlaced PNG, 16-bit-per-channel PNG, CMYK JPEG, arithmetic-coded JPEG.**
  Real formats the decoders do not claim to support. Their absence should be
  documented in `Sprite.load`'s docstring rather than tested.
- **Large-image performance.** The 500×500 assets exist and decode fine; the
  suite has no performance budget to assert against and should not grow one.
