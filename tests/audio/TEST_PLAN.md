# Test Plan: audio

Phase 3. Scores against the rubric in [../TEST_PLAN.md](../TEST_PLAN.md), which
also carries the suite-wide conventions and constraints every item here obeys.

## Scope

- **In**: `src/create/audio/` — `Sound` (`load`, `from_pcm`), `Audio` (voice
  lifecycle, generation-counted ids, `play`/`stop`/`stop_all`/`pause`/`resume`/
  `set_volume`/`is_playing`, the per-frame `update`), and the two FFI shims
  `_sdl_audio.mojo` and `_sndfile.mojo`.
- **Out**: whether anything is audible. Under `SDL_AUDIO_DRIVER=dummy` there is
  no device to observe; this plan targets bookkeeping, which is where the bugs
  a user would hit actually live.

## Current state

348 src LOC against 89 test LOC — **the widest src-to-test gap in the repo**,
and the only package where a documented, mandatory API call has no test at all.

| File | Tests | Asserts | Wall | What it asserts |
|---|---:|---:|---:|---|
| `test_audio.mojo` | 5 | 8 | ~2 s | `play` returns a live id; `stop` invalidates it; `stop_all` invalidates several; `pause`/`resume` flip `is_playing`; a stale id does not alias the voice that recycled its slot |
| `test_sound.mojo` | 3 | 9 | ~1 s | `from_pcm` byte length, little-endian packing (including a negative sample), and the `channels=1`/`freq=44100` defaults |

Both files are well written for what they cover. `test_stale_id_after_slot_
recycle` in particular tests the subtlest thing in the package — the generation
counter — and does it correctly. The problem is not the quality of these eight
tests; it is that they cover roughly a third of the package's surface.

**No audio fixture file exists anywhere in the repo.** Every `Sound` under test
is synthesised in-process with `from_pcm`.

## Feasibility under `SDL_AUDIO_DRIVER=dummy`

This was checked empirically rather than assumed, because it determines whether
the largest gap below is closable at all. Results:

- `Audio()`, `open_device_stream`, `put_data`, `resume`/`pause_stream`,
  `set_gain`, `destroy_stream` all succeed against the dummy driver. Every
  bookkeeping operation is testable.
- **The dummy driver consumes queued audio in real time.** A 256-sample mono
  S16 buffer (≈5.8 ms of audio) drains within ~50 ms of wall clock. So
  `update()`'s one-shot reap *is* reachable in a test — but only by waiting.
- The contract AGENTS.md warns about reproduces exactly: with no `update()`
  call, a finished one-shot voice stays `is_playing == True` indefinitely; one
  `update()` after the drain reaps it. A looping voice survives repeated
  `update()` calls across the same span.

So `update()` is testable, at the cost of the suite's only wall-clock
dependency. That trade-off is priced into W3 below.

## Coverage map

**C** covered, **I** indirect, **U** untested.

| Symbol | | Note |
|---|---|---|
| `Sound.from_pcm` | C | Length, LE packing, defaults |
| `Sound.from_pcm` with an empty list | **U** | |
| `Sound.__init__` (direct) | I | Only via `from_pcm` and `load` |
| `Sound.load` — magic-byte dispatch | **U** | No fixture exists |
| `Sound.load` — WAV branch (`SDL_LoadWAV`) | **U** | |
| `Sound.load` — libsndfile branch (OGG/FLAC/MP3) | **U** | |
| `Sound.load` — file shorter than 4 bytes, nonexistent path | **U** | |
| `Voice.__init__`, `Voice.reset` | I | `reset` is proven only through `_valid` failing afterwards |
| `Audio.__init__` | C | Constructed by every test |
| `Audio._encode` / `_decode` / `_valid` | I | Never asserted directly — see G2 |
| `Audio.play` — one-shot | C | |
| `Audio.play` — **`loop=True`** | **U** | Never called anywhere in the suite — G1 |
| `Audio.play` — slot reuse vs. append | C / **U** | Reuse is covered by the recycle test; the append-past-one-voice path only incidentally |
| `Audio.play` — applies `self.volume` as initial gain | **U** | |
| `Audio.stop`, `stop_all` | C | |
| `Audio.pause`, `resume` | C | |
| `Audio.is_playing` | C | |
| `Audio.set_volume` | **U** | |
| `Audio.volume` field | **U** | |
| `Audio.update` — one-shot reap | **U** | The documented mandatory call — G1 |
| `Audio.update` — loop refill | **U** | |
| `Audio._free_slot` | I | |
| `Audio.__deinit__` | **U** | Swallows all exceptions |
| `ArcPointer[Sound]` sharing on a looping voice | **U** | The stated reason for the signature — G1 |
| `_sdl_audio` — `init`, `open_device_stream`, `put_data`, `resume_stream`, `pause_stream`, `set_gain`, `destroy_stream` | I | Exercised via `Audio`, never asserted |
| `_sdl_audio` — `load_wav`, `available`, `clear_stream`, `get_error`, `quit` | **U** | `available` is reached only from `update`, which is untested |
| `_sndfile` — `SndFile.__init__`, `load` | **U** | Never constructed |
| `_sndfile` — the `read_frames < frames` truncation branch | **U** | |

