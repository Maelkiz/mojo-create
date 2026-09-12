"""One frame, drawn twice, compared pixel by pixel.

The CPU replay is the reference implementation — every geometry decision the
GL path makes exists to agree with it — and `tests/render/test_tessellate.mojo`
only checks the arithmetic that leads up to a triangle. This is the other half:
that the triangle, once rasterised by a driver, lands where the CPU put it.

**Why the tolerance is not zero.** Two rasterisers cannot agree exactly and
neither is wrong for it:

- coverage is integer arithmetic in `_raster.blend` and float arithmetic in the
  fragment shader, so a blended pixel can differ by a unit in the last place;
- an edge that falls between two pixel centres is claimed by the CPU's
  fill rule or by the GPU's, and the two rules are not the same rule — so a
  one-pixel-wide seam along every shape boundary is expected;
- a glyph's coverage multiplies the fill alpha on both sides, but in a
  different order and precision.

So the test asserts two things instead, chosen because a real divergence
breaks them and rounding cannot. The mean absolute channel error catches a
wrong colour or a missing command. Comparing the two frames' drawn-on masks
with a one-pixel slack catches a displacement: the slack is exactly the
disagreement the fill rules are entitled to, and anything beyond it is a shape
somewhere the other backend did not put one. Both were verified by breaking an
emitter on purpose before this was committed — shifting `_mapped_quad` down two
pixels leaves the mean at 0.96 against a limit of 2.0, and strands 100 pixels
against a limit of 40.

MSAA is deliberately off: the CPU path antialiases nothing, so multisampling
would compare a smooth edge against a hard one and prove nothing about
geometry.

**It skips without a display.** There is no CI, `pixi run test` has to stay
runnable over SSH, and a GL context needs a compositor.
"""

from std.os import getenv
from std.math import abs, max
from std.testing import TestSuite, assert_true

from create import *
from create.core._frame import step
from create.core.headless import run_headless
from create.render._backend import BACKEND_GPU
from create.render._gl import (
    GL,
    GL_COLOR_ATTACHMENT0,
    GL_CLAMP_TO_EDGE,
    GL_FRAMEBUFFER,
    GL_FRAMEBUFFER_COMPLETE,
    GL_NEAREST,
    GL_PACK_ALIGNMENT,
    GL_RGBA,
    GL_RGBA8,
    GL_TEXTURE_2D,
    GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_MIN_FILTER,
    GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T,
    GL_UNSIGNED_BYTE,
    _Bytes,
    _UInts,
)
from create.render.canvas import PersistentCanvasState
from window import GLWindow

comptime _DESIGN_W = 200
comptime _DESIGN_H = 150
comptime _PIXEL_W = 240
"""Wider than the design, so `FIT` leaves a letterbox bar on each side while
the scale factor stays exactly 1 — a resampled sprite would be comparing two
interpolation rules rather than two backends."""
comptime _PIXEL_H = 150

comptime _MEAN_ERROR_LIMIT = 2.0
"""Mean absolute channel error over the frame, out of 255.

Loose on purpose: this one catches a wrong *colour* or a missing command, not
a small displacement — a shape moved by a pixel or two barely moves a mean
taken over 36000 pixels. Displacement is what `_unmatched` is for.
"""

comptime _BACKGROUND = Color(0x20, 0x30, 0x40)
comptime _INK_THRESHOLD = 8
"""How far from the background a pixel has to be to count as drawn on."""
comptime _STRAY_LIMIT = 40
"""Pixels either frame may draw on further than one pixel from anything the
other drew. The tight one: a displaced shape strands its whole edge."""


