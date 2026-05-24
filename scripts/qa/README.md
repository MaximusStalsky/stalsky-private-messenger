# QA Helpers

This folder contains local QA helpers for the My Messenger prototype. These scripts should stay non-destructive and should not modify server or app source files.

## Run Local QA

```powershell
.\scripts\qa\run-local-qa.ps1
```

Optional URLs:

```powershell
.\scripts\qa\run-local-qa.ps1 -WebUrl http://localhost:5173 -ApiUrl http://localhost:4000
```

The script performs lightweight checks:

- Confirms expected project folders exist.
- Detects package scripts in `server/` and `apps/` without changing them.
- Checks whether the configured web and API URLs respond.
- Prints the manual QA checklist location.

The script intentionally does not install dependencies, start services, reset data, or write files outside `scripts/qa/`.
