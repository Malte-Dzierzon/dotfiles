# idea-to-paper — Idee → Research Paper + Prototyp-Plan

Aktivierung: `/idea-to-paper` oder `paper-modus an`. Danach beschreibt der User seine Idee in einem Satz/Absatz, dann startet der Loop.

## Loop-Regeln (verbindlich)
- Max 50 Fragen insgesamt, 2–4 pro Runde. Jede Runde: erst 1–2 Sätze eigene Überlegung + 1 kurzer Web-Fund (wenn relevant), dann Fragen.
- Jede Frage: nummeriert `[Frage N/50]`, mit 2–4STD-Optionen + **immer** die Optionen `eigene Antwort tippen` und `weiter/skip`.
- `weiter/skip` → offene Fragen mit sinnvollen Defaults beantworten, Loop fortsetzen.
- Nach jeder 3. Runde: Zwischenfazit (max 5 Bulletpoints) + Entscheidung: weiter fragen oder in Synthese gehen.
- User kann jederzeit `synthese` tippen → Loop abbrechen, Artefakte erzeugen.
- Kein Warten auf Perfektion: nach max 50 Fragen automatisch Synthese.

## Paper-Suche (OpenAlex, kein Key nötig)
- Pro Kernbegriff: `https://api.openalex.org/works?search=<begriff>&per-page=5&select=id,title,authorships,publication_year,cited_by_count,doi,open_access`
- Via `read` abrufen, Top-Treffer nach Zitationen filtern, in Synthese als Related Work einbauen.
- Fallback bei leeren Treffern: `web_search` mit `"paper" <begriff> filetype:pdf OR arxiv OR doi`.

## Synthese-Artefakte (Pflicht, ins Ziel-Repo)
1. `PAPER.md` — Titel, Abstract, Motivation, Related Work (mit OpenAlex-Funden + DOI), Methode/Architektur, Evaluationsplan, Risiken, Next Steps. Formeln in `$…$`.
2. `AGENTS.md` — Umsetzungs-Anweisungen für Coding-Agents: Stack, Modul-Schnitt, Dateiplan, Build/Test-Befehle, Do/Don't.
3. `PROTOTYPE.md` — MVP-Scope (max 5 Dateien), Schrittplan, Akzeptanzkriterien je Schritt.
- Sprache: wie User-Idee (deutsch→deutsch, sonst englisch).

## Regeln
- Pragmatisch, ein Durchgang, kein Review-/Rebuttal-Overhead.
- Melde am Ende nur die 3 Dateipfade + 3-Satz-Zusammenfassung.
