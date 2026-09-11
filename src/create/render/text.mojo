from std.math import max
from .align import HAlign, VAlign
from .color import Color
from .font import Font, GlyphInfo, FONT_DEFAULT_PATH, FONT_FALLBACK_PATH
from .raster import blit_glyph
from .style import Style
from .surface import Surface


struct TextRenderer(Movable):
    """Font ownership and glyph layout, kept out of the drawing surface.

    Holds the loaded faces, so it is the other half of what has to survive a
    frame: reloading a font every frame would be absurd. Lays a string out in
    pixel space and hands each glyph's coverage mask to the rasteriser.
    """

    var _font: List[Font]
    var _fallback_font: List[Font]
    var _fallback_attempted: Bool

    def __init__(out self):
        self._font = List[Font]()
        self._fallback_font = List[Font]()
        self._fallback_attempted = False

    def set_font(mut self, var f: Font):
        self._font = List[Font]()
        self._font.append(f^)

    def _ensure_font(mut self, size: Int) raises:
        """Lazily load the packaged default/fallback fonts on first use.

        Construction never touches disk — a program that draws no text pays no
        freetype cost and can't fail on a missing default. The fallback load is
        attempted at most once; a missing fallback file just means no fallback
        glyphs, not a draw failure.
        """
        if len(self._font) == 0:
            self._font.append(Font(FONT_DEFAULT_PATH, size))
        if not self._fallback_attempted:
            self._fallback_attempted = True
            try:
                self._fallback_font.append(Font(FONT_FALLBACK_PATH, size))
            except:
                pass

    def _glyph(mut self, codepoint: Int, size: Int) raises -> GlyphInfo:
        """Render one glyph, falling back for codepoints the main face lacks."""
        if len(self._fallback_font) > 0 and not self._font[0].has_glyph(
            codepoint
        ):
            return self._fallback_font[0].render(codepoint, size)
        return self._font[0].render(codepoint, size)

    def draw[
        o: Origin[mut=True]
    ](
        mut self,
        surf: Surface[o],
        s: String,
        tx: Float64,
        ty: Float64,
        style: Style,
        pixel_scale: Float64,
    ) raises:
        """Lay `s` out around the already-mapped anchor `(tx, ty)` and draw it.

        The caller maps the anchor; glyphs rasterise upright in pixel space, so
        `VAlign.TOP`/`BOTTOM` keep meaning the top and bottom of the text box
        however the world axes are oriented.
        """
        var size = max(Int(Float64(style.font_size) * pixel_scale + 0.5), 1)
        self._ensure_font(size)
        self._font[0]._set_weight(style.font_weight)
        var c = style.fill

        # Two-pass: measure total advance for alignment, then render.
        # First pass: measure (iterate codepoints for correct Unicode handling)
        var tw = 0
        for cp in s.codepoints():
            tw += self._glyph(Int(cp), size).advance_x

        var draw_x = Int(tx)
        var draw_y = Int(ty)
        if style.text_halign == HAlign.CENTER:
            draw_x -= tw // 2
        elif style.text_halign == HAlign.RIGHT:
            draw_x -= tw

        var asc = self._font[0].ascender
        var desc = self._font[0].descender
        var baseline_y = draw_y
        if style.text_valign == VAlign.TOP:
            baseline_y += asc
        elif style.text_valign == VAlign.MIDDLE:
            baseline_y += (asc + desc) // 2
        elif style.text_valign == VAlign.BOTTOM:
            baseline_y += desc

        # Second pass: render
        var cx = draw_x
        for cp in s.codepoints():
            var g = self._glyph(Int(cp), size)
            if g.width > 0 and g.height > 0:
                blit_glyph(
                    surf, g, cx + g.bearing_x, baseline_y - g.bearing_y, c
                )
            cx += g.advance_x
