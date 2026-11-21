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
        property string movement: "Constant"
        property int cpusamplerate: 1000
        property string fansensor: ""
        property bool fanautorange: true
        property string fanlearnedsensor: ""
        property int fanlearnedmin: -1
        property int fanlearnedmax: -1
        property int fanminrpm: 0
        property int fanmaxrpm: 2000
        property int proximityreach: 300
        property double gifspeed: 1.0
        property double glbspeed: 2.0
        property bool mirror: false
        property bool hq: true
    }

    visible: false
    width: 0
    height: 0
}