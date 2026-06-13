# Flutter mobile dev — auto reload

## One command (recommended)

Stop any other `flutter run` first, then:

```bash
cd mobile
npm run dev
```

This keeps Flutter running in Chrome and **automatically hot-reloads** whenever any file in `lib/` changes (including when the AI edits code).

## What is configured

- **Auto save** — files save after 800ms
- **Hot reload on save** — when you save a `.dart` file in the editor
- **File watcher** — `scripts/dev.ps1` sends hot reload when `lib/` changes on disk

## Manual commands

| Command | Purpose |
|---------|---------|
| `npm run dev` | Run + auto reload on file changes |
| `npm run start` | Run once (no watcher) |

## Environment

```powershell
$env:API_URL = "http://localhost:5000"
$env:FLUTTER_DEVICE = "chrome"
npm run dev
```
