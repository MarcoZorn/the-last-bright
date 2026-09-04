#!/usr/bin/env python3
"""Genera assets/sprites.png: i personaggi del gioco, 16x16 ciascuno.

Perche' non usiamo quelli di Kenney: i tre leader devono distinguersi a colpo
d'occhio anche da lontano, e gli zombie verdi sui prati verdi sparivano.
La chiave e' il contorno scuro, che qui viene aggiunto in automatico a ogni
figura: separa la sagoma da qualunque sfondo.

Rilanciare dopo ogni modifica:  python3 tools/gen_sprites.py
"""
from PIL import Image

T = 16
NERO = (26, 20, 30, 255)
VUOTO = (0, 0, 0, 0)

# --- pennelli minimi -------------------------------------------------------

def blocco(g, x, y, w, h, c):
    for j in range(y, y + h):
        for i in range(x, x + w):
            if 0 <= i < T and 0 <= j < T:
                g[j][i] = c

def punto(g, x, y, c):
    if 0 <= x < T and 0 <= y < T:
        g[y][x] = c

def contorno(g):
    """Ogni pixel vuoto attaccato a uno pieno diventa nero. Fatto dopo il
    disegno, cosi' non devo ricordarmi di bordare a mano ogni forma."""
    pieni = {(i, j) for j in range(T) for i in range(T) if g[j][i] != VUOTO}
    for (i, j) in list(pieni):
        for di, dj in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            x, y = i + di, j + dj
            if 0 <= x < T and 0 <= y < T and (x, y) not in pieni:
                g[y][x] = NERO

def vuoto():
    return [[VUOTO] * T for _ in range(T)]

# --- corpo comune ----------------------------------------------------------

def schiarisci(c, q=26):
    return tuple(min(255, v + q) if k < 3 else v for k, v in enumerate(c))

def umano(g, pelle, veste, veste_scura, occhi=(38, 32, 44, 255), passo=0):
    """Corpo comune. La luce viene dall'alto a sinistra: senza le due tonalita'
    le figure sembravano ritagli di cartone accanto agli sprite di Kenney."""
    pelle_chiara = schiarisci(pelle, 20)
    blocco(g, 5, 3, 6, 4, pelle)          # testa piu' larga: ci stanno gli occhi
    blocco(g, 5, 3, 6, 1, pelle_chiara)   # fronte in luce
    blocco(g, 6, 7, 4, 1, pelle)          # collo
    punto(g, 6, 5, occhi)                 # occhi staccati dal bordo, si vedono
    punto(g, 9, 5, occhi)
    punto(g, 7, 6, tuple(max(0, v - 22) if k < 3 else v for k, v in enumerate(pelle)))
    blocco(g, 5, 8, 6, 4, veste)          # busto
    blocco(g, 5, 8, 3, 4, schiarisci(veste))   # meta' in luce
    blocco(g, 5, 11, 6, 1, veste_scura)   # piega bassa
    blocco(g, 4, 8, 1, 3, veste_scura)    # braccia
    blocco(g, 11, 8, 1, 3, veste_scura)
    # due fotogrammi: nel secondo le gambe si scambiano di un pixel. A questa
    # scala basta quello per leggere una camminata invece di uno scivolamento.
    if passo == 0:
        blocco(g, 5, 12, 2, 2, veste_scura)
        blocco(g, 9, 12, 2, 2, veste_scura)
    else:
        blocco(g, 5, 12, 2, 1, veste_scura)
        blocco(g, 6, 12, 2, 2, veste_scura)
        blocco(g, 9, 13, 2, 1, veste_scura)

def chiesa(passo=0):
    g = vuoto()
    umano(g, (232, 196, 160, 255), (238, 234, 224, 255), (198, 190, 182, 255), passo=passo)
    # mitra: la sagoma piu' alta e appuntita delle tre, riconoscibile da lontano
    blocco(g, 7, 0, 2, 1, (250, 214, 96, 255))
    blocco(g, 6, 1, 4, 1, (250, 214, 96, 255))
    blocco(g, 4, 2, 8, 1, (236, 190, 70, 255))
    blocco(g, 7, 8, 2, 4, (176, 92, 200, 255))   # stola viola
    contorno(g)
    return g

