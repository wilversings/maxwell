#!/usr/bin/env bash
# dbus_control.sh - Control a live Maxwell widget via DBus
#
# Finds a Maxwell widget instance (on the desktop or in a panel) and
# writes one or more values into its config, the same way General.qml
# does - so anything in contents/config/main.xml can be changed live,
# not just "dbustrigger". Called with no key=value pairs, it defaults to
# bumping "dbustrigger", which MaxwellWidget.qml watches to play the
# theme song - this works even if the widget's "Play theme song" setting
# is "Never", since this is an explicit external request, not a click.
#
# Run with --help for usage, examples, and the full list of properties
# that can be set.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

# Keep in sync with contents/config/main.xml (see AGENTS.md's "New config
# options should be added to..." list - this file is one of those places).
# Format: name|type|default|description
PROPERTIES=(
    "displaymode|String|GIF|Display mode: \"GIF\" or \"3D Mesh\""
    "gifpath|Path|assets/maxwell-spinning.gif|Path to the animated GIF to display"
    "glbpath|Path|assets/maxwell-spinning.glb|Path to the 3D model (GLB) to display"
    "themepath|Path|assets/stockmarket.wav|Path to the theme song audio file"
    "playthemesong|String|On Double Click|When to play theme song (Never, On Click, On Double Click)"
    "themesongloops|Int|1|Number of times to loop the theme song"
    "gifspeed|Double|1|GIF animation playback speed multiplier"
    "glbspeed|Double|2|3D model rotation speed multiplier"
    "mirror|Bool|false|Whether to mirror the GIF horizontally"
    "hq|Bool|true|Whether to use mipmap for higher quality GIF rendering"
    "allowcameradrag|Bool|true|Whether dragging in 3D Mesh mode orbits the camera"
    "camposx|Double|10|Persisted 3D camera orbit target (X)"
    "camposy|Double|8|Persisted 3D camera orbit target (Y)"
    "camposz|Double|5|Persisted 3D camera orbit target (Z)"
    "camrotx|Double|-20|Persisted 3D camera orbit angle (X)"
    "camroty|Double|0|Persisted 3D camera orbit angle (Y)"
    "camzoom|Double|33|Persisted 3D camera distance"
    "dbustrigger|Int|0|Not user-facing - bump (any changed value) to play the theme song. This is what happens when no key=value is given"
)

print_properties() {
    printf '%-16s %-7s %-28s %s\n' "PROPERTY" "TYPE" "DEFAULT" "DESCRIPTION"
    for p in "${PROPERTIES[@]}"; do
        IFS='|' read -r name type default desc <<< "$p"
        printf '%-16s %-7s %-28s %s\n' "$name" "$type" "$default" "$desc"
    done
}

print_help() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTION] [key=value ...]

Writes one or more config values live into a running Maxwell widget over
DBus - anything settable in contents/config/main.xml, not just the
theme-song trigger. Uses org.kde.plasmashell's evaluateScript DBus method
(via qdbus/qdbus-qt6/qdbus6, whichever is found first) under the hood.

Options:
  -l, --list              List every Maxwell instance found (index,
                          applet id, desktop/panel) and exit.
  -p, --list-properties   List every property that can be set via
                          key=value (name, type, default, description)
                          and exit.
  -i, --index N           Target the Nth instance found (0-based).
                          Default: 0, i.e. the first instance found
                          (desktops before panels).
      --id ID             Target the instance with this exact applet
                          id (see --list) instead of --index.
  -h, --help              Show this help and exit.

  key=value               Any property below. Repeatable. If none are
                          given, defaults to bumping dbustrigger (i.e.
                          plays the theme song). Values are typed as
                          int/float/bool/string based on their shape.

Examples:
  $SCRIPT_NAME
      Play the theme song (bumps dbustrigger) on the first instance found.

  $SCRIPT_NAME gifspeed=3 mirror=true
      Speed up and mirror the GIF on the first instance found.

  $SCRIPT_NAME displaymode="3D Mesh"
      Switch the first instance found to 3D Mesh mode.

  $SCRIPT_NAME --list
      Show every Maxwell instance currently on the desktop/panels.

  $SCRIPT_NAME --id 42 displaymode="3D Mesh"
      Switch the instance with applet id 42 specifically.

  $SCRIPT_NAME --index 1 dbustrigger=1
      Play the theme song on the 2nd instance found instead of the 1st.

  $SCRIPT_NAME --list-properties
      Print the table below on its own.

