---
type: decision
updated: 2026-07-14
tags: [decision]
---
# Versione: file VERSION autorevole + git describe come arricchimento

- **Contesto**: BM-07 doveva sanare il drift (la costante nello script diceva
  1.1.0 mentre i tag erano a v1.1.2) e il piano lasciava aperta `[?]` la scelta
  tra file `VERSION` e `git describe`. Fatti verificati: il README installa via
  `git clone`, ma GitHub genera automaticamente tarball/zip per ogni tag — chi
  li scarica NON ha `.git`, e lì `git describe` non produce nulla.
- **Decisione** (approvata dall'utente 2026-07-14): file `VERSION` alla root come
  fonte AUTOREVOLE (presente sempre: clone, tarball, copia); `git describe`
  usato SOLO per arricchire la stringa quando esiste un work tree (mostra la
  distanza dal tag e lo stato dirty); `make version-check` come guard-rail che
  fallisce se `VERSION` e l'ultimo tag `vX.Y.Z` divergono.
- **Alternative scartate**: (a) solo `git describe` — fonte unica per costruzione
  e zero drift possibile, ma in un tarball la versione diventa "unknown" e ogni
  avvio costa un fork di git; (b) solo file `VERSION` — semplice e portabile, ma
  è ESATTAMENTE il pattern che ha prodotto il drift attuale: senza un check
  automatico si ri-disallinea alla prima release distratta.
- **Conseguenze**: alla release, `VERSION` e il tag vanno aggiornati nello STESSO
  commit (il check lo impone). `git describe` filtra i tag di release
  (`--match 'v[0-9]*.[0-9]*.[0-9]*' --exclude '*-*'`) perché i tag helper come
  `v1.1.2-baseline` altrimenti verrebbero agganciati come tag più vicino e la
  versione mostrata sarebbe fuorviante.
