"""Generate a custom launcher icon for the My Notes app.

Produces:
  - assets/icon.png            : full icon (indigo bg + note) for iOS / legacy.
  - assets/icon_foreground.png : note graphic on transparent bg for Android
                                 adaptive icons (content kept inside the safe
                                 zone), paired with a solid indigo background.
Renders at 2x then downsamples with Lanczos for crisp, anti-aliased edges.
"""

from PIL import Image, ImageDraw

S = 2048          # supersample resolution
OUT = 1024        # final output size

INDIGO_TOP = (63, 81, 181)    # Material Indigo 500
INDIGO_BOT = (40, 53, 147)    # Material Indigo 800
WHITE = (255, 255, 255)
LINE = (121, 134, 203)        # Indigo 300 (soft text lines)
GREEN = (56, 142, 60)         # Green 800 (strong contrast on white)
FOLD = (220, 226, 248)        # light tint for the folded corner
FOLD_EDGE = (171, 182, 225)


def gradient(size, top, bot):
    g = Image.new("RGB", (1, size))
    for y in range(size):
        t = y / (size - 1)
        g.putpixel((0, y), tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3)))
    return g.resize((size, size))


def draw_note(d, size, paper_frac, paper_color=WHITE, fold=True):
    """Draw the note card + check badge, centered in a `size` x `size` canvas."""
    cx = cy = size / 2
    half = size * paper_frac / 2
    left, top, right, bottom = cx - half, cy - half, cx + half, cy + half
    radius = int(size * 0.085)

    d.rounded_rectangle((left, top, right, bottom), radius=radius, fill=paper_color)

    if fold:
        f = size * 0.11
        d.polygon([(right - f, top), (right, top), (right, top + f)], fill=FOLD)
        d.line([(right - f, top), (right, top + f)],
               fill=FOLD_EDGE, width=max(2, int(size * 0.012)))

    # text lines (leave room on the right for the check badge)
    lw = int(size * 0.026)
    lx0 = left + size * 0.085
    lx1 = right - size * 0.21
    for frac in (0.355, 0.465, 0.575):
        y = size * frac
        d.rounded_rectangle((lx0, y, lx1, y + lw), radius=lw // 2, fill=LINE)

    # check badge bottom-right, overlapping the paper edge
    R = size * 0.135
    bcx = right - size * 0.035
    bcy = bottom - size * 0.035
    d.ellipse((bcx - R, bcy - R, bcx + R, bcy + R), fill=GREEN)
    cw = max(3, int(R * 0.30))
    p1 = (bcx - R * 0.45, bcy + R * 0.05)
    p2 = (bcx - R * 0.05, bcy + R * 0.45)
    p3 = (bcx + R * 0.55, bcy - R * 0.40)
    d.line([p1, p2], fill=WHITE, width=cw, joint="curve")
    d.line([p2, p3], fill=WHITE, width=cw, joint="curve")


# --- 1) Full icon: indigo gradient + note -----------------------------------
img = gradient(S, INDIGO_TOP, INDIGO_BOT).convert("RGBA")
draw = ImageDraw.Draw(img)
draw_note(draw, S, paper_frac=0.62)
img.convert("RGB").resize((OUT, OUT), Image.LANCZOS).save("assets/icon.png")

# --- 2) Adaptive foreground: note on transparent, inside the safe zone ------
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
draw2 = ImageDraw.Draw(fg)
draw_note(draw2, S, paper_frac=0.56)
fg.resize((OUT, OUT), Image.LANCZOS).save("assets/icon_foreground.png")

print("Wrote assets/icon.png and assets/icon_foreground.png")
