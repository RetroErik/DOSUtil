# Description Edit for Windows

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
https://www.youtube.com/@RetroErik

## Scope and architecture

- This is a Windows 11 x64 desktop application using C#, .NET 10, WinUI 3,
  and Microsoft.WindowsAppSDK 2.4.0. Keep its existing unpackaged deployment.
- Use `Microsoft.UI.Xaml` APIs. Do not introduce WPF, WinForms, or UWP UI types.
- Keep parsing, file models, and safe-save behavior in the platform-neutral
  `DescriptionEditForWindows.Core` project. Code-behind coordinates UI events,
  navigation, dialogs, and asynchronous work. Avoid broad architectural rewrites
  as part of a bug fix.
- Keep SDK/runtime versions pinned unless an upgrade is specifically needed.
  The WinUI analyzer is a private development dependency, not a runtime feature.
- Keep controls virtualized, use effective OneWay/TwoWay bindings for changing
  data, and provide accessible names and stable AutomationIds.
- Keep all UI collection/control access on the UI thread. Copy save values before
  starting worker tasks. Serialize document operations and ContentDialogs.
- Preserve the English interface, DES/4DOS colors, Unicode support, stale-line
  editing, conflict prompts, and same-directory backups.

## Tools and verification

- Use the installed Microsoft `winui` and `winappcli` plugin skills when relevant.
  Verify uncertain APIs against this app's restored references, for example:
  `winapp find-api members TextBox --filter Text --json --project-dir src/DescriptionEditForWindows`.
- Build and run the console test harness from this folder:
  `powershell -ExecutionPolicy Bypass -File .\build.ps1 -Configuration Debug`.
- Also run the Release build before completing a code change. Read all analyzer
  findings; do not blanket-disable diagnostics to obtain a clean build.
- The core tests are a console executable, not a `dotnet test` project.
- For behavioral fixes, add focused regression coverage. UI fixes also require
  running the application and exercising the changed behavior; report exactly
  what was checked and what still needs manual validation.
- Use disposable fixtures for save/navigation tests. Do not edit real description
  files, change associations, or overwrite preserved release ZIPs during testing.
- See `DEVELOPMENT.md` for setup, regression scenarios, and rollback instructions.

## Git and reversibility

- Inspect `git status` before starting. Preserve existing work before changes;
  do not discard or silently include unrelated edits in implementation commits.
- Work on a feature branch and keep setup changes separate from bug-fix commits.
- Preserve `checkpoint/before-winui-review-2026-11-20`. Never force-update it.
- Keep previous releases and third-party source unchanged. Do not publish or push
  without a request. Use ordinary commits and `git revert` for shared history.
