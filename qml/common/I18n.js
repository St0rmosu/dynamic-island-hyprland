// i18n JavaScript helper module for Dynamic Island
.pragma library

var translations = {
    // --- Polkit & Biometrics ---
    "use_face_id": { "it": "Usa Face ID", "en": "Use Face ID", "de": "Face ID verwenden", "es": "Usar Face ID", "fr": "Utiliser Face ID" },
    "use_touch_id": { "it": "Usa Touch ID", "en": "Use Touch ID", "de": "Touch ID verwenden", "es": "Usar Touch ID", "fr": "Utiliser Touch ID" },
    "use_password": { "it": "Usa Password", "en": "Use Password", "de": "Passwort verwenden", "es": "Usar contraseña", "fr": "Utiliser mot de passe" },
    "face_id_title": { "it": "Face ID (Windows Hello)", "en": "Face ID (Windows Hello)", "de": "Face ID (Windows Hello)", "es": "Face ID (Windows Hello)", "fr": "Face ID (Windows Hello)" },
    "touch_id_title": { "it": "Touch ID (Impronta)", "en": "Touch ID (Fingerprint)", "de": "Touch ID (Fingerabdruck)", "es": "Touch ID (Huella)", "fr": "Touch ID (Empreinte)" },
    "face_id_prompt": { "it": "Posizionati davanti alla fotocamera", "en": "Position yourself in front of the camera", "de": "Vor der Kamera positionieren", "es": "Colócate frente a la cámara", "fr": "Placez-vous devant la caméra" },
    "touch_id_prompt": { "it": "Poggia il dito per sbloccare", "en": "Place finger to unlock", "de": "Finger zum Entsperren auflegen", "es": "Coloca el dedo para desbloquear", "fr": "Posez le doigt pour déverrouiller" },
    "enter_password": { "it": "Inserisci la password", "en": "Enter password", "de": "Passwort eingeben", "es": "Introduce la contraseña", "fr": "Entrez le mot de passe" },
    "face_scanning": { "it": "Scansione del volto...", "en": "Scanning face...", "de": "Gesichtsscan...", "es": "Escaneando rostro...", "fr": "Scan du visage..." },
    "fingerprint_scanning": { "it": "Scansione dell'impronta...", "en": "Scanning fingerprint...", "de": "Fingerabdruckscan...", "es": "Escaneando huella...", "fr": "Scan de l'empreinte..." },
    "face_verifying": { "it": "Riconoscimento facciale...", "en": "Facial recognition...", "de": "Gesichtserkennung...", "es": "Reconocimiento facial...", "fr": "Reconnaissance faciale..." },
    "fingerprint_verifying": { "it": "Verifica impronta in corso...", "en": "Verifying fingerprint...", "de": "Fingerabdruck wird überprüft...", "es": "Verificando huella...", "fr": "Vérification de l'empreinte..." },
    "auth_verifying": { "it": "Verifica autorizzazione...", "en": "Verifying authorization...", "de": "Autorisierung wird überprüft...", "es": "Verificando autorización...", "fr": "Vérification de l'autorisation..." },
    "checking_credentials": { "it": "Controllo credenziali...", "en": "Checking credentials...", "de": "Anmeldedaten prüfen...", "es": "Comprobando credenciales...", "fr": "Vérification des identifiants..." },
    "auth_face_success": { "it": "Autenticato con Face ID", "en": "Authenticated with Face ID", "de": "Mit Face ID authentifiziert", "es": "Autenticado con Face ID", "fr": "Authentifié avec Face ID" },
    "auth_fp_success": { "it": "Touch ID Confermato", "en": "Touch ID Confirmed", "de": "Touch ID bestätigt", "es": "Touch ID confirmado", "fr": "Touch ID confirmé" },
    "access_granted": { "it": "Accesso consentito", "en": "Access granted", "de": "Zugriff gewährt", "es": "Acceso permitido", "fr": "Accès autorisé" },
    "face_not_recognized": { "it": "Viso non riconosciuto", "en": "Face not recognized", "de": "Gesicht nicht erkannt", "es": "Rostro no reconocido", "fr": "Visage non reconnu" },
    "fp_not_recognized": { "it": "Impronta non riconosciuta", "en": "Fingerprint not recognized", "de": "Fingerabdruck nicht erkannt", "es": "Huella no reconocida", "fr": "Empreinte non reconnue" },
    "wrong_password": { "it": "Password errata. Riprova.", "en": "Incorrect password. Try again.", "de": "Falsches Passwort. Bitte erneut versuchen.", "es": "Contraseña incorrecta. Inténtalo de nuevo.", "fr": "Mot de passe incorrect. Réessayez." },
    "face_retry_hint": { "it": "Posizionati davanti alla fotocamera o usa la password", "en": "Look at camera or enter password", "de": "In die Kamera blicken oder Passwort eingeben", "es": "Mira a la cámara o usa la contraseña", "fr": "Regardez la caméra ou entrez le mot de passe" },
    "fp_retry_hint": { "it": "Poggia nuovamente il dito sul sensore", "en": "Place finger on sensor again", "de": "Finger erneut auflegen", "es": "Coloca el dedo de nuevo en el sensor", "fr": "Reposez le doigt sur le capteur" },
    "pwd_retry_hint": { "it": "Riprova con la password corretta", "en": "Try again with correct password", "de": "Mit dem richtigen Passwort erneut versuchen", "es": "Reintenta con la contraseña correcta", "fr": "Réessayez avec le bon mot de passe" },

    // --- Control Center & Connectivity ---
    "wi_fi": { "it": "Wi-Fi", "en": "Wi-Fi", "de": "WLAN", "es": "Wi-Fi", "fr": "Wi-Fi" },
    "bluetooth": { "it": "Bluetooth", "en": "Bluetooth", "de": "Bluetooth", "es": "Bluetooth", "fr": "Bluetooth" },
    "volume": { "it": "Volume", "en": "Volume", "de": "Lautstärke", "es": "Volumen", "fr": "Volume" },
    "volume_control": { "it": "Controllo Volume", "en": "Volume Control", "de": "Lautstärkeregelung", "es": "Control de volumen", "fr": "Contrôle du volume" },
    "brightness": { "it": "Luminosità", "en": "Brightness", "de": "Helligkeit", "es": "Brillo", "fr": "Luminosité" },
    "display_brightness": { "it": "Luminosità Display", "en": "Display Brightness", "de": "Bildschirmhelligkeit", "es": "Brillo de pantalla", "fr": "Luminosité de l'écran" },
    "notifications": { "it": "Notifiche", "en": "Notifications", "de": "Benachrichtigungen", "es": "Notificaciones", "fr": "Notifications" },
    "notification_center": { "it": "Centro Notifiche", "en": "Notification Center", "de": "Mitteilungszentrale", "es": "Centro de notificaciones", "fr": "Centre de notifications" },
    "night_light": { "it": "Luce Notturna", "en": "Night Light", "de": "Nachtmodus", "es": "Luz nocturna", "fr": "Mode nuit" },
    "night_light_focus": { "it": "Luce Notturna & Focus", "en": "Night Light & Focus", "de": "Nachtlicht & Fokus", "es": "Luz nocturna y enfoque", "fr": "Lumière nocturne et focus" },
    "battery": { "it": "Batteria", "en": "Battery", "de": "Batterie", "es": "Batería", "fr": "Batterie" },
    "battery_profile": { "it": "Profilo Batteria TLP", "en": "TLP Battery Profile", "de": "TLP-Batterieprofil", "es": "Perfil de batería TLP", "fr": "Profil de batterie TLP" },
    "connected": { "it": "Connesso", "en": "Connected", "de": "Verbunden", "es": "Conectado", "fr": "Connecté" },
    "disconnected": { "it": "Disconnesso", "en": "Disconnected", "de": "Getrennt", "es": "Desconectado", "fr": "Déconnecté" },
    "connecting": { "it": "Connessione in corso...", "en": "Connecting...", "de": "Verbinde...", "es": "Conectando...", "fr": "Connexion..." },
    "disconnecting": { "it": "Disconnessione in corso...", "en": "Disconnecting...", "de": "Trenne...", "es": "Desconectando...", "fr": "Déconnexion..." },
    "connect": { "it": "Connetti", "en": "Connect", "de": "Verbinden", "es": "Conectar", "fr": "Connecter" },
    "disconnect": { "it": "Disconnetti", "en": "Disconnect", "de": "Trennen", "es": "Desconectar", "fr": "Déconnecter" },
    "forget": { "it": "Dimentica", "en": "Forget", "de": "Vergessen", "es": "Olvidar", "fr": "Oublier" },
    "scan": { "it": "Scansiona", "en": "Scan", "de": "Scannen", "es": "Escanear", "fr": "Scanner" },
    "stop": { "it": "Ferma", "en": "Stop", "de": "Stopp", "es": "Detener", "fr": "Arrêter" },
    "no_new_notifications": { "it": "Nessuna nuova notifica", "en": "No new notifications", "de": "Keine neuen Benachrichtigungen", "es": "No hay notificaciones nuevas", "fr": "Aucune nouvelle notification" },
    "clear_all": { "it": "Cancella tutto", "en": "Clear all", "de": "Alles löschen", "es": "Borrar todo", "fr": "Effacer tout" },
    "desktop_bar": { "it": "Barra Desktop", "en": "Desktop Bar", "de": "Desktop-Leiste", "es": "Barra de escritorio", "fr": "Barre de bureau" },
    "clipboard": { "it": "Appunti", "en": "Clipboard", "de": "Zwischenablage", "es": "Portapapeles", "fr": "Presse-papiers" },
    "history": { "it": "Cronologia", "en": "History", "de": "Verlauf", "es": "Historial", "fr": "Historique" },
    "back": { "it": "Indietro", "en": "Back", "de": "Zurück", "es": "Atrás", "fr": "Retour" },
    "silent": { "it": "Silenzioso", "en": "Silent", "de": "Stumm", "es": "Silencio", "fr": "Silencieux" },
    "settings": { "it": "Impostazioni", "en": "Settings", "de": "Einstellungen", "es": "Ajustes", "fr": "Paramètres" },
    "update_shell": { "it": "Aggiorna Shell", "en": "Update Shell", "de": "Shell aktualisieren", "es": "Actualizar Shell", "fr": "Mettre à jour" },
    "bar_clipboard": { "it": "Barra & Appunti", "en": "Bar & Clipboard", "de": "Leiste & Zwischenablage", "es": "Barra y portapapeles", "fr": "Barre et presse-papiers" },
    "clock_battery": { "it": "Orologio & Batteria", "en": "Clock & Battery", "de": "Uhr & Akku", "es": "Reloj y batería", "fr": "Horloge et batterie" },
    "wifi_card": { "it": "Scheda Wi-Fi", "en": "Wi-Fi Card", "de": "WLAN-Karte", "es": "Tarjeta Wi-Fi", "fr": "Carte Wi-Fi" },
    "bluetooth_card": { "it": "Scheda Bluetooth", "en": "Bluetooth Card", "de": "Bluetooth-Karte", "es": "Tarjeta Bluetooth", "fr": "Carte Bluetooth" },

    // --- Power Menu ---
    "lock": { "it": "Blocca", "en": "Lock", "de": "Sperren", "es": "Bloquear", "fr": "Verrouiller" },
    "logout": { "it": "Esci", "en": "Log out", "de": "Abmelden", "es": "Cerrar sesión", "fr": "Déconnexion" },
    "suspend": { "it": "Sospendi", "en": "Suspend", "de": "Energiesparen", "es": "Suspender", "fr": "Mettre en veille" },
    "restart": { "it": "Riavvia", "en": "Restart", "de": "Neustarten", "es": "Reiniciar", "fr": "Redémarrer" },
    "shutdown": { "it": "Spegni", "en": "Shut down", "de": "Herunterfahren", "es": "Apagar", "fr": "Éteindre" },

    // --- File Shelf & Clipboard & Shortcuts ---
    "drag_files": { "it": "Trascina file o cartelle sull'Isola Dinamica", "en": "Drag files or folders onto Dynamic Island", "de": "Dateien oder Ordner auf die Dynamic Island ziehen", "es": "Arrastra archivos o carpetas a la Isla Dinámica", "fr": "Glissez des fichiers ou dossiers sur la Dynamic Island" },
    "reorder_files": { "it": "Trascina un file per riordinarlo o rilascialo in un'altra applicazione", "en": "Drag a file to reorder it or drop it into another application", "de": "Datei ziehen zum Sortieren oder in andere Anwendung ablegen", "es": "Arrastra un archivo para reordenarlo o suéltalo en otra aplicación", "fr": "Glissez un fichier pour le réorganiser ou déposez-le dans une autre application" },
    "search_clipboard": { "it": "Cerca negli appunti...", "en": "Search clipboard...", "de": "Zwischenablage durchsuchen...", "es": "Buscar en portapapeles...", "fr": "Rechercher dans le presse-papiers..." },
    "no_copied_items": { "it": "Nessun elemento copiato", "en": "No copied items", "de": "Keine kopierten Elemente", "es": "No hay elementos copiados", "fr": "Aucun élément copié" },
    "no_results_found": { "it": "Nessun risultato trovato", "en": "No results found", "de": "Keine Ergebnisse gefunden", "es": "No se encontraron resultados", "fr": "Aucun résultat trouvé" },
    "image": { "it": "Immagine", "en": "Image", "de": "Bild", "es": "Imagen", "fr": "Image" },
    "copied": { "it": "Copiato!", "en": "Copied!", "de": "Kopiert!", "es": "¡Copiado!", "fr": "Copié !" },

    // --- Settings Pages ---
    "island_geometry": { "it": "Isola & Geometria", "en": "Island & Geometry", "de": "Insel & Geometrie", "es": "Isla y geometría", "fr": "Île et géométrie" },
    "control_center_studio": { "it": "Control Center & Studio", "en": "Control Center & Studio", "de": "Kontrollzentrum & Studio", "es": "Centro de control y estudio", "fr": "Centre de contrôle et studio" },
    "appearance_fonts": { "it": "Aspetto, Sfondi & Font", "en": "Appearance, Wallpapers & Fonts", "de": "Erscheinungsbild, Hintergrund & Schriftarten", "es": "Apariencia, fondos y fuentes", "fr": "Apparence, fonds d'écran et polices" },
    "keyboard_shortcuts": { "it": "Scorciatoie da Tastiera", "en": "Keyboard Shortcuts", "de": "Tastaturkürzel", "es": "Atajos de teclado", "fr": "Raccourcis clavier" },
    "language_setting": { "it": "Lingua dell'Interfaccia", "en": "Interface Language", "de": "Oberflächensprache", "es": "Idioma de la interfaz", "fr": "Langue de l'interface" },
    "language_auto": { "it": "Predefinita di Sistema (Auto)", "en": "System Default (Auto)", "de": "Systemstandard (Auto)", "es": "Predeterminado del sistema (Auto)", "fr": "Par défaut du système (Auto)" }
};

// Build reverse lookup index for Italian & English strings
var index = {};
(function() {
    for (var k in translations) {
        var d = translations[k];
        index[k.toLowerCase()] = d;
        for (var lang in d) {
            index[d[lang].toLowerCase()] = d;
        }
    }
})();

function tr(text, forcedLang) {
    if (!text) return "";
    var key = String(text).trim().toLowerCase();
    var dict = index[key];
    if (!dict) return text;

    var lang = forcedLang || "it";
    if (typeof I18n !== "undefined" && I18n && I18n.currentLanguage) {
        lang = I18n.currentLanguage;
    }

    if (dict[lang]) return dict[lang];
    if (dict["en"]) return dict["en"];
    if (dict["it"]) return dict["it"];
    return text;
}
