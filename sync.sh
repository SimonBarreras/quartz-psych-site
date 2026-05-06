#!/bin/bash
# Weekly auto-sync: IB Psychology Notes → GitHub Pages
# Runs via launchd every Monday at 9 AM

VAULT_PSYCH="/Users/simon/Library/Mobile Documents/iCloud~md~obsidian/Documents/rigoberto walteros/Oak House/Psychology"
SITE="$HOME/quartz-psych-site"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sync..."

# Sync notes from vault
rsync -a --include="*/" --include="*.md" --exclude="*" \
  "$VAULT_PSYCH/" \
  "$SITE/content/"

# Only commit and push if something actually changed
cd "$SITE"
if ! git diff --quiet || ! git diff --cached --quiet; then
  git add -A
  git commit -m "Auto-update: $(date '+%Y-%m-%d')"
  git push
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Changes pushed."
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] No changes, nothing to push."
fi
