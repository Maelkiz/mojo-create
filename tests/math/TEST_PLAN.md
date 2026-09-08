# Test Plan: math

Phase 1. Scores against the rubric in [../TEST_PLAN.md](../TEST_PLAN.md), which
also carries the suite-wide conventions and constraints every item here obeys.

## Scope

- **In**: `src/create/math/` — `vector2`, `vector3`, `matrix`, `geometry`
  (including `Convex` and `overlaps[A, B]`), `random`, `util`.
- **Out**: every consumer of these types. `Matrix` as used by `Viewport` and
  `Canvas` belongs to the core plan; `Vector2` as a canvas coordinate likewise.

## Current state

712 src LOC against 1163 test LOC across six files — the best-covered package
in the repo, and the reason it goes first: the rubric gets calibrated against
the thing closest to good.

| File | Tests | Asserts | Wall | What it asserts |
|---|---:|---:|---:|---|
| `test_vector2.mojo` | 27 | 52 | ~1 s | Four of six ctors, every operator and in-place operator, `mag`/`mag_sq`/`normalize`/`dot`/`dist`/`dist_sq`/`lerp`, `write_to` |
| `test_vector3.mojo` | 29 | 76 | ~2 s | Same shape as `vector2` plus `cross` (basis vectors and anticommutativity) |
| `test_matrix.mojo` | 21 | 67 | ~2 s | Zero-init, get/set, `identity` at two sizes, `__matmul__` by identity and by value, `transposed` square and non-square, `translate`/`scale`/`rotate` structure *and* effect through `apply`, `perspective` key elements, `inverse` at 2×2/3×3/identity, one composition-order test |
| `test_geometry.mojo` | 47 | 75 | ~2 s | All four shapes' `center`/`contains`/`closest_point`/`move_to`/`translate`, each concrete `overlaps` pair, `Line.intersects`, `overlaps[A,B]` for circle-circle and rect-circle, three boundary-contact cases |
| `test_util.mojo` | 35 | 45 | ~1 s | All nine functions, including deliberate out-of-range extrapolation for `lerp`/`map`/`norm` and negative inputs for `fract`/`fmod` |
| `test_random.mojo` | 6 | 6 | ~1 s | 1000-draw range checks for `float`/`float(lo,hi)`/`int`, a ~50% `bool` proportion, same-seed determinism, different-seeds-differ |

The tests are readable, densely asserted and mostly value-exact. `test_matrix`
is the standout: it checks both a transform's matrix *structure* and its
*effect* on a point, so a transposed constructor cannot pass. `test_geometry`
is the most thorough by count but the weakest by strength (below).

## Coverage map

**C** covered, **I** indirect, **U** untested.

| Symbol | | Note |
|---|---|---|
| `Vector2` — 4 ctors, `zero`, `one`, `+ - * /`, unary `-`, `+= -= *= /=`, `== !=`, `mag`, `mag_sq`, `normalize`, `dot`, `dist`, `dist_sq`, `lerp`, `write_to` | C | |
| `Vector2.__init__(Tuple[Int, Float64])`, `__init__(Tuple[Float64, Int])` | **U** | The mixed-type tuple ctors |
| `Vector3` — everything `Vector2` has, plus `cross` | C | |
| `Vector3` — the 5 mixed-`Tuple` ctors | **U** | Only the all-`Float64` and all-`Int` forms are built |
| `Matrix.__init__()`, `__getitem__`, `__setitem__`, `__matmul__`, `transposed` | C | |
| `Matrix.__init__(*, copy:)`, `write_to` | **U** | |
| `identity`, `translate`, `rotate`, `scale(sx,sy)`, `scale(s)`, `perspective` | C | `perspective` only by four "key elements" |
| `apply(Matrix[3,3], x, y)` | C | |
| `apply(Matrix[4,4], x, y, z)` | **U** | Including its perspective divide by `ow` |
| `inverse[N]` | C | 2×2 by value, 3×3 by round-trip, identity |
| `Convex` trait, `overlaps[A, B]` | C | Circle-circle and rect-circle only |
| `Rectangle` — ctors, `center`, edges, `contains` (both), `closest_point`, `move_to` (3), `translate` (3), `overlaps` (both) | C | |
| `Circle` — same surface | C | |
| `Line` — ctors, `length`, `length_sq`, `intersects` | C | |
| `Triangle` — ctors, `center`, `contains` (both), `closest_point`, `move_to`, `translate`, `overlaps` | C | |
| `_closest_on_segment` zero-length branch, `_ccw`, `_project_min`/`_project_max`, `Triangle._separates` | I | Reached, never the subject |
| `Random.__init__(seed)`, `float`, `float(lo,hi)`, `int`, `bool` | C | |
| `Random.__init__()` (entropy-seeded), `_rotl`, `_next` | **U** / I | The default ctor is never constructed |
| `util` — all 9 | C | |

