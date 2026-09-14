# GetMeBack — Live hosting

## Public URLs (all live)

| Slot | URL |
|------|-----|
| **v5 (recommended)** | https://noreplymjv.github.io/getmeback/v5/ |
| **v3a** | https://noreplymjv.github.io/getmeback/v3a/ |
| **v3** | https://noreplymjv.github.io/getmeback/v3/ |
| **v2** | https://noreplymjv.github.io/getmeback/v2/ |
| **Stable (root)** | https://noreplymjv.github.io/getmeback/ |
| **Chooser** | https://noreplymjv.github.io/getmeback/versions.html |

> **v5** ships world-class smash graphics: impact hit-flash, pulsing cinematic
> vignette, expanding + fading shockwave rings, richer branching crack decals,
> and beveled/edge-highlighted material shards.
>
> The **`/v4/` slot is reserved and currently unused (404)** — do not deploy into it.

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

# Update ONLY v5 (keeps root / v2 / v3 / v3a online)
./scripts/deploy-github-pages.sh v5

# Other slots
./scripts/deploy-github-pages.sh v3a
./scripts/deploy-github-pages.sh v3
./scripts/deploy-github-pages.sh v2
./scripts/deploy-github-pages.sh --root
# NOTE: never deploy /v4/ — reserved/unused slot
```

## Cloudflare note

GitHub Pages is the live production host. Cloudflare can be connected later for a custom domain.

## Local backup

http://127.0.0.1:8899/index.html (when local server is running)

## Local portable tooling

Flutter/JDK: `../.portable-sdk` — see `../PORTABLE-TOOLING.md`.
