# Automated regression tests

Run from the repository root with Godot 4.6 or newer and PowerShell:

```powershell
./tests/run_tests.ps1 -Godot /path/to/godot
```

The runner imports the project, tests the editor setup helper, runs the regression scene headlessly, and rejects
script errors, engine errors, failed checks, and missing completion output. Logs
and temporary test files are written under `.godot/`. It needs no testing addon.

The editor stage checks component creation, ownership, settings isolation, undo/redo,
and saving. The runtime stage also plays dialogue in that saved scene. Godot 4.6
reports native RID leaks at shutdown even with an empty `--editor --script`
SceneTree; the runner excludes only those editor shutdown messages from failure
detection. Runtime engine errors still fail the run.

You can also run `tests/regression_tests.tscn` directly in Godot. It exits with a
nonzero status on failed checks and has a timeout for suspended playback.

Coverage includes cancellation, completion chaining, stale timers, malformed DQD,
source-preserving replay, configuration, character import/export failures,
first-found lookup, text effects, zero increments, the existing dialogue examples,
and the documented flags API. `tests/tests.tscn` remains the manual UI example.