## Rubric scores

**1. Behavioural coverage — 4/5.** Nearly every public symbol is the subject of
an assertion. What is missing is narrow and mechanical: seven mixed-`Tuple`
vector constructors, `Matrix.__init__(*, copy:)` and `write_to`, the 4×4
`apply`, and the entropy-seeded `Random()`. Nothing structural is unvisited.

**2. Boundary coverage — 3/5.** Good where the author went looking:
`test_util` deliberately extrapolates past `t ∈ [0,1]`, feeds `fract` and
`fmod` negatives, and pins `smoothstep` at both edges; `test_geometry` has
three explicit contact cases; `test_random` draws 1000 samples rather than one.
But the *degenerate* boundary — the one that divides by zero — is absent
everywhere. `Vector2.normalize()` on the zero vector, `map`/`norm` with
`in_low == in_high`, `smoothstep` with `edge0 == edge1`, `fmod(x, 0.0)`,
`inverse` of a singular matrix, a zero-length `Line`, a collinear `Triangle`:
seven division-by-zero or ill-defined paths, none asserted.

**3. Error and invalid input — 1/5.** No function in this package raises, so
there is no `raise` path to provoke — and correspondingly no test states what
happens instead. Every degenerate input above silently returns `nan` or `inf`
and propagates. `Random.int` guards with `debug_assert`, which is a no-op in a
release build, so `rng.int(5, 5)` reaches `% UInt64(0)`. The package's
contract for bad input is currently *undocumented and unasserted*, which is the
lowest score on this axis, not because tests are missing but because the
behaviour has never been decided.

**4. Assertion strength — 4/5** overall, **2/5 for `test_random`.** The vector,
matrix and util files assert exact values and would fail on a wrong
implementation. `test_random` would not: `test_float_in_unit_interval` asserts
`0.0 <= v <= 1.0`, which an implementation returning a constant `0.5` passes;
`test_bool_roughly_half` allows a wide band; `test_deterministic_seed` compares
two same-seeded streams to each other rather than to recorded values, so a
change to the generator that keeps it deterministic passes silently. There is
no golden-vector test pinning xoroshiro128+ output.

**5. Isolation and determinism — 5/5.** Pure value types, no I/O, no clock, no
shared state, every input constructed in the test. The one non-deterministic
symbol, `Random()`, is the one the suite never constructs. Nothing here depends
on the working directory, so `math` is unaffected by the suite-wide CWD defect.

**6. Runtime cost — 5/5.** ~9 s across six files, all compilation. The 1000-
iteration loops in `test_random` cost nothing measurable. No reason to add a
seventh file.

**7. Failure clarity — 4/5.** Test names are full behavioural sentences and
`assert_equal`'s left/right output localises a failure immediately. The
exception is `test_random`'s loops: a failure reports the offending value with
no indication of which of 1000 draws produced it, and the loop aborts at the
first bad draw, so the failure says nothing about the distribution.

## Gaps, ranked by risk × likelihood

**G1 — `overlaps[A, B]` contradicts the concrete `overlaps` methods, and a test
can prove it.** The generic is not SAT despite `Convex` being described as the
SAT trait:

```mojo
def overlaps[A: Convex, B: Convex](a: A, b: B) -> Bool:
    var c = a.center()
    var p = b.closest_point(c.x, c.y)
    return a.contains(p.x, p.y)
```

Two edge-touching rectangles — `Rectangle(0, 0, 10, 10)` and
`Rectangle(10, 0, 10, 10)`, a's right edge exactly on b's left — resolve
differently by path. `a.overlaps(b)` uses strict `<`/`>` and returns **False**
(this is asserted today, in `test_rect_touching_edges_do_not_overlap`).
`overlaps(a, b)` takes a's centre `(0,0)`, clamps it into b to get `(5, 0)`,
and asks `a.contains(5, 0)` — `contains` is inclusive, so **True**. Same two
rectangles, opposite answers, and only one of the two paths is tested for this
case. It is also asymmetric by construction: the generic reads `a`'s centre and
`b`'s surface, so swapping the arguments is a different computation.

**G2 — boundary-contact semantics are inconsistent between shape pairs, and the
tests document the inconsistency instead of flagging it.** `Rectangle.overlaps(
Rectangle)` is strict, so touching is not overlap. `Circle.overlaps(Circle)`
and `Rectangle.overlaps(Circle)` use `<=`, so touching *is* overlap.
`Triangle.overlaps(Triangle)` separates on `max1 < min2`, so touching is
overlap. Three of four pairs say yes, one says no. The two existing tests each
assert the local behaviour with a comment explaining the operator — accurate,
but they read as "this is what the code does" rather than "this is what the
library promises", and nothing compares the pairs against each other.

