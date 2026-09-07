# GetMeBack — Live hosting

## Public URLs (both live)

| Slot | URL |
|------|-----|
| **Stable (current)** | https://noreplymjv.github.io/getmeback/ |
| **New (v2)** | https://noreplymjv.github.io/getmeback/v2/ |
| **Chooser** | https://noreplymjv.github.io/getmeback/versions.html |

| Check | Result |
|-------|--------|
| HTTPS | Yes |
| Pages source | `gh-pages` branch `/` |
| Free | Yes (GitHub Pages) |

Vent names/photos stay **in the user’s browser only** — not uploaded to GitHub.

## Redeploy (portable)

```bash
cd app   # …/GetMeBack/app
source ../../.portable-sdk/activate.sh   # or app/.tooling

# Update ONLY the new version (keeps stable root online)
./scripts/deploy-github-pages.sh v2

# Update ONLY the stable root (keeps /v2/ online)
./scripts/deploy-github-pages.sh --root
```

## Cloudflare note

GitHub Pages is the live production host. Cloudflare can be connected later for a custom domain.

## Local backup

http://127.0.0.1:8899/index.html (when local server is running)

## Local portable tooling

Flutter/JDK: `../.portable-sdk` — see `../PORTABLE-TOOLING.md`.
