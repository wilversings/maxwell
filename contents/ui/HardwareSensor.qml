import QtQuick
import org.kde.ksysguard.sensors as Sensors

// Kept in its own file so the org.kde.ksysguard.sensors import (libksysguard)
// is isolated: a Loader pointing here goes to Loader.Error when the module
// is missing, and MaxwellWidget.qml falls back to constant speed.
Item {
    id: root

    property string sensorId
    property int sampleRate: 1000

    // The current Sensor, recreated whenever sensorId changes: a reused
    // Sensor keeps (and re-announces) the previous id's value until the new
    // one reports, which would briefly apply e.g. a GPU usage percentage to a
    // fan's RPM range.
    property var sensor: null

    // False until the sensor exists and has reported. A sensor id that
    // doesn't exist (no GPU, a fan that disappeared) never gets here - it
    // just stays in Loading.
    readonly property bool ready: sensor !== null && sensor.status === Sensors.Sensor.Ready

    // The sensor reports undefined until the first sample arrives.
    readonly property real value: ready && typeof sensor.value === "number" ? sensor.value : 0

    Instantiator {
        model: root.sensorId !== "" ? [root.sensorId] : []

        delegate: Sensors.Sensor {
            required property string modelData
            sensorId: modelData
            updateRateLimit: root.sampleRate
        }

        onObjectAdded: (index, object) => root.sensor = object
        onObjectRemoved: (index, object) => {
            if (root.sensor === object) {
                root.sensor = null
            }
        }
    }
}
