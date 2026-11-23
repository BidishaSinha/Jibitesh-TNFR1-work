import fitz
import os
HERE = os.path.dirname(os.path.abspath(__file__))
S = HERE + "/"
rows = [list("abcd"), list("efgh"), list("ijk")]            # same grouping as the thesis figure
BRACKET = {"a", "j"}                                          # panels whose x-axis is the five curvature classes
docs = {L: fitz.open(S+"panels_fig3_2/"+L+".pdf") for r in rows for L in r}
LX, M, G, RG, EXTRA = 14, 10, 10, 12, 30                      # letter gutter, margin, col gap, row gap, room under class axes
sz = {L: (d[0].rect.width, d[0].rect.height) for L, d in docs.items()}

def class_ticks(page):
    """x-extent of the four bracketed class labels and the lowest label y, read from the panel PDF's own text."""
    H = page.rect.height
    words = [w for w in page.get_text("words") if w[1] > H*0.45]
    def ext(*prefixes):
        ws = [w for w in words if any(w[4].upper().startswith(p) for p in prefixes)]
        return min(w[0] for w in ws), max(w[2] for w in ws)
    return ({"cup": ext("CUP","PIT"), "trough": ext("TROUGH"), "ridge": ext("RIDGE"), "dome": ext("DOME","HILL")},
            max(w[3] for w in words))

rowW = [sum(LX+sz[L][0] for L in r) + G*(len(r)-1) for r in rows]
rowH = [max(sz[L][1] + (EXTRA if L in BRACKET else 0) for L in r) for r in rows]
W = 2*M + max(rowW); H = 2*M + sum(rowH) + RG*(len(rows)-1)
out = fitz.open(); page = out.new_page(width=W, height=H)
y = M
for r, rh in zip(rows, rowH):
    x = M
    for L in r:
        w, h = sz[L]; ox, oy = x+LX, y
        page.show_pdf_page(fitz.Rect(ox, oy, ox+w, oy+h), docs[L], 0)         # vector, native size
        page.insert_text((x, y+11), L, fontsize=13, fontname="hebo")          # letter in its own gutter
        if L in BRACKET:
            t, ybot = class_ticks(docs[L][0]); yb = oy + ybot + 4
            for (a, b), text in (((t["cup"][0], t["trough"][1]), "Outward bending"),
                                 ((t["ridge"][0], t["dome"][1]), "Inward bending")):
                xa, xb = ox + a - 2, ox + b + 2
                sh = page.new_shape()
                sh.draw_line((xa, yb-3), (xa, yb)); sh.draw_line((xa, yb), (xb, yb)); sh.draw_line((xb, yb), (xb, yb-3))
                sh.finish(color=(0.15,0.15,0.15), width=0.8, closePath=False, fill=None); sh.commit()
                tw = fitz.get_text_length(text, fontname="helv", fontsize=7)
                page.insert_text(((xa+xb)/2 - tw/2, yb + 9), text, fontsize=7, fontname="helv", color=(0.1,0.1,0.1))
        x += LX + w + G
    y += rh + RG
dst = os.path.join(HERE, "..", "final_figures", "Figure_3.2_rebuilt_from_saved_plots.pdf")
out.save(dst)
print("page", round(W), round(H), "->", dst)
