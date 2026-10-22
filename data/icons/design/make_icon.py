"""Generate the Kumiko icon: a square asanoha kumiko panel on a dark tile.

Run from the repository root to regenerate the installed icons:

    python3 data/icons/design/make_icon.py

Geometry (100x100 canvas, like the previous icon): a frame from LO to HI,
a cross through the centre O dividing it into four panes, diagonals from O
to the four corners, and in each of the 8 triangles (O, corner, edge
midpoint) three strips meeting at the triangle's centroid: the asanoha
("hemp leaf") pattern of the reference panel.
"""
LO, HI = 20.0, 80.0
O = ((LO + HI) / 2, (LO + HI) / 2)
TILE = "#15181E"          # same dark tile as before
WOOD = "#E9D2AE"          # light maple
WOOD_DARK = "#C9A97C"     # inner strips, a shade deeper
ACCENT = "#4ADE80"        # Kumiko green, from the previous icon

corners = [(LO, LO), (HI, LO), (HI, HI), (LO, HI)]
mids = [((LO + HI) / 2, LO), (HI, (LO + HI) / 2), ((LO + HI) / 2, HI), (LO, (LO + HI) / 2)]


def triangles():
    # each corner pairs with its two adjacent edge midpoints
    out = []
    for i, c in enumerate(corners):
        for m in (mids[i], mids[i - 1]):
            out.append((O, c, m))
    return out


def centroid(t):
    return (sum(p[0] for p in t) / 3, sum(p[1] for p in t) / 3)


def f(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def line(a, b):
    return f"M{f(a[0])} {f(a[1])}L{f(b[0])} {f(b[1])}"


def svg(lit_pane=False, size=512):
    leaves = []
    for t in triangles():
        g = centroid(t)
        leaves += [line(p, g) for p in t]
    diagonals = [line(O, c) for c in corners]
    cross = [line(mids[0], mids[2]), line(mids[3], mids[1])]
    frame = f"M{f(LO)} {f(LO)}H{f(HI)}V{f(HI)}H{f(LO)}Z"
    # short overhangs where the cross meets the frame, as in real kumiko joinery
    stubs = [line((m[0] + (m[0] - O[0]) * 0.1, m[1] + (m[1] - O[1]) * 0.1), m) for m in mids]

    lit = ""
    if lit_pane:
        # the bottom-right pane, softly lit: a focused split pane
        lit = (f'  <rect x="{f(O[0])}" y="{f(O[1])}" width="{f(HI - O[0])}" height="{f(HI - O[1])}" '
               f'fill="{ACCENT}" opacity="0.22"/>\n')

    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="{size}" height="{size}">
  <title>Kumiko</title>
  <rect width="100" height="100" rx="22" fill="{TILE}"/>
{lit}  <g fill="none" stroke-linecap="round" stroke-linejoin="round">
    <path d="{" ".join(leaves)}" stroke="{WOOD_DARK}" stroke-width="1.6"/>
    <path d="{" ".join(diagonals)}" stroke="{WOOD}" stroke-width="2.2"/>
    <path d="{" ".join(cross + stubs)}" stroke="{WOOD}" stroke-width="3.6"/>
    <path d="{frame}" stroke="{WOOD}" stroke-width="3.6"/>
  </g>
</svg>
'''


def symbolic():
    # 16x16 monochrome: frame, cross and diagonals (the leaves are too fine)
    lo, hi, o = 2.5, 13.5, 8
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <title>Kumiko-symbolic</title>
  <g fill="none" stroke="#bebebe" stroke-linecap="round" stroke-linejoin="round">
    <path d="M{lo} {lo}H{hi}V{hi}H{lo}Z M{o} {lo}V{hi} M{lo} {o}H{hi}" stroke-width="1.3"/>
    <path d="M{lo} {lo}L{hi} {hi} M{hi} {lo}L{lo} {hi}" stroke-width="0.9"/>
  </g>
</svg>
'''


APPS = "data/icons/hicolor/scalable/apps"
OUTPUTS = {
    f"{APPS}/io.github.iqzer0.kumiko.svg": lambda: svg(lit_pane=True),
    f"{APPS}/io.github.iqzer0.kumiko-symbolic.svg": symbolic,
    "data/kumiko.svg": lambda: svg(lit_pane=True),
    "docs/assets/images/logo.svg": lambda: svg(lit_pane=True),
}

if __name__ == "__main__":
    for path, make in OUTPUTS.items():
        with open(path, "w") as out:
            out.write(make())
        print("wrote", path)
