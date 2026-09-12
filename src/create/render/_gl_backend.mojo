"""The GPU half of `Backend` — a frame's commands as batched `glDrawArrays`.

The split with `_tessellate.mojo` is deliberate and load-bearing: *where* a
triangle goes is arithmetic and is decided there, testable with no context and
no GPU; this file is only the GL plumbing that uploads and draws it. Nothing
here decides geometry.

**One batch spans as many commands as it can.** The vertex buffer accumulates
across commands and is flushed only when something makes a shared draw call
impossible — today an opaque `CMD_CLEAR` (which resets the framebuffer, so
earlier vertices must already have landed) and the end of the frame; a texture
switch. That is the whole point of baking the
transform per vertex rather than passing it as a uniform: a per-command
uniform would force a draw call per command and there would be no batching to
speak of.

**Clearing follows the CPU replay rather than the obvious GL call.**
`_raster.fill_all` *composites* — a `background` with `a < 255` blends over
what was already drawn — so only an opaque clear becomes `glClear`. A
translucent one is a full-drawable quad in the batch, which blends, and an
`a == 0` one draws nothing at all.
"""

from std.collections import Dict, Optional

from ._command import (
    CMD_CIRCLE,
    CMD_CLEAR,
    CMD_LETTERBOX,
    CMD_LINE,
    CMD_RECT,
    CMD_SPRITE,
    CMD_TRIANGLE,
    DrawCommand,
)
from ._gl import (
    GL,
    GL_ARRAY_BUFFER,
    GL_BLEND,
    GL_CLAMP_TO_EDGE,
    GL_COLOR_BUFFER_BIT,
    GL_COMPILE_STATUS,
    GL_FALSE,
    GL_FLOAT,
    GL_FRAGMENT_SHADER,
    GL_INFO_LOG_LENGTH,
    GL_LINEAR,
    GL_LINK_STATUS,
    GL_MULTISAMPLE,
    GL_ONE_MINUS_SRC_ALPHA,
    GL_R8,
    GL_RGBA,
    GL_RGBA8,
    GL_RED,
    GL_SRC_ALPHA,
    GL_STREAM_DRAW,
    GL_TEXTURE0,
    GL_TEXTURE_2D,
    GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_MIN_FILTER,
    GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T,
    GL_TRIANGLES,
    GL_UNPACK_ALIGNMENT,
    GL_UNSIGNED_BYTE,
    GL_VERTEX_SHADER,
    _Bytes,
    _Address,
    _Ints,
    _Strings,
    _UInts,
)
from ._image import _Image
from ._tessellate import (
    MODE_SOLID,
    VertexBuffer,
    emit_circle,
    emit_letterbox,
    emit_line,
    emit_rect,
    emit_sprite,
    emit_triangle,
)
from .color import Color

comptime _VERTEX_FLOATS = 9
"""Mirrors `_tessellate._VERTEX_FLOATS`, which the attribute layout below
unpacks into four attributes."""

comptime ATLAS_SIZE = 1024
"""The glyph atlas is square and fixed: a resize would have to re-pack and
re-upload every glyph mid-frame, and a face large enough to overflow a
megatexel of coverage is past what this backend is for."""


comptime _VERTEX_SHADER = String(
    """#version 330 core
layout (location = 0) in vec2 a_pos;
layout (location = 1) in vec2 a_uv;
layout (location = 2) in vec4 a_color;
layout (location = 3) in float a_mode;

uniform vec2 u_viewport;

out vec2 v_uv;
out vec4 v_color;
out float v_mode;

void main() {
    // Device pixels, y down, to NDC. The y flip is here rather than in the
    // tessellator so vertices stay in the same space the CPU replay scans.
    vec2 ndc = vec2(
        a_pos.x / u_viewport.x * 2.0 - 1.0,
        1.0 - a_pos.y / u_viewport.y * 2.0
    );
    gl_Position = vec4(ndc, 0.0, 1.0);
    v_uv = a_uv;
    v_color = a_color;
    v_mode = a_mode;
}
"""
)

comptime _FRAGMENT_SHADER = String(
    """#version 330 core
in vec2 v_uv;
in vec4 v_color;
in float v_mode;

uniform sampler2D u_texture;

out vec4 frag_color;

void main() {
    if (v_mode < 0.5) {
        frag_color = v_color;
    } else if (v_mode < 1.5) {
        frag_color = vec4(v_color.rgb, v_color.a * texture(u_texture, v_uv).r);
    } else {
        frag_color = v_color * texture(u_texture, v_uv);
    }
}
"""
)