## Rubric scores

**1. Behavioural coverage — 2/5.** Five of `Audio`'s nine public methods are
covered, and one of `Sound`'s two. The uncovered set is not a tail of
conveniences: it contains `update`, which the documentation states must be
called every frame or playback breaks, and `Sound.load`, which is how a program
gets audio in the first place. The entire `_sndfile.mojo` module — 55 LOC and
three of the four supported formats — has never been constructed.

**2. Boundary coverage — 2/5.** `from_pcm`'s tests do reach for boundaries
(`32767`, `-100`, and a negative that exercises the sign-shift in the LE
packing). `Audio`'s do not: no test plays more than two voices, so nothing
exercises the voice list growing, and nothing tests a voice slot recycled more
than once. Empty PCM, zero-length sounds, and a very large voice count are all
absent.

**3. Error and invalid input — 2/5.** Better than graphics scored, and for a
good reason: `stop`/`pause`/`resume`/`set_volume`/`is_playing` all no-op on an
invalid id, and `test_stale_id_after_slot_recycle` verifies that for the
subtlest case. But the no-op contract is only checked for one kind of invalid
id. An id that was never issued, a negative id, and an id whose index is past
the end of `_voices` are all unverified — and one of those is a live hazard, see
G2. The eleven `raise` sites across the two FFI shims are unreachable under a
working dummy driver and are correctly out of scope.

**4. Assertion strength — 4/5.** High, and the best score of any package on
this axis. Every one of the eight assertions checks a specific state transition
against a specific expected boolean, and none would pass against a stubbed
implementation. `test_stale_id_after_slot_recycle` asserts both halves — the
stale id is dead *and* the new id is live — which is exactly the shape that
catches an aliasing bug. The package's problem is quantity, not quality.

**5. Isolation and determinism — 4/5.** Each test constructs its own `Audio`
and its own `Sound`; nothing is shared, nothing touches the filesystem, no test
depends on the working directory. The two dependencies are external: SDL3 must
be present and `SDL_AUDIO_DRIVER=dummy` must be exported. The latter is set by
the pixi task only — running `mojo run -I src tests/audio/test_audio.mojo`
directly, as the AGENTS.md single-file recipe suggests, opens a real audio
device. That is a documentation gap rather than a test defect, but it bites.

**6. Runtime cost — 5/5.** ~3 s across two files. There is ample headroom here;
audio is the package that can most afford to grow, which is fortunate given how
much of it needs to.

**7. Failure clarity — 4/5.** Names state the behaviour, `assert_true`/
`assert_false` on `is_playing` localise cleanly, and the recycle test carries a
comment explaining what the assertion protects. The one weakness is generic:
`assert_false(audio.is_playing(id))` prints `False` vs `True` with no
indication of *which* voice or generation, so a failure in a multi-voice test
would need the test name to carry all the context.

## Gaps, ranked by risk × likelihood

**G1 — the looping path is entirely untested, and it is half the package.**
`audio.play(sound, loop=True)` is not called once in the suite. That single
absence leaves all of the following unexercised: `Voice.looping` and
`Voice.loop_sound`, the `Optional(sound) if loop else None` branch in `play`,
the `ArcPointer` refcount share that is the documented reason the parameter is
an `ArcPointer` at all, and `update`'s entire refill branch — including the
deliberate design choice, explained at length in `update`'s docstring, to top
up *before* the queue drains rather than after `available()` hits zero. That
docstring describes a bug the author already fixed once (a click at every loop
boundary); nothing prevents its return.

