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
    add(QStringLiteral("system_auto"), QStringLiteral("Sistema (Auto)"), QStringLiteral("System (Auto)"), QStringLiteral("System (Auto)"), QStringLiteral("Sistema (Auto)"), QStringLiteral("Système (Auto)"));
    add(QStringLiteral("hours_24"), QStringLiteral("24 Ore"), QStringLiteral("24 Hours"), QStringLiteral("24 Stunden"), QStringLiteral("24 Horas"), QStringLiteral("24 Heures"));
    add(QStringLiteral("hours_12"), QStringLiteral("12 Ore (AM/PM)"), QStringLiteral("12 Hours (AM/PM)"), QStringLiteral("12 Stunden (AM/PM)"), QStringLiteral("12 Horas (AM/PM)"), QStringLiteral("12 Heures (AM/PM)"));

    add(QStringLiteral("glass_style"), QStringLiteral("Stile Vetro & Trasparenza"), QStringLiteral("Glass Style & Transparency"), QStringLiteral("Glas-Stil & Transparenz"), QStringLiteral("Estilo de cristal y transparencia"), QStringLiteral("Style de verre et transparence"));
    add(QStringLiteral("island_opacity"), QStringLiteral("Opacità Sfondo Isola"), QStringLiteral("Island Background Opacity"), QStringLiteral("Deckkraft des Inselhintergrunds"), QStringLiteral("Opacidad del fondo de la isla"), QStringLiteral("Opacité de l'arrière-plan de l'île"));
    add(QStringLiteral("island_opacity_desc"), QStringLiteral("Percentuale di copertura del vetro scuro matte"), QStringLiteral("Dark matte glass coverage percentage"), QStringLiteral("Abdeckungsprozentsatz des dunklen Mattglases"), QStringLiteral("Porcentaje de cobertura de cristal mate oscuro"), QStringLiteral("Pourcentage de couverture en verre mat sombre"));
    add(QStringLiteral("glass_blur"), QStringLiteral("Sfocatura Vetro (Blur)"), QStringLiteral("Glass Blur"), QStringLiteral("Glasunschärfe (Blur)"), QStringLiteral("Desenfoque de cristal (Blur)"), QStringLiteral("Flou du verre (Blur)"));
    add(QStringLiteral("glass_blur_desc"), QStringLiteral("Intensità dell'effetto frosted glass dietro i pannelli"), QStringLiteral("Frosted glass intensity behind panels"), QStringLiteral("Intensität des Milchglaseffekts hinter Fenstern"), QStringLiteral("Intensidad del efecto de cristal esmerilado detrás de paneles"), QStringLiteral("Intensité de l'effet verre dépoli derrière les panneaux"));
    add(QStringLiteral("clock_format"), QStringLiteral("Formato Orologio"), QStringLiteral("Clock Format"), QStringLiteral("Uhrzeitformat"), QStringLiteral("Formato del reloj"), QStringLiteral("Format de l'horloge"));
    add(QStringLiteral("clock_format_desc"), QStringLiteral("Visualizzazione delle ore nei moduli e nell'isola"), QStringLiteral("Time display in modules and island"), QStringLiteral("Zeitanzeige in Modulen und auf der Insel"), QStringLiteral("Visualización de la hora en módulos e isla"), QStringLiteral("Affichage de l'heure dans les modules et l'île"));
    add(QStringLiteral("language_desc"), QStringLiteral("Lingua visualizzata nella shell e nell'isola dinamica (rilevata automaticamente dal sistema)"), QStringLiteral("Language displayed in the shell and dynamic island (auto-detected from system)"), QStringLiteral("Sprache in Shell und Dynamic Island (vom System erkannt)"), QStringLiteral("Idioma mostrado en la interfaz y la isla dinámica (detectado automáticamente)"), QStringLiteral("Langue affichée dans la shell et l'île dynamique (détectée automatiquement)"));

    add(QStringLiteral("colors_harmony"), QStringLiteral("Colori & Armonia Temi"), QStringLiteral("Colors & Theme Harmony"), QStringLiteral("Farben & Themenharmonie"), QStringLiteral("Colores y armonía de temas"), QStringLiteral("Couleurs et harmonie des thèmes"));
    add(QStringLiteral("dynamic_palette"), QStringLiteral("Palette Dinamica"), QStringLiteral("Dynamic Palette"), QStringLiteral("Dynamische Palette"), QStringLiteral("Paleta dinámica"), QStringLiteral("Palette dynamique"));
    add(QStringLiteral("dynamic_palette_desc"), QStringLiteral("Estrae e sfuma i colori dell'accento in tempo reale dallo sfondo del desktop"), QStringLiteral("Extracts and tints accent colors in real-time from desktop wallpaper"), QStringLiteral("Extrahiert Akzentfarben in Echtzeit aus dem Desktop-Hintergrund"), QStringLiteral("Extrae y difumina colores de acento en tiempo real del fondo de escritorio"), QStringLiteral("Extrait et teinte les couleurs d'accent en temps réel depuis le fond d'écran"));
    add(QStringLiteral("palette_engine"), QStringLiteral("Motore Palette Compatibile"), QStringLiteral("Palette Engine"), QStringLiteral("Paletten-Engine"), QStringLiteral("Motor de paleta compatible"), QStringLiteral("Moteur de palette compatible"));
    add(QStringLiteral("palette_engine_desc"), QStringLiteral("Scegli o rileva automaticamente il generatore di colori del tuo sistema"), QStringLiteral("Choose or auto-detect system color generator"), QStringLiteral("Wähle oder erkenne automatisch den Farbgenerator deines Systems"), QStringLiteral("Elige o detecta automáticamente el generador de colores del sistema"), QStringLiteral("Choisissez ou détectez automatiquement le générateur de couleurs de votre système"));
    add(QStringLiteral("wallpaper_mgmt"), QStringLiteral("Gestione Sfondi (Wallpaper)"), QStringLiteral("Wallpaper Management"), QStringLiteral("Hintergrundbildverwaltung"), QStringLiteral("Gestión de fondos de pantalla"), QStringLiteral("Gestion des fonds d'écran"));
    add(QStringLiteral("typography_fonts"), QStringLiteral("Tipografia & Font di Sistema"), QStringLiteral("Typography & System Fonts"), QStringLiteral("Typografie & Systemschriftarten"), QStringLiteral("Tipografía y fuentes del sistema"), QStringLiteral("Typographie et polices du système"));
    add(QStringLiteral("main_font"), QStringLiteral("Font Principale (Interfaccia)"), QStringLiteral("Main UI Font"), QStringLiteral("Haupt-Schriftart (UI)"), QStringLiteral("Fuente principal (Interfaz)"), QStringLiteral("Police principale (Interface)"));
    add(QStringLiteral("hero_font"), QStringLiteral("Font Titoli & Orologio (Hero)"), QStringLiteral("Hero & Clock Font"), QStringLiteral("Titel- & Uhr-Schriftart (Hero)"), QStringLiteral("Fuente de títulos y reloj (Hero)"), QStringLiteral("Police des titres et horloge (Hero)"));
    add(QStringLiteral("icon_font"), QStringLiteral("Font Icone Nerd Font"), QStringLiteral("Nerd Font Icons"), QStringLiteral("Nerd Font Icons"), QStringLiteral("Iconos Nerd Font"), QStringLiteral("Icônes Nerd Font"));
    add(QStringLiteral("select_btn"), QStringLiteral("Seleziona..."), QStringLiteral("Select..."), QStringLiteral("Auswählen..."), QStringLiteral("Seleccionar..."), QStringLiteral("Sélectionner..."));
    add(QStringLiteral("typography_and_fonts"), QStringLiteral("Tipografia & Caratteri"), QStringLiteral("Typography & Fonts"), QStringLiteral("Typografie & Schriftarten"), QStringLiteral("Tipografía y fuentes"), QStringLiteral("Typographie et polices"));
    add(QStringLiteral("text_font_title"), QStringLiteral("Carattere Testo & Controlli"), QStringLiteral("Text & UI Font"), QStringLiteral("Text- & UI-Schriftart"), QStringLiteral("Fuente de texto e interfaz"), QStringLiteral("Police du texte et interface"));
    add(QStringLiteral("icon_font_title"), QStringLiteral("Carattere Icone & Glifi"), QStringLiteral("Icons & Glyphs Font"), QStringLiteral("Icons- & Symbole-Schriftart"), QStringLiteral("Fuente de iconos y glifos"), QStringLiteral("Police d'icônes et glyphes"));
    add(QStringLiteral("browse_btn"), QStringLiteral("Sfoglia"), QStringLiteral("Browse"), QStringLiteral("Durchsuchen"), QStringLiteral("Examinar"), QStringLiteral("Parcourir"));

    // Geometry
    add(QStringLiteral("geom_section"), QStringLiteral("Geometria Isola & Schermo"), QStringLiteral("Island & Screen Geometry"), QStringLiteral("Insel- & Bildschirmgeometrie"), QStringLiteral("Geometría de la isla y pantalla"), QStringLiteral("Géométrie de l'île et de l'écran"));
    add(QStringLiteral("resting_w"), QStringLiteral("Larghezza a Riposo"), QStringLiteral("Resting Width"), QStringLiteral("Ruhebreite"), QStringLiteral("Anchura en reposo"), QStringLiteral("Largeur au repos"));
    add(QStringLiteral("resting_h"), QStringLiteral("Altezza a Riposo"), QStringLiteral("Resting Height"), QStringLiteral("Ruhehöhe"), QStringLiteral("Altura en reposo"), QStringLiteral("Hauteur au repos"));
    add(QStringLiteral("corner_r"), QStringLiteral("Raggio di Curvatura"), QStringLiteral("Corner Radius"), QStringLiteral("Eckenradius"), QStringLiteral("Radio de curvatura"), QStringLiteral("Rayon de courbure"));
    add(QStringLiteral("top_margin"), QStringLiteral("Margine Superiore"), QStringLiteral("Top Margin"), QStringLiteral("Oberer Rand"), QStringLiteral("Margen superior"), QStringLiteral("Marge supérieure"));
    add(QStringLiteral("exclusive_zone"), QStringLiteral("Zona Riservata (Exclusive Zone)"), QStringLiteral("Exclusive Zone"), QStringLiteral("Exklusive Zone"), QStringLiteral("Zona reservada"), QStringLiteral("Zone réservée"));
    add(QStringLiteral("auto_hide_sec"), QStringLiteral("Auto-Nascondimento (Auto-Hide)"), QStringLiteral("Auto-Hide"), QStringLiteral("Automatisches Ausblenden"), QStringLiteral("Ocultación automática"), QStringLiteral("Masquage automatique"));
    add(QStringLiteral("hide_idle"), QStringLiteral("Nascondi Isola in Inattività"), QStringLiteral("Hide Island on Inactivity"), QStringLiteral("Insel bei Inaktivität ausblenden"), QStringLiteral("Ocultar isla en inactividad"), QStringLiteral("Masquer l'île en inactivité"));
    add(QStringLiteral("idle_delay"), QStringLiteral("Ritardo Inattività"), QStringLiteral("Inactivity Delay"), QStringLiteral("Inaktivitätsverzögerung"), QStringLiteral("Retardo de inactividad"), QStringLiteral("Délai d'inactivité"));
    add(QStringLiteral("show_ws_idle"), QStringLiteral("Mostra Workspace in Auto-Hide"), QStringLiteral("Show Workspace on Auto-Hide"), QStringLiteral("Arbeitsbereich bei Auto-Hide anzeigen"), QStringLiteral("Mostrar espacio de trabajo en auto-ocultación"), QStringLiteral("Afficher l'espace de travail en masquage automatique"));
    add(QStringLiteral("hover_sec"), QStringLiteral("Interazione Hover (Mouse)"), QStringLiteral("Mouse Hover Interaction"), QStringLiteral("Maus-Hover-Interaktion"), QStringLiteral("Interacción al pasar el ratón (Hover)"), QStringLiteral("Interaction de survol (Souris)"));
    add(QStringLiteral("hover_expand"), QStringLiteral("Espandi al Passaggio del Mouse"), QStringLiteral("Expand on Hover"), QStringLiteral("Beim Zeigen erweitern"), QStringLiteral("Expandir al pasar el ratón"), QStringLiteral("Développer au survol"));
    add(QStringLiteral("hover_action"), QStringLiteral("Cosa Aprire all'Hover"), QStringLiteral("Open on Hover"), QStringLiteral("Beim Hover öffnen"), QStringLiteral("Qué abrir al pasar el ratón"), QStringLiteral("Quoi ouvrir au survol"));
    add(QStringLiteral("hover_delay"), QStringLiteral("Ritardo Espansione Hover"), QStringLiteral("Hover Expand Delay"), QStringLiteral("Hover-Verzögerung"), QStringLiteral("Retardo de expansión al pasar el ratón"), QStringLiteral("Délai d'expansion au survol"));

    // Mouse Actions & Geometry Descriptions
    add(QStringLiteral("min_w_desc"), QStringLiteral("Larghezza minima della capsula prima delle espansioni"), QStringLiteral("Minimum capsule width before expansions"), QStringLiteral("Minimale Kapselbreite vor der Erweiterung"), QStringLiteral("Ancho mínimo de la cápsula antes de expandirse"), QStringLiteral("Largeur minimale de la capsule avant expansion"));
    add(QStringLiteral("base_h_desc"), QStringLiteral("Altezza base della capsula con orologio"), QStringLiteral("Base capsule height with clock"), QStringLiteral("Basishöhe der Kapsel mit Uhr"), QStringLiteral("Altura base de la cápsula con reloj"), QStringLiteral("Hauteur de base de la capsule avec horloge"));
    add(QStringLiteral("corner_r_desc"), QStringLiteral("Morbidezza degli angoli (squircle arrotondato)"), QStringLiteral("Corner roundness (rounded squircle)"), QStringLiteral("Eckenabrundung (abgerundetes Squircle)"), QStringLiteral("Suavidad de las esquinas (squircle redondeado)"), QStringLiteral("Arrondi des coins (squircle arrondi)"));
    add(QStringLiteral("top_margin_desc"), QStringLiteral("Distanza dal bordo alto dello schermo"), QStringLiteral("Distance from screen top edge"), QStringLiteral("Abstand zum oberen Bildschirmrand"), QStringLiteral("Distancia desde el borde superior de la pantalla"), QStringLiteral("Distance du bord supérieur de l'écran"));
    add(QStringLiteral("exclusive_zone_desc"), QStringLiteral("Spazio che spinge in basso le finestre delle app"), QStringLiteral("Space pushing application windows down"), QStringLiteral("Bereich, der Anwendungsfenster nach unten verschiebt"), QStringLiteral("Espacio que empuja las ventanas hacia abajo"), QStringLiteral("Espace qui repousse les fenêtres d'applications vers le bas"));
    add(QStringLiteral("hide_idle_desc"), QStringLiteral("Ritira l'isola verso l'alto quando non ci sono alert o musica"), QStringLiteral("Retracts island upwards when there are no alerts or music"), QStringLiteral("Zieht die Insel nach oben zurück, wenn keine Benachrichtigungen oder Musik aktiv sind"), QStringLiteral("Oculta la isla hacia arriba cuando no hay alertas o música"), QStringLiteral("Rétracte l'île vers le haut en l'absence d'alertes ou de musique"));
    add(QStringLiteral("idle_delay_desc"), QStringLiteral("Tempo prima di nascondere l'isola in assenza di attività"), QStringLiteral("Time before hiding island when inactive"), QStringLiteral("Zeit vor dem Ausblenden der Insel bei Inaktivität"), QStringLiteral("Tiempo antes de ocultar la isla por inactividad"), QStringLiteral("Temps avant de masquer l'île en cas d'inactivité"));
    add(QStringLiteral("show_ws_desc"), QStringLiteral("Mostra un piccolo indicatore del desktop quando l'isola è nascosta"), QStringLiteral("Show a small desktop indicator when island is hidden"), QStringLiteral("Zeigt einen kleinen Arbeitsbereich-Indikator, wenn die Insel ausgeblendet ist"), QStringLiteral("Muestra un pequeño indicador de escritorio cuando la isla está oculta"), QStringLiteral("Affiche un petit indicateur de bureau lorsque l'île est masquée"));
    add(QStringLiteral("hover_expand_desc"), QStringLiteral("Apre automaticamente l'isola quando il puntatore si sofferma sopra"), QStringLiteral("Automatically expands island when hovering"), QStringLiteral("Öffnet die Insel automatisch beim Darüberfahren mit der Maus"), QStringLiteral("Abre automáticamente la isla al pasar el cursor"), QStringLiteral("Développe automatiquement l'île au survol du curseur"));
    add(QStringLiteral("hover_action_desc"), QStringLiteral("Scegli il pannello che appare all'espansione"), QStringLiteral("Choose panel to show on expansion"), QStringLiteral("Wähle das Panel, das bei Erweiterung angezeigt wird"), QStringLiteral("Elige el panel que aparece al expandir"), QStringLiteral("Choisissez le panneau à afficher lors du développement"));
    add(QStringLiteral("hover_delay_desc"), QStringLiteral("Tempo di permanenza del cursore prima dell'apertura"), QStringLiteral("Cursor dwell time before opening"), QStringLiteral("Verweildauer des Mauszeigers vor dem Öffnen"), QStringLiteral("Tiempo de permanencia del cursor antes de abrir"), QStringLiteral("Temps d'arrêt du curseur avant ouverture"));

    add(QStringLiteral("click_actions"), QStringLiteral("Azioni del Click del Mouse"), QStringLiteral("Mouse Click Actions"), QStringLiteral("Mausklick-Aktionen"), QStringLiteral("Acciones de clic del ratón"), QStringLiteral("Actions du clic de souris"));
    add(QStringLiteral("primary_click"), QStringLiteral("Click Sinistro (Principale)"), QStringLiteral("Primary Click (Left)"), QStringLiteral("Primärer Klick (Links)"), QStringLiteral("Clic principal (Izquierdo)"), QStringLiteral("Clic principal (Gauche)"));
    add(QStringLiteral("primary_click_desc"), QStringLiteral("Azione quando premi sull'isola a riposo"), QStringLiteral("Action when clicking resting island"), QStringLiteral("Aktion beim Klick auf die ruhende Insel"), QStringLiteral("Acción al pulsar la isla en reposo"), QStringLiteral("Action lors d'un clic sur l'île au repos"));
    add(QStringLiteral("secondary_click"), QStringLiteral("Click Destro (Secondario)"), QStringLiteral("Secondary Click (Right)"), QStringLiteral("Sekundärer Klick (Rechts)"), QStringLiteral("Clic secundario (Derecho)"), QStringLiteral("Clic secondaire (Droite)"));
    add(QStringLiteral("secondary_click_desc"), QStringLiteral("Azione al tasto destro del mouse"), QStringLiteral("Action on right mouse click"), QStringLiteral("Aktion bei Rechtsklick"), QStringLiteral("Acción con clic derecho"), QStringLiteral("Action au clic droit"));
    add(QStringLiteral("middle_click"), QStringLiteral("Click Rotella (Centrale)"), QStringLiteral("Middle Click"), QStringLiteral("Mittelklick"), QStringLiteral("Clic central"), QStringLiteral("Clic molette"));
    add(QStringLiteral("middle_click_desc"), QStringLiteral("Azione alla pressione della rotellina del mouse"), QStringLiteral("Action on middle mouse click"), QStringLiteral("Aktion bei Mittelklick"), QStringLiteral("Acción con clic central de la rueda"), QStringLiteral("Action au clic molette"));
    add(QStringLiteral("double_click"), QStringLiteral("Doppio Click"), QStringLiteral("Double Click"), QStringLiteral("Doppelklick"), QStringLiteral("Doble clic"), QStringLiteral("Double-clic"));
    add(QStringLiteral("double_click_desc"), QStringLiteral("Azione rapida al doppio click rapido"), QStringLiteral("Quick action on double click"), QStringLiteral("Schnellaktion bei Doppelklick"), QStringLiteral("Acción rápida con doble clic"), QStringLiteral("Action rapide au double-clic"));
    add(QStringLiteral("toggle_island"), QStringLiteral("Nascondi Isola"), QStringLiteral("Hide Island"), QStringLiteral("Insel ausblenden"), QStringLiteral("Ocultar isla"), QStringLiteral("Masquer l'île"));
    add(QStringLiteral("overview"), QStringLiteral("Overview"), QStringLiteral("Overview"), QStringLiteral("Übersicht"), QStringLiteral("Vista general"), QStringLiteral("Vue d'ensemble"));
    add(QStringLiteral("file_shelf"), QStringLiteral("File Shelf"), QStringLiteral("File Shelf"), QStringLiteral("Dateiablage"), QStringLiteral("Estante de archivos"), QStringLiteral("Étagère de fichiers"));
    add(QStringLiteral("power_menu"), QStringLiteral("Power Menu"), QStringLiteral("Power Menu"), QStringLiteral("Energiemenü"), QStringLiteral("Menú de apagado"), QStringLiteral("Menu d'alimentation"));
    add(QStringLiteral("app_launcher"), QStringLiteral("App Launcher"), QStringLiteral("App Launcher"), QStringLiteral("Anwendungsstarter"), QStringLiteral("Lanzador de aplicaciones"), QStringLiteral("Lanceur d'applications"));
    add(QStringLiteral("media_player"), QStringLiteral("Media Player"), QStringLiteral("Media Player"), QStringLiteral("Medienplayer"), QStringLiteral("Reproductor multimedia"), QStringLiteral("Lecteur multimédia"));
    add(QStringLiteral("control_center"), QStringLiteral("Control Center"), QStringLiteral("Control Center"), QStringLiteral("Kontrollzentrum"), QStringLiteral("Centro de control"), QStringLiteral("Centre de contrôle"));

    add(QStringLiteral("scroll_sec"), QStringLiteral("Rotella del Mouse (Scroll sull'Isola)"), QStringLiteral("Mouse Wheel Scroll"), QStringLiteral("Mausrad-Scroll"), QStringLiteral("Rueda del ratón (Desplazamiento)"), QStringLiteral("Molette de la souris (Défilement)"));
    add(QStringLiteral("scroll_vert"), QStringLiteral("Scorrimento Verticale (Su / Giù)"), QStringLiteral("Vertical Scroll (Up / Down)"), QStringLiteral("Vertikales Scrollen (Auf / Ab)"), QStringLiteral("Desplazamiento vertical (Arriba / Abajo)"), QStringLiteral("Défilement vertical (Haut / Bas)"));
    add(QStringLiteral("scroll_vert_desc"), QStringLiteral("Regola al volo una funzione di sistema"), QStringLiteral("Quickly adjust a system function"), QStringLiteral("Schnelle Anpassung einer Systemfunktion"), QStringLiteral("Ajusta al vuelo una función del sistema"), QStringLiteral("Ajustez rapidement une fonction système"));
    add(QStringLiteral("audio_volume"), QStringLiteral("Volume Audio"), QStringLiteral("Audio Volume"), QStringLiteral("Lautstärke"), QStringLiteral("Volumen de audio"), QStringLiteral("Volume audio"));
    add(QStringLiteral("scroll_horiz"), QStringLiteral("Scorrimento Orizzontale (Sinistra / Destra)"), QStringLiteral("Horizontal Scroll (Left / Right)"), QStringLiteral("Horizontales Scrollen (Links / Rechts)"), QStringLiteral("Desplazamiento horizontal (Izquierda / Derecha)"), QStringLiteral("Défilement horizontal (Gauche / Droite)"));
    add(QStringLiteral("scroll_horiz_desc"), QStringLiteral("Spostamento laterale della rotellina"), QStringLiteral("Lateral wheel movement"), QStringLiteral("Seitliche Mausradbewegung"), QStringLiteral("Desplazamiento lateral de la rueda"), QStringLiteral("Mouvement latéral de la molette"));
    add(QStringLiteral("change_track"), QStringLiteral("Cambia Canzone"), QStringLiteral("Change Track"), QStringLiteral("Titel wechseln"), QStringLiteral("Cambiar canción"), QStringLiteral("Changer de morceau"));
    add(QStringLiteral("change_workspace"), QStringLiteral("Cambia Workspace"), QStringLiteral("Change Workspace"), QStringLiteral("Arbeitsbereich wechseln"), QStringLiteral("Cambiar espacio de trabajo"), QStringLiteral("Changer d'espace de travail"));
    add(QStringLiteral("scroll_step"), QStringLiteral("Passo di Regolazione Volume/Luminosità"), QStringLiteral("Volume/Brightness Step"), QStringLiteral("Lautstärke-/Helligkeitsschritt"), QStringLiteral("Paso de ajuste de volumen/brillo"), QStringLiteral("Pas de réglage volume/luminosité"));
    add(QStringLiteral("scroll_step_desc"), QStringLiteral("Percentuale per ogni scatto della rotellina"), QStringLiteral("Percentage per scroll notch"), QStringLiteral("Prozentsatz pro Mausrad-Raste"), QStringLiteral("Porcentaje por cada muesca de la rueda"), QStringLiteral("Pourcentage par cran de molette"));
    add(QStringLiteral("player_behavior"), QStringLiteral("Comportamento Media Player"), QStringLiteral("Media Player Behavior"), QStringLiteral("Medienplayer-Verhalten"), QStringLiteral("Comportamiento del reproductor"), QStringLiteral("Comportement du lecteur multimédia"));
    add(QStringLiteral("disable_auto_expand"), QStringLiteral("Disabilita Espansione al Cambio Canzone"), QStringLiteral("Disable Auto-Expand on Song Change"), QStringLiteral("Automatisches Erweitern bei Liedwechsel deaktivieren"), QStringLiteral("Desactivar expansión al cambiar de canción"), QStringLiteral("Désactiver l'expansion au changement de morceau"));
    add(QStringLiteral("disable_auto_expand_desc"), QStringLiteral("Evita che l'isola si apra da sola ogni volta che inizia un nuovo brano"), QStringLiteral("Prevents island from auto-expanding whenever a new song starts"), QStringLiteral("Verhindert, dass die Insel sich bei jedem neuen Lied öffnet"), QStringLiteral("Evita que la isla se abra automáticamente al iniciar una canción"), QStringLiteral("Empêche l'île de s'ouvrir à chaque nouveau morceau"));

    // --- Language & Quick Header ---
    add(QStringLiteral("lang_local_section"), QStringLiteral("Lingua & Localizzazione"), QStringLiteral("Language & Localization"), QStringLiteral("Sprache & Lokalisierung"), QStringLiteral("Idioma y localización"), QStringLiteral("Langue et localisation"));
    add(QStringLiteral("lang_only_en"), QStringLiteral("Inglese"), QStringLiteral("English"), QStringLiteral("Englisch"), QStringLiteral("Inglés"), QStringLiteral("Anglais"));
    add(QStringLiteral("lang_it"), QStringLiteral("Italiano"), QStringLiteral("Italian"), QStringLiteral("Italienisch"), QStringLiteral("Italiano"), QStringLiteral("Italien"));

    // --- Studio Layout Canvas ---
    add(QStringLiteral("studio_canvas_title"), QStringLiteral("Studio Canvas • Griglia a Caselle"), QStringLiteral("Studio Canvas • Grid Layout"), QStringLiteral("Studio Canvas • Kachelraster"), QStringLiteral("Studio Canvas • Cuadrícula"), QStringLiteral("Studio Canvas • Grille"));
    add(QStringLiteral("studio_canvas_desc"), QStringLiteral("Trascina per ordinare • Ridimensiona per caselle stile iOS"), QStringLiteral("Drag to reorder • Resize iOS-style tiles"), QStringLiteral("Ziehen zum Anordnen • Kacheln im iOS-Stil anpassen"), QStringLiteral("Arrastra para ordenar • Redimensiona casillas estilo iOS"), QStringLiteral("Glisser pour ordonner • Redimensionner les tuiles style iOS"));
    add(QStringLiteral("reset_btn"), QStringLiteral("Ripristina"), QStringLiteral("Reset"), QStringLiteral("Zurücksetzen"), QStringLiteral("Restablecer"), QStringLiteral("Réinitialiser"));
    add(QStringLiteral("reload_btn"), QStringLiteral("Ricarica"), QStringLiteral("Reload"), QStringLiteral("Neu laden"), QStringLiteral("Recargar"), QStringLiteral("Recharger"));
    add(QStringLiteral("pinned_bar_top"), QStringLiteral("Barra Fissa in Cima (Immobile)"), QStringLiteral("Pinned Top Bar (Fixed)"), QStringLiteral("Obere Leiste fixiert"), QStringLiteral("Barra fija superior (Inmóvil)"), QStringLiteral("Barre supérieure fixe (Immobile)"));
    add(QStringLiteral("pinned_clock_batt"), QStringLiteral("Orologio & Batteria (Fisso in Cima)"), QStringLiteral("Clock & Battery (Pinned to Top)"), QStringLiteral("Uhr & Akku (Oben fixiert)"), QStringLiteral("Reloj y batería (Fijo arriba)"), QStringLiteral("Horloge et batterie (Fixe en haut)"));
    add(QStringLiteral("live_canvas_area"), QStringLiteral("Area Live Canvas"), QStringLiteral("Live Canvas Area"), QStringLiteral("Live-Canvas-Bereich"), QStringLiteral("Área de lienzo en vivo"), QStringLiteral("Zone Canevas en direct"));
    add(QStringLiteral("modules_library_title"), QStringLiteral("LIBRERIA DEI MODULI DISPONIBILI"), QStringLiteral("AVAILABLE MODULES LIBRARY"), QStringLiteral("VERFÜGBARE MODULE"), QStringLiteral("BIBLIOTECA DE MÓDULOS DISPONIBLES"), QStringLiteral("BIBLIOTHÈQUE DE MODULES DISPONIBLES"));
    add(QStringLiteral("modules_library_desc"), QStringLiteral("Clicca per aggiungere un modulo alla griglia dell'isola o rimuoverlo."), QStringLiteral("Click to add or remove a module from the island grid."), QStringLiteral("Klicken, um Modul hinzuzufügen oder zu entfernen."), QStringLiteral("Haz clic para añadir o eliminar un módulo de la cuadrícula."), QStringLiteral("Cliquez pour ajouter ou supprimer un module de la grille."));
    add(QStringLiteral("vertical_slider"), QStringLiteral("Cursore Verticale"), QStringLiteral("Vertical Slider"), QStringLiteral("Vertikaler Schieberegler"), QStringLiteral("Control deslizante vertical"), QStringLiteral("Curseur vertical"));
    add(QStringLiteral("row_unit"), QStringLiteral("Riga"), QStringLiteral("Row"), QStringLiteral("Zeile"), QStringLiteral("Fila"), QStringLiteral("Ligne"));
    add(QStringLiteral("rows_unit"), QStringLiteral("Righe"), QStringLiteral("Rows"), QStringLiteral("Zeilen"), QStringLiteral("Filas"), QStringLiteral("Lignes"));
    add(QStringLiteral("col_unit"), QStringLiteral("Col"), QStringLiteral("Col"), QStringLiteral("Spalte"), QStringLiteral("Col"), QStringLiteral("Col"));

    // Studio Modules & Descriptions
    add(QStringLiteral("mod_header_desc"), QStringLiteral("Pillola superiore con orologio e percentuale batteria"), QStringLiteral("Top pill with clock and battery percentage"), QStringLiteral("Obere Kapsel mit Uhr und Akkustand"), QStringLiteral("Píldora superior con reloj y batería"), QStringLiteral("Pilule supérieure avec horloge et batterie"));
    add(QStringLiteral("mod_wifi_desc"), QStringLiteral("Stato connessione, rete attiva e discovery drawer"), QStringLiteral("Connection status, active network and discovery drawer"), QStringLiteral("Verbindungsstatus, aktives Netzwerk und Erkennung"), QStringLiteral("Estado de conexión, red activa y panel de búsqueda"), QStringLiteral("État de connexion, réseau actif et tiroir de découverte"));
    add(QStringLiteral("mod_bt_desc"), QStringLiteral("Controller bluetooth e periferiche connesse"), QStringLiteral("Bluetooth controller and connected devices"), QStringLiteral("Bluetooth-Controller und verbundene Geräte"), QStringLiteral("Controlador Bluetooth y dispositivos conectados"), QStringLiteral("Contrôleur Bluetooth et périphériques connectés"));
    add(QStringLiteral("mod_bright_desc"), QStringLiteral("Cursore retroilluminazione schermo"), QStringLiteral("Screen backlight brightness slider"), QStringLiteral("Helligkeitsregler für Hintergrundbeleuchtung"), QStringLiteral("Control deslizante de brillo de pantalla"), QStringLiteral("Curseur de luminosité de l'écran"));
    add(QStringLiteral("mod_vol_desc"), QStringLiteral("Cursore volume audio master"), QStringLiteral("Master audio volume slider"), QStringLiteral("Hauptlautstärkeregler"), QStringLiteral("Control deslizante de volumen maestro"), QStringLiteral("Curseur de volume audio principal"));
    add(QStringLiteral("mod_notif_desc"), QStringLiteral("Cronologia notifiche, contatore e cancellazione rapida"), QStringLiteral("Notification history, badge counter and quick clear"), QStringLiteral("Benachrichtigungsverlauf, Zähler und Schnelllöschung"), QStringLiteral("Historial de notificaciones, contador y borrado rápido"), QStringLiteral("Historique des notifications, compteur et suppression rapide"));
    add(QStringLiteral("mod_toggles_desc"), QStringLiteral("Filtro luce blu e modalità non disturbare"), QStringLiteral("Blue light filter and do not disturb mode"), QStringLiteral("Blaulichtfilter und Bitte-nicht-stören-Modus"), QStringLiteral("Filtro de luz azul y modo no molestar"), QStringLiteral("Filtre de lumière bleue et mode ne pas déranger"));
    add(QStringLiteral("mod_batt_desc"), QStringLiteral("Selettore Risparmio, Bilanciato, Prestazioni"), QStringLiteral("Power Saver, Balanced, Performance profile selector"), QStringLiteral("Energiespar-, Ausbalanciert-, Leistungsprofilauswahl"), QStringLiteral("Selector de Ahorro, Equilibrado, Rendimiento"), QStringLiteral("Sélecteur Économie, Équilibré, Performance"));
    add(QStringLiteral("mod_quick_desc"), QStringLiteral("Pulsanti rapidi desktop workspace e cronologia appunti"), QStringLiteral("Quick workspace switcher and clipboard history buttons"), QStringLiteral("Schnelltasten für Arbeitsbereiche und Zwischenablage"), QStringLiteral("Botones rápidos de escritorio y portapapeles"), QStringLiteral("Boutons rapides d'espaces de travail et presse-papiers"));

    // --- Shortcuts Page ---
    add(QStringLiteral("shortcuts_header"), QStringLiteral("Scorciatoie Hyprland (Registra al volo premendo la tastiera)"), QStringLiteral("Hyprland Shortcuts (Record on the fly from keyboard)"), QStringLiteral("Hyprland-Tastaturkürzel (Direkt über Tastatur aufnehmen)"), QStringLiteral("Atajos de Hyprland (Graba al vuelo desde el teclado)"), QStringLiteral("Raccourcis Hyprland (Enregistrer à la volée au clavier)"));
    add(QStringLiteral("reset_all_btn"), QStringLiteral("Ripristina Tutte"), QStringLiteral("Reset All"), QStringLiteral("Alle zurücksetzen"), QStringLiteral("Restablecer todos"), QStringLiteral("Tout réinitialiser"));
    add(QStringLiteral("modified_badge"), QStringLiteral("Modificata"), QStringLiteral("Modified"), QStringLiteral("Geändert"), QStringLiteral("Modificado"), QStringLiteral("Modifié"));
    add(QStringLiteral("listening_state"), QStringLiteral("In Ascolto..."), QStringLiteral("Listening..."), QStringLiteral("Höre zu..."), QStringLiteral("Escuchando..."), QStringLiteral("À l'écoute..."));
    add(QStringLiteral("record_btn"), QStringLiteral("Registra"), QStringLiteral("Record"), QStringLiteral("Aufnehmen"), QStringLiteral("Grabar"), QStringLiteral("Enregistrer"));
    add(QStringLiteral("recorded_state"), QStringLiteral("REGISTRATO!"), QStringLiteral("RECORDED!"), QStringLiteral("AUFGENOMMEN!"), QStringLiteral("¡GRABADO!"), QStringLiteral("ENREGISTRÉ !"));
    add(QStringLiteral("listening_badge"), QStringLiteral("IN ASCOLTO..."), QStringLiteral("LISTENING..."), QStringLiteral("HÖRE ZU..."), QStringLiteral("ESCUCHANDO..."), QStringLiteral("À L'ÉCOUTE..."));
    add(QStringLiteral("shortcut_saved_success"), QStringLiteral("Scorciatoia aggiornata e salvata con successo!"), QStringLiteral("Shortcut successfully updated and saved!"), QStringLiteral("Tastaturkürzel erfolgreich aktualisiert und gespeichert!"), QStringLiteral("¡Atajo actualizado y guardado con éxito!"), QStringLiteral("Raccourci mis à jour et enregistré avec succès !"));
    add(QStringLiteral("press_keys_prompt"), QStringLiteral("Premi i tasti sulla tastiera per registrare sul momento (es. SUPER + K)"), QStringLiteral("Press keys on keyboard to record shortcut (e.g. SUPER + K)"), QStringLiteral("Tasten auf der Tastatur drücken (z. B. SUPER + K)"), QStringLiteral("Pulsa las teclas en el teclado para grabar (ej. SUPER + K)"), QStringLiteral("Appuyez sur les touches du clavier pour enregistrer (ex. SUPER + K)"));
    add(QStringLiteral("cancel_esc"), QStringLiteral("Annulla (Esc)"), QStringLiteral("Cancel (Esc)"), QStringLiteral("Abbrechen (Esc)"), QStringLiteral("Cancelar (Esc)"), QStringLiteral("Annuler (Échap)"));
    add(QStringLiteral("press_combo_hint"), QStringLiteral("Premi una combinazione (es. SUPER + Tab, ALT + Spazio, o premi solo una lettera)"), QStringLiteral("Press a key combination (e.g. SUPER + Tab, ALT + Space, or press a single key)"), QStringLiteral("Tastenkombination drücken (z. B. SUPER + Tab, ALT + Leertaste)"), QStringLiteral("Pulsa una combinación (ej. SUPER + Tab, ALT + Espacio)"), QStringLiteral("Appuyez sur une combinaison (ex. SUPER + Tab, ALT + Espace)"));
    add(QStringLiteral("quick_mods"), QStringLiteral("Modificatori rapidi:"), QStringLiteral("Quick modifiers:"), QStringLiteral("Schnellmodifikatoren:"), QStringLiteral("Modificadores rápidos:"), QStringLiteral("Modificateurs rapides :"));
    add(QStringLiteral("lua_sync_title"), QStringLiteral("Configurazione Hyprland (Lua) - Aggiornata in Tempo Reale"), QStringLiteral("Hyprland Configuration (Lua) - Live Synced"), QStringLiteral("Hyprland-Konfiguration (Lua) - Live synchronisiert"), QStringLiteral("Configuración de Hyprland (Lua) - Sincronizada en vivo"), QStringLiteral("Configuration Hyprland (Lua) - Synchronisée en direct"));
    add(QStringLiteral("lua_sync_checkbox"), QStringLiteral("Sincronizza automaticamente con ~/.config/hypr/moduli/binds.lua"), QStringLiteral("Auto-sync with ~/.config/hypr/moduli/binds.lua"), QStringLiteral("Automatisch mit ~/.config/hypr/moduli/binds.lua synchronisieren"), QStringLiteral("Sincronizar automáticamente con ~/.config/hypr/moduli/binds.lua"), QStringLiteral("Synchroniser automatiquement avec ~/.config/hypr/moduli/binds.lua"));
    add(QStringLiteral("synced_with_hyprland"), QStringLiteral("Sincronizzato con Hyprland!"), QStringLiteral("Synced with Hyprland!"), QStringLiteral("Mit Hyprland synchronisiert!"), QStringLiteral("¡Sincronizado con Hyprland!"), QStringLiteral("Synchronisé avec Hyprland !"));
    add(QStringLiteral("apply_hyprland_btn"), QStringLiteral("Applica a Hyprland"), QStringLiteral("Apply to Hyprland"), QStringLiteral("Auf Hyprland anwenden"), QStringLiteral("Aplicar a Hyprland"), QStringLiteral("Appliquer à Hyprland"));

    // Official Shortcut Items
    add(QStringLiteral("sc_overview_title"), QStringLiteral("Workspace Overview"), QStringLiteral("Workspace Overview"), QStringLiteral("Arbeitsbereichsübersicht"), QStringLiteral("Vista de espacios"), QStringLiteral("Aperçu des espaces"));
    add(QStringLiteral("sc_overview_desc"), QStringLiteral("Visualizzatore interattivo di tutti i workspace e finestre"), QStringLiteral("Interactive visualizer of all workspaces and windows"), QStringLiteral("Interaktive Übersicht aller Arbeitsbereiche und Fenster"), QStringLiteral("Visor interactivo de todos los espacios y ventanas"), QStringLiteral("Visualiseur interactif de tous les espaces et fenêtres"));
    add(QStringLiteral("sc_power_title"), QStringLiteral("Power Menu (Wlogout)"), QStringLiteral("Power Menu (Wlogout)"), QStringLiteral("Energiemenü (Wlogout)"), QStringLiteral("Menú de energía (Wlogout)"), QStringLiteral("Menu d'alimentation (Wlogout)"));
    add(QStringLiteral("sc_power_desc"), QStringLiteral("Menu rapido per Blocca, Esci, Sospendi, Riavvia, Spegni"), QStringLiteral("Quick menu for Lock, Logout, Suspend, Restart, Shutdown"), QStringLiteral("Schnellmenü für Sperren, Abmelden, Ruhezustand, Neustart, Herunterfahren"), QStringLiteral("Menú rápido para Bloquear, Salir, Suspender, Reiniciar, Apagar"), QStringLiteral("Menu rapide pour Verrouiller, Quitter, Veille, Redémarrer, Éteindre"));
    add(QStringLiteral("sc_notif_title"), QStringLiteral("Notification Center"), QStringLiteral("Notification Center"), QStringLiteral("Mitteilungszentrale"), QStringLiteral("Centro de notificaciones"), QStringLiteral("Centre de notifications"));
    add(QStringLiteral("sc_notif_desc"), QStringLiteral("Pannello con cronologia notifiche e cancellazione"), QStringLiteral("Panel with notification history and clear options"), QStringLiteral("Leiste mit Benachrichtigungsverlauf und Löschfunktion"), QStringLiteral("Panel con historial de notificaciones y borrado"), QStringLiteral("Panneau avec historique et suppression des notifications"));
    add(QStringLiteral("sc_wall_title"), QStringLiteral("Wallpaper Switcher"), QStringLiteral("Wallpaper Switcher"), QStringLiteral("Hintergrundbildwechsler"), QStringLiteral("Cambiador de fondos"), QStringLiteral("Sélecteur de fond d'écran"));
    add(QStringLiteral("sc_wall_desc"), QStringLiteral("Selettore a schede per cambiare sfondo con animazione"), QStringLiteral("Card selector to switch wallpapers with smooth animation"), QStringLiteral("Karten-Auswahl zum Wechseln des Hintergrundbilds mit Animation"), QStringLiteral("Selector de tarjetas para cambiar fondos con animación"), QStringLiteral("Sélecteur à cartes pour changer de fond d'écran avec animation"));
    add(QStringLiteral("sc_apps_title"), QStringLiteral("Application Launcher"), QStringLiteral("Application Launcher"), QStringLiteral("Anwendungsstarter"), QStringLiteral("Lanzador de aplicaciones"), QStringLiteral("Lanceur d'applications"));
    add(QStringLiteral("sc_apps_desc"), QStringLiteral("Ricerca rapida e avvio delle applicazioni installate"), QStringLiteral("Fast search and launch installed applications"), QStringLiteral("Schnellsuche und Start installierter Anwendungen"), QStringLiteral("Búsqueda rápida e inicio de aplicaciones instaladas"), QStringLiteral("Recherche rapide et lancement d'applications"));
    add(QStringLiteral("sc_files_title"), QStringLiteral("File Shelf"), QStringLiteral("File Shelf"), QStringLiteral("Dateiablage"), QStringLiteral("Estante de archivos"), QStringLiteral("Étagère de fichiers"));
    add(QStringLiteral("sc_files_desc"), QStringLiteral("Cassetto rapido per trascinare e incollare file al volo"), QStringLiteral("Quick drawer to drag and drop files on the fly"), QStringLiteral("Schnellablage zum Ziehen und Ablegen von Dateien"), QStringLiteral("Cajón rápido para arrastrar y soltar archivos al vuelo"), QStringLiteral("Tiroir rapide pour glisser-déposer des fichiers"));
    add(QStringLiteral("sc_clip_title"), QStringLiteral("Clipboard History"), QStringLiteral("Clipboard History"), QStringLiteral("Zwischenablageverlauf"), QStringLiteral("Historial de portapapeles"), QStringLiteral("Historique du presse-papiers"));
    add(QStringLiteral("sc_clip_desc"), QStringLiteral("Cronologia degli appunti con testi, codici e immagini"), QStringLiteral("Clipboard history with text, code snippets and images"), QStringLiteral("Zwischenablageverlauf mit Texten, Code und Bildern"), QStringLiteral("Historial de portapapeles con texto, código e imágenes"), QStringLiteral("Historique du presse-papiers avec texte, code et images"));

    // --- Wallpaper & Fonts ---
    add(QStringLiteral("wall_folder_title"), QStringLiteral("Cartella Raccolta Sfondi"), QStringLiteral("Wallpaper Collection Folder"), QStringLiteral("Hintergrundbild-Ordner"), QStringLiteral("Carpeta de fondos"), QStringLiteral("Dossier de fonds d'écran"));
    add(QStringLiteral("wall_folder_desc"), QStringLiteral("Percorso directory da cui il carosello carica le anteprime"), QStringLiteral("Directory path where carousel loads wallpaper previews"), QStringLiteral("Verzeichnispfad, aus dem die Vorschauen geladen werden"), QStringLiteral("Ruta del directorio de donde se cargan las vistas previas"), QStringLiteral("Chemin du dossier d'où le carrousel charge les aperçus"));
    add(QStringLiteral("default_btn"), QStringLiteral("Predefinito"), QStringLiteral("Default"), QStringLiteral("Standard"), QStringLiteral("Predeterminado"), QStringLiteral("Par défaut"));
    add(QStringLiteral("wall_cmd_title"), QStringLiteral("Comando Applicazione Sfondo"), QStringLiteral("Wallpaper Apply Command"), QStringLiteral("Befehl zum Anwenden des Hintergrunds"), QStringLiteral("Comando para aplicar fondo"), QStringLiteral("Commande d'application du fond"));
    add(QStringLiteral("wall_cmd_desc"), QStringLiteral("Script o comando eseguito passando il file come parametro $1"), QStringLiteral("Script or command executed passing file path as argument $1"), QStringLiteral("Skript oder Befehl, der mit Dateipfad als Argument $1 ausgeführt wird"), QStringLiteral("Script o comando ejecutado pasando el archivo como argumento $1"), QStringLiteral("Script ou commande exécuté avec le fichier comme argument $1"));

    // --- Font Browser ---
    add(QStringLiteral("font_browser_icon_title"), QStringLiteral("Sfoglia Font per Icone & Glifi"), QStringLiteral("Browse Icon & Glyph Fonts"), QStringLiteral("Icon- & Symbol-Schriftarten durchsuchen"), QStringLiteral("Examinar fuentes de iconos y glifos"), QStringLiteral("Parcourir les polices d'icônes et glyphes"));
    add(QStringLiteral("font_browser_sys_title"), QStringLiteral("Sfoglia Font di Sistema"), QStringLiteral("Browse System Fonts"), QStringLiteral("Systemschriftarten durchsuchen"), QStringLiteral("Examinar fuentes del sistema"), QStringLiteral("Parcourir les polices système"));
    add(QStringLiteral("font_search_icon_placeholder"), QStringLiteral("Cerca font per icone (es. Nerd Font, Material, Symbols)..."), QStringLiteral("Search icon fonts (e.g. Nerd Font, Material, Symbols)..."), QStringLiteral("Icon-Schriftart suchen (z. B. Nerd Font, Material)..."), QStringLiteral("Buscar fuentes de iconos (ej. Nerd Font, Material)..."), QStringLiteral("Rechercher polices d'icônes (ex. Nerd Font, Material)..."));
    add(QStringLiteral("font_search_sys_placeholder"), QStringLiteral("Cerca font di sistema (es. Google Sans, Inter, JetBrains)..."), QStringLiteral("Search system fonts (e.g. Google Sans, Inter, JetBrains)..."), QStringLiteral("Systemschriftart suchen (z. B. Google Sans, Inter)..."), QStringLiteral("Buscar fuentes del sistema (ej. Google Sans, Inter)..."), QStringLiteral("Rechercher polices système (ex. Google Sans, Inter)..."));
    add(QStringLiteral("installed_count"), QStringLiteral("installati"), QStringLiteral("installed"), QStringLiteral("installiert"), QStringLiteral("instalados"), QStringLiteral("installées"));
    add(QStringLiteral("available_count"), QStringLiteral("disponibili"), QStringLiteral("available"), QStringLiteral("verfügbar"), QStringLiteral("disponibles"), QStringLiteral("disponibles"));

    // --- Other Shell Modules ---
    add(QStringLiteral("search_app"), QStringLiteral("Cerca applicazione..."), QStringLiteral("Search application..."), QStringLiteral("Anwendung suchen..."), QStringLiteral("Buscar aplicación..."), QStringLiteral("Rechercher application..."));
    add(QStringLiteral("no_apps_found"), QStringLiteral("Nessuna applicazione trovata"), QStringLiteral("No applications found"), QStringLiteral("Keine Anwendungen gefunden"), QStringLiteral("No se encontraron aplicaciones"), QStringLiteral("Aucune application trouvée"));
    add(QStringLiteral("no_apps_found_for"), QStringLiteral("Nessuna applicazione trovata per"), QStringLiteral("No applications found for"), QStringLiteral("Keine Anwendungen gefunden für"), QStringLiteral("No se encontraron aplicaciones para"), QStringLiteral("Aucune application trouvée pour"));
    add(QStringLiteral("incoming_call"), QStringLiteral("Chiamata in arrivo..."), QStringLiteral("Incoming call..."), QStringLiteral("Eingehender Anruf..."), QStringLiteral("Llamada entrante..."), QStringLiteral("Appel entrant..."));
    add(QStringLiteral("screen_sharing"), QStringLiteral("Condivisione Schermo"), QStringLiteral("Screen Sharing"), QStringLiteral("Bildschirmfreigabe"), QStringLiteral("Compartir pantalla"), QStringLiteral("Partage d'écran"));
    add(QStringLiteral("screen_sharing_desc"), QStringLiteral("Seleziona la sorgente da condividere con l'applicazione"), QStringLiteral("Select source to share with the application"), QStringLiteral("Quelle für die Freigabe auswählen"), QStringLiteral("Selecciona la fuente para compartir con la aplicación"), QStringLiteral("Sélectionnez la source à partager avec l'application"));
    add(QStringLiteral("screen_tab"), QStringLiteral("Schermo"), QStringLiteral("Screen"), QStringLiteral("Bildschirm"), QStringLiteral("Pantalla"), QStringLiteral("Écran"));
    add(QStringLiteral("window_tab"), QStringLiteral("Finestra"), QStringLiteral("Window"), QStringLiteral("Fenster"), QStringLiteral("Ventana"), QStringLiteral("Fenêtre"));
    add(QStringLiteral("region_tab"), QStringLiteral("Regione"), QStringLiteral("Region"), QStringLiteral("Bereich"), QStringLiteral("Región"), QStringLiteral("Région"));
    add(QStringLiteral("drag_crosshair"), QStringLiteral("Trascina mirino"), QStringLiteral("Drag crosshair"), QStringLiteral("Fadenkreuz ziehen"), QStringLiteral("Arrastra el punto de mira"), QStringLiteral("Glisser le réticule"));
    add(QStringLiteral("allow_restore_token"), QStringLiteral("Consenti token di ripristino"), QStringLiteral("Allow restore token"), QStringLiteral("Wiederherstellungs-Token erlauben"), QStringLiteral("Permitir token de restauración"), QStringLiteral("Autoriser le jeton de restauration"));
    add(QStringLiteral("select_window_title"), QStringLiteral("Seleziona Finestra"), QStringLiteral("Select Window"), QStringLiteral("Fenster auswählen"), QStringLiteral("Selecciona ventana"), QStringLiteral("Sélectionner la fenêtre"));
    add(QStringLiteral("select_window_desc"), QStringLiteral("Fai clic sulla finestra che desideri condividere"), QStringLiteral("Click the window you want to share"), QStringLiteral("Klicke auf das Fenster, das du freigeben möchtest"), QStringLiteral("Haz clic en la ventana que deseas compartir"), QStringLiteral("Cliquez sur la fenêtre que vous souhaitez partager"));
    add(QStringLiteral("remember_token"), QStringLiteral("Ricorda token"), QStringLiteral("Remember token"), QStringLiteral("Token merken"), QStringLiteral("Recordar token"), QStringLiteral("Se souvenir du jeton"));
    add(QStringLiteral("no_windows_detected"), QStringLiteral("Nessuna finestra aperta rilevata"), QStringLiteral("No open windows detected"), QStringLiteral("Keine offenen Fenster erkannt"), QStringLiteral("No se detectaron ventanas abiertas"), QStringLiteral("Aucune fenêtre ouverte détectée"));

    // --- Key badges & Actions ---
    add(QStringLiteral("space_key"), QStringLiteral("Spazio"), QStringLiteral("Space"), QStringLiteral("Leertaste"), QStringLiteral("Espacio"), QStringLiteral("Espace"));
    add(QStringLiteral("reset_default_btn"), QStringLiteral("Ripristina Default"), QStringLiteral("Reset Default"), QStringLiteral("Standard wiederherstellen"), QStringLiteral("Restablecer predeterminado"), QStringLiteral("Rétablir par défaut"));
    add(QStringLiteral("applying_status"), QStringLiteral("Applicando..."), QStringLiteral("Applying..."), QStringLiteral("Wird angewendet..."), QStringLiteral("Aplicando..."), QStringLiteral("Application en cours..."));
    add(QStringLiteral("copied_status"), QStringLiteral("Copiato!"), QStringLiteral("Copied!"), QStringLiteral("Kopiert!"), QStringLiteral("¡Copiado!"), QStringLiteral("Copié !"));
    add(QStringLiteral("copy_code_btn"), QStringLiteral("Copia Codice"), QStringLiteral("Copy Code"), QStringLiteral("Code kopieren"), QStringLiteral("Copiar código"), QStringLiteral("Copier le code"));

    // --- Studio Canvas Action Tags ---
    add(QStringLiteral("pinned_tag"), QStringLiteral("Fisso"), QStringLiteral("Pinned"), QStringLiteral("Fixiert"), QStringLiteral("Fijado"), QStringLiteral("Épinglé"));
    add(QStringLiteral("remove_tag"), QStringLiteral("Rimuovi"), QStringLiteral("Remove"), QStringLiteral("Entfernen"), QStringLiteral("Eliminar"), QStringLiteral("Supprimer"));
    add(QStringLiteral("active_tag"), QStringLiteral("Attivo"), QStringLiteral("Active"), QStringLiteral("Aktiv"), QStringLiteral("Activo"), QStringLiteral("Actif"));
    add(QStringLiteral("add_tag"), QStringLiteral("Aggiungi"), QStringLiteral("Add"), QStringLiteral("Hinzufügen"), QStringLiteral("Añadir"), QStringLiteral("Ajouter"));
    add(QStringLiteral("connected_tag"), QStringLiteral("Connesso"), QStringLiteral("Connected"), QStringLiteral("Verbunden"), QStringLiteral("Conectado"), QStringLiteral("Connecté"));
    add(QStringLiteral("live_canvas_badge"), QStringLiteral("AREA LIVE CANVAS • WORKSPACE 8 RIGHE • "), QStringLiteral("LIVE CANVAS AREA • 8-ROW WORKSPACE • "), QStringLiteral("LIVE-CANVAS-BEREICH • 8-ZEILEN-WORKSPACE • "), QStringLiteral("ÁREA DE LIENZO EN VIVO • ESPACIO DE 8 FILAS • "), QStringLiteral("ZONE CANEVAS EN DIRECT • ESPACE 8 LIGNES • "));

    // --- Headphones & Audio ---
    add(QStringLiteral("noise_control_title"), QStringLiteral("CONTROLLO RUMORE"), QStringLiteral("NOISE CONTROL"), QStringLiteral("GERÄUSCHKONTROLLE"), QStringLiteral("CONTROL DE RUIDO"), QStringLiteral("CONTRÔLE DU BRUIT"));
    add(QStringLiteral("audio_perf_title"), QStringLiteral("AUDIO & PRESTAZIONI"), QStringLiteral("AUDIO & PERFORMANCE"), QStringLiteral("AUDIO & LEISTUNG"), QStringLiteral("AUDIO Y RENDIMIENTO"), QStringLiteral("AUDIO ET PERFORMANCES"));
    add(QStringLiteral("earbud_left"), QStringLiteral("Sinistro"), QStringLiteral("Left"), QStringLiteral("Links"), QStringLiteral("Izquierdo"), QStringLiteral("Gauche"));
    add(QStringLiteral("earbud_right"), QStringLiteral("Destro"), QStringLiteral("Right"), QStringLiteral("Rechts"), QStringLiteral("Derecho"), QStringLiteral("Droit"));
    add(QStringLiteral("case_battery"), QStringLiteral("Case"), QStringLiteral("Case"), QStringLiteral("Ladeetui"), QStringLiteral("Estuche"), QStringLiteral("Boîtier"));
    add(QStringLiteral("anc_transparency"), QStringLiteral("Trasparenza"), QStringLiteral("Transparency"), QStringLiteral("Transparenz"), QStringLiteral("Transparencia"), QStringLiteral("Transparence"));
    add(QStringLiteral("low_latency"), QStringLiteral("Bassa Latenza"), QStringLiteral("Low Latency"), QStringLiteral("Niedrige Latenz"), QStringLiteral("Baja latencia"), QStringLiteral("Faible latence"));
    add(QStringLiteral("open_windows_count"), QStringLiteral("aperte"), QStringLiteral("open"), QStringLiteral("geöffnet"), QStringLiteral("abiertas"), QStringLiteral("ouvertes"));
    add(QStringLiteral("select_dots"), QStringLiteral("Seleziona..."), QStringLiteral("Select..."), QStringLiteral("Auswählen..."), QStringLiteral("Seleccionar..."), QStringLiteral("Sélectionner..."));
    add(QStringLiteral("remember_auth_desc"), QStringLiteral("— Ricorda l'autorizzazione per non doverla confermare ogni volta"), QStringLiteral("— Remember authorization to avoid asking every time"), QStringLiteral("— Berechtigung merken, um nicht jedes Mal nachzufragen"), QStringLiteral("— Recordar la autorización para no confirmar cada vez"), QStringLiteral("— Mémoriser l'autorisation pour éviter de demander à chaque fois"));
}

