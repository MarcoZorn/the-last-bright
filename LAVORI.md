# Lavori — The Last Bright

Lista che guida il loop notturno. La voce piu' in alto e' la prossima da fare.

## Regola fissa di ogni ciclo

Prima di chiudere: `./gioca.sh test`, poi `./gioca.sh windows` e verificare che
l'exe esista. Marco la vuole sempre pronta. Commit piccoli, push su origin main.

Se la lista qui sotto si esaurisce: iniziare la versione **3D** (stessa logica di
gioco, client nuovo), cercando asset 3D con licenza CC0.

## Prossimi

1. **Chiudere il ciclo di bilanciamento.** `./gioca.sh sim` deve smettere di dire
   "0 zombie uccisi": finche' nessuno muore, l'assedio e' scenografia. Capire se i
   varchi cadono davvero e se le guardie arrivano a sparare.
2. **Multiplayer a 3** su ENet. E' il pezzo che rende vera la politica: oggi le
   altre due fazioni sono un'IA che sceglie fra tre priorita'.
3. **Stealth del ribelle**: visibilita' filtrata per giocatore
   (`MultiplayerSynchronizer`), arriva quasi gratis col multiplayer.
4. **Schermata di fine partita** che spieghi *perche'* hai perso, con i numeri.
5. Animazioni a piu' fotogrammi (adesso c'e' solo l'ondeggio del passo).

## Fatto

- Mappa da schizzo, tileset/collisioni/A* derivati da `assets/map.txt`
- Ciclo giorno/notte, ondate crescenti, fronti che si aprono col tempo
- Barricate, guardie comandabili con livelli, edifici come bersagli
- Potere a somma zero, golpe, ribelle con azioni proprie, spedizioni
- Audio CC0, ombre, schizzi, scossone, minimappa, menu, manuale in gioco
- Export Windows (file unico) e Web (senza thread), repo privato su GitHub
- Sprite disegnati in casa: i tre leader hanno identita' di fazione, gli zombie
  hanno contorno scuro e occhi rossi (prima sparivano sull'erba)
- Budget di tre azioni al giorno, azioni solo di giorno: e' il costo opportunita'
  che prima non esisteva
- Simulatore (`./gioca.sh sim`) che gioca partite intere e riporta il perche'

## Difetti trovati dalle critiche e chiusi

- Il potere si ridistribuiva in modo additivo e la normalizzazione lo riassorbiva:
  il golpe non scattava **mai**. Ora e' una quota di merito.
- `mia` in `azioni.gd` leggeva la fazione del giocatore invece di quella
  dell'esecutore: un'IA ribelle regalava potere al giocatore.
- Il morale non aveva tetto e le tasse lo leggevano prima del clamp.
- Le azioni funzionavano anche di notte, l'IA no: il giocatore ne faceva tre
  per ognuna loro.
- Il tetto agli zombie contava schizzi e numerini di danno, strozzando lo spawn.
- `dentro_le_mura` era un frammento: le porte spezzano il perimetro in archi.
- Una guardia morta restava nel gruppo e si poteva licenziare due volte per 20$.