**G2 — the first voice id is `0`, which is indistinguishable from a
zero-initialised field.** Verified: on a fresh `Audio`, `play` returns index 0
with generation 0, and `_encode(0, 0) == 0`. So `audio.is_playing(0)` returns
`True` for the first voice ever played. A program holding `var current_voice:
Int` — the obvious way to track a voice, and `@fieldwise_init` structs commonly
zero such a field — cannot distinguish "no voice" from "the first voice", and
will happily `stop(0)` a voice it never started. There is no sentinel invalid
id, and no test states what an invalid id looks like. This is the most likely
bug a *user* of the library will hit, as opposed to a bug in the library.

**G3 — `update()` is never called by any test.** It is the one method
AGENTS.md singles out as mandatory-per-frame, with a documented failure mode on
both branches (a stalled loop, and leaked one-shot slots forever). Both
branches are reachable under the dummy driver, as measured above. Related:
because nothing calls `update`, `_sdl_audio.available()` is never invoked
either, so the whole drain-detection mechanism is unproven.

**G4 — `Sound.load` is untested and there is no audio fixture.** All four
advertised formats, the magic-byte dispatch that chooses between them, and both
FFI decode paths. `_sndfile.mojo` — its `SF_INFO` offset arithmetic, its
`sf_readf_short` call, and its truncation fallback — has never executed.
Getting one small WAV and one small OGG into `tests/assets/` closes most of
this, and the magic-byte dispatch is specifically worth testing because it is
deliberately content-based rather than extension-based, the opposite of the
choice `Sprite.load` made.

**G5 — `set_volume` and the `volume` field are untested.** `play` reads
`self.volume` and applies it as the new stream's gain; `set_volume` overrides
one voice independently. Neither is asserted. Under the dummy driver the *gain*
cannot be observed, but the bookkeeping can: that `set_volume` on a stale id is
a no-op rather than a crash, and that it does not disturb `is_playing`.

**G6 — voice-list growth is barely exercised.** No test plays more than two
concurrent voices, so `play`'s append branch runs at most twice and the
free-slot scan never searches past index 1. A program playing a dozen
overlapping one-shots — the normal case for a game — exercises code the suite
never has.

**G7 — `__deinit__` swallows every exception.** `try: stop_all(); quit()
except: pass`. Defensible for a destructor, but it means a failure during
teardown is invisible, including one caused by the very bookkeeping these tests
verify. Nothing asserts that dropping an `Audio` with live voices is clean.

## Proposed work

Ordered, commit-sized. Each leaves the suite green. All additions go into the
two existing files; no new test file is needed.

**W1 — Cover the looping voice's bookkeeping.** `test_audio.mojo`. Play with
`loop=True` and assert: the returned id is live; it stays live across several
`update()` calls (unlike a one-shot, W3); `stop` releases it; and `stop_all`
releases a mix of looping and one-shot voices together. Closes the cheap,
deterministic half of G1 without any wall-clock dependency. Do this first — it
is the largest coverage gain per line in the package.

**W2 — Assert the `ArcPointer` share.** `test_audio.mojo`. Hold a
`ArcPointer[Sound]`, play it looping, and assert the PCM is shared rather than
copied — by checking the pointer's reference count rose, or, if that is not
reachable from a test, by asserting the caller's `ArcPointer` still yields the
same `pcm` contents and length after the voice is stopped and the `Audio`
dropped. This is the property the parameter type exists to provide and the one
AGENTS.md tells programs to rely on.

**W3 — Cover `update()` on both branches.** `test_audio.mojo`. Three
assertions, in one test to pay the wall-clock cost once:

1. A one-shot voice with no `update()` call stays `is_playing` after its audio
   has drained — the documented leak.
2. One `update()` after the drain reaps it.
3. A looping voice played at the same time is *still* live after that same
   `update()`.

The drain needs real elapsed time; ~50 ms suffices for a 256-sample mono buffer
and ~200 ms is a safe margin. **Gate the timing on a measured condition, not a
fixed sleep** — spin until `_sdl.available(stream) == 0` with a generous
timeout, then assert — so the test is robust on a slow machine rather than
merely lucky on a fast one. This is the suite's only wall-clock-dependent test;
keep it to one, and say so in a comment.

