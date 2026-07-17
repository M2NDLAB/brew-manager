#!/usr/bin/env bash
# Self-test di scripts/hooks-install.sh — caso "symlink dangling + FORCE_OVERWRITE=1" (IMP-032).
#
# Difetto (RED, prima del fix): nel ramo FORCE_OVERWRITE=1, un hook preesistente che è un
# symlink DANGLING (bersaglio inesistente) fa fallire `cp -L "${target}" "${target}.bak"`
# (cp dereferenzia il link → bersaglio assente → errore); sotto `set -euo pipefail` lo script
# ABORTA con exit!=0 PRIMA del backup e del `rm`, in divergenza col commento di testata che
# promette "si procede: backup poi rimozione". Nessuna perdita dati (un dangling non ha
# contenuto), ma il contratto dichiarato è violato e l'errore è criptico.
#
# Atteso (GREEN, dopo il fix): lo script salta il backup vacuo con un avviso dedicato, rimuove
# comunque il link e installa l'hook generato, uscendo 0.
#
# Il test è HERMETIC: stub di gitleaks/npx (i prerequisiti non c'entrano con la logica in prova)
# e un repo git usa-e-getta. Esegue lo script REALE end-to-end (smoke, non solo l'unità isolata).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_INSTALL="${SCRIPT_DIR}/hooks-install.sh"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

# --- Stub dei prerequisiti: isolano la logica FORCE dai check gitleaks/npx ------------------
stub_bin="${workdir}/bin"
mkdir -p "${stub_bin}"
for tool in gitleaks npx; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "${stub_bin}/${tool}"
  chmod +x "${stub_bin}/${tool}"
done
export PATH="${stub_bin}:${PATH}"

# --- Repo usa-e-getta con una COPIA dello script (REPO_ROOT deriva dalla posizione dello script)
repo="${workdir}/repo"
mkdir -p "${repo}/scripts"
git init -q "${repo}"
cp "${HOOKS_INSTALL}" "${repo}/scripts/hooks-install.sh"

# --- Pianta un symlink DANGLING come hook pre-commit preesistente ---------------------------
ln -s "/percorso/che/non/esiste/xyz" "${repo}/.git/hooks/pre-commit"
if [[ ! -L "${repo}/.git/hooks/pre-commit" || -e "${repo}/.git/hooks/pre-commit" ]]; then
  echo "SETUP FALLITO: il symlink dangling non è stato creato come atteso" >&2
  exit 1
fi

# --- Esegui lo script sotto test con FORCE_OVERWRITE=1 --------------------------------------
set +e
FORCE_OVERWRITE=1 bash "${repo}/scripts/hooks-install.sh" >"${workdir}/out.log" 2>&1
rc=$?
set -e

fail() {
  echo "FAIL (IMP-032): $1" >&2
  echo "--- output dello script (rc=${rc}) ---" >&2
  cat "${workdir}/out.log" >&2
  exit 1
}

# --- Asserzioni GREEN -----------------------------------------------------------------------
target="${repo}/.git/hooks/pre-commit"
[[ ${rc} -eq 0 ]]      || fail "exit code atteso 0, ottenuto ${rc} (cp -L sul dangling ha abortito lo script?)"
[[ ! -L "${target}" ]] || fail "il symlink dangling non è stato rimosso"
[[ -f "${target}" ]]   || fail "l'hook generato non è stato installato al posto del link"
grep -q "Hook generato da scripts/hooks-install.sh" "${target}" \
                       || fail "il pre-commit installato non è quello generato dal framework"
[[ ! -e "${target}.bak" ]] \
                       || fail "un dangling non ha contenuto: non deve creare un .bak vacuo"

echo "PASS (IMP-032): dangling + FORCE_OVERWRITE=1 → nessun abort, link rimosso, hook installato, nessun .bak vacuo."
