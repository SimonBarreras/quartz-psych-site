# Medicine site (quartz-med-site)

Setup kit for a second Quartz site that publishes the `Universidad de Navarra`
folder of the vault to `https://simonbarreras.github.io/quartz-med-site/`.

## One-time setup (on the Mac)

```bash
cd ~/quartz-psych-site && git pull && bash medicine-site/setup-med-site.sh
```

The script:

1. Creates `~/quartz-med-site` from this repo's Quartz engine (no psych notes).
2. Renames the site to "Medicine Notes" and points the password gate at the new
   site (same password as the psych site; change it in
   `quartz/static/password-gate.html`).
3. Copies notes and images from `rigoberto walteros/Universidad de Navarra`.
4. Creates the public GitHub repo `SimonBarreras/quartz-med-site` (via `gh` if
   installed, otherwise it asks you to create it on github.com) and pushes.
5. Installs a launchd job that runs `sync.sh` every day at 9 AM.

Then enable GitHub Pages once: repo Settings > Pages > Deploy from a branch >
`gh-pages` / root (after the first Actions run has created that branch).

## How updates work

`~/quartz-med-site/sync.sh` mirrors the vault folder into `content/`
(new, edited, renamed and deleted notes, plus png/jpg/gif/svg/webp/pdf
attachments), commits, and pushes. The push triggers the GitHub Action that
rebuilds the site. Folders named `personal`/`Personal`, `.obsidian` and
`.trash` are never copied. `content/index.md` is the home page and is managed in
the site repo, not the vault.

Run a sync by hand: `bash ~/quartz-med-site/sync.sh`. Log: `~/quartz-med-site/sync.log`.

If the vault folder lives somewhere else, edit `VAULT_MED` at the top of
`template/sync.sh` before running setup (or in `~/quartz-med-site/sync.sh` after).
