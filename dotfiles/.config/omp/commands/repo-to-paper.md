# repo-to-paper — GitHub-Repo → Überblicks-PDF

Nimm ein lokales GitHub-Repo (oder URL) und erstelle ein Überblicks-PDF für Nicht-Professoren:
verständlich, Formeln in LaTeX, kein akademischer Apparat.

## Phasen

**Phase 1 — Repo scannen (lokal, kein Web):**
- Struktur (`glob`), README, zentrale Module, Tests identifizieren
- Ausgabe: `docs/overview-outline.md` — Kapitelvorschlag + Kernbegriffe

**Phase 2 — Online-Research:**
- Zu den Kernbegriffen 3–6 Quellen recherchieren (`web_search`, `read`)
- URLs + Kernaussagen in `docs/overview-sources.md` sammeln
- Nur was zum Verständnis beiträgt, keine Literaturliste für die Uni

**Phase 3 — Text schreiben:**
- Kapitel aus Outline füllen: Was macht das Projekt? Wie funktioniert's (mit LaTeX-Formeln)? Was zeigen die Tests? Einordnung via Research
- Ausgabe: `docs/overview-draft.md`, Markdown + `$…$`/`$$…$$` für Formeln
- Nutze für Fleißtext die `smol`-Rolle, Endredaktion mit `default`
- Bilder: vorhandene aus dem Repo übernehmen, sonst als Platzhalter `[BILD: Suchbegriff]` markieren

**Phase 4 — PDF rendern:**
- `overview-draft.md` → LaTeX → PDF nach `docs/overview.pdf`
- `[BILD: …]`-Platzhalter auflösen: Bild suchen, einbetten, neu rendern
- Tool: was verfügbar ist (`pandoc` bevorzugt, sonst Typst/LaTeX direkt)

**Phase 5 — Aufräumen (Pflicht):**
- Alles in `docs/` löschen AUSSER `overview.pdf`
- Also: `overview-outline.md`, `overview-sources.md`, `overview-draft.md`, `.tex`, Bilder, Logs
- Melde nur den Pfad des fertigen PDFs zurück

## Regeln
- Sprache des Repos/README beachten (deutsch → deutsch, sonst englisch)
- Kein Review-, kein Rebuttal-, kein Integrity-Overhead — ein Durchgang, pragmatisch
- `docs/`-Ordner im Ziel-Repo neu initialisieren falls nicht vorhanden
