# Development workflow

By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
https://www.youtube.com/@RetroErik

## VS Code setup

Open **this application directory** as the VS Code folder so its `.vscode`
settings, tasks, and launch configuration are active. The Git repository root
is the parent `DOS Utils` directory. Workspace-wide instructions still apply.

Use the recommended Microsoft C# Dev Kit, WinApp, PowerShell, and OpenAI Codex
extensions. Run **Developer: Reload Window** after installing extensions.
WinApp editor tooling is currently public preview. The app remains an unpackaged
WinUI 3 app; installing editor tools does not change its release format.

The .NET 10 SDK is required. `global.json` accepts stable .NET 10 feature bands
and patches, without automatically switching to .NET 11 or a preview SDK.

Microsoft's agent plugins are installed separately from VS Code extensions:

```text
codex plugin marketplace add microsoft/WinAppCli
codex plugin add winui@winappcli
codex plugin add winappcli@winappcli
```

Start a new Codex session after installation to discover the new skills.
Useful skills include `winui-code-review`, `winui-dev-workflow`, and
`winui-ui-testing`. Verify the machine with `winui-setup` when needed.
WinApp CLI 0.7 or later supports the current skill workflows.

Official references:

- [WinUI agent plugin](https://learn.microsoft.com/en-us/windows/apps/develop/ai-assisted/winui-agent-plugin)
- [WinApp VS Code extension](https://marketplace.visualstudio.com/items?itemName=Microsoft-WinAppCLI.winapp)
- [Code page provider behavior on modern .NET](https://learn.microsoft.com/en-us/dotnet/api/system.text.codepagesencodingprovider)

## Build, test, and debug

Press **Ctrl+Shift+B** to build Debug and run the core regression harness.
Press **F5** to run the same checks and launch the existing unpackaged x64 app
under the C# debugger. A failed check prevents launching.
Choose **Tasks: Run Task → Build and test (Release)** for Release validation.

Equivalent terminal commands from this directory:

```text
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Configuration Debug
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Configuration Release
```

The test project is a console harness, so use `build.ps1`, not `dotnet test`.
The app project includes `Microsoft.Windows.SDK.BuildTools.WinUIAnalyzer` as a
private development dependency. Check warnings before committing; do not disable
the analyzer globally. Stable row metadata uses explicit OneTime bindings;
editable descriptions and derived status use TwoWay and OneWay respectively.

For API discovery, scope WinApp to the restored app project:

```text
winapp find-api members TextBox --filter Text --json --project-dir src/DescriptionEditForWindows
```

## Regression checks

Core tests cover UTF-8 with/without BOM, UTF-16 LE/BE, active Windows ANSI
decoding, status notifications, parsing, directory merge, stale-line removal,
backup creation, external-change detection, and UNC path syntax.

The ANSI regression uses the machine's active Windows ANSI page. On a system
configured for UTF-8 ANSI, run it again on a legacy ANSI system for fallback
coverage. UTF-8 validity alone cannot identify every historical DOS/OEM code
page; automatic OEM detection is not provided.

Use disposable folders when exercising the UI. Before release, check:

| Scenario | Expected behavior |
|---|---|
| Change or clear a description | Status updates immediately |
| Enter / Esc while editing | Finish in memory / restore the edit's original text |
| Save button and Ctrl+S | Save current values and preserve the previous file as a backup |
| Save, refresh, navigate, or close repeatedly | Operations cannot overlap or discard pending edits |
| Navigate with unsaved edits | Save, Discard, and Cancel work without overlapping dialogs |
| External modification | Overwrite prompt appears; Cancel preserves the external file |
| Delete selected MISSING rows | Only stale descriptions are removed on save |
| Invalid or inaccessible path | Error dialog appears; previous document remains usable |
| F5, Back, Up, mouse Back | Correct folder and history behavior |
| Light/dark/high contrast; 100–200% scaling | Readable labels, focus, descriptions, and status |
| Keyboard and screen reader | Named path field, list, and row controls are reachable |
| Writable/read-only/disconnected shares | Responsive UI, useful errors, correct backups |

Local UI automation can move focus and type on the desktop. Prefer Windows
Sandbox when it is already available. Do not enable Windows features or change
file associations as a side effect of a test. Keep screenshots and structured
results under ignored `artifacts/` paths.

The previously documented mouse-wheel issue is still a separate investigation;
do not claim it fixed without reproducing it on affected hardware.

## Review and rollback

The original app version is 1.0.5. Existing release ZIPs are preserved.
Before this review, all existing untracked XGA work was preserved in commit
`1651a2e`, tagged `checkpoint/before-winui-review-2026-11-20`.
The improvements are isolated on `improve/description-edit-winui`.

Inspect changes from the repository root:

```text
git status --short
git log --oneline checkpoint/before-winui-review-2026-11-20..HEAD
git diff checkpoint/before-winui-review-2026-11-20..HEAD -- "Description Edit for Windows"
```

With a clean working tree, switch back to the preserved baseline on `main`:

```text
git switch main
```

To inspect the checkpoint alongside the improved version without changing the
current checkout, create a separate directory from the repository root:

```text
git worktree add --detach "../DOS-Utils-before-winui" checkpoint/before-winui-review-2026-11-20
```

Rebuild after switching revisions. For changes already merged into shared
history, use `git revert <commit>` rather than rewriting history. Tool
installations are per-user and are independent of Git rollback. No push or
publication is part of this review.
