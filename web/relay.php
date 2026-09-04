<?php
/* The Last Bright - staffetta per il multiplayer via HTTP.
 *
 * Perche' non WebSocket: nel browser ENet non esiste, e su questo host
 * proxy_wstunnel non e' attivo (servirebbe root). Questo giro di posta regge
 * tre giocatori a ~10 pacchetti al secondo, che per un gioco dove si decide di
 * giorno e si regge di notte e' abbastanza.
 *
 * Chi ospita simula la partita e deposita un'istantanea; gli altri la leggono
 * e depositano i propri comandi. Nessuno stato di gioco vive qui dentro: e'
 * solo una cassetta delle lettere.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

const CARTELLA   = '/tmp/tlb';
const SCADENZA   = 120;    // una stanza silenziosa da due minuti viene buttata
const POSTI      = 3;
const CORPO_MAX  = 262144; // 256 KB: un'istantanea onesta sta molto sotto

function fine($dati, $codice = 200) {
    http_response_code($codice);
    echo json_encode($dati);
    exit;
}

$stanza = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', $_GET['r'] ?? ''));
if (strlen($stanza) < 4 || strlen($stanza) > 8) {
    fine(['errore' => 'codice stanza non valido'], 400);
}
$azione = preg_replace('/[^a-z]/', '', $_GET['a'] ?? '');

if (!is_dir(CARTELLA)) { @mkdir(CARTELLA, 0700, true); }

// una spazzata ogni tanto, cosi' /tmp non cresce all'infinito
if (mt_rand(1, 50) === 1) {
    foreach (glob(CARTELLA . '/*.json') as $vecchio) {
        if (time() - filemtime($vecchio) > SCADENZA) { @unlink($vecchio); }
    }
}

$percorso = CARTELLA . '/' . $stanza . '.json';
$f = fopen($percorso, 'c+');
if ($f === false) { fine(['errore' => 'stanza non apribile'], 500); }
flock($f, LOCK_EX);

$grezzo = stream_get_contents($f);
$s = $grezzo ? json_decode($grezzo, true) : null;
if (!is_array($s)) {
    $s = ['giocatori' => [], 'istantanea' => null, 'turno' => 0, 'comandi' => [], 'nato' => time()];
}

$ora = time();
foreach ($s['giocatori'] as $id => $g) {          // chi tace da troppo esce
    if ($ora - $g['visto'] > 15) { unset($s['giocatori'][$id]); }
}

$id = preg_replace('/[^A-Za-z0-9]/', '', $_POST['id'] ?? $_GET['id'] ?? '');

switch ($azione) {

case 'entra':
    if ($id === '') { $id = bin2hex(random_bytes(6)); }
    if (!isset($s['giocatori'][$id])) {
        if (count($s['giocatori']) >= POSTI) {
            flock($f, LOCK_UN); fclose($f);
            fine(['errore' => 'stanza piena'], 409);
        }
        $presi = array_column($s['giocatori'], 'fazione');
        $fazione = 0;
        for ($i = 0; $i < POSTI; $i++) { if (!in_array($i, $presi, true)) { $fazione = $i; break; } }
        // il primo che entra ospita e simula
        $s['giocatori'][$id] = ['fazione' => $fazione, 'ospite' => count($s['giocatori']) === 0, 'visto' => $ora];
    } else {
        $s['giocatori'][$id]['visto'] = $ora;
    }
    $risposta = ['id' => $id, 'giocatori' => $s['giocatori'], 'turno' => $s['turno']];
    break;

case 'stato':   // solo chi ospita deposita l'istantanea
    if (!isset($s['giocatori'][$id]) || !$s['giocatori'][$id]['ospite']) {
        flock($f, LOCK_UN); fclose($f);
        fine(['errore' => 'non sei tu a ospitare'], 403);
    }
    $corpo = file_get_contents('php://input', false, null, 0, CORPO_MAX + 1);
    if (strlen($corpo) > CORPO_MAX) {
        flock($f, LOCK_UN); fclose($f);
        fine(['errore' => 'istantanea troppo grossa'], 413);
    }
    $s['giocatori'][$id]['visto'] = $ora;
    $s['istantanea'] = $corpo;
    $s['turno']++;
    $comandi = $s['comandi'];      // consegnati a chi ospita e svuotati
    $s['comandi'] = [];
    $risposta = ['turno' => $s['turno'], 'comandi' => $comandi, 'giocatori' => $s['giocatori']];
    break;

case 'leggi':   // chi non ospita: manda i suoi comandi e prende l'istantanea
    if (!isset($s['giocatori'][$id])) {
        flock($f, LOCK_UN); fclose($f);
        fine(['errore' => 'non sei nella stanza'], 403);
    }
    $s['giocatori'][$id]['visto'] = $ora;
    $corpo = file_get_contents('php://input', false, null, 0, 8192);
    if ($corpo !== '' && $corpo !== false) {
        $s['comandi'][] = ['da' => $id, 'c' => $corpo];
        if (count($s['comandi']) > 90) { array_shift($s['comandi']); }
    }
    $risposta = ['turno' => $s['turno'], 'istantanea' => $s['istantanea'], 'giocatori' => $s['giocatori']];
    break;

case 'esci':
    unset($s['giocatori'][$id]);
    $risposta = ['ok' => true];
    break;

default:
    flock($f, LOCK_UN); fclose($f);
    fine(['errore' => 'azione sconosciuta'], 400);
}

ftruncate($f, 0);
rewind($f);
fwrite($f, json_encode($s));
fflush($f);
flock($f, LOCK_UN);
fclose($f);
fine($risposta);
