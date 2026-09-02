# tools/

## dbus_control.sh

Controls a live Maxwell widget over DBus - write any `contents/config/main.xml`
entry (not just `dbustrigger`) into a running instance, and pick which
instance if you have more than one on your desktop.

```bash
./tools/dbus_control.sh [OPTION] [key=value ...]
```

- **No `key=value` given** — defaults to bumping `dbustrigger`, i.e. plays
  the theme song. `MaxwellWidget.qml` watches that value and plays
  regardless of the widget's "Play theme song" setting, so this works even
  if that's set to "Never".
- **`key=value` (repeatable)** — writes any config entry, e.g.
  `gifspeed=2.5`, `mirror=true`, `displaymode="3D Mesh"`. Values are typed
  as int/float/bool/string based on their shape.
- **`-i`/`--index N`** — target the Nth Maxwell instance found (0-based,
  desktops before panels). Default `0`, i.e. the first one found — with
  no selector, only that one instance is touched, so having several
  Maxwells on your desktop doesn't mean they all react at once.
- **`--id ID`** — target the instance with that exact Plasma applet id
  instead of a position (see `--list`). Takes precedence over `--index`.
- **`-l`/`--list`** — print every Maxwell instance found (index, applet id,
  desktop/panel) and exit without changing anything.
- **`-p`/`--list-properties`** — print every config entry that can be
  used as a `key=value` (name, type, default, description) and exit.
  Kept in sync with `contents/config/main.xml` by hand — see the note in
  `AGENTS.md`'s "New config options" list.
- **`-h`/`--help`** — print full usage, examples, and the properties
  table, then exit.

Examples:

```bash
./tools/dbus_control.sh                          # play the theme song
./tools/dbus_control.sh gifspeed=3 mirror=true    # tweak GIF playback
./tools/dbus_control.sh --list
./tools/dbus_control.sh --list-properties
./tools/dbus_control.sh --id 42 displaymode="3D Mesh"
./tools/dbus_control.sh --index 1 dbustrigger=1   # play on the 2nd instance
./tools/dbus_control.sh --help
```

It works by calling `org.kde.plasmashell`'s `evaluateScript` DBus method
(via `qdbus`/`qdbus-qt6`/`qdbus6`, whichever is found first) to run a
small Plasma Shell script that enumerates widgets of type `maxwell` across
all desktops and panels, picks the target instance, and calls
`writeConfig()`/`reloadConfig()` on it — the same mechanism `General.qml`
itself uses to persist settings, just invoked from outside the widget.

Requires a running `plasmashell` (i.e. an actual Plasma session) and at
least one Maxwell widget already added to the desktop or a panel.

### Calling it directly, without the script

This isn't running a hidden background service — it's a single, real DBus
method call (`org.kde.PlasmaShell.evaluateScript`, an existing method that
`plasmashell` always exposes), so any DBus tool can invoke it directly.
`dbus_control.sh` just builds this call for you from its arguments;
here's the same request (trigger the first instance found) written out by
hand with `qdbus`:

```bash
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
function findFirst(containments) {
    for (var i = 0; i < containments.length; i++) {
        var widgets = containments[i].widgets("maxwell");
        if (widgets.length > 0) {
            return widgets[0];
        }
    }
    return null;
}
var target = findFirst(desktops()) || findFirst(panels());
if (target) {
    target.currentConfigGroup = ["General"];
    target.writeConfig("dbustrigger", Date.now());
    target.reloadConfig();
    print("Maxwell instance triggered");
} else {
    print("No Maxwell instance found");
}
'
```

Or with `busctl` (note the `s` type signature before the script string):

```bash
busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s '
function findFirst(containments) {
    for (var i = 0; i < containments.length; i++) {
        var widgets = containments[i].widgets("maxwell");
        if (widgets.length > 0) {
            return widgets[0];
        }
    }
    return null;
}
var target = findFirst(desktops()) || findFirst(panels());
if (target) {
    target.currentConfigGroup = ["General"];
    target.writeConfig("dbustrigger", Date.now());
    target.reloadConfig();
    print("Maxwell instance triggered");
} else {
    print("No Maxwell instance found");
}
'
```

To set an arbitrary config entry by hand instead, swap the
`target.writeConfig("dbustrigger", Date.now())` line for e.g.
`target.writeConfig("gifspeed", 3)` — the script does exactly this,
generalized to any key/value pairs and to `--index`/`--id`/`--list`.

