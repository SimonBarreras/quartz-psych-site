#!/bin/bash
# Daily auto-sync: Universidad de Navarra notes -> GitHub Pages
# Runs via launchd (com.simon.quartz-med-sync) every day at 9 AM

VAULT_MED="${VAULT_MED:-/Users/simon/Library/Mobile Documents/iCloud~md~obsidian/Documents/rigoberto walteros/Universidad de Navarra}"
SITE="${SITE:-$HOME/quartz-med-site}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sync..."

# Refuse to run against a missing or empty source, since --delete would wipe the site
if [ ! -d "$VAULT_MED" ] || [ -z "$(ls -A "$VAULT_MED" 2>/dev/null)" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Vault folder missing or empty: $VAULT_MED. Aborting."
  exit 1
fi

# Sync notes and attachments from vault. --delete removes notes you deleted or
# renamed in the vault. The site home page (content/index.md) is excluded,
# which also protects it from --delete.
rsync -a --delete \
  --exclude="/index.md" \
  --exclude="personal/" --exclude="Personal/" \
  --exclude=".obsidian/" --exclude=".trash/" --exclude=".DS_Store" \
  --include="*/" \
  --include="*.md" \
  --include="*.png" --include="*.jpg" --include="*.jpeg" --include="*.gif" \
  --include="*.svg" --include="*.webp" --include="*.pdf" \
  --exclude="*" \
  "$VAULT_MED/" \
  "$SITE/content/"

# Commit if something changed, then push anything not yet on GitHub
# (this also retries a push that failed on an earlier run)
cd "$SITE" || exit 1
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "Auto-update: $(date '+%Y-%m-%d')"
fi
if [ -n "$(git log --oneline @{u}..HEAD 2>/dev/null || echo unpushed)" ]; then
  if git push -u origin main; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Changes pushed."
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Push failed; will retry next run."
  fi
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] No changes, nothing to push."
fi
