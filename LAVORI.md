# Lavori — The Last Bright

Lista che guida il loop notturno. La voce piu' in alto e' la prossima da fare.

## Regola fissa di ogni ciclo

Prima di chiudere: `./gioca.sh test`, poi `./gioca.sh windows` e verificare che
l'exe esista. Marco la vuole sempre pronta. Commit piccoli, push su origin main.

Se la lista qui sotto si esaurisce: iniziare la versione **3D** (stessa logica di
gioco, client nuovo), cercando asset 3D con licenza CC0.

## Prossimi

1. **Il gioco e' troppo facile.** Un bot che gioca a caso vince 5 partite su 5.
   Serve alzare la pressione finche' il pavimento non scende sotto la meta'.
2. **Le difese non ammazzano quasi niente** (1.2 zombie a partita): quasi tutti
   muoiono all'alba. Se il 90% degli zombie muore di sole, guardie e mura sono
   decorazione. Il contatore "uccisi vs bruciati" in `./gioca.sh sim` dice
   quanto e' grave.
3. **Schermata di fine partita** che spieghi *perche'* hai perso, con i numeri.
4. **Provare il multiplayer con tre persone vere**: finora e' verificato solo
   con due istanze headless sulla stessa macchina.
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
- **Multiplayer a tre su ENet**: lobby, fazioni assegnate all'arrivo, i posti
  vuoti li riempie l'IA. Movimento del leader al client, tutto il resto al
  server. Verificato con due istanze headless: stato identico sui due lati.
- **Stealth del ribelle**: di notte il server non manda la sua posizione agli
  altri peer oltre i 120 pixel, e il sabotaggio non produce annuncio

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
