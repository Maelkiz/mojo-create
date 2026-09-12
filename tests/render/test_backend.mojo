# The CPU backend replays a recorded command list onto a Surface. These tests
# hand-build the list — no Canvas involved — so they check the replay itself,
# and the last one pins it against the Canvas output it has to reproduce.

from std.math import pi
from std.testing import TestSuite, assert_equal, assert_true

from create import *
from create.core.headless import run_headless
from create.render.surface import MemorySurface
from create.render.viewport import Viewport
from create.render._style import Style
from create.render._backend import Backend
from create.render._command import (
    DrawCommand,
    clear_command,
    rect_command,
    circle_command,
    line_command,
    triangle_command,
    sprite_command,
    text_command,
    letterbox_command,
)


comptime _W = 100
comptime _H = 100


def _base(width: Int = _W, height: Int = _H) -> Matrix[3, 3]:
    """The same world-to-pixel mapping a 1:1 frame gets, taken from `Viewport`
    rather than rebuilt, so a change there cannot silently desync these."""
    var v = Viewport()
    v.set_design(width, height)
    v.set_size(width, height)
    return v.base_matrix()


def _solid(fill: Color) -> Style:
    var s = Style()
    s.fill = fill
    s.fill_enabled = True
    s.stroke_enabled = False
    return s^


def _replay(cmds: List[DrawCommand]) raises -> MemorySurface:
    var mem = MemorySurface(_W, _H)
    var backend = Backend()
    backend.replay(mem.surface(), cmds, 1.0)
    return mem^


def test_clear_covers_every_pixel() raises -> None:
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color(10, 20, 30)))
    var m = _replay(cmds)
    assert_equal(m.pixel(0, 0), Color(10, 20, 30))
    assert_equal(m.pixel(_W - 1, _H - 1), Color(10, 20, 30))
    assert_equal(m.pixel(50, 50), Color(10, 20, 30))


