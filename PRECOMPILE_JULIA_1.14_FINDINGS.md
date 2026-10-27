# Precompile stall on Julia 1.14 (alpha) - findings and test protocol

Status: **experimental branch, work paused.** Written for a human user and for an AI agent that picks this up later
(e.g. after testing on Ubuntu / macOS).

## 1. Symptom

`pkg> precompile` of CasualPlots hangs on Julia `1.14.0-alpha2` (Windows 11) while it works on 1.13.
After Ctrl-C the log shows, repeating:

```
[pid N] Waiting for background task / IO / timer to finish:
 Handle type        uv_handle_t->data
 pipe[NNNN]         ...->...
```

The message comes from Julia's precompile worker: it refuses to finish while a libuv handle is still open.
The workload in `src/precompile.jl` starts a hidden Electron window (`Ele.serve_app(app; show=false)`).

## 2. Findings

### 2.1 Real bugs found and fixed (independent of 1.14)
| Bug | Effect |
|---|---|
| Workload looped over `[Lines, Scatter, BarPlot]` (Makie types), but `get_plot_config` needs the strings `"Lines"`, `"Scatter"`, `"BarPlot"` | `MethodError` on every Julia version since July 2026. It was swallowed by `catch e; @debug ...`, so the plotting part of the workload never ran. |
| Cleanup (`close(app)`, `Ele.close_display`) was inside `try`, after the code that could throw | After any error the Electron process and its pipes stayed open. |

Both are fixed in `src/precompile.jl`: string plot types, cleanup in `finally`, `@error` plus `rethrow`.
Even with these fixes, the stall on 1.14 remains.

### 2.2 The stall is caused by Electron.jl, not by CasualPlots, Bonito or WGLMakie
Bisect with the temporary switch `CASUALPLOTS_PC_STAGE` (Windows, Julia 1.14.0-alpha2, Electron.jl 7.0.0):

| Stage | Workload | Result on 1.14 |
|---|---|---|
| 0 | DataFrame preprocessing only | **passes** (8 s) |
| 1 | + `Ele.get_electron_app()` then `Ele.close_display(; strict=true)` (no Bonito, no app, no window) | **stalls** |
| 3 | full workload (app, window, plots) | stalls |

Stage 1 is the **minimal reproducer**: starting and closing an `Electron.Application()` is enough.

### 2.3 What is known about the leftover pipe
Measured right after `close_display(strict=true)`, in stage 3 (diagnostic output `PCDIAG`):
- `electron.exe` has exited: `running=false`, `exitcode=0`, within about 0.1 s.
- `proc.in` (the stdin `PipeEndpoint` of the spawned process) stays open after `close(app)`. It is not in `Base.uvhandles`.
  Closing it explicitly works, but **does not fix the stall**.
- After that, `Base.uvhandles` contains no pipe, yet the stall persists.
- The `pipe[N]` number in the stall message never matched a handle visible from Julia. Handle values do not follow creation order.

Conclusion: the leftover pipe is **not reachable from Julia objects**. It is inside Electron.jl or libuv
(a candidate is one of the sockets or servers created in `Electron.Application()`; unverified).
Earlier attempts that did not help on 1.14: `Bonito.cleanup_globals()`, closing everything in `Base.uvhandles`,
`kill(proc)`, `close(proc.in)`.

### 2.4 Caveats about earlier "verification"
- "Precompile succeeds on 1.13" proves nothing: 1.13 never hung, even with everything left open.
- `isopen(::Process)` is always `true` here (stdout/stderr are `DevNull`), so it is useless as a guard.
- Julia gotcha: `VERSION < v"1.14"` is **true** for `1.14.0-alpha2` (prereleases sort below the release).
  Use `v"1.14.0-"` to catch all 1.14 prereleases. (This bug made one test run use the wrong stage.)

## 3. Current workaround (in this branch)

`src/precompile.jl`: the Electron part of the workload is skipped on Julia >= 1.14 by default.
Default stage is `3` for `VERSION < v"1.14.0-"`, else `0`. Env var `CASUALPLOTS_PC_STAGE` overrides it.
Verified: on 1.14 `precompile` now finishes in ~8 s. On 1.13 the full workload still runs.
Cost: slower first plot on 1.14, because the GUI path is not precompiled there.