def governo(passo=0):
    g = vuoto()
    umano(g, (226, 186, 150, 255), (190, 60, 58, 255), (150, 42, 44, 255), passo=passo)
    blocco(g, 3, 2, 10, 1, (60, 56, 70, 255))    # tuba bassa e larga
    blocco(g, 6, 0, 4, 2, (60, 56, 70, 255))
    blocco(g, 5, 9, 6, 1, (240, 230, 210, 255))  # fascia bianca
    contorno(g)
    return g

def esercito(passo=0):
    g = vuoto()
    umano(g, (214, 172, 138, 255), (92, 108, 140, 255), (66, 78, 108, 255), passo=passo)
    blocco(g, 5, 2, 6, 2, (168, 176, 190, 255))  # elmo
    blocco(g, 7, 0, 2, 2, (208, 76, 60, 255))    # cresta rossa
    blocco(g, 5, 9, 6, 1, (168, 176, 190, 255))  # corazza
    contorno(g)
    return g

def guardia(passo=0):
    g = vuoto()
    umano(g, (218, 178, 144, 255), (96, 138, 190, 255), (62, 96, 142, 255), passo=passo)
    blocco(g, 5, 2, 6, 2, (178, 190, 206, 255))  # elmo senza cresta:
    blocco(g, 12, 4, 1, 9, (150, 110, 62, 255))  # e' truppa, non un leader
    blocco(g, 12, 2, 1, 2, (190, 196, 206, 255)) # lancia
    contorno(g)
    return g

def zombie(variante=0, passo=0):
    """Ingobbito e asimmetrico: si distingue dagli umani anche in mezzo alla
    mischia, senza doverlo colorare di fluorescente."""
    g = vuoto()
    carne = [(122, 152, 96, 255), (104, 140, 100, 255), (134, 148, 84, 255)][variante % 3]
    carne_scura = tuple(max(0, c - 34) if k < 3 else 255 for k, c in enumerate(carne))
    stracci = (86, 74, 68, 255)
    blocco(g, 5, 4, 4, 4, carne)                 # testa bassa e spostata
    blocco(g, 5, 7, 4, 1, carne_scura)
    punto(g, 5, 6, (206, 60, 48, 255))           # occhi rossi: l'unico dettaglio
    punto(g, 8, 6, (206, 60, 48, 255))           # acceso, si legge anche a 1x
    blocco(g, 5, 8, 6, 4, carne)                 # busto
    blocco(g, 5, 10, 6, 1, stracci)
    blocco(g, 10, 7, 2, 2, carne)                # un braccio proteso in avanti
    blocco(g, 4, 9, 1, 2, carne_scura)           # l'altro penzoloni
    if passo == 0:
        blocco(g, 5, 12, 2, 2, carne_scura)
        blocco(g, 8, 12, 2, 2, stracci)
    else:
        blocco(g, 5, 12, 2, 1, carne_scura)
        blocco(g, 6, 12, 2, 2, carne_scura)
        blocco(g, 8, 13, 2, 1, stracci)
    contorno(g)
    return g

# una colonna per personaggio, una riga per fotogramma
COLONNE = [chiesa, governo, esercito, guardia,
           lambda passo=0: zombie(0, passo),
           lambda passo=0: zombie(1, passo),
           lambda passo=0: zombie(2, passo)]
FOTOGRAMMI = 2

foglio = Image.new("RGBA", (T * len(COLONNE), T * FOTOGRAMMI), VUOTO)
for n, disegna in enumerate(COLONNE):
    for f in range(FOTOGRAMMI):
        g = disegna(f)
        for y in range(T):
            for x in range(T):
                foglio.putpixel((n * T + x, f * T + y), g[y][x])
foglio.save("assets/sprites.png")
print("assets/sprites.png  %d personaggi x %d fotogrammi: chiesa governo esercito guardia zombie x3"
      % (len(COLONNE), FOTOGRAMMI))
