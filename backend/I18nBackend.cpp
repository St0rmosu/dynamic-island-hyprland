#include "I18nBackend.h"
#include <QByteArray>
#include <cstdlib>

I18nBackend *I18nBackend::s_instance = nullptr;

I18nBackend::I18nBackend(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
    m_systemLanguage = detectSystemLanguage();
    initTranslations();
}

I18nBackend *I18nBackend::instance()
{
    return s_instance;
}

QString I18nBackend::detectSystemLanguage() const
{
    // Check LC_ALL, LC_MESSAGES, LANG
    const char *lcAll = std::getenv("LC_ALL");
    const char *lcMessages = std::getenv("LC_MESSAGES");
    const char *lang = std::getenv("LANG");

    QString envLang;
    if (lcAll && *lcAll) envLang = QString::fromUtf8(lcAll);
    else if (lcMessages && *lcMessages) envLang = QString::fromUtf8(lcMessages);
    else if (lang && *lang) envLang = QString::fromUtf8(lang);

    if (envLang.isEmpty()) {
        envLang = QLocale::system().name();
    }

    envLang = envLang.toLower();
    if (envLang.startsWith(QLatin1String("it"))) return QStringLiteral("it");
    if (envLang.startsWith(QLatin1String("de"))) return QStringLiteral("de");
    if (envLang.startsWith(QLatin1String("es"))) return QStringLiteral("es");
    if (envLang.startsWith(QLatin1String("fr"))) return QStringLiteral("fr");
    if (envLang.startsWith(QLatin1String("en"))) return QStringLiteral("en");

    return QStringLiteral("en");
}

QString I18nBackend::language() const
{
    return m_language;
}

void I18nBackend::setLanguage(const QString &lang)
{
    QString trimmed = lang.trimmed().toLower();
    if (trimmed.isEmpty()) trimmed = QStringLiteral("auto");
    if (m_language != trimmed) {
        m_language = trimmed;
        emit languageChanged();
    }
}

QString I18nBackend::currentLanguage() const
{
    if (m_language == QLatin1String("auto") || m_language.isEmpty()) {
        return m_systemLanguage;
    }
    return m_language;
}

QString I18nBackend::systemLanguage() const
{
    return m_systemLanguage;
}

bool I18nBackend::isItalian() const { return currentLanguage() == QLatin1String("it"); }
bool I18nBackend::isEnglish() const { return currentLanguage() == QLatin1String("en"); }
bool I18nBackend::isGerman() const { return currentLanguage() == QLatin1String("de"); }
bool I18nBackend::isSpanish() const { return currentLanguage() == QLatin1String("es"); }
bool I18nBackend::isFrench() const { return currentLanguage() == QLatin1String("fr"); }

QString I18nBackend::tr(const QString &text) const
{
    if (text.isEmpty()) return text;

    QString key = text.trimmed().toLower();
    auto it = m_translations.constFind(key);
    if (it != m_translations.constEnd()) {
        const auto &dict = it.value();
        QString cur = currentLanguage();
        auto transIt = dict.constFind(cur);
        if (transIt != dict.constEnd() && !transIt.value().isEmpty()) {
            return transIt.value();
        }
        // Fallback to English, then Italian, then original text
        auto enIt = dict.constFind(QStringLiteral("en"));
        if (enIt != dict.constEnd() && !enIt.value().isEmpty()) {
            return enIt.value();
        }
        auto itIt = dict.constFind(QStringLiteral("it"));
        if (itIt != dict.constEnd() && !itIt.value().isEmpty()) {
            return itIt.value();
        }
    }
    return text;
}