The stage switch and the `PCDIAG` diagnostics are **temporary** experiment code. Remove them before merging anything.
The repository's intended final shape is a plain `VERSION < v"1.14.0-"` guard on the Electron part
(plus the fixes from 2.1). `src/electron.jl` was restored to its committed state and is unchanged.

## 4. How to test on another computer (Ubuntu, macOS, or another Windows machine)

Goal: find out whether the stage 1 stall is Windows-specific and whether it also appears on newer 1.14 builds.

1. Clone this branch, install Julia 1.14 (alpha or newer) via juliaup, e.g. `juliaup add 1.14` / `juliaup add alpha`.
2. Start `julia +1.14` in the project root, then:
   ```julia
   ] activate .
   ] instantiate
   ```
   The repo may contain only `Manifest-v1.13.toml` and `Manifest-v1.14.toml`; Julia picks the versioned one.
   If the 1.14 manifest does not resolve on that machine, run `] resolve` and note that.
3. **Baseline (default, stage 0 on 1.14):** `] precompile`. Expected: finishes in seconds.
4. **Reproducer (stage 1):** start a **fresh** Julia 1.14 session, then:
   ```julia
   ENV["CASUALPLOTS_PC_STAGE"] = "1"
   ```
   ```julia-repl
   (CasualPlots) pkg> precompile
   ```
   - If it finishes: record "stage 1 passes on <OS>". Optionally try stage 2 and 3 the same way (fresh session each time).
   - If it stalls: wait for the `PCDIAG ...` lines and the first `Waiting for background task...` message,
     press Ctrl-C, and keep the whole output. Restart Julia before the next run.
5. On Linux without a display, Electron may need `xvfb-run julia ...`. The workload is skipped when
   `Sys.islinux() && ENV["CI"] == "true"`; unset `CI` for the experiment.
6. Report for each machine: OS and version, `versioninfo()`, Electron.jl version
   (`] status Electron`), the stage reached, and the full log of any stall.

Notes: a passing stage gets cached; touch `src/precompile.jl` or change the stage's code to force a re-run.
The env var does not invalidate the cache, so after a pass run `] precompile` only after modifying the file.

## 5. Instructions for an AI agent continuing this work

- Read this file first. Do not repeat the dead ends listed in 2.3.
- Julia 1.14 sessions may not answer through Kaimon (they showed as `stalled` after a hung precompile).
  The user ran the 1.14 steps; Kaimon sessions on 1.13 were usable for parsing checks and introspection only.
  Do not conclude anything about 1.14 from a 1.13 run.
- Do not start Julia processes through the native terminal; use Kaimon, or ask the user to run commands.
- Next steps, in order of value:
  1. Collect the cross-platform results of section 4 and add them to a table in this file.
  2. If the stall also happens on Linux/macOS, it is an Electron.jl / Julia 1.14 issue. Prepare an upstream issue for
     Electron.jl using the stage 1 reproducer (`Electron.Application()` then `close(app)` inside a precompile workload).
     A truly minimal reproducer would be a tiny package whose `@compile_workload` only does that.
  3. Check whether newer Julia 1.14 builds or a newer Electron.jl fix it; if so, drop the guard.
  4. If the cause is found, a real fix would live in Electron.jl (closing the leaked pipe) or in
     `Ele.close_application` in `src/electron.jl`, not in the workload.
  5. Before merging: remove `CASUALPLOTS_PC_STAGE` and the `PCDIAG` code from `src/precompile.jl`, keep the `VERSION < v"1.14.0-"`
     guard, re-run the full 1.13 precompile, and ask the user about updating `AGENTS.md` and `docs/src/changelog.md`.

## 6. Files touched in this branch
- `src/precompile.jl` - bug fixes (2.1), temporary stage switch, `PCDIAG` diagnostics, default guard for >= 1.14.
- `src/CasualPlots.jl` - include condition for `precompile.jl` is `(VERSION.major, VERSION.minor) >= (1, 15) || include(...)`
  (already changed before this session; the `precompile.jl` file itself does the 1.14 skipping at runtime of the workload).
- `Project.toml` - version bump to 0.12.2 (made by the user, not part of this investigation).