Properties:
EOF
    print_properties
}

MODE="set"
INDEX=0
ID=""
HAVE_ID=false
declare -a PAIRS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        -l|--list)
            MODE="list"
            shift
            ;;
        -p|--list-properties)
            MODE="list-properties"
            shift
            ;;
        -i|--index)
            [[ $# -ge 2 ]] || { echo "ERROR: $1 needs a value" >&2; exit 1; }
            INDEX="$2"
            shift 2
            ;;
        --id)
            [[ $# -ge 2 ]] || { echo "ERROR: --id needs a value" >&2; exit 1; }
            ID="$2"
            HAVE_ID=true
            shift 2
            ;;
        *=*)
            PAIRS+=("$1")
            shift
            ;;
        *)
            echo "ERROR: unrecognized argument: $1 (see --help)" >&2
            exit 1
            ;;
    esac
done

if [ "$MODE" = "list-properties" ]; then
    print_properties
    exit 0
fi

QDBUS=""
for candidate in qdbus6 qdbus-qt6 qdbus; do
    if command -v "$candidate" &> /dev/null; then
        QDBUS="$candidate"
        break
    fi
done

if [ -z "$QDBUS" ]; then
    echo "ERROR: no qdbus binary found (tried qdbus6, qdbus-qt6, qdbus)" >&2
    exit 1
fi

# Renders a bash value as a JS string literal (double-quoted, escaped).
to_js_string() {
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    printf '"%s"' "$v"
}

# Renders a bash value as a JS literal, inferring int/float/bool/string.
to_js_value() {
    local v="$1"
    if [[ "$v" =~ ^-?[0-9]+$ ]] || [[ "$v" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
        printf '%s' "$v"
    elif [[ "$v" == "true" || "$v" == "false" ]]; then
        printf '%s' "$v"
    else
        to_js_string "$v"
    fi
}

if [ "$MODE" = "set" ] && [ ${#PAIRS[@]} -eq 0 ]; then
    PAIRS_JS='[["dbustrigger", Date.now()]]'
else
    entries=()
    for pair in "${PAIRS[@]}"; do
        key="${pair%%=*}"
        value="${pair#*=}"
        entries+=("[$(to_js_string "$key"), $(to_js_value "$value")]")
    done
    IFS=,
    PAIRS_JS="[${entries[*]}]"
    unset IFS
fi

if [ "$HAVE_ID" = true ]; then
    SELECT_JS="var target = null;
for (var i = 0; i < instances.length; i++) {
    if (instances[i].widget.id === $(to_js_value "$ID")) { target = instances[i].widget; break; }
}"
else
    SELECT_JS="var target = instances[$(to_js_value "$INDEX")] ? instances[$(to_js_value "$INDEX")].widget : null;"
fi

SCRIPT="
function collect() {
    var result = [];
    function collectFrom(containments, kind) {
        for (var i = 0; i < containments.length; i++) {
            var widgets = containments[i].widgets(\"maxwell\");
            for (var j = 0; j < widgets.length; j++) {
                result.push({ widget: widgets[j], kind: kind });
            }
        }
    }
    collectFrom(desktops(), \"desktop\");
    collectFrom(panels(), \"panel\");
    return result;
}

var instances = collect();
"

if [ "$MODE" = "list" ]; then
    SCRIPT="$SCRIPT
if (instances.length === 0) {
    print(\"No Maxwell instance found\");
} else {
    var lines = [];
    for (var i = 0; i < instances.length; i++) {
        lines.push(i + \": id=\" + instances[i].widget.id + \" (\" + instances[i].kind + \")\");
    }
    print(lines.join(\"\\n\"));
}
"
else
    SCRIPT="$SCRIPT
$SELECT_JS
if (!target) {
    print(\"No matching Maxwell instance found\");
} else {
    var pairs = $PAIRS_JS;
    target.currentConfigGroup = [\"General\"];
    var summary = [];
    for (var i = 0; i < pairs.length; i++) {
        target.writeConfig(pairs[i][0], pairs[i][1]);
        summary.push(pairs[i][0] + \"=\" + pairs[i][1]);
    }
    target.reloadConfig();
    print(\"Updated instance id=\" + target.id + \": \" + summary.join(\", \"));
}
"
fi

"$QDBUS" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT"
