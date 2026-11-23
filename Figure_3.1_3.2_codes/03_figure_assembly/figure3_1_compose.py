import fitz
import os
HERE = os.path.dirname(os.path.abspath(__file__))
S = HERE + "/"
names = [("a","B1_classpct_snapshot"),("b","B2_curvature_by_class_snapshot"),("c","C1_SDcurvature_cluster_vs_random"),
         ("d","C3_classmix_cluster_vs_random"),("e","A7_SDt_vs_NFlips"),("f","A9_correlation_heatmap_small")]
BRACKET = {"a","b","d"}                    # panels whose x-axis is the five curvature classes
docs = [fitz.open(S+"panels_fig3_1/"+n+".pdf") for _,n in names]
sz   = [(d[0].rect.width, d[0].rect.height) for d in docs]

def class_ticks(page):
    """x-extent of the four bracketed class labels (CUP/PIT, TROUGH, RIDGE, DOME/HILL) and the lowest text y,
    read from the words in the lower half of each panel PDF (labels may be split over two lines)."""
    H = page.rect.height
    words = [w for w in page.get_text("words") if w[1] > H*0.45]
    def ext(*prefixes):
        ws = [w for w in words if any(w[4].upper().startswith(p) for p in prefixes)]
        return min(w[0] for w in ws), max(w[2] for w in ws)
    ticks = {"cup": ext("CUP","PIT"), "trough": ext("TROUGH"), "ridge": ext("RIDGE"), "dome": ext("DOME","HILL")}
    return ticks, max(w[3] for w in words)

LX, M, G, EXTRA = 14, 10, 12, 30           # letter gutter, outer margin, gap between cells, room under class axes for brackets
cellW = [LX + max(sz[c][0], sz[c+3][0]) for c in range(3)]
rowH  = [max(sz[i][1] + (EXTRA if names[i][0] in BRACKET else 0) for i in range(3*r, 3*r+3)) for r in range(2)]
W = 2*M + sum(cellW) + 2*G; H = 2*M + sum(rowH) + G
out = fitz.open(); page = out.new_page(width=W, height=H)
y = M
for r in range(2):
    x = M
    for c in range(3):
        i = r*3 + c; lab = names[i][0]; w, h = sz[i]
        ox, oy = x + LX, y
        page.show_pdf_page(fitz.Rect(ox, oy, ox+w, oy+h), docs[i], 0)       # vector, native size
        page.insert_text((x, y+11), lab, fontsize=13, fontname="hebo")      # letter lives in its own gutter
        if lab in BRACKET:
            t, ybot = class_ticks(docs[i][0])
            yb = oy + ybot + 4
            for (a, b), text in (((t["cup"][0], t["trough"][1]), "Outward bending"),
                                 ((t["ridge"][0], t["dome"][1]), "Inward bending")):
                xa, xb = ox + a - 2, ox + b + 2
                sh = page.new_shape()
                sh.draw_line((xa, yb-3), (xa, yb)); sh.draw_line((xa, yb), (xb, yb)); sh.draw_line((xb, yb), (xb, yb-3))
                sh.finish(color=(0.15,0.15,0.15), width=0.8, closePath=False, fill=None); sh.commit()   # open bracket, not a box
                tw = fitz.get_text_length(text, fontname="helv", fontsize=7)
                page.insert_text(((xa+xb)/2 - tw/2, yb + 9), text, fontsize=7, fontname="helv", color=(0.1,0.1,0.1))
        x += cellW[c] + G
    y += rowH[r] + G
dst = os.path.join(HERE, "..", "final_figures", "Figure_3.1_rebuilt_from_saved_plots.pdf")
out.save(dst)
print("page", round(W), round(H), "->", dst)
