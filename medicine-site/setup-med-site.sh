#!/bin/bash
# One-time setup for the medicine Quartz site.
# Run on your Mac from inside quartz-psych-site:  bash medicine-site/setup-med-site.sh
#
# It creates ~/quartz-med-site from this project's Quartz engine, pulls in your
# "Universidad de Navarra" notes, creates the GitHub repo, pushes it, and
# installs a daily launchd job that keeps the site in sync with the vault.
set -euo pipefail

GH_OWNER="SimonBarreras"
REPO_NAME="quartz-med-site"
SITE_TITLE="Medicine Notes"
PSYCH="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$PSYCH/medicine-site/template"
MED="${SITE:-$HOME/$REPO_NAME}"
PLIST_NAME="com.simon.quartz-med-sync.plist"

if [ -e "$MED" ]; then
  echo "$MED already exists. Remove it or set SITE=/other/path first." >&2
  exit 1
fi

echo "==> Copying Quartz engine to $MED"
mkdir -p "$MED"
rsync -a \
  --exclude=".git/" --exclude="node_modules/" --exclude="public/" --exclude=".quartz-cache/" \
  --exclude="/content/" --exclude="/medicine-site/" \
  --exclude="/sync.sh" --exclude="/sync.log" --exclude="/com.simon.quartz-psych-sync.plist" \
  "$PSYCH/" "$MED/"
rsync -a "$TEMPLATE/" "$MED/"

echo "==> Rebranding for $SITE_TITLE"
cd "$MED"
perl -pi -e "s#IB Psychology Notes#$SITE_TITLE#g; s#quartz-psych-site#$REPO_NAME#; s#ignorePatterns: \\[\"private\"#ignorePatterns: [\"private\", \"personal\", \"Personal\"#" quartz.config.ts
perl -pi -e "s|psych_auth|med_auth|g; s|quartz-psych-site|$REPO_NAME|g" quartz/components/Head.tsx
perl -pi -e "s|IB Psychology Notes|$SITE_TITLE|g; s|psych_auth|med_auth|g; s|quartz-psych-site|$REPO_NAME|g" \
  quartz/static/password-gate.html
printf '\n# Sync log\nsync.log\n' >> .gitignore

echo "==> Initialising git"
git init -q -b main
git add -A
git commit -q -m "Initial medicine site"

echo "==> Pulling notes from the vault"
SITE="$MED" bash "$MED/sync.sh" || true   # push fails until the remote exists; that's fine

if [ "${SKIP_GITHUB:-0}" = "1" ]; then
  echo "SKIP_GITHUB=1: stopping before GitHub and launchd steps."
  exit 0
fi

echo "==> Creating GitHub repo $GH_OWNER/$REPO_NAME"
if command -v gh >/dev/null 2>&1; then
  gh repo create "$GH_OWNER/$REPO_NAME" --public --source "$MED" --remote origin --push
else
  echo "GitHub CLI (gh) not found. Create an empty public repo named $REPO_NAME at"
  echo "https://github.com/new (no README), then press Enter to continue."
  read -r
  git remote add origin "https://github.com/$GH_OWNER/$REPO_NAME.git"
  git push -u origin main
fi

echo "==> Installing daily sync (9 AM)"
mkdir -p "$HOME/Library/LaunchAgents"
cp "$MED/$PLIST_NAME" "$HOME/Library/LaunchAgents/$PLIST_NAME"
launchctl unload "$HOME/Library/LaunchAgents/$PLIST_NAME" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/$PLIST_NAME"

cat <<MSG

Done. One manual step left:
  1. Wait for the first "Deploy Quartz site" run to finish:
     https://github.com/$GH_OWNER/$REPO_NAME/actions
  2. Then go to https://github.com/$GH_OWNER/$REPO_NAME/settings/pages
     and set Source = "Deploy from a branch", Branch = gh-pages, folder = / (root).

Your site will be at https://$(echo "$GH_OWNER" | tr "[:upper:]" "[:lower:]").github.io/$REPO_NAME/
To sync right now instead of waiting for 9 AM:  bash ~/$REPO_NAME/sync.sh
MSG
