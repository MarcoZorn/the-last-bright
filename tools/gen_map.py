#!/usr/bin/env python3
"""Genera assets/map.txt: Ponte Milvio, in scala reale.

Misure vere (fonte: Roma Capitale, Turismo Roma, Archeoroma):
  - il ponte e' lungo 132 m e largo 15,5, con sei arcate (quattro maggiori
    piu' due laterali minori), in blocchi di tufo
  - all'imbocco c'e' la Torretta Valadier, torre neoclassica del 1805 di
    Giuseppe Valadier: nel gioco e' il posto di blocco sul ponte, che e'
    esattamente cio' che era
  - davanti al ponte c'e' il Piazzale di Ponte Milvio, slargo pedonale: nella
    finzione lo abbiamo fortificato

Una casella = 3 metri. La mappa e' 56x84 caselle, cioe' 168 x 252 metri.

Legenda:  . erba/terreno  ~ Tevere  = impalcato del ponte  A arcata (pilone)
          # muro  + porta/barricata  T Torretta Valadier
          , selciato  : piazzale  C chiesa  G palazzo  M caserma
          V blocco veicolare  S sorgente degli zombie
          t albero  o barile  x sacchi

Rilanciare SOVRASCRIVE le modifiche fatte a mano su map.txt.
"""
import random

W, H = 56, 84
PASSO_M = 3.0

# --- geografia reale, convertita in caselle ---
FIUME_SU, FIUME_GIU = 12, 42          # 30 caselle = 90 m di Tevere
PONTE_SX, PONTE_DX = 25, 29           # 5 caselle = 15 m, il ponte e' largo 15,5
PONTE_SU, PONTE_GIU = 10, 44          # 35 caselle = 105 m fra le due testate
TORRETTA_RIGA = 9                     # la Torretta sta alla testata nord
PIAZZA_SU, PIAZZA_GIU = 47, 80        # il piazzale fortificato
PIAZZA_SX, PIAZZA_DX = 6, 49

g = [['.'] * W for _ in range(H)]

def box(r0, r1, c0, c1, ch):
    for r in range(max(0, r0), min(H, r1 + 1)):
        for c in range(max(0, c0), min(W, c1 + 1)):
            g[r][c] = ch

# --- il Tevere ---
box(FIUME_SU, FIUME_GIU, 0, W - 1, '~')

# --- il ponte, con le sei arcate ---
box(PONTE_SU, PONTE_GIU, PONTE_SX, PONTE_DX, '=')
# i piloni fra un'arcata e l'altra: quattro maggiori al centro, due minori ai lati.
# Sono decorativi in pianta ma danno il ritmo giusto al modello 3D.
luce = (FIUME_GIU - FIUME_SU) / 6.0
for i in range(1, 6):
    r = int(FIUME_SU + luce * i)
    g[r][PONTE_SX - 1] = 'A'
    g[r][PONTE_DX + 1] = 'A'

# --- Torretta Valadier: la porta fortificata alla testata nord ---
box(TORRETTA_RIGA - 1, TORRETTA_RIGA, PONTE_SX - 2, PONTE_DX + 2, 'T')
for c in range(PONTE_SX, PONTE_DX + 1):
    g[TORRETTA_RIGA][c] = '+'          # il varco sotto la torre

# --- la strada dal ponte al piazzale (via Flaminia) ---
box(PONTE_GIU + 1, PIAZZA_SU, PONTE_SX, PONTE_DX, ',')

# --- il piazzale fortificato ---
box(PIAZZA_SU, PIAZZA_SU, PIAZZA_SX, PIAZZA_DX, '#')
box(PIAZZA_GIU, PIAZZA_GIU, PIAZZA_SX, PIAZZA_DX, '#')
for r in range(PIAZZA_SU, PIAZZA_GIU + 1):
    g[r][PIAZZA_SX] = g[r][PIAZZA_DX] = '#'
box(PIAZZA_SU + 1, PIAZZA_GIU - 1, PIAZZA_SX + 1, PIAZZA_DX - 1, ',')

# lo slargo pedonale davanti al ponte
cy, cx, ry, rx = 60, 27.5, 7, 11
for r in range(H):
    for c in range(W):
        if ((r - cy) / ry) ** 2 + ((c - cx) / rx) ** 2 <= 1:
            g[r][c] = ':'

# --- i tre poli di potere ---
box(50, 56, 20, 35, 'C')     # la chiesa, affacciata sul piazzale
box(58, 66, 9, 17, 'G')      # il palazzo, lato ovest
box(58, 68, 39, 47, 'M')     # la caserma, lato est

# --- i varchi: sotto la torre e ai quattro lati del piazzale ---
for c in range(PONTE_SX, PONTE_DX + 1):
    g[PIAZZA_SU][c] = '+'
    g[PIAZZA_GIU][c] = '+'
for r in (62, 63, 64):
    g[r][PIAZZA_SX] = g[r][PIAZZA_DX] = '+'

# --- blocco veicolare a sud, fuori le mura ---
box(PIAZZA_GIU + 1, PIAZZA_GIU + 1, 24, 31, 'V')

# --- sorgenti dell'infezione ---
for c in (10, 27, 45):
    g[1][c] = 'S'                       # oltre il fiume: la pressione principale
for r in (52, 62, 74):
    g[r][0] = g[r][W - 1] = 'S'         # i fianchi
for c in (16, 28, 40):
    g[H - 1][c] = 'S'                   # alle spalle

# --- arredo, con seme fisso: la mappa e' sempre la stessa ---
random.seed(11)

def libera(r, c):
    if g[r][c] != ',':
        return False
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            rr, cc = r + dr, c + dc
            if 0 <= rr < H and 0 <= cc < W and g[rr][cc] in '+=':
                return False
    return True

posti = [(r, c) for r in range(PIAZZA_SU + 1, PIAZZA_GIU) for c in range(PIAZZA_SX + 1, PIAZZA_DX) if libera(r, c)]
random.shuffle(posti)
for i, (r, c) in enumerate(posti[:70]):
    g[r][c] = 'oxt'[i % 3] if i % 4 else 'o'

fuori = [(r, c) for r in range(H) for c in range(W)
         if g[r][c] == '.' and not any(
             g[r + dr][c + dc] in 'S+=T' for dr in (-1, 0, 1) for dc in (-1, 0, 1)
             if 0 <= r + dr < H and 0 <= c + dc < W)]
random.shuffle(fuori)
for r, c in fuori[:130]:
    g[r][c] = 't'

open('assets/map.txt', 'w').write('\n'.join(''.join(r) for r in g) + '\n')
print('assets/map.txt %dx%d caselle = %.0f x %.0f metri  (ponte %d m, largo %d m)'
      % (W, H, W * PASSO_M, H * PASSO_M,
         (PONTE_GIU - PONTE_SU + 1) * PASSO_M, (PONTE_DX - PONTE_SX + 1) * PASSO_M))
