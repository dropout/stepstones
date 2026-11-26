# Stepstones website

Legal and support pages served by Firebase Hosting at `https://stepstones-prod.web.app`.

- Pages are Markdown files in this folder; `_includes/layout.njk` wraps them.
- Set `updated:` in a page's front matter whenever its content changes.
- `npm run build` writes to `../public` (git-ignored); `npm run serve` previews with live reload.
- `firebase deploy --only hosting` builds the site first (see the `predeploy` in `../firebase.json`).
