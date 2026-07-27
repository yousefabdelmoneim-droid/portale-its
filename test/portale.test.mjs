// I gate di qualità del Portale ITS. Se uno di questi rosseggia, la pipeline si ferma.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { render, totaleOre } from "../src/build.mjs";

const dati = JSON.parse(readFileSync("data/corsi.json", "utf8"));

test("il catalogo non è vuoto", () => {
  assert.ok(dati.corsi.length > 0, "nessun corso nel catalogo");
});

test("ogni corso ha codice, titolo e ore positive", () => {
  for (const c of dati.corsi) {
    assert.match(c.codice ?? "", /^[A-Z]{3}-[A-Z]{2,3}$/, `codice non valido: ${c.codice}`);
    assert.ok((c.titolo ?? "").length > 2, `titolo mancante per ${c.codice}`);
    assert.ok(Number.isInteger(c.ore) && c.ore > 0, `ore non valide per ${c.codice}: ${c.ore}`);
  }
});

test("il totale ore è la somma esatta delle ore dei corsi", () => {
  const attesa = dati.corsi.reduce((a, c) => a + c.ore, 0);
  assert.equal(totaleOre(dati.corsi), attesa);
});

test("la pagina generata contiene una riga per ogni corso", () => {
  const html = render(dati, "test");
  for (const c of dati.corsi) {
    assert.ok(html.includes(c.titolo), `manca il corso ${c.titolo}`);
    assert.ok(html.includes(`${c.ore} h`), `mancano le ore di ${c.codice}`);
  }
});

test("la pagina generata mostra il totale ore corretto", () => {
  const html = render(dati, "test");
  assert.ok(html.includes(`${totaleOre(dati.corsi)} h</td>`), "totale ore assente o sbagliato");
});

test("nessun segreto finisce nella pagina pubblicata", () => {
  const html = render(dati, "test");
  const sospetti = [/AKIA[0-9A-Z]{16}/, /password\s*[:=]/i, /secret[_-]?key/i, /-----BEGIN [A-Z ]*PRIVATE KEY-----/];
  for (const re of sospetti) {
    assert.ok(!re.test(html), `stringa sospetta nel sito pubblicato: ${re}`);
  }
});