@fieldwise_init
struct _Parity(Program):
    """Every command kind the GL backend implements, in one frame."""

    var logo: Sprite

    @staticmethod
    def create(mut ctx: Context) raises -> _Parity:
        ctx.autoscale = AutoScale.FIT
        ctx.design(_DESIGN_W, _DESIGN_H)
        return _Parity(Sprite.load("tests/fixtures/test_2x2.png"))

    def render(self, mut canvas: Canvas) raises:
        canvas.background(_BACKGROUND)

        with canvas.style():
            canvas.no_stroke()
            canvas.fill(Color(0xE0, 0x40, 0x40))
            canvas.rectangle((-60, 40), 50, 30)

        with canvas.style():
            canvas.fill(Color(0x40, 0xC0, 0xE0))
            canvas.stroke(Color.BLACK)
            canvas.stroke_width(4)
            canvas.rectangle((10, 40), 50, 30)

        with canvas.style():
            canvas.no_stroke()
            canvas.fill(Color(0xF0, 0xC0, 0x30))
            canvas.circle((-60, -20), 24)

        with canvas.style():
            canvas.stroke(Color(0x80, 0xFF, 0x80))
            canvas.stroke_width(3)
            canvas.line((-90, -60), (90, -60))

        with canvas.style():
            canvas.no_stroke()
            canvas.fill(Color(0xA0, 0x60, 0xF0))
            canvas.triangle((20, -50), (70, -50), (45, -5))

        # Native size: at a scale of 1 neither backend resamples, so this is
        # testing the blit, not the filter.
        canvas.sprite(self.logo, 70, 50, 2, 2)

        with canvas.style():
            canvas.no_stroke()
            canvas.fill(Color.WHITE)
            canvas.font_size(16)
            canvas.text_align(HorizontalAlignment.CENTER, VerticalAlignment.MIDDLE)
            canvas.text("parity", 0, 0)


def _mask(pixels: List[UInt8]) -> List[Bool]:
    """Which pixels are not the background."""
    var m = List[Bool](length=_PIXEL_W * _PIXEL_H, fill=False)
    for i in range(_PIXEL_W * _PIXEL_H):
        var dr = Int(pixels[i * 4]) - Int(_BACKGROUND.r)
        var dg = Int(pixels[i * 4 + 1]) - Int(_BACKGROUND.g)
        var db = Int(pixels[i * 4 + 2]) - Int(_BACKGROUND.b)
        m[i] = max(max(abs(dr), abs(dg)), abs(db)) > _INK_THRESHOLD
    return m^


def _unmatched(a: List[Bool], b: List[Bool]) -> Int:
    """Pixels drawn on in `a` with nothing drawn on within one pixel in `b`.

    A one-pixel dilation is exactly the disagreement two rasterisers are
    entitled to — `device_bounds` scans a row the GPU's pixel-centre rule
    excludes, so a shape's bottom edge is routinely one row wider on the CPU —
    and allowing it here is what keeps the threshold meaningful. Anything
    further out is a shape in the wrong place, the wrong size, or missing.
    """
    var count = 0
    for y in range(_PIXEL_H):
        for x in range(_PIXEL_W):
            if not a[y * _PIXEL_W + x]:
                continue
            var near = False
            for dy in range(max(y - 1, 0), min(y + 2, _PIXEL_H)):
                for dx in range(max(x - 1, 0), min(x + 2, _PIXEL_W)):
                    if b[dy * _PIXEL_W + dx]:
                        near = True
                        break
                if near:
                    break
            if not near:
                count += 1
    return count


def _has_display() -> Bool:
    return (
        getenv("DISPLAY").byte_length() > 0
        or getenv("WAYLAND_DISPLAY").byte_length() > 0
    )


