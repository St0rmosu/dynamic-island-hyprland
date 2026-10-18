pragma Singleton
import QtQuick

QtObject {
    id: root

    // --- Colors from DESIGN.md ---
    readonly property color primary: "#0066cc"           // Action Blue (Light canvas)
    readonly property color primaryFocus: "#0071e3"      // Focus Blue (2px outline)
    readonly property color primaryOnDark: "#2997ff"     // Sky Link Blue (Dark canvas / lockscreen)
    
    readonly property color ink: "#1d1d1f"
    readonly property color body: "#1d1d1f"
    readonly property color bodyOnDark: "#ffffff"
    readonly property color bodyMuted: "#cccccc"
    readonly property color inkMuted80: "#333333"
    readonly property color inkMuted48: "#7a7a7a"
    readonly property color hairline: "#e0e0e0"
    readonly property color hairlineDark: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    readonly property color hairlineDarkActive: Qt.rgba(1.0, 1.0, 1.0, 0.28)
    
    readonly property color surfaceBlack: "#000000"      // Pure OLED black (Dynamic Island, nav)
    readonly property color surfaceTile1: "#272729"      // Product tile dark
    readonly property color surfaceTile2: "#2a2a2c"
    readonly property color surfaceTile3: "#252527"
    readonly property color surfaceGlassDark: Qt.rgba(0.11, 0.11, 0.12, 0.72) // 18px card acrylic
    readonly property color surfaceGlassInput: Qt.rgba(1.0, 1.0, 1.0, 0.09)    // Search/Password input
    readonly property color surfaceGlassPill: Qt.rgba(0.0, 0.0, 0.0, 0.85)

    readonly property color errorRed: "#ff453a"
    readonly property color successGreen: "#30d158"

    // --- Typography from DESIGN.md ---
    readonly property string displayFont: "SF Pro Display"
    readonly property string textFont: "SF Pro Text"
    readonly property real letterSpacingDisplay: -0.374
    readonly property real letterSpacingBody: -0.374

    // --- Radii from DESIGN.md ---
    readonly property int radiusXs: 5
    readonly property int radiusSm: 8    // Compact utility / album art
    readonly property int radiusMd: 11
    readonly property int radiusLg: 18   // Utility card / Media player
    readonly property int radiusPill: 9999 // All pill buttons, search-input, Island

    // --- Micro-interactions ---
    readonly property real pressScale: 0.95
    readonly property int animDurationFast: 180
    readonly property int animDurationNormal: 280
    readonly property int animDurationFluid: 420
}
