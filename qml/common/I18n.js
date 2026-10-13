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
    "language_auto": { "it": "Predefinita di Sistema (Auto)", "en": "System Default (Auto)", "de": "Systemstandard (Auto)", "es": "Predeterminado del sistema (Auto)", "fr": "Par défaut du système (Auto)" },
    "geom_workspace_placement": { "it": "Posizionamento & Pillola Workspace", "en": "Placement & Workspace Pill", "de": "Platzierung & Arbeitsbereich-Pille", "es": "Ubicación y píldora de espacio", "fr": "Placement et pilule d'espace" },
    "lock_clock_center": { "it": "Blocca Orologio al Centro Morto", "en": "Lock Clock to Dead Center", "de": "Uhr in der toten Mitte fixieren", "es": "Bloquear reloj en el centro", "fr": "Verrouiller l'horloge au centre" },
    "lock_clock_center_desc": { "it": "Mantiene l'orologio principale esattamente al centro di tutti i monitor", "en": "Keeps main clock exactly centered across all monitors", "de": "Hält Hauptuhr auf allen Monitoren genau zentriert", "es": "Mantiene el reloj principal exactamente en el centro", "fr": "Maintient l'horloge principale exactement au centre" },
    "active_workspace_pill": { "it": "Pillola Workspace Attivo", "en": "Active Workspace Pill", "de": "Aktive Arbeitsbereichs-Pille", "es": "Píldora de espacio activo", "fr": "Pilule d'espace actif" },
    "active_workspace_pill_desc": { "it": "Mostra una pillola satellite accanto all'orologio che indica il workspace corrente", "en": "Shows a satellite pill next to clock indicating current workspace", "de": "Zeigt Satelliten-Kapsel neben der Uhr für aktuellen Arbeitsbereich", "es": "Muestra una píldora satélite junto al reloj con el espacio actual", "fr": "Affiche une pilule satellite à côté de l'horloge indiquant l'espace actuel" },
    "workspace_pill_position": { "it": "Posizione Pillola Workspace", "en": "Workspace Pill Position", "de": "Position der Arbeitsbereichs-Pille", "es": "Posición de la píldora de espacio", "fr": "Position de la pilule d'espace" },
    "workspace_pill_position_desc": { "it": "Scegli se posizionare la pillola workspace a destra o a sinistra dell'orologio", "en": "Choose whether to place workspace pill to the right or left of clock", "de": "Wähle Platzierung der Arbeitsbereichs-Pille rechts oder links der Uhr", "es": "Elige si colocar la píldora a la derecha o izquierda del reloj", "fr": "Choisissez de placer la pilule à droite ou à gauche de l'horloge" },
    "right_default": { "it": "Destra (Predefinito)", "en": "Right (Default)", "de": "Rechts (Standard)", "es": "Derecha (Predeterminado)", "fr": "Droite (Par défaut)" },
    "left": { "it": "Sinistra", "en": "Left", "de": "Links", "es": "Izquierda", "fr": "Gauche" },
    "show_app_icons": { "it": "Mostra Icone Applicazioni", "en": "Show Application Icons", "de": "Anwendungs-Icons anzeigen", "es": "Mostrar iconos de aplicaciones", "fr": "Afficher les icônes d'applications" },
    "show_app_icons_desc": { "it": "Visualizza le miniature delle icone (es. Discord, browser, terminale) nei workspace con finestre aperte", "en": "Displays icon thumbnails (e.g. Discord, browser, terminal) in workspaces with open windows", "de": "Zeigt Icon-Vorschauen in Arbeitsbereichen mit offenen Fenstern", "es": "Muestra miniaturas de iconos en espacios con ventanas abiertas", "fr": "Affiche les vignettes d'icônes dans les espaces avec fenêtres ouvertes" },
    "shown_workspaces_count": { "it": "Numero Workspace Mostrati", "en": "Number of Workspaces Shown", "de": "Anzahl angezeigter Arbeitsbereiche", "es": "Número de espacios mostrados", "fr": "Nombre d'espaces affichés" },
    "shown_workspaces_count_desc": { "it": "Imposta quanti workspace visualizzare nella pillola (espande automaticamente se navighi oltre)", "en": "Set how many workspaces to show in pill (automatically expands if you navigate past)", "de": "Legt fest, wie viele Arbeitsbereiche in der Pille angezeigt werden", "es": "Establece cuántos espacios mostrar en la píldora", "fr": "Définit le nombre d'espaces à afficher dans la pilule" },
    "ten_default": { "it": "10 (Predefinito)", "en": "10 (Default)", "de": "10 (Standard)", "es": "10 (Predeterminado)", "fr": "10 (Par défaut)" },
    "open_btn": { "it": "Apri", "en": "Open", "de": "Öffnen", "es": "Abrir", "fr": "Ouvrir" },
    "quickshell_wallpaper": { "it": "Sfondo Integrato nella Shell", "en": "Integrated Shell Wallpaper", "de": "Integrierter Shell-Hintergrund", "es": "Fondo integrado en la shell", "fr": "Fond d'écran intégré à la shell" },
    "quickshell_wallpaper_desc": { "it": "Lo sfondo viene gestito direttamente da Quickshell", "en": "Wallpaper is managed directly by Quickshell", "de": "Hintergrundbild wird direkt von Quickshell verwaltet", "es": "El fondo es gestionado directamente por Quickshell", "fr": "Le fond d'écran est géré directement par Quickshell" },
    "update_shell_btn": { "it": "Aggiorna Shell", "en": "Update Shell", "de": "Shell aktualisieren", "es": "Actualizar Shell", "fr": "Mettre à jour la shell" },
    "settings_window_title": { "it": "Dynamic Island — Impostazioni", "en": "Dynamic Island — Settings", "de": "Dynamic Island — Einstellungen", "es": "Dynamic Island — Ajustes", "fr": "Dynamic Island — Paramètres" },
    "clear_history_btn": { "it": "Clear", "en": "Clear", "de": "Löschen", "es": "Borrar", "fr": "Effacer" },
    "cancella_btn": { "it": "Cancella", "en": "Clear", "de": "Löschen", "es": "Borrar", "fr": "Effacer" },
    "display_title": { "it": "Display", "en": "Display", "de": "Bildschirm", "es": "Pantalla", "fr": "Écran" },
    "sound_title": { "it": "Sound", "en": "Sound", "de": "Ton", "es": "Sonido", "fr": "Son" },
    "night_mode_title": { "it": "Night mode", "en": "Night mode", "de": "Nachtmodus", "es": "Modo noche", "fr": "Mode nuit" },
    "silent_ring_label": { "it": "Suoneria", "en": "Ring", "de": "Klingeln", "es": "Timbre", "fr": "Sonnerie" },
    "in_call_state": { "it": "In chiamata...", "en": "In call...", "de": "Im Anruf...", "es": "En llamada...", "fr": "En appel..." },
    "admin_password_placeholder": { "it": "Password amministratore...", "en": "Administrator password...", "de": "Administrator-Passwort...", "es": "Contraseña de administrador...", "fr": "Mot de passe administrateur..." },
    "screen_trans_active": { "it": "Trasmissione video attiva", "en": "Screen transmission active", "de": "Bildschirmübertragung aktiv", "es": "Transmisión de pantalla activa", "fr": "Diffusion d'écran active" },
    "notification_single": { "it": "Notifica", "en": "Notification", "de": "Benachrichtigung", "es": "Notificación", "fr": "Notification" },
    "cancel_btn": { "it": "Cancel", "en": "Cancel", "de": "Abbrechen", "es": "Cancelar", "fr": "Annuler" },
    "annulla_btn": { "it": "Annulla", "en": "Cancel", "de": "Abbrechen", "es": "Cancelar", "fr": "Annuler" },
    "enter_password_for_prefix": { "it": "Enter password for ", "en": "Enter password for ", "de": "Passwort eingeben für ", "es": "Introduce la contraseña para ", "fr": "Entrez le mot de passe pour " },
    "enter_pwd_it_prefix": { "it": "Inserisci la password per ", "en": "Enter password for ", "de": "Passwort eingeben für ", "es": "Introduce la contraseña para ", "fr": "Entrez le mot de passe pour " },
    "pwd_field_label": { "it": "Password", "en": "Password", "de": "Passwort", "es": "Contraseña", "fr": "Mot de passe" },
    "join_network_btn": { "it": "Join", "en": "Join", "de": "Beitreten", "es": "Unirse", "fr": "Rejoindre" },
    "turn_on_wifi_hint": { "it": "Turn on Wi-Fi to see nearby networks.", "en": "Turn on Wi-Fi to see nearby networks.", "de": "WLAN aktivieren, um Netzwerke in der Nähe anzuzeigen.", "es": "Activa el Wi-Fi para ver las redes cercanas.", "fr": "Activez le Wi-Fi pour voir les réseaux proches." },
    "scanning_wifi_hint": { "it": "Scanning nearby networks...", "en": "Scanning nearby networks...", "de": "Netzwerke in der Nähe werden gesucht...", "es": "Buscando redes cercanas...", "fr": "Recherche des réseaux proches..." },
    "turn_on_bt_hint": { "it": "Turn on Bluetooth to see nearby devices.", "en": "Turn on Bluetooth to see nearby devices.", "de": "Bluetooth aktivieren, um Geräte in der Nähe anzuzeigen.", "es": "Activa Bluetooth para ver los dispositivos cercanos.", "fr": "Activez le Bluetooth pour voir les appareils proches." },
    "scanning_bt_hint": { "it": "Scanning nearby devices...", "en": "Scanning nearby devices...", "de": "Geräte in der Nähe werden gesucht...", "es": "Buscando dispositivos cercanos...", "fr": "Recherche des appareils proches..." },
    "no_bt_devices_found": { "it": "No devices found. Put your device in pairing mode, then scan again.", "en": "No devices found. Put your device in pairing mode, then scan again.", "de": "Keine Geräte gefunden. Gerät in den Kopplungsmodus versetzen und erneut suchen.", "es": "No se encontraron dispositivos. Pon el dispositivo en modo emparejamiento y vuelve a buscar.", "fr": "Aucun appareil trouvé. Mettez votre appareil en mode jumelage puis réessayez." },
    "paired_state": { "it": "Paired", "en": "Paired", "de": "Gekoppelt", "es": "Emparejado", "fr": "Jumelé" },
    "available_state": { "it": "Available", "en": "Available", "de": "Verfügbar", "es": "Disponible", "fr": "Disponible" },
    "notification_history": { "it": "Cronologia Notifiche", "en": "Notification History", "de": "Benachrichtigungsverlauf", "es": "Historial de notificaciones", "fr": "Historique des notifications" },
    "no_notifications": { "it": "Nessuna notifica", "en": "No notifications", "de": "Keine Benachrichtigungen", "es": "Sin notificaciones", "fr": "Aucune notification" },
    "from_prep": { "it": "Da", "en": "From", "de": "Von", "es": "De", "fr": "De" },
    "search_wallpapers_ellipsis": { "it": "Cerca sfondi...", "en": "Search wallpapers…", "de": "Hintergründe suchen…", "es": "Buscar fondos…", "fr": "Rechercher des fonds d'écran…" },
    "search_wallpapers_ascii": { "it": "Cerca sfondi...", "en": "Search wallpapers...", "de": "Hintergründe suchen...", "es": "Buscar fondos...", "fr": "Rechercher des fonds d'écran..." },
    "anc_high": { "it": "Alta", "en": "High", "de": "Hoch", "es": "Alta", "fr": "Haute" },
    "anc_mid": { "it": "Media", "en": "Medium", "de": "Mittel", "es": "Media", "fr": "Moyenne" },
    "anc_low": { "it": "Bassa", "en": "Low", "de": "Niedrig", "es": "Baja", "fr": "Basse" },
    "anc_adaptive": { "it": "Adattiva", "en": "Adaptive", "de": "Adaptiv", "es": "Adaptativa", "fr": "Adaptative" },
    "bass_boost": { "it": "Bass Boost", "en": "Bass Boost", "de": "Bass-Verstärkung", "es": "Realce de graves", "fr": "Amplification des basses" },

    // --- Shadows & Visual Depth ---
    "shadows_visual_depth": { "it": "Ombre & Profondità Visiva", "en": "Shadows & Visual Depth", "de": "Schatten & Visuelle Tiefe", "es": "Sombras y profundidad visual", "fr": "Ombres et profondeur visuelle" },
    "enable_floating_shadows": { "it": "Abilita Ombre Fluttuanti", "en": "Enable Floating Shadows", "de": "Schwebende Schatten aktivieren", "es": "Activar sombras flotantes", "fr": "Activer les ombres flottantes" },
    "floating_shadows_desc": { "it": "Crea un effetto rilievo moderno sotto la capsula principale e i satelliti", "en": "Create a modern elevation relief under the main capsule and satellites", "de": "Erstellt ein modernes Relief unter der Hauptkapsel und Satelliten", "es": "Crea un efecto de relieve moderno bajo la cápsula principal y satélites", "fr": "Crée un effet de relief moderne sous la capsule principale et satellites" },
    "shadow_intensity": { "it": "Intensità Ombre", "en": "Shadow Intensity", "de": "Schattenintensität", "es": "Intensidad de sombras", "fr": "Intensité des ombres" },
    "shadow_intensity_desc": { "it": "Opacità e contrasto dello strato di profondità scuro", "en": "Dark depth layer opacity and contrast", "de": "Deckkraft und Kontrast der dunklen Tiefenebene", "es": "Opacidad y contraste de la capa de profundidad oscura", "fr": "Opacité et contraste du calque de profondeur sombre" },
    "shadow_spread_radius": { "it": "Diffusione e Raggio Ombre", "en": "Shadow Spread & Radius", "de": "Schattenausbreitung & -radius", "es": "Difusión y radio de sombras", "fr": "Diffusion et rayon des ombres" },
    "shadow_spread_radius_desc": { "it": "Raggio di sfocatura per ombre morbide ed eleganti", "en": "Blur radius for soft and elegant shadows", "de": "Unschärferadius für weiche und elegante Schatten", "es": "Radio de desenfoque para sombras suaves y elegantes", "fr": "Rayon de flou pour des ombres douces et élégantes" },

    // --- Wallpaper Transitions & Custom Colors ---
    "wallpaper_anim_title": { "it": "Animazione Cambio Sfondo", "en": "Wallpaper Transition Animation", "de": "Hintergrundübergang-Animation", "es": "Animación de transición de fondo", "fr": "Animation de transition du fond" },
    "wallpaper_anim_desc": { "it": "Effetto animato applicato da awww al cambio dello sfondo", "en": "Animated effect applied by awww when changing wallpaper", "de": "Animierter Effekt von awww beim Hintergrundwechsel", "es": "Efecto animado aplicado por awww al cambiar de fondo", "fr": "Effet animé appliqué par awww lors du changement de fond" },
    "anim_random": { "it": "Casuale", "en": "Random", "de": "Zufällig", "es": "Aleatorio", "fr": "Aléatoire" },
    "anim_simple": { "it": "Semplice", "en": "Simple", "de": "Einfach", "es": "Simple", "fr": "Simple" },
    "anim_circle": { "it": "Cerchio", "en": "Circle", "de": "Kreis", "es": "Círculo", "fr": "Cercle" },
    "anim_wave": { "it": "Onda", "en": "Wave", "de": "Welle", "es": "Ola", "fr": "Vague" },
    "anim_grow": { "it": "Espansione", "en": "Grow", "de": "Wachsen", "es": "Expansión", "fr": "Expansion" },
    "anim_center": { "it": "Centro", "en": "Center", "de": "Zentrum", "es": "Centro", "fr": "Centre" },
    "anim_any": { "it": "Qualsiasi", "en": "Any", "de": "Beliebig", "es": "Cualquiera", "fr": "N'importe" },
    "static_wallpaper_desc": { "it": "Gestione statica in Quickshell (lascia disattivato per vedere le animazioni native awww)", "en": "Static handling in Quickshell (leave off to see native awww animations)", "de": "Statische Verwaltung in Quickshell (deaktiviert lassen für native awww-Animationen)", "es": "Gestión estática en Quickshell (dejar desactivado para animaciones nativas awww)", "fr": "Gestion statique dans Quickshell (laisser désactivé pour voir les animations awww)" },
    "custom_accent_color": { "it": "Colore Accento Personalizzato", "en": "Custom Accent Color", "de": "Benutzerdefinierte Akzentfarbe", "es": "Color de acento personalizado", "fr": "Couleur d'accent personnalisée" },
    "custom_accent_desc": { "it": "Seleziona una tonalità vivace o digita un codice HEX", "en": "Select a vibrant tone or type a HEX code", "de": "Wähle einen lebendigen Ton oder gib einen HEX-Code ein", "es": "Selecciona un tono vibrante o introduce un código HEX", "fr": "Sélectionnez une teinte vive ou entrez un code HEX" },

    // --- Hover & Behavior ---
    "behavior_media_mouse": { "it": "Comportamento, Media & Mouse", "en": "Behavior, Media & Mouse", "de": "Verhalten, Medien & Maus", "es": "Comportamiento, multimedia y ratón", "fr": "Comportement, médias et souris" },
    "expand_island_hover": { "it": "Espandi Isola al Passaggio del Mouse (Hover)", "en": "Expand Island on Mouse Hover", "de": "Insel bei Mausberührung (Hover) erweitern", "es": "Expandir isla al pasar el ratón (Hover)", "fr": "Agrandir l'île au survol de la souris (Hover)" },
    "hover_action_desc": { "it": "Apre il centro di controllo o il player multimediale quando passi il cursore sopra la barra", "en": "Opens control center or media player when hovering over the bar", "de": "Öffnet das Kontrollzentrum oder den Medienplayer beim Überfahren der Leiste", "es": "Abre el centro de control o el reproductor multimedia al pasar el cursor sobre la barra", "fr": "Ouvre le centre de contrôle ou le lecteur multimédia au survol de la barre" },
    "prevent_auto_expand_desc": { "it": "Evita che l'isola si apra da sola a schermo ogni volta che inizia un nuovo brano", "en": "Prevent island from expanding on screen each time a new track starts", "de": "Verhindert automatisches Erweitern der Insel bei jedem neuen Titel", "es": "Evita que la isla se expanda sola en pantalla cada vez que empieza una nueva canción", "fr": "Évite que l'île ne s'agrandisse à l'écran à chaque nouveau morceau" },

    // --- Shelf, Clipboard & Bluetooth Messages ---
    "connecting_ellipsis": { "it": "Connessione in corso...", "en": "Connecting...", "de": "Verbinde...", "es": "Conectando...", "fr": "Connexion..." },
    "disconnecting_ellipsis": { "it": "Disconnessione in corso...", "en": "Disconnecting...", "de": "Trenne...", "es": "Desconectando...", "fr": "Déconnexion..." },
    "copied_excl": { "it": "Copiato!", "en": "Copied!", "de": "Kopiert!", "es": "¡Copiado!", "fr": "Copié !" },
    "search_clipboard": { "it": "Cerca negli appunti...", "en": "Search clipboard...", "de": "Zwischenablage durchsuchen...", "es": "Buscar en portapapeles...", "fr": "Rechercher dans le presse-papiers..." },
    "file_shelf_drop_hint": { "it": "Trascina file o cartelle sulla Dynamic Island", "en": "Drag files or folders onto Dynamic Island", "de": "Dateien oder Ordner auf die Dynamic Island ziehen", "es": "Arrastra archivos o carpetas a la Dynamic Island", "fr": "Faites glisser des fichiers ou des dossiers sur Dynamic Island" },
    "file_shelf_reorder_hint": { "it": "Trascina un file per riordinarlo o rilascialo in un'altra applicazione", "en": "Drag a file to reorder it or drop it into another application", "de": "Datei ziehen zum Umordnen oder in einer anderen Anwendung ablegen", "es": "Arrastra un archivo para reordenarlo o suéltalo en otra aplicación", "fr": "Faites glisser un fichier pour le réordonner ou déposez-le dans une autre application" }
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
