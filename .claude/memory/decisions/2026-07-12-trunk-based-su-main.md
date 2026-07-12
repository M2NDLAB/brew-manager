---
type: decision
updated: 2026-07-12
tags: [decision]
---
# Trunk-based su main: integrazione e stabile coincidono

- **Contesto**: all'innesto del framework andava dichiarato il modello di branching
  (docs/04 usa i RUOLI integrazione/stabile con default develop/main). brew-manager
  ha `main` attivo (v1.1.2, tutto il lavoro recente) e un `origin/dev` remoto
  allineato allo stesso commit di main (c0f456f), senza branch locale.
- **Decisione**: trunk-based su `main` — i due ruoli coincidono. Feature branch →
  merge in `main` via blocco `/integrate` (sviluppatore singolo, niente PR verso
  se stessi). `origin/dev` è considerato dormiente.
- **Alternative scartate**: ripristinare `dev` come integrazione (modello a due
  branch) — scartata perché dev è fermo e identico a main: aggiungerebbe cerimonia
  senza controllo aggiuntivo; il trunk-based è un caso previsto dal framework
  (IMP-025 del framework, che lo usa esso stesso).
- **Conseguenze**: dove i doc del framework dicono `develop`, qui vale `main`;
  `reset-task.sh` protegge `main` e `dev`; il regime di versioning è post-1.0
  (tag annotati su main alla release). Se dev tornasse in uso, questa decisione
  va rivista esplicitamente.
