# Lavori — The Last Bright

Lista che guida il loop notturno. La voce piu' in alto e' la prossima da fare.
Aggiornare a ogni ciclo: cosa e' stato fatto, cosa resta.

## Prossimi

1. **Far girare il simulatore di bilanciamento** (`./gioca.sh sim`) e tarare i numeri
   in base agli esiti. Finora non e' mai stato eseguito: non sappiamo se il gioco
   sia vincibile ne' se sia troppo facile.
2. **Critica adversariale col subagent** su design e codice, e agire sui rilievi.
3. **Leggibilita' degli zombie**: sprite verdi piccoli su erba verde, si vedono male.
4. **Multiplayer a 3** su ENet: e' il pezzo che sblocca politica, golpe e ribelle
   come esperienza vera invece che simulata dall'IA.
5. **Stealth del ribelle**: visibilita' filtrata per giocatore (arriva quasi gratis
   col multiplayer di Godot, `MultiplayerSynchronizer`).

## Fatto

- Mappa da schizzo, tileset/collisioni/A* derivati da `assets/map.txt`
- Ciclo giorno/notte, ondate crescenti, fronti che si aprono col tempo
- Barricate, guardie comandabili con livelli, edifici come bersagli
- Potere a somma zero, golpe, ribelle con azioni proprie, spedizioni
- Audio CC0, ombre, schizzi, scossone, minimappa, menu, manuale in gioco
- Export Windows (file unico) e Web (senza thread), repo privato su GitHub
