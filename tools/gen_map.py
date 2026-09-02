#!/usr/bin/env python3
"""Genera assets/map.txt dalla mappa concettuale (Ponte Milvio post-apocalittico).
Una volta generata, map.txt si edita a mano: e' solo testo. Rilanciare questo
script SOVRASCRIVE le modifiche manuali.

Legenda:  . erba   ~ acqua   = ponte   # muro   + porta/barricata
          , terra  : piazza  C chiesa  G governo  A caserma
          V blocco veicolare   S spawn zombie
          t albero  o barile/cassa  x sacchi di sabbia   (tutti solidi)
"""
import random
W, H = 40, 52
BRIDGE = range(18, 22)          # colonne del ponte
SQ_TOP, SQ_BOT, SQ_L, SQ_R = 20, 49, 4, 35   # muri della piazza fortificata

g = [['.'] * W for _ in range(H)]

def box(r0, r1, c0, c1, ch):
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            if 0 <= r < H and 0 <= c < W:
                g[r][c] = ch

# fiume + ponte
box(7, 13, 0, W - 1, '~')
for r in range(7, 14):
    for c in BRIDGE:
        g[r][c] = '='
# checkpoint barricato a nord del ponte: la prima linea di difesa
box(6, 6, 15, 24, '#')
for c in BRIDGE:
    g[6][c] = '+'
# strada dal ponte alla piazza
box(14, 19, 18, 21, ',')

# piazza fortificata: muri perimetrali
box(SQ_TOP, SQ_TOP, SQ_L, SQ_R, '#')
box(SQ_BOT, SQ_BOT, SQ_L, SQ_R, '#')
for r in range(SQ_TOP, SQ_BOT + 1):
    g[r][SQ_L] = g[r][SQ_R] = '#'
box(SQ_TOP + 1, SQ_BOT - 1, SQ_L + 1, SQ_R - 1, ',')

# piazza centrale (ellisse)
cy, cx, ry, rx = 34, 19.5, 5, 6.5
for r in range(H):
    for c in range(W):
        if ((r - cy) / ry) ** 2 + ((c - cx) / rx) ** 2 <= 1:
            g[r][c] = ':'

# i tre poli di potere (posizioni prese dallo schizzo)
box(23, 28, 15, 24, 'C')   # chiesa grande, a nord della piazza
box(30, 36, 6, 11, 'G')    # governo, a ovest  (il rettangolo rosso)
box(30, 38, 28, 33, 'A')   # caserma, a est    (il poligono viola)

# le 4 porte, disegnate per ultime: sovrascrivono i muri
for c in BRIDGE:
    g[SQ_TOP][c] = g[SQ_BOT][c] = '+'
for r in (33, 34, 35):
    g[r][SQ_L] = g[r][SQ_R] = '+'

# blocco veicolare a sud, fuori le mura
box(50, 50, 17, 22, 'V')
# sorgenti dell'infezione: il grosso arriva da oltre il fiume e deve passare
# per il ponte, ma i fianchi e le spalle non sono sicuri.
for c in (8, 19, 30):
    g[1][c] = 'S'          # nord, oltre il fiume: la pressione principale
for r in (26, 34, 44):
    g[r][0] = g[r][W - 1] = 'S'   # fianchi
for c in (10, 20, 30):
    g[H - 1][c] = 'S'      # alle spalle

# arredo: la piazza vuota sembrava un parcheggio. Seme fisso, cosi' la mappa
# e' sempre la stessa e si puo' ritoccare a mano dopo.
random.seed(7)

def libera(r, c):
    """Non arreda sopra strade, varchi o le loro vicinanze: gli zombie devono
    poter arrivare e i giocatori poter passare."""
    if g[r][c] != ',':
        return False
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            rr, cc = r + dr, c + dc
            if 0 <= rr < H and 0 <= cc < W and g[rr][cc] in '+=':
                return False
    return True

posti = [(r, c) for r in range(SQ_TOP + 1, SQ_BOT) for c in range(SQ_L + 1, SQ_R) if libera(r, c)]
random.shuffle(posti)
for i, (r, c) in enumerate(posti[:46]):
    g[r][c] = 'oxt'[i % 3] if i % 4 else 'o'

# alberi e macerie fuori le mura, ma non sulle rotte di avvicinamento
fuori = [(r, c) for r in range(H) for c in range(W)
         if g[r][c] == '.' and not any(
             g[r + dr][c + dc] in 'S+=' for dr in (-1, 0, 1) for dc in (-1, 0, 1)
             if 0 <= r + dr < H and 0 <= c + dc < W)]
random.shuffle(fuori)
for r, c in fuori[:70]:
    g[r][c] = 't'

open('assets/map.txt', 'w').write('\n'.join(''.join(r) for r in g) + '\n')
print(f'assets/map.txt {W}x{H}')
