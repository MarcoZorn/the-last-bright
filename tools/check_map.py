#!/usr/bin/env python3
"""Verifica che map.txt sia giocabile. Da rilanciare dopo ogni modifica alla mappa.
Il modo piu' facile di rompere il gioco editando map.txt e' murare un varco:
gli zombie non arrivano piu' e sembra che il gioco 'funzioni'."""
from collections import deque

g = open('assets/map.txt').read().strip().split('\n')
H, W = len(g), len(g[0])
BLOCCANTI = "~#CGAV"

assert all(len(r) == W for r in g), "map.txt: righe di lunghezza diversa"

spawn = [(y, x) for y in range(H) for x in range(W) if g[y][x] == 'S']
piazza = [(y, x) for y in range(H) for x in range(W) if g[y][x] == ':']
porte = [(y, x) for y in range(H) for x in range(W) if g[y][x] == '+']
assert spawn and piazza and porte, "map.txt: mancano spawn, piazza o porte"

def raggiungibili(partenze):
    visti, q = set(partenze), deque(partenze)
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (y + dy, x + dx)
            if 0 <= n[0] < H and 0 <= n[1] < W and n not in visti and g[n[0]][n[1]] not in BLOCCANTI:
                visti.add(n); q.append(n)
    return visti

da_spawn = raggiungibili(spawn)
non_arrivano = [s for s in spawn if not any(p in da_spawn for p in piazza)]
assert not non_arrivano, f"la piazza e' irraggiungibile dagli spawn {non_arrivano}"

# ogni varco deve servire a qualcosa, altrimenti e' decorazione
inutili = [p for p in porte if p not in da_spawn]
print(f"OK  {W}x{H} | {len(spawn)} spawn | {len(porte)} varchi | piazza {len(piazza)} celle")
if inutili:
    print(f"    attenzione: {len(inutili)} varchi non raggiungibili dagli zombie {inutili[:4]}")