def _gpu_frame(mut win: GLWindow) raises -> List[UInt8]:
    """The same frame through the GL backend, into an offscreen RGBA target.

    A framebuffer object rather than the window's own buffer: the pixel size
    has to be exactly `_PIXEL_W` x `_PIXEL_H` for the comparison to mean
    anything, and a window manager is free to hand back a different drawable.

    Returns rows top-down, matching `MemorySurface`; `glReadPixels` hands them
    back bottom-up.
    """
    var gl = GL()
    var names = List[UInt32](length=1, fill=0)
    gl.gen_textures(1, _UInts(unsafe_from_address=Int(names.unsafe_ptr())))
    var color = names[0]
    gl.bind_texture(GL_TEXTURE_2D, color)
    var blank = List[UInt8](length=_PIXEL_W * _PIXEL_H * 4, fill=0)
    gl.tex_image_2d(
        GL_TEXTURE_2D,
        0,
        GL_RGBA8,
        Int32(_PIXEL_W),
        Int32(_PIXEL_H),
        0,
        GL_RGBA,
        GL_UNSIGNED_BYTE,
        Int(blank.unsafe_ptr()),
    )
    _ = blank^
    gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    gl.gen_framebuffers(1, _UInts(unsafe_from_address=Int(names.unsafe_ptr())))
    var fbo = names[0]
    gl.bind_framebuffer(GL_FRAMEBUFFER, fbo)
    gl.framebuffer_texture_2d(
        GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color, 0
    )
    if gl.check_framebuffer_status(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        raise Error("the offscreen framebuffer is incomplete")

    var ctx = Context()
    ctx.view.set_design(_DESIGN_W, _DESIGN_H)
    ctx.autoscale = AutoScale.FIT
    ctx._set_viewport(_PIXEL_W, _PIXEL_H)
    var program = _Parity.create(ctx)
    ctx._set_viewport(_PIXEL_W, _PIXEL_H)
    var input = Input()
    var state = PersistentCanvasState(BACKEND_GPU)
    ctx.time._start(0)
    ctx.time._tick(16)
    state = step(program, ctx, input, state^)
    state.backend.present_gpu(_PIXEL_W, _PIXEL_H, ctx.view.scale)

    var flipped = List[UInt8](length=_PIXEL_W * _PIXEL_H * 4, fill=0)
    gl.pixel_storei(GL_PACK_ALIGNMENT, 1)
    gl.read_pixels(
        0,
        0,
        Int32(_PIXEL_W),
        Int32(_PIXEL_H),
        GL_RGBA,
        GL_UNSIGNED_BYTE,
        _Bytes(unsafe_from_address=Int(flipped.unsafe_ptr())),
    )
    gl.check("reading the offscreen frame back")

    var out = List[UInt8](length=_PIXEL_W * _PIXEL_H * 4, fill=0)
    for y in range(_PIXEL_H):
        var src = (_PIXEL_H - 1 - y) * _PIXEL_W * 4
        var dst = y * _PIXEL_W * 4
        for i in range(_PIXEL_W * 4):
            out[dst + i] = flipped[src + i]

    gl.bind_framebuffer(GL_FRAMEBUFFER, 0)
    gl.delete_framebuffers(
        1, _UInts(unsafe_from_address=Int(names.unsafe_ptr()))
    )
    # Rule 3: the renderer's GL objects are freed when `state` drops, which
    # must happen while the context is still current.
    _ = state^
    _ = names^
    _ = flipped^
    return out^


def test_the_gl_backend_matches_the_cpu_backend() raises -> None:
    if not _has_display():
        print("SKIP — no DISPLAY or WAYLAND_DISPLAY, so no GL context")
        return
    var win: GLWindow
    try:
        # Tiny and never drawn into: the frame goes to an FBO, and this exists
        # only because a GL context needs a window to belong to.
        win = GLWindow("parity", 64, 64)
    except e:
        print("SKIP — no GL context:", e)
        return

    var gpu = _gpu_frame(win)
    var cpu = run_headless[_Parity](
        _DESIGN_W, _DESIGN_H, 1, _PIXEL_W, _PIXEL_H
    )

    var total = 0
    for i in range(_PIXEL_W * _PIXEL_H):
        # Alpha is skipped: the CPU buffer keeps whatever the last blend left,
        # while the GL default framebuffer's alpha is the driver's business.
        for ch in range(3):
            var a = Int(cpu.data[i * 4 + ch])
            var b = Int(gpu[i * 4 + ch])
            total += a - b if a > b else b - a

    var mean = Float64(total) / Float64(_PIXEL_W * _PIXEL_H * 3)
    assert_true(
        mean < _MEAN_ERROR_LIMIT,
        "mean channel error " + String(mean) + " exceeds the tolerance",
    )

    var cpu_mask = _mask(cpu.data)
    var gpu_mask = _mask(gpu)
    var stray = _unmatched(gpu_mask, cpu_mask)
    var missing = _unmatched(cpu_mask, gpu_mask)
    assert_true(
        stray < _STRAY_LIMIT,
        String(stray) + " GPU pixels are more than one pixel from anything"
        " the CPU drew",
    )
    assert_true(
        missing < _STRAY_LIMIT,
        String(missing) + " CPU pixels are more than one pixel from anything"
        " the GPU drew",
    )
    _ = win^


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