void I18nBackend::initTranslations()
{
    auto add = [this](const QString &key, const QString &it, const QString &en, const QString &de = {}, const QString &es = {}, const QString &fr = {}) {
        QHash<QString, QString> dict;
        dict[QStringLiteral("it")] = it;
        dict[QStringLiteral("en")] = en;
        dict[QStringLiteral("de")] = de.isEmpty() ? en : de;
        dict[QStringLiteral("es")] = es.isEmpty() ? en : es;
        dict[QStringLiteral("fr")] = fr.isEmpty() ? en : fr;

        m_translations[key.toLower()] = dict;
        m_translations[it.toLower()] = dict;
        m_translations[en.toLower()] = dict;
        if (!de.isEmpty()) m_translations[de.toLower()] = dict;
        if (!es.isEmpty()) m_translations[es.toLower()] = dict;
        if (!fr.isEmpty()) m_translations[fr.toLower()] = dict;
    };

    // --- Polkit & Biometrics ---
    add(QStringLiteral("use_face_id"), QStringLiteral("Usa Face ID"), QStringLiteral("Use Face ID"), QStringLiteral("Face ID verwenden"), QStringLiteral("Usar Face ID"), QStringLiteral("Utiliser Face ID"));
    add(QStringLiteral("use_touch_id"), QStringLiteral("Usa Touch ID"), QStringLiteral("Use Touch ID"), QStringLiteral("Touch ID verwenden"), QStringLiteral("Usar Touch ID"), QStringLiteral("Utiliser Touch ID"));
    add(QStringLiteral("use_password"), QStringLiteral("Usa Password"), QStringLiteral("Use Password"), QStringLiteral("Passwort verwenden"), QStringLiteral("Usar contraseña"), QStringLiteral("Utiliser mot de passe"));
    add(QStringLiteral("face_id_title"), QStringLiteral("Face ID (Windows Hello)"), QStringLiteral("Face ID (Windows Hello)"), QStringLiteral("Face ID (Windows Hello)"), QStringLiteral("Face ID (Windows Hello)"), QStringLiteral("Face ID (Windows Hello)"));
    add(QStringLiteral("touch_id_title"), QStringLiteral("Touch ID (Impronta)"), QStringLiteral("Touch ID (Fingerprint)"), QStringLiteral("Touch ID (Fingerabdruck)"), QStringLiteral("Touch ID (Huella)"), QStringLiteral("Touch ID (Empreinte)"));
    add(QStringLiteral("face_id_prompt"), QStringLiteral("Posizionati davanti alla fotocamera"), QStringLiteral("Position yourself in front of the camera"), QStringLiteral("Vor der Kamera positionieren"), QStringLiteral("Colócate frente a la cámara"), QStringLiteral("Placez-vous devant la caméra"));
    add(QStringLiteral("touch_id_prompt"), QStringLiteral("Poggia il dito per sbloccare"), QStringLiteral("Place finger to unlock"), QStringLiteral("Finger zum Entsperren auflegen"), QStringLiteral("Coloca el dedo para desbloquear"), QStringLiteral("Posez le doigt pour déverrouiller"));
    add(QStringLiteral("enter_password"), QStringLiteral("Inserisci la password"), QStringLiteral("Enter password"), QStringLiteral("Passwort eingeben"), QStringLiteral("Introduce la contraseña"), QStringLiteral("Entrez le mot de passe"));
    add(QStringLiteral("face_scanning"), QStringLiteral("Scansione del volto..."), QStringLiteral("Scanning face..."), QStringLiteral("Gesichtsscan..."), QStringLiteral("Escaneando rostro..."), QStringLiteral("Scan du visage..."));
    add(QStringLiteral("fingerprint_scanning"), QStringLiteral("Scansione dell'impronta..."), QStringLiteral("Scanning fingerprint..."), QStringLiteral("Fingerabdruckscan..."), QStringLiteral("Escaneando huella..."), QStringLiteral("Scan de l'empreinte..."));
    add(QStringLiteral("face_verifying"), QStringLiteral("Riconoscimento facciale..."), QStringLiteral("Facial recognition..."), QStringLiteral("Gesichtserkennung..."), QStringLiteral("Reconocimiento facial..."), QStringLiteral("Reconnaissance faciale..."));
    add(QStringLiteral("fingerprint_verifying"), QStringLiteral("Verifica impronta in corso..."), QStringLiteral("Verifying fingerprint..."), QStringLiteral("Fingerabdruck wird überprüft..."), QStringLiteral("Verificando huella..."), QStringLiteral("Vérification de l'empreinte..."));
    add(QStringLiteral("auth_verifying"), QStringLiteral("Verifica autorizzazione..."), QStringLiteral("Verifying authorization..."), QStringLiteral("Autorisierung wird überprüft..."), QStringLiteral("Verificando autorización..."), QStringLiteral("Vérification de l'autorisation..."));
    add(QStringLiteral("checking_credentials"), QStringLiteral("Controllo credenziali..."), QStringLiteral("Checking credentials..."), QStringLiteral("Anmeldedaten prüfen..."), QStringLiteral("Comprobando credenciales..."), QStringLiteral("Vérification des identifiants..."));
    add(QStringLiteral("auth_face_success"), QStringLiteral("Autenticato con Face ID"), QStringLiteral("Authenticated with Face ID"), QStringLiteral("Mit Face ID authentifiziert"), QStringLiteral("Autenticado con Face ID"), QStringLiteral("Authentifié avec Face ID"));
    add(QStringLiteral("auth_fp_success"), QStringLiteral("Touch ID Confermato"), QStringLiteral("Touch ID Confirmed"), QStringLiteral("Touch ID bestätigt"), QStringLiteral("Touch ID confirmado"), QStringLiteral("Touch ID confirmé"));
    add(QStringLiteral("access_granted"), QStringLiteral("Accesso consentito"), QStringLiteral("Access granted"), QStringLiteral("Zugriff gewährt"), QStringLiteral("Acceso permitido"), QStringLiteral("Accès autorisé"));
    add(QStringLiteral("face_not_recognized"), QStringLiteral("Viso non riconosciuto"), QStringLiteral("Face not recognized"), QStringLiteral("Gesicht nicht erkannt"), QStringLiteral("Rostro no reconocido"), QStringLiteral("Visage non reconnu"));
    add(QStringLiteral("fp_not_recognized"), QStringLiteral("Impronta non riconosciuta"), QStringLiteral("Fingerprint not recognized"), QStringLiteral("Fingerabdruck nicht erkannt"), QStringLiteral("Huella no reconocida"), QStringLiteral("Empreinte non reconnue"));
    add(QStringLiteral("wrong_password"), QStringLiteral("Password errata. Riprova."), QStringLiteral("Incorrect password. Try again."), QStringLiteral("Falsches Passwort. Bitte erneut versuchen."), QStringLiteral("Contraseña incorrecta. Inténtalo de nuevo."), QStringLiteral("Mot de passe incorrect. Réessayez."));
    add(QStringLiteral("face_retry_hint"), QStringLiteral("Posizionati davanti alla fotocamera o usa la password"), QStringLiteral("Look at camera or enter password"), QStringLiteral("In die Kamera blicken oder Passwort eingeben"), QStringLiteral("Mira a la cámara o usa la contraseña"), QStringLiteral("Regardez la caméra ou entrez le mot de passe"));
    add(QStringLiteral("fp_retry_hint"), QStringLiteral("Poggia nuovamente il dito sul sensore"), QStringLiteral("Place finger on sensor again"), QStringLiteral("Finger erneut auflegen"), QStringLiteral("Coloca el dedo de nuevo en el sensor"), QStringLiteral("Reposez le doigt sur le capteur"));
    add(QStringLiteral("pwd_retry_hint"), QStringLiteral("Riprova con la password corretta"), QStringLiteral("Try again with correct password"), QStringLiteral("Mit dem richtigen Passwort erneut versuchen"), QStringLiteral("Reintenta con la contraseña correcta"), QStringLiteral("Réessayez avec le bon mot de passe"));

    // --- Control Center & Connectivity ---
    add(QStringLiteral("wi_fi"), QStringLiteral("Wi-Fi"), QStringLiteral("Wi-Fi"), QStringLiteral("WLAN"), QStringLiteral("Wi-Fi"), QStringLiteral("Wi-Fi"));
    add(QStringLiteral("bluetooth"), QStringLiteral("Bluetooth"), QStringLiteral("Bluetooth"), QStringLiteral("Bluetooth"), QStringLiteral("Bluetooth"), QStringLiteral("Bluetooth"));
    add(QStringLiteral("volume"), QStringLiteral("Volume"), QStringLiteral("Volume"), QStringLiteral("Lautstärke"), QStringLiteral("Volumen"), QStringLiteral("Volume"));
    add(QStringLiteral("volume_control"), QStringLiteral("Controllo Volume"), QStringLiteral("Volume Control"), QStringLiteral("Lautstärkeregelung"), QStringLiteral("Control de volumen"), QStringLiteral("Contrôle du volume"));
    add(QStringLiteral("brightness"), QStringLiteral("Luminosità"), QStringLiteral("Brightness"), QStringLiteral("Helligkeit"), QStringLiteral("Brillo"), QStringLiteral("Luminosité"));
    add(QStringLiteral("display_brightness"), QStringLiteral("Luminosità Display"), QStringLiteral("Display Brightness"), QStringLiteral("Bildschirmhelligkeit"), QStringLiteral("Brillo de pantalla"), QStringLiteral("Luminosité de l'écran"));
    add(QStringLiteral("notifications"), QStringLiteral("Notifiche"), QStringLiteral("Notifications"), QStringLiteral("Benachrichtigungen"), QStringLiteral("Notificaciones"), QStringLiteral("Notifications"));
    add(QStringLiteral("notification_center"), QStringLiteral("Centro Notifiche"), QStringLiteral("Notification Center"), QStringLiteral("Mitteilungszentrale"), QStringLiteral("Centro de notificaciones"), QStringLiteral("Centre de notifications"));
    add(QStringLiteral("night_light"), QStringLiteral("Luce Notturna"), QStringLiteral("Night Light"), QStringLiteral("Nachtmodus"), QStringLiteral("Luz nocturna"), QStringLiteral("Mode nuit"));
    add(QStringLiteral("night_light_focus"), QStringLiteral("Luce Notturna & Focus"), QStringLiteral("Night Light & Focus"), QStringLiteral("Nachtlicht & Fokus"), QStringLiteral("Luz nocturna y enfoque"), QStringLiteral("Lumière nocturne et focus"));
    add(QStringLiteral("battery"), QStringLiteral("Batteria"), QStringLiteral("Battery"), QStringLiteral("Batterie"), QStringLiteral("Batería"), QStringLiteral("Batterie"));
    add(QStringLiteral("battery_profile"), QStringLiteral("Profilo Batteria TLP"), QStringLiteral("TLP Battery Profile"), QStringLiteral("TLP-Batterieprofil"), QStringLiteral("Perfil de batería TLP"), QStringLiteral("Profil de batterie TLP"));
    add(QStringLiteral("connected"), QStringLiteral("Connesso"), QStringLiteral("Connected"), QStringLiteral("Verbunden"), QStringLiteral("Conectado"), QStringLiteral("Connecté"));
    add(QStringLiteral("disconnected"), QStringLiteral("Disconnesso"), QStringLiteral("Disconnected"), QStringLiteral("Getrennt"), QStringLiteral("Desconectado"), QStringLiteral("Déconnecté"));
    add(QStringLiteral("connecting"), QStringLiteral("Connessione in corso..."), QStringLiteral("Connecting..."), QStringLiteral("Verbinde..."), QStringLiteral("Conectando..."), QStringLiteral("Connexion..."));
    add(QStringLiteral("disconnecting"), QStringLiteral("Disconnessione in corso..."), QStringLiteral("Disconnecting..."), QStringLiteral("Trenne..."), QStringLiteral("Desconectando..."), QStringLiteral("Déconnexion..."));
    add(QStringLiteral("connect"), QStringLiteral("Connetti"), QStringLiteral("Connect"), QStringLiteral("Verbinden"), QStringLiteral("Conectar"), QStringLiteral("Connecter"));
    add(QStringLiteral("disconnect"), QStringLiteral("Disconnetti"), QStringLiteral("Disconnect"), QStringLiteral("Trennen"), QStringLiteral("Desconectar"), QStringLiteral("Déconnecter"));
    add(QStringLiteral("forget"), QStringLiteral("Dimentica"), QStringLiteral("Forget"), QStringLiteral("Vergessen"), QStringLiteral("Olvidar"), QStringLiteral("Oublier"));
    add(QStringLiteral("scan"), QStringLiteral("Scansiona"), QStringLiteral("Scan"), QStringLiteral("Scannen"), QStringLiteral("Escanear"), QStringLiteral("Scanner"));
    add(QStringLiteral("stop"), QStringLiteral("Ferma"), QStringLiteral("Stop"), QStringLiteral("Stopp"), QStringLiteral("Detener"), QStringLiteral("Arrêter"));
    add(QStringLiteral("no_new_notifications"), QStringLiteral("Nessuna nuova notifica"), QStringLiteral("No new notifications"), QStringLiteral("Keine neuen Benachrichtigungen"), QStringLiteral("No hay notificaciones nuevas"), QStringLiteral("Aucune nouvelle notification"));
    add(QStringLiteral("clear_all"), QStringLiteral("Cancella tutto"), QStringLiteral("Clear all"), QStringLiteral("Alles löschen"), QStringLiteral("Borrar todo"), QStringLiteral("Effacer tout"));
    add(QStringLiteral("desktop_bar"), QStringLiteral("Barra Desktop"), QStringLiteral("Desktop Bar"), QStringLiteral("Desktop-Leiste"), QStringLiteral("Barra de escritorio"), QStringLiteral("Barre de bureau"));
    add(QStringLiteral("clipboard"), QStringLiteral("Appunti"), QStringLiteral("Clipboard"), QStringLiteral("Zwischenablage"), QStringLiteral("Portapapeles"), QStringLiteral("Presse-papiers"));
    add(QStringLiteral("history"), QStringLiteral("Cronologia"), QStringLiteral("History"), QStringLiteral("Verlauf"), QStringLiteral("Historial"), QStringLiteral("Historique"));
    add(QStringLiteral("back"), QStringLiteral("Indietro"), QStringLiteral("Back"), QStringLiteral("Zurück"), QStringLiteral("Atrás"), QStringLiteral("Retour"));
    add(QStringLiteral("silent"), QStringLiteral("Silenzioso"), QStringLiteral("Silent"), QStringLiteral("Stumm"), QStringLiteral("Silencio"), QStringLiteral("Silencieux"));
    add(QStringLiteral("settings"), QStringLiteral("Impostazioni"), QStringLiteral("Settings"), QStringLiteral("Einstellungen"), QStringLiteral("Ajustes"), QStringLiteral("Paramètres"));
    add(QStringLiteral("bar_clipboard"), QStringLiteral("Barra & Appunti"), QStringLiteral("Bar & Clipboard"), QStringLiteral("Leiste & Zwischenablage"), QStringLiteral("Barra y portapapeles"), QStringLiteral("Barre et presse-papiers"));
    add(QStringLiteral("clock_battery"), QStringLiteral("Orologio & Batteria"), QStringLiteral("Clock & Battery"), QStringLiteral("Uhr & Akku"), QStringLiteral("Reloj y batería"), QStringLiteral("Horloge et batterie"));
    add(QStringLiteral("wifi_card"), QStringLiteral("Scheda Wi-Fi"), QStringLiteral("Wi-Fi Card"), QStringLiteral("WLAN-Karte"), QStringLiteral("Tarjeta Wi-Fi"), QStringLiteral("Carte Wi-Fi"));
    add(QStringLiteral("bluetooth_card"), QStringLiteral("Scheda Bluetooth"), QStringLiteral("Bluetooth Card"), QStringLiteral("Bluetooth-Karte"), QStringLiteral("Tarjeta Bluetooth"), QStringLiteral("Carte Bluetooth"));

    // --- Power Menu ---
    add(QStringLiteral("lock"), QStringLiteral("Blocca"), QStringLiteral("Lock"), QStringLiteral("Sperren"), QStringLiteral("Bloquear"), QStringLiteral("Verrouiller"));
    add(QStringLiteral("logout"), QStringLiteral("Esci"), QStringLiteral("Log out"), QStringLiteral("Abmelden"), QStringLiteral("Cerrar sesión"), QStringLiteral("Déconnexion"));
    add(QStringLiteral("suspend"), QStringLiteral("Sospendi"), QStringLiteral("Suspend"), QStringLiteral("Energiesparen"), QStringLiteral("Suspender"), QStringLiteral("Mettre en veille"));
    add(QStringLiteral("restart"), QStringLiteral("Riavvia"), QStringLiteral("Restart"), QStringLiteral("Neustarten"), QStringLiteral("Reiniciar"), QStringLiteral("Redémarrer"));
    add(QStringLiteral("shutdown"), QStringLiteral("Spegni"), QStringLiteral("Shut down"), QStringLiteral("Herunterfahren"), QStringLiteral("Apagar"), QStringLiteral("Éteindre"));

    // --- File Shelf & Clipboard & Shortcuts ---
    add(QStringLiteral("drag_files"), QStringLiteral("Trascina file o cartelle sull'Isola Dinamica"), QStringLiteral("Drag files or folders onto Dynamic Island"), QStringLiteral("Dateien oder Ordner auf die Dynamic Island ziehen"), QStringLiteral("Arrastra archivos o carpetas a la Isla Dinámica"), QStringLiteral("Glissez des fichiers ou dossiers sur la Dynamic Island"));
    add(QStringLiteral("reorder_files"), QStringLiteral("Trascina un file per riordinarlo o rilascialo in un'altra applicazione"), QStringLiteral("Drag a file to reorder it or drop it into another application"), QStringLiteral("Datei ziehen zum Sortieren oder in andere Anwendung ablegen"), QStringLiteral("Arrastra un archivo para reordenarlo o suéltalo en otra aplicación"), QStringLiteral("Glissez un fichier pour le réorganiser ou déposez-le dans une autre application"));
    add(QStringLiteral("search_clipboard"), QStringLiteral("Cerca negli appunti..."), QStringLiteral("Search clipboard..."), QStringLiteral("Zwischenablage durchsuchen..."), QStringLiteral("Buscar en portapapeles..."), QStringLiteral("Rechercher dans le presse-papiers..."));
    add(QStringLiteral("no_copied_items"), QStringLiteral("Nessun elemento copiato"), QStringLiteral("No copied items"), QStringLiteral("Keine kopierten Elemente"), QStringLiteral("No hay elementos copiados"), QStringLiteral("Aucun élément copié"));
    add(QStringLiteral("no_results_found"), QStringLiteral("Nessun risultato trovato"), QStringLiteral("No results found"), QStringLiteral("Keine Ergebnisse gefunden"), QStringLiteral("No se encontraron resultados"), QStringLiteral("Aucun résultat trouvé"));
    add(QStringLiteral("image"), QStringLiteral("Immagine"), QStringLiteral("Image"), QStringLiteral("Bild"), QStringLiteral("Imagen"), QStringLiteral("Image"));
    add(QStringLiteral("copied"), QStringLiteral("Copiato!"), QStringLiteral("Copied!"), QStringLiteral("Kopiert!"), QStringLiteral("¡Copiado!"), QStringLiteral("Copié !"));

    // --- Settings Pages ---
    add(QStringLiteral("island_geometry"), QStringLiteral("Isola & Geometria"), QStringLiteral("Island & Geometry"), QStringLiteral("Insel & Geometrie"), QStringLiteral("Isla y geometría"), QStringLiteral("Île et géométrie"));
    add(QStringLiteral("control_center_studio"), QStringLiteral("Control Center & Studio"), QStringLiteral("Control Center & Studio"), QStringLiteral("Kontrollzentrum & Studio"), QStringLiteral("Centro de control y estudio"), QStringLiteral("Centre de contrôle et studio"));
    add(QStringLiteral("appearance_fonts"), QStringLiteral("Aspetto, Sfondi & Font"), QStringLiteral("Appearance, Wallpapers & Fonts"), QStringLiteral("Erscheinungsbild, Hintergrund & Schriftarten"), QStringLiteral("Apariencia, fondos y fuentes"), QStringLiteral("Apparence, fonds d'écran et polices"));
    add(QStringLiteral("keyboard_shortcuts"), QStringLiteral("Scorciatoie da Tastiera"), QStringLiteral("Keyboard Shortcuts"), QStringLiteral("Tastaturkürzel"), QStringLiteral("Atajos de teclado"), QStringLiteral("Raccourcis clavier"));
    add(QStringLiteral("language_setting"), QStringLiteral("Lingua dell'Interfaccia"), QStringLiteral("Interface Language"), QStringLiteral("Oberflächensprache"), QStringLiteral("Idioma de la interfaz"), QStringLiteral("Langue de l'interface"));
    add(QStringLiteral("language_auto"), QStringLiteral("Predefinita di Sistema (Auto)"), QStringLiteral("System Default (Auto)"), QStringLiteral("Systemstandard (Auto)"), QStringLiteral("Predeterminado del sistema (Auto)"), QStringLiteral("Par défaut du système (Auto)"));
}
