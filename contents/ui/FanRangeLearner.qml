import QtQuick

// Learns a fan's RPM range for "By fan speed" movement with fanautorange on,
// since fans rarely report a usable maximum and their real range depends on
// the machine's fan curve. The learned range is persisted in
// plasmoid.configuration (fanlearned*) and tied to the fan it was learned
// for, so switching fans starts over.
Item {
    id: learner

    property string sensorId
    // True while this fan is being followed and has a fresh reading.
    property bool active: false
    property real rpm: 0
    property int sampleRate: 1000

    // The range is never treated as narrower than this, so RPM jitter while
    // little has been learned doesn't swing Maxwell between slowest and
    // fastest. It also means he starts out calm and livens up once the fan
    // actually ramps.
    readonly property int minimumSpan: 500

    // -1 = nothing learned yet.
    property int learnedMin: -1
    property int learnedMax: -1
    readonly property bool hasLearned: learnedMin >= 0 && learnedMax >= 0

    // Before anything is learned, the current reading is the bottom of the
    // range, i.e. slowest.
    readonly property real rangeMin: hasLearned ? learnedMin : rpm
    readonly property real rangeMax: Math.max(hasLearned ? learnedMax : 0, rangeMin + minimumSpan)

    property int previousRpm: -1
    property bool writing: false

    function loadFromConfig() {
        saveTimer.stop()
        const config = plasmoid.configuration
        if (sensorId !== "" && config.fanlearnedsensor === sensorId) {
            learnedMin = config.fanlearnedmin
            learnedMax = config.fanlearnedmax
        } else {
            learnedMin = -1
            learnedMax = -1
        }
        previousRpm = -1
    }

    function sample() {
        const current = Math.round(rpm)
        if (previousRpm >= 0) {
            // Only extend the range to values held for two samples in a row,
            // so a one-off spike (e.g. a spin-up burst) doesn't widen it for
            // good.
            const sustainedLow = Math.max(previousRpm, current)
            const sustainedHigh = Math.min(previousRpm, current)
            let changed = false
            if (!hasLearned) {
                learnedMin = learnedMax = Math.round((previousRpm + current) / 2)
                changed = true
            } else {
                if (sustainedLow < learnedMin) {
                    learnedMin = sustainedLow
                    changed = true
                }
                if (sustainedHigh > learnedMax) {
                    learnedMax = sustainedHigh
                    changed = true
                }
            }
            if (changed) {
                saveTimer.restart()
            }
        }
        previousRpm = current
    }

    onSensorIdChanged: loadFromConfig()
    onActiveChanged: previousRpm = -1
    Component.onCompleted: loadFromConfig()

    // Driven by a timer rather than rpm changes: a steady fan reports the
    // same value repeatedly, which wouldn't re-trigger a change handler. At
    // twice the sample rate, since readings arrive somewhat later than the
    // rate asks for - sampling faster could see one spike reading twice and
    // take it as sustained.
    Timer {
        interval: 2 * learner.sampleRate
        repeat: true
        running: learner.active
        onTriggered: learner.sample()
    }

    // The range mostly grows early on, one new extreme per sample - debounce
    // so that doesn't turn into a config write every second.
    Timer {
        id: saveTimer
        interval: 10000
        onTriggered: {
            learner.writing = true
            plasmoid.configuration.fanlearnedmin = learner.learnedMin
            plasmoid.configuration.fanlearnedmax = learner.learnedMax
            plasmoid.configuration.fanlearnedsensor = learner.sensorId
            learner.writing = false
        }
    }

    // External changes, i.e. the "Reset learned range" button in
    // config/Movement.qml. Our own writes are skipped: the three entries
    // change one at a time, so reloading mid-write would read a mix of old
    // and new values.
    Connections {
        target: plasmoid.configuration
        function onFanlearnedsensorChanged() { if (!learner.writing) learner.loadFromConfig() }
        function onFanlearnedminChanged() { if (!learner.writing) learner.loadFromConfig() }
        function onFanlearnedmaxChanged() { if (!learner.writing) learner.loadFromConfig() }
    }
}