def test_rect_replays_centred_and_y_up() raises -> None:
    # A 20x20 rect at the world origin covers pixels [40, 60) on both axes —
    # the same centring promise the Canvas tests assert.
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(rect_command(_base(), _solid(Color.RED), 0.0, 0.0, 20.0, 20.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.RED)
    assert_equal(m.pixel(41, 41), Color.RED)
    assert_equal(m.pixel(58, 58), Color.RED)
    assert_equal(m.pixel(30, 50), Color.BLACK)
    assert_equal(m.pixel(50, 30), Color.BLACK)


def test_rect_above_the_origin_lands_above_it() raises -> None:
    # Positive world y is a smaller pixel row. A y-down replay would paint the
    # mirror of this and every other assertion here would still pass.
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(rect_command(_base(), _solid(Color.RED), 0.0, 20.0, 10.0, 10.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 30), Color.RED)
    assert_equal(m.pixel(50, 70), Color.BLACK)


def test_rect_stroke_frames_the_fill() raises -> None:
    var st = _solid(Color.RED)
    st.stroke_enabled = True
    st.stroke = Color.BLUE
    st.stroke_width = 2
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(rect_command(_base(), st, 0.0, 0.0, 20.0, 20.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(41, 50), Color.BLUE)
    assert_equal(m.pixel(50, 50), Color.RED)


def test_circle_replays_round() raises -> None:
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(circle_command(_base(), _solid(Color.GREEN), 0.0, 0.0, 20.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.GREEN)
    assert_equal(m.pixel(50, 35), Color.GREEN)
    # The corner of the bounding box is outside the disc.
    assert_equal(m.pixel(35, 35), Color.BLACK)


def test_line_replays_between_its_endpoints() raises -> None:
    var st = Style()
    st.fill_enabled = False
    st.stroke_enabled = True
    st.stroke = Color.WHITE
    st.stroke_width = 1
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(line_command(_base(), st, -20.0, 0.0, 20.0, 0.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.WHITE)
    assert_equal(m.pixel(35, 50), Color.WHITE)
    assert_equal(m.pixel(50, 40), Color.BLACK)


def test_line_with_stroke_disabled_draws_nothing() raises -> None:
    var st = Style()
    st.stroke_enabled = False
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(line_command(_base(), st, -20.0, 0.0, 20.0, 0.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.BLACK)


def test_triangle_replays_inside_only() raises -> None:
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(
        triangle_command(
            _base(), _solid(Color.RED), 0.0, 20.0, -20.0, -20.0, 20.0, -20.0
        )
    )
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 60), Color.RED)
    # Outside the sloping edge, still inside the bounding box.
    assert_equal(m.pixel(32, 33), Color.BLACK)


def test_sprite_replays_from_an_interned_image() raises -> None:
    # Two pixels: red left, blue right. Interning copies them into the backend,
    # so the command only ever carries the id.
    var src = List[UInt8](length=8, fill=0)
    src[0] = 255
    src[3] = 255
    src[6] = 255
    src[7] = 255
    var mem = MemorySurface(_W, _H)
    var backend = Backend()
    var id = backend.intern_image(7, src.unsafe_ptr(), 2, 1)
    assert_equal(id, 7)

    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(
        sprite_command(_base(), Style(), 0.0, 0.0, 20.0, 10.0, id, 2, 1)
    )
    backend.replay(mem.surface(), cmds, 1.0)
    assert_equal(mem.pixel(45, 50), Color.RED)
    assert_equal(mem.pixel(55, 50), Color.BLUE)


def test_interning_the_same_key_twice_reuses_the_copy() raises -> None:
    var src = List[UInt8](length=4, fill=255)
    var backend = Backend()
    var a = backend.intern_image(3, src.unsafe_ptr(), 1, 1)
    var b = backend.intern_image(3, src.unsafe_ptr(), 1, 1)
    assert_equal(a, b)
    assert_equal(len(backend.images), 1)


def test_sprite_with_an_unknown_image_is_skipped() raises -> None:
    # A command referring to an id the backend never interned must be dropped,
    # not read out of bounds.
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(
        sprite_command(_base(), Style(), 0.0, 0.0, 20.0, 10.0, 999, 2, 1)
    )
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.BLACK)


def test_text_replays_through_the_backend_font() raises -> None:
    # Layout happens here, at replay, in the backend that owns the font — the
    # command carried nothing but the string and its anchor.
    var st = _solid(Color.WHITE)
    st.font_size = 24
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(text_command(_base(), st, -40.0, 0.0, String("III")))
    var m = _replay(cmds)
    var lit = 0
    for y in range(_H):
        for x in range(_W):
            if m.pixel(x, y) != Color.BLACK:
                lit += 1
    assert_true(lit > 0, "text drew no pixels")


def test_text_with_fill_disabled_draws_nothing() raises -> None:
    var st = Style()
    st.fill_enabled = False
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(text_command(_base(), st, -40.0, 0.0, String("III")))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.BLACK)


def test_letterbox_paints_outside_the_device_content_rect() raises -> None:
    # The one command whose geometry is already device pixels.
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.RED))
    cmds.append(letterbox_command(Color.BLUE, 10.0, 20.0, 90.0, 80.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.RED)
    assert_equal(m.pixel(50, 10), Color.BLUE)
    assert_equal(m.pixel(50, 90), Color.BLUE)
    assert_equal(m.pixel(5, 50), Color.BLUE)
    assert_equal(m.pixel(95, 50), Color.BLUE)


def test_commands_replay_in_order() raises -> None:
    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(rect_command(_base(), _solid(Color.RED), 0.0, 0.0, 40.0, 40.0))
    cmds.append(rect_command(_base(), _solid(Color.BLUE), 0.0, 0.0, 20.0, 20.0))
    var m = _replay(cmds)
    assert_equal(m.pixel(50, 50), Color.BLUE)
    assert_equal(m.pixel(35, 50), Color.RED)


comptime _ANGLE = 0.4
comptime _RECT_W = 34.0
comptime _RECT_H = 18.0


struct RotatedRect(Program):
    """The Canvas side of the equivalence check below."""

    var _unused: Int

    @staticmethod
    def create(mut ctx: Context) raises -> RotatedRect:
        return RotatedRect(0)

    def __init__(out self, unused: Int):
        self._unused = unused

    def render(self, mut canvas: Canvas) raises:
        canvas.background(Color.BLACK)
        canvas.no_stroke()
        canvas.fill(Color.RED)
        with canvas.transform(rotate(_ANGLE)):
            canvas.rectangle(12.0, 6.0, _RECT_W, _RECT_H)


def test_a_rotated_rect_replays_identically_to_canvas() raises -> None:
    # Rotation defeats the axis-aligned fast path, so this is the per-pixel
    # inverse-mapping route — the one the command buffer most has to preserve,
    # since a pre-mapped device rect could not express it at all.
    var want = run_headless[RotatedRect](_W, _H)

    var cmds = List[DrawCommand]()
    cmds.append(clear_command(Color.BLACK))
    cmds.append(
        rect_command(
            _base() @ rotate(_ANGLE),
            _solid(Color.RED),
            12.0,
            6.0,
            _RECT_W,
            _RECT_H,
        )
    )
    var got = _replay(cmds)

    for y in range(_H):
        for x in range(_W):
            assert_equal(
                got.pixel(x, y),
                want.pixel(x, y),
                "pixel " + String(x) + "," + String(y),
            )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