**W4 — Decide and assert what an invalid voice id is.** `test_audio.mojo`, and
probably a source change. The current answer — that `0` is a valid id — is
almost certainly not intended. Options: start generations at 1 so no valid id is
ever 0, or expose a named invalid constant. Then assert: a never-issued id, a
negative id, and an out-of-range index are all `is_playing == False` and are
no-ops for `stop`/`pause`/`resume`/`set_volume`. Closes G2, which is the
highest user-facing risk in the package even though it is not the largest gap.

**W5 — A WAV fixture and `Sound.load`'s WAV branch.** New fixture,
`tests/assets/tone.wav` — a few hundred frames of a synthesised tone, kept
small. Assert the decoded `channels`, `freq`, and `len(pcm)` against the known
file, and spot-check a sample value so the test would fail on a byte-order or
stride error rather than only on a failed open. Use the fixture-path helper
from the suite-wide CWD fix if it has landed by then, rather than a literal
`tests/assets/…` path — this package is currently free of that defect and
should stay so.

**W6 — An OGG or FLAC fixture and the libsndfile branch.** New fixture. Same
assertion shape as W5. This is what gives `_sndfile.mojo` its first execution
ever, including the `SF_INFO` offset arithmetic — offsets hand-derived from a C
header, which is exactly the kind of thing that is silently wrong on a
different libsndfile build. Prefer FLAC over MP3: lossless, so sample values
can be asserted exactly.

**W7 — Magic-byte dispatch, not extension.** `test_audio.mojo` or
`test_sound.mojo`. Copy the WAV fixture to a path with a `.ogg` extension and
assert it still decodes as WAV. This is the behaviour the docstring promises
and the deliberate difference from `Sprite.load`; one assertion pins it. Add the
nonexistent-path and too-short-file cases here.

**W8 — `set_volume` and the `volume` field.** `test_audio.mojo`. `set_volume`
on a live voice does not disturb `is_playing`; on a stale id it is a no-op;
setting `audio.volume` before `play` does not raise. Bookkeeping only — state
in a comment that gain itself is unobservable under the dummy driver, so a
future reader does not mistake the test for a gain assertion.

**W9 — Many concurrent voices.** `test_audio.mojo`. Play sixteen one-shots,
assert all sixteen ids are live and mutually distinct, stop every other one,
assert the survivors are still live and the stopped ones are not, then play
eight more and assert none of them aliases a stopped id. Exercises the append
path, the free-slot scan past index 1, and generation counting under repeated
recycling — all of G6, and it deepens G2's coverage as a side effect.

**W10 — `from_pcm` boundaries.** `test_sound.mojo`. Empty list (assert
`len(pcm) == 0` and that playing it does not raise), a single sample, and
`Int16.MIN` — the last because `-32768`'s sign-shift is the one value where the
`(sample >> 8) & 0xFF` packing could differ from a naive implementation.

**W11 — Clean teardown with live voices.** `test_audio.mojo`. Construct an
`Audio` in a scope, play several voices including a looping one, let it drop,
and assert the process continues and a second `Audio` can be constructed
afterwards. Cannot assert much given `__deinit__` swallows exceptions — which
is itself the finding — but it proves the common shutdown path is not silently
broken.

## Out of scope / untestable

- **Whether anything is audible.** No device under `dummy`. Sample values can be
  verified going *in* (W5, W6, W10); nothing verifies them coming out.
- **Actual gain applied to a stream.** `SDL_SetAudioStreamGain` succeeds and
  there is no way to read the mixed output back. Test that `set_volume` is
  called and does not disturb bookkeeping; do not claim more.
- **The `raise` paths in `_sdl_audio.mojo` and `_sndfile.mojo`.** Eleven of
  them, each triggered by an SDL or libsndfile call failing. Provoking these
  means forcing a library failure, which is neither portable nor stable across
  versions. The one exception is `sf_open` failing on a nonexistent or
  malformed file, which W7 reaches naturally.
- **`update`'s click-free refill timing.** The docstring's reason for topping up
  before the drain is an *audible* property. The testable proxy is that a
  looping voice's `available()` never reaches zero across a span of `update()`
  calls; that is worth asserting inside W3, but it is a proxy and should be
  commented as one.
- **Generation counter overflow.** `_encode` shifts the generation left 32 bits;
  it would take 2³¹ slot recycles to overflow. Not reachable in a test.
