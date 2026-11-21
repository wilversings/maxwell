# Movement roadmap

Ideas for new movement types. All of them stick to what a stock Plasma 6
install already ships: QML/JS, `org.kde.ksysguard.sensors` (libksysguard),
`org.kde.plasma.plasma5support` data engines and `org.kde.taskmanager`. No
extra libraries, no C++, no special permissions.

Already implemented: `Constant`, `By CPU usage`, `By GPU usage`,
`By fan speed`, `By cursor proximity`.

## More sensors

Only a different sensor id, a range and a mapping onto speed are needed.
`HardwareSensor.qml` can be reused as-is.

- **RAM usage** (`memory/physical/usedPercent`): Maxwell gets slower as
  memory fills up, like he's full after a big meal.
- **Network traffic** (`network/all/download` + `network/all/upload`): spins
  one way on download and the other way on upload, with speed based on
  throughput. Probably the most fun to watch, and the cheapest to add.
- **Disk I/O** (`disk/all/read` / `disk/all/write`): spins when the drive is
  busy, like an old HDD activity light.
- **CPU or GPU temperature** (`cpu/all/averageTemperature`,
  `gpu/gpu0/temperature`): the hotter the machine, the faster he spins. The
  range could be learned the same way `FanRangeLearner.qml` learns fan RPM.
- **Battery** (`power/<battery>/chargePercentage`, charge rate): slows down
  as the battery drains and spins backwards while charging.

## Data engines (`Plasma5Support.DataSource`)

- **Music playing** (`mpris2` engine): spins only while a player is
  `Playing` and stops on pause. Speed could follow the playback rate or
  progress, or he could do a burst on each track change. Needs no audio
  capture, so no microphone permission.
- **Time of day** (`time` engine or plain JS `Date`): sleepy and slow at
  night, lively around midday. Alternatively, one full turn per minute so he
  works as a clock, with the seconds driving the rotation angle directly.
- **Clipboard** (`org.kde.plasma.clipboard` / Klipper engine): a quick spin
  burst every time something is copied.
- **Idle and activity** (`powermanagement` engine, or the `executable` engine
  running `qdbus` for the ScreenSaver idle time): winds down to sleep while
  you're away and speeds up when you come back.

## Desktop (`org.kde.taskmanager`)

- **Window count**: speed scales with the number of open windows.
- **Window switching**: a small spin impulse on each active-window change,
  decaying over time, so he reacts to alt-tabbing.
- **Fullscreen**: stops (or hides) while a fullscreen window is active, so he
  doesn't distract while gaming or watching something.

## Pure logic (no data source)

- **Wander**: speed and direction follow smooth noise (Perlin-like, easy in
  JS) with random pauses and direction flips, so he looks alive rather than
  mechanical.
- **Flick physics**: drag or flick him to spin, then inertia and friction
  until he stops. Idle drift could slowly start him up again on his own. In
  3D mode this has to coexist with the camera drag.
- **Pomodoro**: slow steady spin during focus time, a fast celebratory spin
  on breaks. The timer lives in QML.
- **Moon phase / sun position**: computed from the date (plus optional
  latitude/longitude in the config). Speed follows the moon's illumination
  or the sun's height.
- **Metronome**: the user sets a BPM and he does snappy half-turns on the
  beat. Could sync with the theme song.

## Combined

- **Stress**: the maximum of normalized CPU, GPU, temperature and RAM. One
  type that answers "is my PC struggling?"
- **Moods**: a small state machine (sleeping, idle, playful, panicking) fed by
  idle time, music and load. Each state gets its own speed profile, with
  eased transitions between them.

## Ruled out

These break the "no special libraries, C++ or permissions" constraint:

- **Microphone or system audio level**: QML can't read input levels without
  C++.
- **Global keyboard/mouse activity**: needs access to input devices.
- **Global cursor position**: not exposed to widgets, and Wayland doesn't
  allow it. `By cursor proximity` only sees the cursor on Maxwell's own
  surface for this reason.
- **Anything run through `executable` that needs root.**
