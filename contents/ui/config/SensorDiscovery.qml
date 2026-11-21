import QtQuick
import org.kde.ksysguard.sensors as Sensors

// Finds which sensor-driven movement types this machine supports. Kept in
// its own file, like ../HardwareSensor.qml, so Movement.qml can load it
// through a Loader and treat Loader.Error as "libksysguard missing".
Item {
    id: root

    // False until the sensor tree has been scanned once (it fills in
    // asynchronously) - until then, nothing is known to be unavailable.
    property bool scanned: false
    property bool gpuAvailable: false
    property var fanIds: []

    // One row per discovered fan: { sensorId, label, maximum }. label
    // includes the live RPM so it's easy to tell working fans from dead
    // headers; maximum is 0 when the fan doesn't report one.
    readonly property alias fans: fanModel

    function indexOfFan(sensorId) {
        for (let i = 0; i < fanModel.count; i++) {
            if (fanModel.get(i).sensorId === sensorId) {
                return i
            }
        }
        return -1
    }

    // Prefers a fan that's actually spinning, so picking "By fan speed"
    // doesn't default to an empty header.
    function defaultFan() {
        for (let i = 0; i < fanSensors.count; i++) {
            const sensor = fanSensors.objectAt(i)
            if (sensor && typeof sensor.value === "number" && sensor.value > 0) {
                return fanModel.get(i)
            }
        }
        return fanModel.count > 0 ? fanModel.get(0) : null
    }

    ListModel {
        id: fanModel
    }

    Sensors.SensorTreeModel {
        id: sensorTree
        onRowsInserted: scanTimer.restart()
        onModelReset: scanTimer.restart()
    }

    // The tree arrives in bursts of row insertions; rescan once it settles.
    Timer {
        id: scanTimer
        interval: 200
        onTriggered: root.scan()
    }

    // In case the sensor daemon never answers, stop treating everything as
    // "not known yet".
    Timer {
        interval: 3000
        running: !root.scanned
        onTriggered: root.scanned = true
    }

    function scan() {
        const ids = []
        function walk(parent) {
            for (let row = 0; row < sensorTree.rowCount(parent); row++) {
                const index = sensorTree.index(row, 0, parent)
                const id = sensorTree.data(index, Sensors.SensorTreeModel.SensorId)
                if (id) {
                    ids.push(id)
                }
                walk(index)
            }
        }
        walk(undefined)

        // Fans are "fanN" leaves, e.g. lmsensors/nct6793-isa-0290/fan1 or
        // gpu/gpu0/fan1.
        const foundFanIds = ids.filter(id => /\/fan\d*$/.test(id))
        gpuAvailable = ids.some(id => /^gpu\/gpu\d+\/usage$/.test(id))

        if (JSON.stringify(foundFanIds) !== JSON.stringify(fanIds)) {
            fanModel.clear()
            foundFanIds.forEach(id => fanModel.append({ sensorId: id, label: id, maximum: 0 }))
            fanIds = foundFanIds
        }
        scanned = true
    }

    Instantiator {
        id: fanSensors
        model: root.fanIds

        delegate: Sensors.Sensor {
            id: fanSensor
            required property int index
            required property string modelData

            sensorId: modelData
            updateRateLimit: 1000

            function refresh() {
                // lmsensors fans are just named "Fan N", so add the chip
                // they belong to; GPU fans already say "GPU N Fan N".
                const parts = fanSensor.sensorId.split("/")
                const chip = parts[0] === "lmsensors" && parts.length > 2 ? parts[1] : ""
                const name = (fanSensor.name || fanSensor.sensorId) + (chip ? " (" + chip + ")" : "")
                const rpm = typeof fanSensor.value === "number" ? i18n("%1 RPM", Math.round(fanSensor.value)) : "…"
                if (fanSensor.index < fanModel.count) {
                    fanModel.setProperty(fanSensor.index, "label", name + " — " + rpm)
                    fanModel.setProperty(fanSensor.index, "maximum", fanSensor.maximum > 0 ? fanSensor.maximum : 0)
                }
            }

            onValueChanged: refresh()
            onMetaDataChanged: refresh()
            Component.onCompleted: refresh()
        }
    }
}