Note: Plasma doesn't give a QML-only widget like Maxwell its own dedicated
DBus interface/method (e.g. a bare `PlayThemeSong()` you'd see with no
arguments in `d-feet`) — that would need a compiled C++ component or a
separate background daemon to own a DBus service name, which is a much
bigger commitment than this hobby widget's pure-QML, KDE-Store-tarball
packaging is set up for. Routing through `evaluateScript` is the
lightest-weight way to reach a running widget instance over DBus without
that.

## grab_screenshot.qml

Renders `view3d.qml` (3D Mesh mode) offscreen at a chosen pose and saves
it as a **transparent** PNG. Useful for KDE Store listing screenshots,
README images, etc. — anywhere you want Maxwell without a background to
crop or key out by hand.

Adapted from the equivalent tool in
[contriburg](https://github.com/wilversings/contriburg). It doesn't touch
a live Plasmoid, panel, or `plasmoidviewer` at all — it supplies its own
minimal mock `plasmoid` context property (the same one `tests/tst_main.qml`
uses) so `view3d.qml` loads standalone. The transparency comes from
`view3d.qml`'s own `SceneEnvironment.Transparent` setup — this script just
grabs the rendered frame with `Item.grabToImage()`, which preserves alpha,
instead of screenshotting a real window (desktop screenshot tools flatten
transparency against whatever's behind the window, so they won't work for
this).

Unlike contriburg's tool, the root `Item` here is `visible: true`, not
`false`. `view3d.qml`'s 3D content renders through QtQuick3D's own
internal render pass, which only picks up a property change once the
window has actually been shown and the render loop has run at least one
real frame — with `visible: false` (contriburg's approach, fine for its
plain 2D content), `grabToImage()` keeps grabbing whatever the 3D scene's
texture happened to be at its very first sync, no matter what you change
afterwards. This cost some debugging time (see git history if curious),
so: don't "fix" this back to `visible: false`.

### Usage

Requires the `qml-qt6` binary (ships with `qt6-qtdeclarative`/
`qt6-qtdeclarative-devel`, same as `tests/`), plus QtQuick3D and the
Assimp asset import plugin — same requirements as running the actual
widget in 3D Mesh mode, see `AGENTS.md`. Also needs a real windowing
backend (a live desktop session, or Xvfb) — the Qt `offscreen` QPA
platform doesn't support QtQuick3D's RHI-based rendering at all. Run from
the `tools/` directory (the script's `Loader` source path is relative to
it):

```bash
cd tools
qml-qt6 grab_screenshot.qml
```

This saves `maxwell-3d.png` (500x500, posed at a 45° yaw) into the
current directory.

All arguments are optional and positional:

```bash
qml-qt6 grab_screenshot.qml [outputPath] [width] [height] [rotationY]
```

Examples:

```bash
# Custom output path and size
qml-qt6 grab_screenshot.qml store-listing.png 1200 900

# Face Maxwell the other way
qml-qt6 grab_screenshot.qml turned-shot.png 500 500 180
```

The tool pauses `view3d.qml`'s spin animation (`modelSpinning`) and poses
the model directly (`modelEulerRotation`) before grabbing, so the pose is
fully controlled by `rotationY` (degrees) and reproducible — the same
arguments always produce a byte-identical image. This is intentional:
the spin animation itself never actually advances during an offscreen
`grabToImage()` capture (it's driven by the render loop, which a
never-shown window doesn't run), so waiting longer or changing
`glbspeed` before grabbing can't change the captured pose — only setting
`modelEulerRotation` directly can.

### Troubleshooting

- **Blank/empty image, exit code 1, "failed to load view3d.qml"**: Qt
  Quick 3D isn't installed in this environment. Same requirement as
  running the actual widget — see `AGENTS.md`.
- **Exit code 1, "GLB model failed to load"**: the Assimp asset import
  plugin is missing — same failure mode `MaxwellWidget.qml` shows in the
  live widget via `hasError`.
- **Same pose every time regardless of `rotationY`**: check that
  `visible: true` wasn't reverted to `false` — see above.
- **No output at all**: `console.log` doesn't reliably surface from
  `qml-qt6` in some sandboxed environments — check the exit code
  (`echo $?`) and whether the output file was actually created instead of
  relying on the printed "Saved ..." message.
