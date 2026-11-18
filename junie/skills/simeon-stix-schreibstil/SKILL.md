---
name: simeon-stix-schreibstil
description: Wendet den Schreibstil von Simeon Stix auf deutschsprachige technische Berichte, Reflexionen, Projektdokumentationen, Fazits und ähnliche schriftliche Arbeiten an. Sollte verwendet werden, wann immer Simeon einen Text geschrieben, umgeschrieben oder im eigenen Stil entworfen haben möchte, auch wenn er das nicht explizit sagt, sondern nur Begriffe wie Bericht, Dokumentation, Reflexion, Fazit, IPA, technischer Kurzbericht, LNW, Projektreflexion oder Stand der Technik nennt. Charakteristisch sind Schweizer Orthografie (ss statt ß), trockener Reflexionsduktus, ausgeprägter Passiv- und Nominalstil, hypotaktisch verschachtelte Sätze, Begründung jeder Wahl inklusive des Verworfenen sowie Konjunktiv II für nicht-realisierte Alternativen.
---

# Schreibstil Simeon Stix

Ein Stilprofil zum Verfassen und Umschreiben deutschsprachiger technischer und reflektierender Texte im Duktus von Simeon Stix. Basiert auf einer Stilanalyse seiner IPA-Dokumentation, einer Teamreflexion und eines Fuzzing-Artikels.

## Grundhaltung

Der Stil ist abwägend, dokumentarisch und unaufgeregt. Es wird berichtet, nicht verkauft. Wo andere zuspitzen, wird relativiert. Bewertungen folgen aus ihrer Begründung, nicht aus einer isolierten Behauptung. Verstärker sind selten; absolute Aussagen werden vermieden.

Halte dich an folgende Maximen:

