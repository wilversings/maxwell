# Memory & GPU Analysis — GIF vs 3D Mesh Mode

Empirical measurement of Maxwell's memory and GPU footprint in each display
mode, a specific check for leaks when switching `3D Mesh` → `GIF` (does the
model, its GPU buffers, and the importing libraries get released?), and a
comparison of the default 3D mesh (loaded natively, no Assimp) against a
custom user-supplied mesh (loaded via `RuntimeLoader` + Assimp).

## Method

`MaxwellWidget.qml` was driven directly (mock `plasmoid`, same pattern as
`tests/tst_main.qml`) inside a real, visible `qml-qt6` window, so the 3D
path renders through the actual GPU rather than an offscreen/software path.
An external sampler launched the driver as its own child process and polled:

- **RSS**: `VmRSS`/`VmHWM` from `/proc/<pid>/status`.
- **GPU memory**: `drm-memory-vram` / `drm-memory-gtt` from
  `/proc/<pid>/fdinfo/*` (exposed per-process by the `amdgpu` kernel driver;
  only readable for a direct-child process on this system, hence launching
  the driver as the sampler's own child).
- **Assimp presence**: whether `libassimp.so` appears in `/proc/<pid>/maps`.

Hardware: AMD Radeon RX 7900 XT/XTX (`amdgpu`), KDE Plasma 6 Wayland
session. Numbers are AMD/amdgpu-specific in magnitude; the architectural
conclusions (leak behavior, Assimp lazy-loading) are driver-agnostic.

**Reproducible tooling**: `tools/measure_memory.qml` + `tools/measure_memory.sh`
(committed to the repo — see `tools/README.md`). Four experiments, each a
fresh process unless noted:

1. **Bare baseline** — plain Qt Quick window, no widget content.
2. **Steady-state single-mode cost** — fresh process cold-started into
   GIF-only, 3D-only (default mesh), or 3D-only (custom mesh), run long
   enough to reach a plateau.
3. **7-cycle switching test** — one continuous process alternating
   `3D → GIF → 3D → GIF …` eight times (12s dwell per phase, ~96s total,
   default mesh throughout), to see whether memory returns to baseline on
   every switch or creeps upward cycle over cycle.
4. **Default vs. custom mesh** — same steady-state 3D scene, only the mesh
   loading mechanism differs, to isolate Assimp's actual cost.

## Steady-state cost per mode

| | RSS | VRAM | GTT |
|---|---|---|---|
| Bare Qt Quick window (no widget) | 134.2 MB | 23.7 MB | 4.0 MB |
| GIF mode (cold, one full loop) | 240.9 MB (+106.7) | 141.7 MB (+118.0) | 6.0 MB (+2.0) |
| 3D mode, **default mesh** (cold) | 291.0 MB (+156.8) | 52.6 MB (+28.9) | 12.0 MB (+8.0) |
| 3D mode, **custom mesh** (cold) | 297.6 MB (+163.4) | 52.6 MB (+28.9) | 12.0 MB (+8.0) |

- **GIF**: VRAM climbs from ~32 MB to ~141.7 MB over ~8s (225 frames × ~33ms
  delay = one loop), then sits flat for further loops.
  `AnimatedImage`/`QMovie` decodes and GPU-uploads each frame as a distinct
  texture on its first pass, then reuses them — a real, bounded, one-time
  cost, not a leak, and larger than 3D mode's entire VRAM footprint.
- **3D, default mesh vs. custom mesh**: VRAM/GTT are identical either way —
  same geometry, same GPU footprint, regardless of how it got there.
  **RSS differs by ~6.6 MB** — this is Assimp's marginal cost inside the
  *full* widget process. Confirmed via `/proc/<pid>/maps`: `libassimp.so`
  is present for the custom-mesh run and **absent** for the default-mesh
  run, every time, across repeated trials.

### Why the isolated Assimp cost (~37 MB) is bigger than the in-widget cost (~6.6 MB)

A minimal test scene (just `View3D` + camera + one mesh, no `QtMultimedia`,
no rest of `MaxwellWidget.qml`) shows a larger jump — 151.3 MB → 189.6 MB,
**~37 MB** — when adding `RuntimeLoader` + Assimp. In the full widget the
same swap only costs ~6.6 MB. Both are real measurements of the same
underlying fact (Assimp isn't free); they differ because Assimp pulls in a
chain of dependency libraries (zlib, pugixml, poly2tri, and others), and in
the full widget most of that chain is already resident anyway — pulled in
by `QtMultimedia`/`ffmpeg`'s own codec libraries for entirely unrelated
reasons. The marginal, *additional* cost of Assimp specifically, on top of
everything else Maxwell already loads, is the smaller number: **~6.6 MB**.

## Does 3D → GIF actually unload the model?

Loading mechanism has changed since the original version of this doc: the
bundled default mesh now loads through a native Qt Quick 3D `Model` (via
`assets/mesh/MaxwellMesh.qml`, pre-converted from the GLB using Qt's
`balsam` tool — see `AGENTS.md`), not `RuntimeLoader`. The 7-cycle test
below uses the default mesh throughout, to check the *general* unload
behavior of `MaxwellWidget.qml`'s `Loader { active: is3DMode }` pattern
(covered for the `RuntimeLoader`/Assimp path too, in the previous version
of this doc — same conclusion, GTT still returns to baseline every time).

8 phases (12s each, starting in 3D), value at the **end** of each phase:

| Phase | Mode | RSS | VRAM | GTT |
|---|---|---|---|---|
| 0 | 3D (1st, cold) | 291.7 MB | 52.6 MB | **12.0 MB** |
| 1 | GIF (1st) | 292.0 MB | 141.7 MB | 6.0 MB |
| 2 | 3D (2nd) | 292.5 MB | 166.6 MB | **12.0 MB** |
| 3 | GIF (2nd) | 292.5 MB | 159.7 MB | 4.0 MB |
| 4 | 3D (3rd) | 292.6 MB | 166.6 MB | **12.0 MB** |
| 5 | GIF (3rd) | 292.6 MB | 163.5 MB | 4.0 MB |
| 6 | 3D (4th) | 292.6 MB | 163.5 MB | **12.0 MB** |
| 7 | GIF (4th, final) | 292.6 MB | 163.5 MB | 4.0 MB |

**GTT: full, clean release every cycle** — 12.0 MB while in 3D, back to
4.0–6.0 MB every time GIF is active, repeated identically across all 4
cycles. This is `Model`'s (or `RuntimeLoader`'s) GPU staging buffers being
properly destroyed each time `Loader { active: is3DMode }` deactivates —
direct evidence the 3D scene is actually torn down, not hidden.

**VRAM: jumps once, then stays flat — and the cause isn't the 3D content.**
The first 3D phase (never having touched GIF) sits at 52.6 MB. From the
second 3D phase onward it's 166.6 MB — a ~114 MB jump — but this happens
with the **same native mesh** used throughout, no `RuntimeLoader`/Assimp
anywhere in this test. The real explanation: `AnimatedImage` in
`MaxwellWidget.qml` is a static, always-present element (only its
`visible` toggles with display mode — unlike the 3D content, it's never
destroyed via `Loader`), so once GIF mode has decoded its 225-frame texture
cache (~141.7 MB), that VRAM stays resident for the rest of the process's
life, on top of whatever 3D needs, regardless of which mode is currently
shown. It's a real, bounded, one-time cost of having visited GIF mode at
all in this session — not a leak (flat across phases 2/4/6, no growth) and
not specific to 3D content's own loading/unloading correctness.

**RSS: negligible growth.** 291.7 MB → 292.6 MB over 4 more full cycles —
0.9 MB total, 0.3%, with no consistent upward slope. RSS not shrinking
after freeing memory is normal glibc `malloc` behavior (freed heap pages
usually aren't returned to the OS) and isn't evidence of a leak by itself;
what matters is whether it climbs indefinitely with repeated cycling, and
it doesn't.

## Verdict

**No leak.** Switching `3D Mesh` → `GIF` correctly and fully releases the
3D scene's GPU staging resources (GTT), confirmed flat across 4 repeated
cycles regardless of which mesh-loading mechanism is used. `RSS` shows no
meaningful growth trend either. The one thing that *does* stay resident
after first use — GIF mode's ~142 MB decoded-frame VRAM cache — is
`AnimatedImage`'s own deliberate design (never destroyed, only hidden, so
switching back to GIF is instant) rather than anything specific to 3D mode,
and it doesn't grow further with repeated switching.

**The default 3D mesh no longer needs Assimp at runtime.** Pre-converting
the bundled GLB to Qt Quick 3D's native format via `balsam` means
`libassimp.so` is never loaded into the process unless a user explicitly
configures a custom mesh via "Path to 3D Mesh" — worth ~6.6 MB RSS in the
full widget (~37 MB in isolation; the gap is because Assimp's dependency
chain overlaps heavily with libraries `QtMultimedia` already loads). On
Fedora this doesn't reduce *install* requirements (`qt6-qtquick3d`'s RPM
hard-requires `assimp` regardless), but it does reduce runtime RAM, and on
other distros/packaging where that coupling doesn't exist, it removes the
install requirement entirely for users who stick with the default cat.

## Tooling

`tools/measure_memory.qml` + `tools/measure_memory.sh` (committed to the
repo, see `tools/README.md`) reproduce all measurements above. Ran on the
**host** machine — already had `qml-qt6`, `qt6-qtquick3d`, and `assimp`
installed from earlier work in this project, and `amdgpu`'s `fdinfo` GPU
accounting needed no extra packages.

**Packages installed in `plasma-widget-dev` distrobox this session**:
`qt6-qtquick3d-devel` (for the `balsam` asset-conversion tool, used once to
pre-convert the bundled GLB — not needed at runtime). Everything else
(`qt6-qtmultimedia`, `qt6-qtquick3d`, `assimp`) was already installed from
earlier sessions.
