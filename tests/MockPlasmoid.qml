import QtQuick

Item {
    id: mockPlasmoidRoot

    // Mock configuration object matching contents/config/main.xml schema
    property var configuration: QtObject {
        property string displaymode: "GIF"
        property string gifpath: "contents/ui/assets/maxwell-spinning.gif"
        property string themepath: "contents/ui/assets/stockmarket.wav"
        property string playthemesong: "On Double Click"
        property int themesongloops: 1
        property double gifspeed: 1.0
        property double glbspeed: 2.0
        property bool mirror: false
        property bool hq: true
    }

    visible: false
    width: 0
    height: 0
}