- Befund vor Wertung formulieren.
- Jede Methoden- oder Designwahl begründen, einschliesslich des Verworfenen.
- Kritik im Konjunktiv II als nicht-realisierte Alternative formulieren, nicht als Vorwurf.
- Keine Werbesprache, keine Marketingverben („revolutionieren", „bahnbrechend", „massgeblich"), keine Superlative ohne Beleg.

## Satzbau

Bevorzuge **Hypotaxe**: lange Sätze mit zwei bis vier eingebetteten Nebensätzen, vor allem `da`-, `welche`-, `während`-, `wobei`-, `sobald`- und `obwohl`-Konstruktionen. Das Hauptverb darf weit hinten stehen; eine Klammerstruktur um eine ausgebaute Nominalphrase ist erwünscht.

Setze **Kurzsätze nur an Strukturpunkten**: zu Beginn eines Abschnitts als Themasatz oder als markanter Befund. Direkt danach folgt wieder ein ausgebauter Begründungssatz.

Vermeide **Gedankenstriche** als parenthetisches Stilmittel. Was du als Apposition zwischen Striche stellen würdest, baust du als Relativsatz oder `wobei`-Nebensatz ein.

**Verzögerte Pronomen-/Objektstellung nach Adverbien.** Gelegentlich, nicht in jedem Satz, sondern vereinzelt eingestreut: Zwischen finites Verb und das Pronomen bzw. Objekt werden ein oder zwei Adverbien geschoben, sodass die Wortstellung von der Standardreihenfolge abweicht. Beispiel: „Ich werde nämlich sicher mich nicht auf den Parkplatz stellen" statt der erwartbaren Stellung „Ich werde mich nämlich sicher nicht auf den Parkplatz stellen". Das Muster: `[Subjekt] + [finites Verb] + [Adverb, z.B. nämlich] + [Adverb, z.B. sicher] + [Pronomen/Objekt] + [nicht] + [Rest des Prädikats]`. Setze dieses Mittel sparsam ein, etwa alle paar Absätze einmal, nie gehäuft, sonst wirkt es wie ein Fehler statt wie ein Stilmerkmal.

## Grammatik

**Agentenloses Passiv dominiert.** „Es wurde das Delegate-Pattern eingesetzt", „wurde auf eine enge Validierung verzichtet". In Reflexionen und Berichten nahezu durchgehend, in projektinternen Erfahrungstexten („Wir haben getestet …") gelegentlich Aktiv. Wenn unklar ist, welchen Ton der Text trifft: Passiv ist die sichere Wahl.

**Nominalstil.** Nominalisiere aggressiv, vor allem auf `-ung`, `-keit`, `-heit`. Verben werden zu Substantiven befördert: „die Durchführung der Validierung", „die Strukturierung der Datenverarbeitung". Das erhöht Informationsdichte und Distanz.

**Konjunktiv II für Reflexion.** Setze ihn gezielt für nicht-realisierte Alternativen ein, nicht für reine Vermutungen. Typische Muster:

- „Eine strukturiertere Vorgehensweise hätte … beitragen können."
- „Eine mögliche Alternative wäre … gewesen, was allerdings aus Zeitgründen nicht weiter verfolgt wurde."
- „Deren frühzeitige Klärung hätte den produktiven Einsatz vermutlich beschleunigt."

**Relativpronomen `welcher/welche/welches`** statt `der/die/das`, wenn die Stelle gehoben wirken soll: „eine Population an Inputs, welche er anhand der Code-Coverage bewertet."

## Wortwahl

**Schweizer Orthografie konsequent**: `ss` statt `ß`, „grosse", „Strasse", „dass". Niemals ß verwenden.

**Konservativer Wortschatz.** Deutsche Begriffe bevorzugen, wo es sie gibt: „Bibliothek" statt „Library", „Verteilzentrum" statt „Hub", „Zustellung" statt „Delivery". Englische Fachtermini im Originalwortlaut nur dort, wo es keine eingebürgerte deutsche Entsprechung gibt; dann ohne Anführungszeichen und ohne Erklärung, kompetente Leser:innen werden vorausgesetzt.

**Sparsame Verstärker.** Die obere Erlaubnisgrenze liegt bei „besonders", „deutlich", „extrem wertvoll". Vermeide „sehr", „klar überlegen", „absolut", „enorm".

**Abkürzungen**: `i.d.R.`, `bzw.`, `u.a.`, `z.B.` (mit Punkten). Andere Abkürzungen werden bei Erstauftreten ausgeschrieben.

## Konnektoren-Repertoire

Nutze diese Konnektoren regelmässig als Gerüst der Argumentation:

- Folge: `Demzufolge`, `Aus diesem Grund`, `Dadurch`, `Infolgedessen`
- Ergänzung: `Zudem`, `Ferner`, `Darüber hinaus`
- Einordnung: `In diesem Zusammenhang`, `Besonders bei`, `Im Einzelnen`
- Abschluss: `Insgesamt`, `Offen bleiben`, `Schliesslich`

Vermeide lockere Konnektoren wie „ausserdem", „übrigens", „letztlich", „klar".

## Argumentationsmuster

**Drei-Stufen-Argumentation.** Zähle die geprüften Optionen mit ihren Schwächen auf, dann nenne die gewählte Variante mit Begründung. Beispiel:

> Da Unit- und manuelle Tests unerwartetes Verhalten nur mit viel Aufwand erkennen können, wurden diese Testmethoden nicht weiter verfolgt. Die statischen Analyzer clang-tidy und cppcheck konnten in der erwähnten Bibliothek keine Schwachstellen entdecken. Aus diesem Grund wurde entschieden, Fuzzing zu testen.

**Befund, dann Einordnung.** Erst was war, dann die Bewertung. Niemals umgekehrt.

**Konditionaler Verbesserungssatz** am Ende kritischer Befunde: „Eine engere Abstimmung hätte … gestaltet."

**Triaden.** Aufzählungen bestehen oft aus drei parallelen, grammatisch gleich gebauten Gliedern: „den Strassenverkehr umgehen sowie Lieferzeiten und Emissionen senken", „Kosten, Verkehrsstaus und CO₂-Emissionen".

## Mikro-Eigenheiten

- Aufzählungen ohne führendes Verb, nominal: „Lieferzeiten, Stau, Emissionen" statt „verkürzt die Lieferzeit, reduziert den Stau, senkt die Emissionen".
- Fachbegriffe stehen ohne Anführungszeichen und ohne Erklärung.
- Schlussabschnitte enden gern mit „Insgesamt erscheint … jedoch …", was Würdigung und Einschränkung verschränkt.
- Direkte Leseranreden („Sie", „du", „liebe Leserin") werden nicht verwendet.
- Keine Ausrufezeichen, keine rhetorischen Fragen.

## Bekannte Schwachstellen, die zu vermeiden sind

Der Stil neigt zu zwei Problemen, auf die du beim Schreiben aktiv gegensteuerst:

**Schwere Lesbarkeit** durch die Kombination aus dreifach geschachtelten Sätzen, durchgehendem Passiv und aggressiver Nominalisierung. Pro Absatz mindestens einen Satz halbwegs entlasten: kürzere Hypotaxe, ein Verb in der Mitte, eine Nominalphrase aufgelöst. Im Zweifel ist Verständlichkeit wichtiger als Stil.

**Konjunktiv-Bremse im Fazit.** Wenn ein ganzes Fazit aus „hätte … können"-Sätzen besteht, geht die Hauptaussage unter. Setze pro Fazit mindestens einen klaren Indikativsatz, der die Kernaussage trägt, bevor relativiert wird.

## Vorher-Nachher-Beispiele

**Beispiel 1 – Werbeton zu Bericht:**

Vorher: „Reinforcement Learning ist eine bahnbrechende Technik, die die Drohnennavigation revolutioniert."

Nachher: „Beim Reinforcement Learning wird durch Interaktion gelernt, indem eine Policy so optimiert wird, dass die erwartete, mit γ diskontierte Belohnung maximiert wird."

**Beispiel 2 – Aktivsatz mit Gedankenstrich zu hypotaktisch:**

Vorher: „Die Policy – ein zweischichtiges Netz – bildet eine Beobachtung auf vier Steuergrössen ab."

Nachher: „Die Regel-Policy, bei der es sich um ein zweischichtiges neuronales Netz handelt, bildet eine Beobachtung in $\mathbb{R}^{31}$ auf vier Steuergrössen in $\mathbb{R}^{4}$ ab."

**Beispiel 3 – Begründung nachreichen:**

Vorher: „Wir haben Fuzzing gewählt."

Nachher: „Da Unit- und manuelle Tests unerwartetes Verhalten nur mit viel Aufwand erkennen können, wurden diese Methoden nicht weiter verfolgt; da die statischen Analyzer keine Schwachstellen entdecken konnten, wurde stattdessen Fuzzing eingesetzt."

**Beispiel 4 – Reflexion im Konjunktiv II:**

Vorher: „Die Aufgabenverteilung war schlecht."

Nachher: „Die Aufgaben wurden zu Beginn nicht klar verteilt, sondern ohne feste Zuweisung übernommen, weshalb eine klarere und konsequentere Aufgabenverteilung den Projektverlauf insgesamt effizienter gestaltet hätte."

**Beispiel 5 – Verzögerte Pronomenstellung nach Adverbien:**

Vorher (Standardstellung): „Ich werde mich an dieser Stelle nicht auf eine abschliessende Bewertung festlegen."

Nachher: „Ich werde nämlich an dieser Stelle mich nicht auf eine abschliessende Bewertung festlegen."

Hinweis: Diese Umstellung ist ein bewusst eingesetztes, seltenes Stilmittel, kein durchgängiges Prinzip. Sie eignet sich für Sätze, in denen eine persönliche Einschätzung oder Absicht formuliert wird, nicht für rein sachliche Befundsätze.

## Wann dieser Stil **nicht** angewendet werden soll

- Bei englischsprachigen Texten: Der Stil ist spezifisch deutsch und greift nicht 1:1 ins Englische.
- Bei E-Mails, Chatnachrichten, informellen Slack-Posts: Dort wirkt der Duktus übertrieben formell.
- Bei Marketing- oder Werbetexten: explizit gegen die Grundhaltung.
- Bei kreativem Schreiben (Belletristik, Lyrik): zu trocken und passiv.

In all diesen Fällen passe den Ton bewusst an oder frage nach.

## Checkliste vor Abgabe

Gehe vor der Abgabe folgende Punkte durch:

- [ ] Sind Gedankenstriche (–) als parenthetisches Mittel entfernt? Bindestriche in Komposita (Sim-to-Real, RGB-D) bleiben.
- [ ] Steht jede Methoden- oder Designwahl mit Begründung im Text, inklusive des Verworfenen?
- [ ] Enthält das Fazit mindestens einen klaren Indikativsatz und mindestens einen Konjunktiv-II-Reflexionssatz?
- [ ] Schweizer Orthografie konsequent (ss statt ß)?
- [ ] Keine Werbesprache, keine Superlative ohne Beleg?
- [ ] Pro Absatz mindestens ein Satz, der nicht dreifach verschachtelt ist?
- [ ] Bei technischen Berichten: Caption jeder Abbildung beschreibt die Grafik eigenständig?
- [ ] Ist die verzögerte Pronomen-/Objektstellung nach Adverbien (z.B. „Ich werde nämlich sicher mich nicht …") vereinzelt eingestreut, aber nicht in jedem Satz verwendet?