def _gen_object(gen: def (Int32, _UInts) thin abi("C") -> None) -> UInt32:
    """One GL object name, read back off the heap.

    Rule 2 from `_gl.mojo`: the name is a C out-parameter, so it comes back
    through a `List` rather than a local array.
    """
    var buf = List[UInt32](length=1, fill=0)
    gen(1, _UInts(unsafe_from_address=Int(buf.unsafe_ptr())))
    return buf[0]


def _delete_object(
    delete: def (Int32, _UInts) thin abi("C") -> None, name: UInt32
):
    var buf = List[UInt32](length=1, fill=name)
    delete(1, _UInts(unsafe_from_address=Int(buf.unsafe_ptr())))
    _ = buf^


def _info_log(
    length: Int,
    get: def (UInt32, Int32, _Address, _Bytes) thin abi("C") -> None,
    name: UInt32,
) -> String:
    if length <= 0:
        return String("(no log)")
    var buf = List[UInt8](length=length + 1, fill=0)
    get(name, Int32(length), 0, _Bytes(unsafe_from_address=Int(buf.unsafe_ptr())))
    var out = String(unsafe_from_utf8_ptr=buf.unsafe_ptr())
    _ = buf^
    return out^


def _compile(gl: GL, kind: UInt32, src: String) raises -> UInt32:
    """One compiled shader, or an error carrying the driver's log.

    The source is passed NUL-terminated with a null length array, and
    `_ = src` keeps it alive across the call — rule 1.
    """
    var shader = gl.create_shader(kind)
    var ptrs = List[_Bytes](
        length=1, fill=_Bytes(unsafe_from_address=Int(src.unsafe_ptr()))
    )
    gl.shader_source(
        shader,
        1,
        _Strings(unsafe_from_address=Int(ptrs.unsafe_ptr())),
        0,
    )
    _ = ptrs^
    _ = src
    gl.compile_shader(shader)

    var status = List[Int32](length=1, fill=0)
    gl.get_shaderiv(
        shader,
        GL_COMPILE_STATUS,
        _Ints(unsafe_from_address=Int(status.unsafe_ptr())),
    )
    if status[0] == 0:
        var length = List[Int32](length=1, fill=0)
        gl.get_shaderiv(
            shader,
            GL_INFO_LOG_LENGTH,
            _Ints(unsafe_from_address=Int(length.unsafe_ptr())),
        )
        var log = _info_log(
            Int(length[0]), gl.get_shader_info_log, shader
        )
        gl.delete_shader(shader)
        raise Error("GL shader failed to compile: " + log)
    return shader

def _link(gl: GL) raises -> UInt32:
    var vertex = _compile(gl, GL_VERTEX_SHADER, _VERTEX_SHADER)
    var fragment = _compile(gl, GL_FRAGMENT_SHADER, _FRAGMENT_SHADER)
    var program = gl.create_program()
    gl.attach_shader(program, vertex)
    gl.attach_shader(program, fragment)
    gl.link_program(program)
    # Attached shaders are freed with the program once it is linked.
    gl.delete_shader(vertex)
    gl.delete_shader(fragment)

    var status = List[Int32](length=1, fill=0)
    gl.get_programiv(
        program,
        GL_LINK_STATUS,
        _Ints(unsafe_from_address=Int(status.unsafe_ptr())),
    )
    if status[0] == 0:
        var length = List[Int32](length=1, fill=0)
        gl.get_programiv(
            program,
            GL_INFO_LOG_LENGTH,
            _Ints(unsafe_from_address=Int(length.unsafe_ptr())),
        )
        var log = _info_log(
            Int(length[0]), gl.get_program_info_log, program
        )
        gl.delete_program(program)
        raise Error("GL shader program failed to link: " + log)
    return program


