# Lavori — The Last Bright

Lista che guida il loop notturno. La voce piu' in alto e' la prossima da fare.

## Regola fissa di ogni ciclo

Prima di chiudere: `./gioca.sh test`, poi `./gioca.sh windows` e verificare che
l'exe esista. Marco la vuole sempre pronta. Commit piccoli, push su origin main.

Se la lista qui sotto si esaurisce: iniziare la versione **3D** (stessa logica di
gioco, client nuovo), cercando asset 3D con licenza CC0.

## Da chiarire con Marco

Messaggio arrivato nella notte del 4/9, che **non corrisponde a questo gioco**:

> "non voglio che tutti si nutrano di luce, gli animali non devono potersi
> nutrire di luce, per quello esistono le piante. e fai il mondo gigante, ma
> con le risorse concentrate al centro"

Qui non ci sono ne' animali ne' piante ne' energia dalla luce: quella e' una
catena alimentare da simulatore di ecosistema, probabilmente di un altro
progetto. L'unico pezzo che potrebbe valere anche qui e' il secondo: **mondo
piu' grande con le risorse concentrate al centro** -- renderebbe le spedizioni
un viaggio vero invece di un timer astratto. Non l'ho implementato senza
conferma perche' cambia la mappa e il ritmo di tutto il gioco.

## Prossimi

1. **Chiudere la taratura.** Con l'ultimo giro di fix (guardie che sparano da
   ferme e restano alle porte della citta') il pavimento va rimisurato con
   `./gioca.sh sim`. L'obiettivo: un bot che gioca a caso deve perdere spesso ma
   non sempre, e la percentuale di zombie *ammazzati* deve salire ben sopra zero.
2. **Provare il multiplayer con tre persone vere**: finora e' verificato solo con
   due istanze headless sulla stessa macchina.
3. Il **morale finisce sempre a 3**: tutte le azioni delle altre due fazioni lo
   consumano e la Chiesa non riesce a stargli dietro. Da guardare quando la
   difficolta' e' a posto -- probabilmente `MORALE_PER_ABITANTE_PERSO` (0.8 per
   abitante) e' troppo forte ora che l'alba costa gente.
4. Suoni ambientali e musica (adesso ci sono solo effetti).

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

## Il caso delle guardie che non sparavano

Vale la pena ricordarlo perche' e' costato quattro giri di simulazione. Il
sintomo era "0% di zombie ammazzati". Le ipotesi sbagliate, in ordine: raggio
troppo corto, guardie che morivano in mischia, guardie che restavano in piazza.
Il test isolato (`tools/test_guardia.tscn`) ha smontato le prime tre mostrando
che una guardia da sola raggiunge un varco a 218px e uccide. La causa vera era
il bonus di priorita' da 600px per i varchi sotto attacco: mandava sempre tutte
le guardie al checkpoint del ponte, che sta oltre il fiume, e passavano la notte
a camminare. Morale: quando i numeri aggregati non tornano, isolare prima di
tarare.

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
