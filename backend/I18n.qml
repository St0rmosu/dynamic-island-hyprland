pragma Singleton
import QtQuick
import IslandBackend

QtObject {
    id: root

    readonly property string currentLanguage: I18nBackend.currentLanguage
    readonly property string systemLanguage: I18nBackend.systemLanguage
    property string language: I18nBackend.language

    onLanguageChanged: {
        if (I18nBackend.language !== language)
            I18nBackend.language = language;
    }

    readonly property bool isItalian: currentLanguage === "it"
    readonly property bool isEnglish: currentLanguage === "en"
    readonly property bool isGerman: currentLanguage === "de"
    readonly property bool isSpanish: currentLanguage === "es"
    readonly property bool isFrench: currentLanguage === "fr"

    function tr(text) {
        var _ = currentLanguage;
        return I18nBackend.tr(text);
    }

    function t(text) {
        return tr(text);
    }
}