**Resolved: touching counts as overlap, everywhere.** Every shape's `contains`
is already inclusive (`<=`), so a point exactly on a shared boundary is
`contains`ed by both shapes — the natural definition of overlap ("shapes share
at least one point") already implies inclusive for the three pairs that use
it. `Rectangle.overlaps(Rectangle)`'s strict `<`/`>` is the outlier, not the
other three, and it is also the smaller fix: two comparisons in one method,
versus loosening three methods and losing the "overlap implies share a
`contains`ed point" invariant everywhere else. `Rectangle.overlaps(Rectangle)`
changes from `left() < other.right() and right() > other.left() and ...` to
`<=`/`>=` throughout. This also resolves G1 for the rect-rect touching case
specifically: `overlaps[A,B]` already returns `True` there (via inclusive
`contains`), so fixing the concrete method to agree removes the contradiction
for that pair. G1's deeper issue — the generic reads only `a`'s centre and
`b`'s surface, so it is asymmetric by construction — is unrelated to this fix
and is what W2 tests for.

**G3 — every degenerate-input path is unasserted.** Seven of them, listed under
rubric axis 2. `Vector2.normalize()` on `Vector2.zero()` is the one most likely
to reach a user: it returns `(nan, nan)` and poisons every subsequent
computation silently. A program normalising a velocity that happens to be zero
for one frame is an ordinary occurrence.

**G4 — `test_random` cannot detect a changed generator.** No golden vectors.
Determinism is verified only against another instance of the same code, so any
edit to `_next` or the SplitMix64 seeding that preserves self-consistency
passes. Combined with axis-4's weak range assertions, the file's real coverage
of `random.mojo` is close to "it does not crash and it is repeatable".

**G5 — `Random.float()` can return exactly 1.0, and no test says whether that
is intended.** It divides by `UInt64.MAX` rather than by `2^64`, so the
interval is closed. `float(low, high)` inherits this and can return `high`.
Most RNG APIs promise a half-open interval; this one does not, and the test
asserts `<= 1.0`, which is compatible with either choice. `int(low, high)` is
half-open and also carries modulo bias — small for typical ranges, unbounded
in principle.

**Resolved: half-open `[0,1)`, matching `int(low, high)`'s existing
convention.** `random.mojo`'s `float()` changes from
`Float64(self._next()) / Float64(UInt64.MAX)` to
`Float64(self._next()) / (Float64(UInt64.MAX) + 1.0)` — `2^64` is exactly
representable in `Float64`, so this is a clean divisor change, not an
approximation. `float(low, high)` needs no change; it already inherits
whatever `float()` promises.

**G6 — the mixed-`Tuple` constructors are untested.** Seven of them across the
two vector types, each a hand-written field-by-field body where an `x`/`y`
transposition would compile. Low risk, trivially cheap to close.

**G7 — `apply(Matrix[4,4], …)` is untested, including its perspective
divide.** `perspective` is only checked for four matrix entries; nothing
applies it to a point. The two are the same gap: the 4×4 path is constructed
but never exercised.

**G8 — `inverse` has no singular-matrix test.** A zero pivot divides straight
through, and the result is `nan`-filled with no signal. Related: `inverse` is
verified by round-trip at 3×3 and by value at 2×2, but never against a matrix
requiring the partial-pivot row swap, so the swap loop is unproven.

## Proposed work

Ordered, commit-sized. Each leaves the suite green. No new files — every item
adds to an existing one, per the runtime-cost constraint.

**W1 — Fix `Rectangle.overlaps(Rectangle)` to inclusive, then pin the contact
semantics of `overlaps[A, B]` against the concrete methods.** One commit,
source before tests:

1. `src/create/math/geometry.mojo`: change `Rectangle.overlaps(Rectangle)`
   from strict `<`/`>` to `<=`/`>=` (see G2's resolution — touching counts as
   overlap everywhere, matching every `contains`).
2. `tests/math/test_geometry.mojo`: `test_rect_touching_edges_do_not_overlap`
   now asserts the wrong thing — rename it (e.g.
   `test_rect_touching_edges_overlap`) and flip its assertion to `True`.
3. Same file: for each pair the library supports (rect-rect, circle-circle,
   rect-circle, circle-rect, triangle-triangle), assert that `overlaps(a, b)`,
   `overlaps(b, a)` and `a.overlaps(b)` agree, over a small table of
   clearly-separated, clearly-overlapping, and exactly-touching
   configurations. With step 1 landed, all rows — including the rect-rect
   touching row that used to contradict — are expected to pass; if any
   touching-pair row still disagrees, that is a new instance of G1 to fix
   before this commit closes, not a reason to weaken the assertion.

**W2 — Assert symmetry of `overlaps[A, B]` on asymmetric shape pairs.**
`test_geometry.mojo`. Long thin rectangle against a triangle, circle against a
triangle, in configurations where neither centre lies inside the other shape —
`overlaps(a, b) == overlaps(b, a)` for each. The generic reads `a`'s centre and
`b`'s surface, so this is the property most likely to be violated and the one a
user relying on the trait would assume.

**W3 — State the degenerate-input contract for `util`.** `test_util.mojo`.
`map`/`norm` with `in_low == in_high`, `smoothstep` with `edge0 == edge1`,
`fmod(x, 0.0)`, `sign(-0.0)`. Assert the value actually promised — if the
answer is "returns nan", assert `isnan`, so the behaviour is pinned rather than
undefined. This is the cheapest way to raise axis 3 off the floor.

**W4 — State the degenerate-input contract for the vectors.**
`test_vector2.mojo` and `test_vector3.mojo`. `Vector2.zero().normalize()` and
the `Vector3` equivalent; division by zero via `__truediv__` and `__itruediv__`.
Same rule as W3: assert what is promised, don't assert "it didn't crash". If
the decision is that `normalize` should return zero for a zero vector rather
than `nan`, this test is where that decision lands, and it will fail until the
implementation follows — which is the correct order.

**W5 — Golden vectors for `Random`.** `test_random.mojo`. Record the first
eight `_next()`-derived outputs for a fixed seed (via `float()` and `int()`)
and assert them exactly. Closes G4: any change to SplitMix64 seeding or the
xoroshiro128+ step fails loudly instead of staying "deterministic".

**W6 — Fix `Random.float()` to half-open, then pin the interval contract.**
One commit, source before tests:

1. `src/create/math/random.mojo`: change `float()`'s divisor from
   `Float64(UInt64.MAX)` to `Float64(UInt64.MAX) + 1.0` (see G5's resolution
   — half-open `[0,1)`, matching `int(low, high)`'s existing convention).
2. `test_random.mojo`: tighten `test_float_in_unit_interval` and
   `test_float_range`'s upper-bound checks from `<=` to `<`; state that
   `int(lo, hi)` is half-open as an explicit contract, not just an implied
   property of `test_int_range`. Land after W5 (golden vectors), or update
   W5's recorded values to the post-fix divisor — not the current one, or the
   golden vectors will pin the wrong contract.

**W7 — Strengthen `test_random`'s distribution checks.** `test_random.mojo`.
Replace the abort-on-first-bad-draw loops with an accumulate-then-assert shape
that reports how many draws fell out of range and, for `bool`, asserts the
count against a stated tolerance rather than a bare band. Raises axis 7 for the
one file that scores below the others.

**W8 — Cover the mixed-`Tuple` constructors.** `test_vector2.mojo` and
`test_vector3.mojo`. One assertion per untested ctor, checking both components
land in the right field with distinct values (never `(1, 1)`). Seven small
assertions; closes G6 outright.

**W9 — Cover the 4×4 `apply` and give `perspective` an effect test.**
`test_matrix.mojo`. Apply a known 4×4 to a point and assert the result
including the `ow` divide; then push a point through `perspective` and assert
the projected coordinates, so the constructor is verified by behaviour and not
only by four entries.

**W10 — Singular and pivot-swapping matrices for `inverse`.**
`test_matrix.mojo`. A matrix whose first pivot is zero, so the partial-pivot
row swap must run for the round-trip to hold — this proves the swap loop. Then
a genuinely singular matrix, asserting whatever the decided contract is.

**W11 — Degenerate geometry.** `test_geometry.mojo`. A zero-length `Line`
(`intersects` against anything, and `length == 0`), a `Triangle` with three
collinear vertices (`contains`, `closest_point`, `overlaps`), and a `Circle`
with `r == 0`. `_closest_on_segment` has an explicit `len_sq == 0.0` branch
that nothing currently reaches; this is the test that reaches it.

**W12 — Cover `Matrix.__init__(*, copy:)` and `write_to`, and `Random()`.**
`test_matrix.mojo` and `test_random.mojo`. Copy a matrix, mutate the original,
assert the copy is unchanged — that is the behaviour worth protecting, not the
constructor's existence. For `Random()`, construct two instances and assert
they produce different streams; that is all the entropy ctor promises.

## Out of scope / untestable

- **`_rotl` and `_next`.** Private, and W5's golden vectors pin them through
  the public surface, which is the right level.
- **Modulo bias in `Random.int`.** Real but not practically assertable — the
  bias for typical ranges is far below what any sample size in a 32-second
  suite could detect. Note it in the source, don't test it.
- **`debug_assert` in `Random.int`.** Compiled out in release, so a test cannot
  observe it in the configuration the suite runs. `rng.int(5, 5)` reaching
  `% 0` is a real hazard but not one a test can safely provoke.
- **Floating-point associativity across platforms.** The suite already uses
  `assert_almost_equal` with explicit `atol` wherever it matters; do not add
  exact-equality assertions to transcendental results.
