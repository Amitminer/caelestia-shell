import Quickshell.Io
import QtQuick

JsonObject {
    property string weatherLocation: "" // A lat,long pair or empty for autodetection, e.g. "37.8267,-122.4233"
    // Temperature unit: "celsius", "fahrenheit", or "auto" (system locale detection)
    property string preferredTemperatureUnit: "auto"
    property bool useFahrenheit: {
        switch (preferredTemperatureUnit) {
        case "celsius":
            return false;
        case "fahrenheit":
            return true;
        case "auto":
            return [Locale.ImperialUSSystem, Locale.ImperialSystem].includes(Qt.locale().measurementSystem);
        default:
            // console.warn("Invalid preferredTemperatureUnit:", preferredTemperatureUnit, "- falling back to 'auto'");
            return [Locale.ImperialUSSystem, Locale.ImperialSystem].includes(Qt.locale().measurementSystem);
        }
    }
    property bool useTwelveHourClock: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().includes("a")
    property string gpuType: "GENERIC"
    property int visualiserBars: 45
    property real audioIncrement: 0.1
    property bool smartScheme: true
    property string defaultPlayer: "Spotify"
    property list<var> playerAliases: [
        {
            "from": "com.github.th_ch.youtube_music",
            "to": "YT Music"
        }
    ]
}