struct GLRenderer(Movable):
    """Everything the GPU path owns: the entry points, one VAO/VBO, the shader
    program, the glyph atlas, and the vertex buffer they are fed from.

    Constructing one requires a current GL context — `GL()` does — so it is
    built by the GL run loop after the window, never eagerly.
    """

    var gl: GL
    var vao: UInt32
    var vbo: UInt32
    var vbo_bytes: Int
    """Capacity of the VBO's current allocation, so a steady frame reuploads
    into it with `glBufferSubData` instead of reallocating."""
    var program: UInt32
    var u_viewport: Int32
    var u_texture: Int32
    var atlas: UInt32
    var textures: Dict[Int, UInt32]
    """Backend image id to GL texture name. The id is already the interning
    key on `Backend.images`, so a sprite drawn a thousand times is one entry
    and one upload; the pixels are read from the `_Image` only the first
    time."""
    var bound: UInt32
    """What is on texture unit 0 right now. A batch is one `glDrawArrays`
    against one sampler, so changing this has to flush first."""
    var vertices: VertexBuffer
    var draw_calls: Int
    """Batches flushed by the last `draw`. Read by the bench example and the
    Phase 8 performance work; it costs one increment a batch."""

    def __init__(out self) raises:
        self.gl = GL()
        self.program = _link(self.gl)
        self.vao = _gen_object(self.gl.gen_vertex_arrays)
        self.vbo = _gen_object(self.gl.gen_buffers)
        self.vbo_bytes = 0
        self.atlas = _gen_object(self.gl.gen_textures)
        self.textures = Dict[Int, UInt32]()
        self.bound = 0
        self.vertices = VertexBuffer()
        self.draw_calls = 0

        var name = String("u_viewport")
        self.u_viewport = self.gl.get_uniform_location(
            self.program, _Bytes(unsafe_from_address=Int(name.unsafe_ptr()))
        )
        _ = name
        var tex_name = String("u_texture")
        self.u_texture = self.gl.get_uniform_location(
            self.program, _Bytes(unsafe_from_address=Int(tex_name.unsafe_ptr()))
        )
        _ = tex_name

        self._setup_vertex_array()
        self._setup_atlas()

        self.gl.enable(GL_BLEND)
        # Straight (non-premultiplied) alpha, matching `_raster.blend`, so a
        # translucent fill composites identically on both backends.
        self.gl.blend_func(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
        self.gl.enable(GL_MULTISAMPLE)
        self.gl.check("initialising the GL renderer")

    def __deinit__(deinit self):
        self.gl.delete_program(self.program)
        _delete_object(self.gl.delete_buffers, self.vbo)
        _delete_object(self.gl.delete_vertex_arrays, self.vao)
        _delete_object(self.gl.delete_textures, self.atlas)
        for ref entry in self.textures.items():
            _delete_object(self.gl.delete_textures, entry.value)

    def _setup_vertex_array(mut self):
        """Bind the VAO once and record the interleaved attribute layout.

        Nothing rebinds these per frame: a VAO remembers the pointers and the
        enables, which is the whole reason to have one.
        """
        comptime stride = Int32(_VERTEX_FLOATS * 4)
        self.gl.bind_vertex_array(self.vao)
        self.gl.bind_buffer(GL_ARRAY_BUFFER, self.vbo)
        self.gl.vertex_attrib_pointer(0, 2, GL_FLOAT, GL_FALSE, stride, 0)
        self.gl.enable_vertex_attrib_array(0)
        self.gl.vertex_attrib_pointer(1, 2, GL_FLOAT, GL_FALSE, stride, 8)
        self.gl.enable_vertex_attrib_array(1)
        self.gl.vertex_attrib_pointer(2, 4, GL_FLOAT, GL_FALSE, stride, 16)
        self.gl.enable_vertex_attrib_array(2)
        self.gl.vertex_attrib_pointer(3, 1, GL_FLOAT, GL_FALSE, stride, 32)
        self.gl.enable_vertex_attrib_array(3)

    def _setup_atlas(mut self) raises:
        """A single-channel coverage atlas, blank but for its white texel.

        Glyphs are packed into it in a later phase; what it has to provide
        now is a sampler the `MODE_MASK` branch can read without undefined
        behaviour, and texel (0, 0) opaque so that branch means "no mask".
        """
        self.gl.active_texture(GL_TEXTURE0)
        self.gl.bind_texture(GL_TEXTURE_2D, self.atlas)
        # One byte per texel: the default four-byte row alignment would
        # mis-stride every upload whose width is not a multiple of four.
        self.gl.pixel_storei(GL_UNPACK_ALIGNMENT, 1)
        var blank = List[UInt8](length=ATLAS_SIZE * ATLAS_SIZE, fill=0)
        blank[0] = 255
        self.gl.tex_image_2d(
            GL_TEXTURE_2D,
            0,
            GL_R8,
            Int32(ATLAS_SIZE),
            Int32(ATLAS_SIZE),
            0,
            GL_RED,
            GL_UNSIGNED_BYTE,
            Int(blank.unsafe_ptr()),
        )
        _ = blank^
        self.gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        self.gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        self.gl.tex_parameteri(
            GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE
        )
        self.gl.tex_parameteri(
            GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE
        )

    def draw(
        mut self,
        cmds: List[DrawCommand],
        images: Dict[Int, _Image],
        width: Int,
        height: Int,
        scale: Float64,
    ) raises:
        """Replay `cmds` onto the current drawable, `width` x `height` pixels.

        `width`/`height` are the *drawable's*, not the viewport's — under
        display scaling the two differ, and the letterbox bars have to reach
        the real edge of the frame.
        """
        self.gl.viewport(0, 0, Int32(width), Int32(height))
        self.gl.use_program(self.program)
        self.gl.bind_vertex_array(self.vao)
        self.gl.uniform_2f(
            self.u_viewport, Float32(width), Float32(height)
        )
        self.gl.uniform_1i(self.u_texture, 0)
        self.gl.active_texture(GL_TEXTURE0)
        self.bound = 0
        self._bind(self.atlas)

        self.vertices.clear()
        self.draw_calls = 0
        for ref c in cmds:
            if c.kind == CMD_CLEAR:
                self._clear(c.style.fill, width, height)
            elif c.kind == CMD_RECT:
                emit_rect(self.vertices, c, scale)
            elif c.kind == CMD_CIRCLE:
                emit_circle(self.vertices, c, scale)
            elif c.kind == CMD_LINE:
                emit_line(self.vertices, c, scale)
            elif c.kind == CMD_TRIANGLE:
                emit_triangle(self.vertices, c, scale)
            elif c.kind == CMD_SPRITE:
                self._sprite(c, images, scale)
            elif c.kind == CMD_LETTERBOX:
                # Bars are solid, but they must land over whatever texture is
                # bound, so no rebind here — `MODE_SOLID` never samples.
                emit_letterbox(self.vertices, c, width, height)
        self._flush()

    def _bind(mut self, name: UInt32) raises:
        """Put `name` on unit 0, flushing first if that changes the sampler."""
        if name == self.bound:
            return
        self._flush()
        self.gl.bind_texture(GL_TEXTURE_2D, name)
        self.bound = name

    def _sprite(
        mut self, c: DrawCommand, images: Dict[Int, _Image], scale: Float64
    ) raises:
        if c.image not in images:
            return
        self._bind(self._texture(c.image, images))
        emit_sprite(self.vertices, c, scale)

    def _texture(
        mut self, id: Int, images: Dict[Int, _Image]
    ) raises -> UInt32:
        """The GL texture for a backend image id, uploaded on first use."""
        if id in self.textures:
            return self.textures[id]
        ref img = images[id]
        var name = _gen_object(self.gl.gen_textures)
        self.gl.bind_texture(GL_TEXTURE_2D, name)
        self.gl.pixel_storei(GL_UNPACK_ALIGNMENT, 1)
        self.gl.tex_image_2d(
            GL_TEXTURE_2D,
            0,
            GL_RGBA8,
            Int32(img.width),
            Int32(img.height),
            0,
            GL_RGBA,
            GL_UNSIGNED_BYTE,
            Int(img.pixels.unsafe_ptr()),
        )
        self.gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        self.gl.tex_parameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        self.gl.tex_parameteri(
            GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE
        )
        self.gl.tex_parameteri(
            GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE
        )
        # The bind above went behind `_bind`'s back; tell it what is current.
        self.bound = name
        self.textures[id] = name
        return name

    def _clear(mut self, color: Color, width: Int, height: Int) raises:
        """`CMD_CLEAR`, composited the way the CPU replay composites it."""
        if color.a == 0:
            return
        if color.a == 255:
            # Opaque: the cheap path, but it wipes the framebuffer, so
            # anything already batched has to land first.
            self._flush()
            self.gl.clear_color(
                Float32(Int(color.r)) / 255.0,
                Float32(Int(color.g)) / 255.0,
                Float32(Int(color.b)) / 255.0,
                1.0,
            )
            self.gl.clear(GL_COLOR_BUFFER_BIT)
            return
        var w = Float64(width)
        var h = Float64(height)
        self.vertices.quad(0.0, 0.0, w, 0.0, w, h, 0.0, h, color)

    def _flush(mut self) raises:
        """Upload what has accumulated and draw it as one batch."""
        var count = self.vertices.count()
        if count == 0:
            return
        var size = len(self.vertices.data) * 4
        var src = Int(self.vertices.data.unsafe_ptr())
        self.gl.bind_buffer(GL_ARRAY_BUFFER, self.vbo)
        if size > self.vbo_bytes:
            self.gl.buffer_data(
                GL_ARRAY_BUFFER, Int64(size), src, GL_STREAM_DRAW
            )
            self.vbo_bytes = size
        else:
            # Orphan the old storage so the driver need not stall waiting for
            # the previous frame's draw to finish reading it.
            self.gl.buffer_data(
                GL_ARRAY_BUFFER, Int64(self.vbo_bytes), 0, GL_STREAM_DRAW
            )
            self.gl.buffer_sub_data(
                GL_ARRAY_BUFFER,
                0,
                Int64(size),
                _Bytes(unsafe_from_address=src),
            )
        self.gl.draw_arrays(GL_TRIANGLES, 0, Int32(count))
        self.vertices.clear()
        self.draw_calls += 1
