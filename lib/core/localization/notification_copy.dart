import 'language_manager.dart';

// Shared copy source: backend/data/notification_copy.json.
const notificationCopyData = {
  "en": {
    "Notifications are off.": "Notifications are off.",
    "Notifications are on.": "Notifications are on.",
    "Paused until {date}, {time}.": "Paused until {date}, {time}.",
    "Next: {date} · {time} workout": "Next: {date} · {time} workout",
    "Turned off in phone settings": "Turned off in phone settings",
    "Tap to allow Setcraft notifications": "Tap to allow Setcraft notifications",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Reminders aren’t available in this version. Rest timer alerts still work.",
    "Couldn’t reach the notification service. Try again later.": "Couldn’t reach the notification service. Try again later.",
    "Reminders": "Reminders",
    "Workout reminders": "Workout reminders",
    "Training days · {time}": "Training days · {time}",
    "Daily check-in": "Daily check-in",
    "How you slept and feel · {time}": "How you slept and feel · {time}",
    "Meal reminder": "Meal reminder",
    "If breakfast isn’t logged · {time}": "If breakfast isn’t logged · {time}",
    "If lunch isn’t logged · {time}": "If lunch isn’t logged · {time}",
    "If dinner isn’t logged · {time}": "If dinner isn’t logged · {time}",
    "If a snack isn’t logged · {time}": "If a snack isn’t logged · {time}",
    "Weekly summary": "Weekly summary",
    "Sundays · {time}": "Sundays · {time}",
    "New weekly plan": "New weekly plan",
    "When next week’s plan is ready": "When next week’s plan is ready",
    "Trial & billing": "Trial & billing",
    "Before your trial ends or access changes": "Before your trial ends or access changes",
    "Trial ending · No automatic charge": "Trial ending · No automatic charge",
    "Trial ending · Renewal cancelled": "Trial ending · Renewal cancelled",
    "Trial ending · Manage renewal in your app store": "Trial ending · Manage renewal in your app store",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.",
    "Quiet hours": "Quiet hours",
    "Quiet from": "Quiet from",
    "Quiet until": "Quiet until",
    "Quiet hours start": "Quiet hours start",
    "Quiet hours end": "Quiet hours end",
    "Quiet hours are off. Set different times to turn them on.": "Quiet hours are off. Set different times to turn them on.",
    "Reminders due during quiet hours arrive when they end.": "Reminders due during quiet hours arrive when they end.",
    "Trial & billing alerts still arrive": "Trial & billing alerts still arrive",
    "Stop all reminders for 7 days": "Stop all reminders for 7 days",
    "When a rest timer you start ends": "When a rest timer you start ends",
    "Allow alerts at the exact second": "Allow alerts at the exact second",
    "Send test notification": "Send test notification",
    "Please wait…": "Please wait…",
    "Test sent. It should arrive shortly.": "Test sent. It should arrive shortly.",
    "Snack": "Snack",
    "Rest finished": "Rest finished",
    "Your next set is ready.": "Your next set is ready.",
    "Rest timer alerts": "Rest timer alerts",
    "Only for timers you start. Works while your phone is locked.":
        "Only for timers you start. Works while your phone is locked.",
    "During workouts": "During workouts",
    "Precise timer alerts": "Precise timer alerts",
    "Allow alarms and reminders for on-time rest alerts.":
        "Allow alarms and reminders for on-time rest alerts.",
    "Pause reminders": "Pause reminders",
    "Resume reminders": "Resume reminders",
    "For 7 days": "For 7 days",
    "Account reminders stay on while training reminders are paused.":
        "Account reminders stay on while training reminders are paused.",
    "Next workout reminder": "Next workout reminder",
    "No upcoming workout reminder.": "No upcoming workout reminder.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Reminders during quiet hours arrive after quiet time ends.",
    "Quiet hours are off.": "Quiet hours are off.",
    "Trial and renewal reminders": "Trial and renewal reminders",
    "Get updates before your trial ends and when access changes.":
        "Get updates before your trial ends and when access changes.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Your trial ends soon. Your subscription is set to end without renewal.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.",
    "Choose a pause within the next 30 days.":
        "Choose a pause within the next 30 days.",
    "Remind me in 15 minutes": "Remind me in 15 minutes",
    "Reminder snoozed.": "Reminder snoozed.",
    "Open your scheduled workout when you’re ready.":
        "Open your scheduled workout when you’re ready.",
    "Your weekly recap is ready": "Your weekly recap is ready",
    "Rest alerts are unavailable on this device.":
        "Rest alerts are unavailable on this device.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Remote reminders are not available yet. Rest timer alerts still work on this phone.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Reminders are temporarily unavailable. Please try again later."
  },
  "de": {
    "Notifications are off.": "Benachrichtigungen sind aus.",
    "Notifications are on.": "Benachrichtigungen sind an.",
    "Paused until {date}, {time}.": "Pausiert bis {date}, {time}.",
    "Next: {date} · {time} workout": "Nächstes Training: {date} · {time}",
    "Turned off in phone settings": "In den Telefoneinstellungen deaktiviert",
    "Tap to allow Setcraft notifications": "Tippen, um Setcraft-Benachrichtigungen zu erlauben",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Erinnerungen sind in dieser Version nicht verfügbar. Pausentimer-Hinweise funktionieren weiterhin.",
    "Couldn’t reach the notification service. Try again later.": "Der Benachrichtigungsdienst ist nicht erreichbar. Versuche es später erneut.",
    "Reminders": "Erinnerungen",
    "Workout reminders": "Trainingserinnerungen",
    "Training days · {time}": "Trainingstage · {time}",
    "Daily check-in": "Täglicher Check-in",
    "How you slept and feel · {time}": "Schlaf und Befinden · {time}",
    "Meal reminder": "Mahlzeit-Erinnerung",
    "If breakfast isn’t logged · {time}": "Wenn das Frühstück nicht erfasst ist · {time}",
    "If lunch isn’t logged · {time}": "Wenn das Mittagessen nicht erfasst ist · {time}",
    "If dinner isn’t logged · {time}": "Wenn das Abendessen nicht erfasst ist · {time}",
    "If a snack isn’t logged · {time}": "Wenn kein Snack erfasst ist · {time}",
    "Weekly summary": "Wochenrückblick",
    "Sundays · {time}": "Sonntags · {time}",
    "New weekly plan": "Neuer Wochenplan",
    "When next week’s plan is ready": "Wenn der Plan für nächste Woche bereit ist",
    "Trial & billing": "Testphase & Abrechnung",
    "Before your trial ends or access changes": "Bevor deine Testphase endet oder sich dein Zugang ändert",
    "Trial ending · No automatic charge": "Testphase endet · Keine automatische Abbuchung",
    "Trial ending · Renewal cancelled": "Testphase endet · Verlängerung gekündigt",
    "Trial ending · Manage renewal in your app store": "Testphase endet · Verlängerung im App Store verwalten",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Tippe auf eine Erinnerung, um die Uhrzeit zu ändern. Du bekommst höchstens 2 davon pro Tag, Training hat Vorrang. Plan- und Abrechnungshinweise zählen nicht.",
    "Quiet hours": "Ruhezeiten",
    "Quiet from": "Ruhe ab",
    "Quiet until": "Ruhe bis",
    "Quiet hours start": "Beginn der Ruhezeit",
    "Quiet hours end": "Ende der Ruhezeit",
    "Quiet hours are off. Set different times to turn them on.": "Ruhezeiten sind aus. Lege unterschiedliche Uhrzeiten fest, um sie einzuschalten.",
    "Reminders due during quiet hours arrive when they end.": "Erinnerungen während der Ruhezeit kommen, sobald sie endet.",
    "Trial & billing alerts still arrive": "Hinweise zu Testphase & Abrechnung kommen weiterhin",
    "Stop all reminders for 7 days": "Alle Erinnerungen für 7 Tage stoppen",
    "When a rest timer you start ends": "Wenn ein von dir gestarteter Pausentimer endet",
    "Allow alerts at the exact second": "Hinweise auf die Sekunde genau erlauben",
    "Send test notification": "Testbenachrichtigung senden",
    "Please wait…": "Bitte warten…",
    "Test sent. It should arrive shortly.": "Test gesendet. Er sollte gleich ankommen.",
    "Snack": "Snack",
    "Rest finished": "Pause beendet",
    "Your next set is ready.": "Bereit für deinen nächsten Satz.",
    "Rest timer alerts": "Pausentimer-Hinweise",
    "Only for timers you start. Works while your phone is locked.":
        "Nur für selbst gestartete Timer. Funktioniert auch bei gesperrtem Handy.",
    "During workouts": "Beim Training",
    "Precise timer alerts": "Pünktliche Timer-Hinweise",
    "Allow alarms and reminders for on-time rest alerts.":
        "Erlaube Alarme und Erinnerungen für pünktliche Pausenhinweise.",
    "Pause reminders": "Erinnerungen pausieren",
    "Resume reminders": "Erinnerungen fortsetzen",
    "For 7 days": "Für 7 Tage",
    "Account reminders stay on while training reminders are paused.":
        "Kontohinweise bleiben während der Trainingspause aktiv.",
    "Next workout reminder": "Nächste Trainingserinnerung",
    "No upcoming workout reminder.": "Keine anstehende Trainingserinnerung.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Erinnerungen während der Ruhezeit kommen danach an.",
    "Quiet hours are off.": "Ruhezeiten sind ausgeschaltet.",
    "Trial and renewal reminders": "Probezeit und Verlängerung",
    "Get updates before your trial ends and when access changes.":
        "Hinweise vor Ende der Probezeit und bei Änderungen deines Zugangs.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Deine Probezeit endet bald. Dein Abo endet ohne Verlängerung.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Deine Probezeit endet bald. Verwalte oder kündige dein Abo vor der Verlängerung im App Store.",
    "Choose a pause within the next 30 days.":
        "Wähle eine Pause innerhalb der nächsten 30 Tage.",
    "Remind me in 15 minutes": "In 15 Minuten erinnern",
    "Reminder snoozed.": "Erinnerung verschoben.",
    "Open your scheduled workout when you’re ready.":
        "Öffne dein geplantes Training, wenn du bereit bist.",
    "Your weekly recap is ready": "Dein Wochenrückblick ist bereit",
    "Rest alerts are unavailable on this device.":
        "Pausenhinweise sind auf diesem Gerät nicht verfügbar.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Erinnerungen sind noch nicht verfügbar. Pausentimer-Hinweise funktionieren auf diesem Handy weiterhin.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Erinnerungen sind vorübergehend nicht verfügbar. Versuche es später erneut."
  },
  "fr": {
    "Notifications are off.": "Les notifications sont désactivées.",
    "Notifications are on.": "Les notifications sont activées.",
    "Paused until {date}, {time}.": "En pause jusqu’au {date}, {time}.",
    "Next: {date} · {time} workout": "Prochaine séance : {date} · {time}",
    "Turned off in phone settings": "Désactivées dans les réglages du téléphone",
    "Tap to allow Setcraft notifications": "Touchez pour autoriser les notifications Setcraft",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Les rappels ne sont pas disponibles dans cette version. Les alertes de fin de repos fonctionnent toujours.",
    "Couldn’t reach the notification service. Try again later.": "Impossible de joindre le service de notifications. Réessayez plus tard.",
    "Reminders": "Rappels",
    "Workout reminders": "Rappels d’entraînement",
    "Training days · {time}": "Jours d’entraînement · {time}",
    "Daily check-in": "Bilan quotidien",
    "How you slept and feel · {time}": "Sommeil et forme du jour · {time}",
    "Meal reminder": "Rappel de repas",
    "If breakfast isn’t logged · {time}": "Si le petit-déjeuner n’est pas noté · {time}",
    "If lunch isn’t logged · {time}": "Si le déjeuner n’est pas noté · {time}",
    "If dinner isn’t logged · {time}": "Si le dîner n’est pas noté · {time}",
    "If a snack isn’t logged · {time}": "Si aucun en-cas n’est noté · {time}",
    "Weekly summary": "Bilan hebdomadaire",
    "Sundays · {time}": "Le dimanche · {time}",
    "New weekly plan": "Nouveau programme de la semaine",
    "When next week’s plan is ready": "Quand le programme de la semaine prochaine est prêt",
    "Trial & billing": "Essai et facturation",
    "Before your trial ends or access changes": "Avant la fin de votre essai ou un changement d’accès",
    "Trial ending · No automatic charge": "Fin de l’essai · Aucun prélèvement automatique",
    "Trial ending · Renewal cancelled": "Fin de l’essai · Renouvellement annulé",
    "Trial ending · Manage renewal in your app store": "Fin de l’essai · Gérez le renouvellement dans votre boutique d’apps",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Touchez un rappel pour changer son heure. Vous en recevez 2 par jour au maximum, l’entraînement en priorité. Les alertes de programme et de facturation ne comptent pas.",
    "Quiet hours": "Heures calmes",
    "Quiet from": "Calme à partir de",
    "Quiet until": "Calme jusqu’à",
    "Quiet hours start": "Début des heures calmes",
    "Quiet hours end": "Fin des heures calmes",
    "Quiet hours are off. Set different times to turn them on.": "Les heures calmes sont désactivées. Choisissez deux heures différentes pour les activer.",
    "Reminders due during quiet hours arrive when they end.": "Les rappels prévus pendant les heures calmes arrivent à leur fin.",
    "Trial & billing alerts still arrive": "Les alertes d’essai et de facturation arrivent toujours",
    "Stop all reminders for 7 days": "Suspendre tous les rappels pendant 7 jours",
    "When a rest timer you start ends": "À la fin d’un minuteur de repos que vous lancez",
    "Allow alerts at the exact second": "Autoriser des alertes à la seconde près",
    "Send test notification": "Envoyer une notification test",
    "Please wait…": "Veuillez patienter…",
    "Test sent. It should arrive shortly.": "Test envoyé. Il devrait arriver sous peu.",
    "Snack": "En-cas",
    "Rest finished": "Repos terminé",
    "Your next set is ready.": "Votre prochaine série vous attend.",
    "Rest timer alerts": "Alertes de fin de repos",
    "Only for timers you start. Works while your phone is locked.":
        "Pour les minuteurs que vous lancez. Fonctionne aussi quand le téléphone est verrouillé.",
    "During workouts": "Pendant les séances",
    "Precise timer alerts": "Alertes précises du minuteur",
    "Allow alarms and reminders for on-time rest alerts.":
        "Autorisez les alarmes et rappels pour des alertes de repos ponctuelles.",
    "Pause reminders": "Suspendre les rappels",
    "Resume reminders": "Reprendre les rappels",
    "For 7 days": "Pendant 7 jours",
    "Account reminders stay on while training reminders are paused.":
        "Les rappels liés au compte restent actifs pendant la pause des rappels d’entraînement.",
    "Next workout reminder": "Prochain rappel d’entraînement",
    "No upcoming workout reminder.": "Aucun rappel d’entraînement à venir.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Les rappels prévus pendant les heures calmes arrivent à la fin de celles-ci.",
    "Quiet hours are off.": "Les heures calmes sont désactivées.",
    "Trial and renewal reminders": "Rappels d’essai et de renouvellement",
    "Get updates before your trial ends and when access changes.":
        "Recevez des rappels avant la fin de l’essai et lors de changements d’accès.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Votre essai se termine bientôt. Votre abonnement prendra fin sans renouvellement.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Votre essai se termine bientôt. Gérez ou annulez votre abonnement dans votre boutique d’applications avant le renouvellement.",
    "Choose a pause within the next 30 days.":
        "Choisissez une pause dans les 30 prochains jours.",
    "Remind me in 15 minutes": "Me rappeler dans 15 minutes",
    "Reminder snoozed.": "Rappel reporté.",
    "Open your scheduled workout when you’re ready.":
        "Ouvrez votre séance prévue quand vous le souhaitez.",
    "Your weekly recap is ready": "Votre bilan hebdomadaire est prêt",
    "Rest alerts are unavailable on this device.":
        "Les alertes de repos ne sont pas disponibles sur cet appareil.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Les rappels ne sont pas encore disponibles. Les alertes du minuteur fonctionnent sur ce téléphone.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Les rappels sont temporairement indisponibles. Réessayez plus tard."
  },
  "sv": {
    "Notifications are off.": "Aviseringar är avstängda.",
    "Notifications are on.": "Aviseringar är på.",
    "Paused until {date}, {time}.": "Pausat till {date}, {time}.",
    "Next: {date} · {time} workout": "Nästa pass: {date} · {time}",
    "Turned off in phone settings": "Avstängt i telefonens inställningar",
    "Tap to allow Setcraft notifications": "Tryck för att tillåta aviseringar från Setcraft",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Påminnelser är inte tillgängliga i den här versionen. Aviseringar för vilotimer fungerar fortfarande.",
    "Couldn’t reach the notification service. Try again later.": "Det gick inte att nå aviseringstjänsten. Försök igen senare.",
    "Reminders": "Påminnelser",
    "Workout reminders": "Träningspåminnelser",
    "Training days · {time}": "Träningsdagar · {time}",
    "Daily check-in": "Daglig incheckning",
    "How you slept and feel · {time}": "Sömn och dagsform · {time}",
    "Meal reminder": "Måltidspåminnelse",
    "If breakfast isn’t logged · {time}": "Om frukosten inte är loggad · {time}",
    "If lunch isn’t logged · {time}": "Om lunchen inte är loggad · {time}",
    "If dinner isn’t logged · {time}": "Om middagen inte är loggad · {time}",
    "If a snack isn’t logged · {time}": "Om inget mellanmål är loggat · {time}",
    "Weekly summary": "Veckosammanfattning",
    "Sundays · {time}": "Söndagar · {time}",
    "New weekly plan": "Ny veckoplan",
    "When next week’s plan is ready": "När nästa veckas plan är klar",
    "Trial & billing": "Provperiod och betalning",
    "Before your trial ends or access changes": "Innan provperioden slutar eller din åtkomst ändras",
    "Trial ending · No automatic charge": "Provperioden slutar · Ingen automatisk debitering",
    "Trial ending · Renewal cancelled": "Provperioden slutar · Förnyelse avbruten",
    "Trial ending · Manage renewal in your app store": "Provperioden slutar · Hantera förnyelse i din appbutik",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Tryck på en påminnelse för att ändra tiden. Du får högst 2 av dessa per dag och träning går först. Aviseringar om planer och betalning räknas inte.",
    "Quiet hours": "Tysta timmar",
    "Quiet from": "Tyst från",
    "Quiet until": "Tyst till",
    "Quiet hours start": "Tysta timmar börjar",
    "Quiet hours end": "Tysta timmar slutar",
    "Quiet hours are off. Set different times to turn them on.": "Tysta timmar är avstängda. Välj olika tider för att slå på dem.",
    "Reminders due during quiet hours arrive when they end.": "Påminnelser under tysta timmar kommer när de är slut.",
    "Trial & billing alerts still arrive": "Aviseringar om provperiod och betalning kommer fortfarande",
    "Stop all reminders for 7 days": "Stoppa alla påminnelser i 7 dagar",
    "When a rest timer you start ends": "När en vilotimer du startar är klar",
    "Allow alerts at the exact second": "Tillåt aviseringar på sekunden",
    "Send test notification": "Skicka testavisering",
    "Please wait…": "Vänta…",
    "Test sent. It should arrive shortly.": "Test skickat. Det bör komma snart.",
    "Snack": "Mellanmål",
    "Rest finished": "Vilan är slut",
    "Your next set is ready.": "Dags för nästa set.",
    "Rest timer alerts": "Aviseringar för vilotimer",
    "Only for timers you start. Works while your phone is locked.":
        "Bara för timers du startar. Fungerar när telefonen är låst.",
    "During workouts": "Under träningen",
    "Precise timer alerts": "Exakta timeraviseringar",
    "Allow alarms and reminders for on-time rest alerts.":
        "Tillåt alarm och påminnelser för viloaviseringar i tid.",
    "Pause reminders": "Pausa påminnelser",
    "Resume reminders": "Återuppta påminnelser",
    "For 7 days": "I 7 dagar",
    "Account reminders stay on while training reminders are paused.":
        "Kontopåminnelser är på medan träningspåminnelser pausas.",
    "Next workout reminder": "Nästa träningspåminnelse",
    "No upcoming workout reminder.": "Ingen kommande träningspåminnelse.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Påminnelser under tysta timmar kommer efteråt.",
    "Quiet hours are off.": "Tysta timmar är av.",
    "Trial and renewal reminders": "Provperiod och förnyelse",
    "Get updates before your trial ends and when access changes.":
        "Få besked innan provperioden slutar och när åtkomsten ändras.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Din provperiod slutar snart. Abonnemanget avslutas utan förnyelse.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Din provperiod slutar snart. Hantera eller avsluta abonnemanget i din appbutik före förnyelsen.",
    "Choose a pause within the next 30 days.":
        "Välj en paus inom de närmaste 30 dagarna.",
    "Remind me in 15 minutes": "Påminn mig om 15 minuter",
    "Reminder snoozed.": "Påminnelsen uppskjuten.",
    "Open your scheduled workout when you’re ready.":
        "Öppna ditt planerade pass när du är redo.",
    "Your weekly recap is ready": "Din veckosammanfattning är klar",
    "Rest alerts are unavailable on this device.":
        "Viloaviseringar är inte tillgängliga på den här enheten.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Påminnelser är inte tillgängliga än. Vilotimerns aviseringar fungerar ändå på den här telefonen.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Påminnelser är tillfälligt otillgängliga. Försök igen senare."
  },
  "no": {
    "Notifications are off.": "Varsler er slått av.",
    "Notifications are on.": "Varsler er slått på.",
    "Paused until {date}, {time}.": "Satt på pause til {date}, {time}.",
    "Next: {date} · {time} workout": "Neste økt: {date} · {time}",
    "Turned off in phone settings": "Slått av i telefoninnstillingene",
    "Tap to allow Setcraft notifications": "Trykk for å tillate varsler fra Setcraft",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Påminnelser er ikke tilgjengelige i denne versjonen. Varsler for pausetimer fungerer fortsatt.",
    "Couldn’t reach the notification service. Try again later.": "Fikk ikke kontakt med varslingstjenesten. Prøv igjen senere.",
    "Reminders": "Påminnelser",
    "Workout reminders": "Treningspåminnelser",
    "Training days · {time}": "Treningsdager · {time}",
    "Daily check-in": "Daglig innsjekk",
    "How you slept and feel · {time}": "Søvn og dagsform · {time}",
    "Meal reminder": "Måltidspåminnelse",
    "If breakfast isn’t logged · {time}": "Hvis frokosten ikke er logget · {time}",
    "If lunch isn’t logged · {time}": "Hvis lunsjen ikke er logget · {time}",
    "If dinner isn’t logged · {time}": "Hvis middagen ikke er logget · {time}",
    "If a snack isn’t logged · {time}": "Hvis ikke noe mellommåltid er logget · {time}",
    "Weekly summary": "Ukesoppsummering",
    "Sundays · {time}": "Søndager · {time}",
    "New weekly plan": "Ny ukeplan",
    "When next week’s plan is ready": "Når neste ukes plan er klar",
    "Trial & billing": "Prøveperiode og betaling",
    "Before your trial ends or access changes": "Før prøveperioden slutter eller tilgangen endres",
    "Trial ending · No automatic charge": "Prøveperioden slutter · Ingen automatisk belastning",
    "Trial ending · Renewal cancelled": "Prøveperioden slutter · Fornyelse avbrutt",
    "Trial ending · Manage renewal in your app store": "Prøveperioden slutter · Administrer fornyelse i appbutikken",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Trykk på en påminnelse for å endre tidspunktet. Du får maks 2 av disse om dagen, og trening kommer først. Varsler om plan og betaling teller ikke.",
    "Quiet hours": "Stille timer",
    "Quiet from": "Stille fra",
    "Quiet until": "Stille til",
    "Quiet hours start": "Stille timer starter",
    "Quiet hours end": "Stille timer slutter",
    "Quiet hours are off. Set different times to turn them on.": "Stille timer er av. Velg ulike tidspunkter for å slå dem på.",
    "Reminders due during quiet hours arrive when they end.": "Påminnelser i stille timer kommer når de er over.",
    "Trial & billing alerts still arrive": "Varsler om prøveperiode og betaling kommer fortsatt",
    "Stop all reminders for 7 days": "Stopp alle påminnelser i 7 dager",
    "When a rest timer you start ends": "Når en pausetimer du starter er ferdig",
    "Allow alerts at the exact second": "Tillat varsler på sekundet",
    "Send test notification": "Send testvarsel",
    "Please wait…": "Vent litt…",
    "Test sent. It should arrive shortly.": "Test sendt. Det bør komme snart.",
    "Snack": "Mellommåltid",
    "Rest finished": "Pausen er over",
    "Your next set is ready.": "Klar for neste sett.",
    "Rest timer alerts": "Varsler for pausetimer",
    "Only for timers you start. Works while your phone is locked.":
        "Bare for tidtakere du starter. Fungerer når telefonen er låst.",
    "During workouts": "Under trening",
    "Precise timer alerts": "Nøyaktige tidtakervarsler",
    "Allow alarms and reminders for on-time rest alerts.":
        "Tillat alarmer og påminnelser for pausevarsler til rett tid.",
    "Pause reminders": "Sett påminnelser på pause",
    "Resume reminders": "Gjenoppta påminnelser",
    "For 7 days": "I 7 dager",
    "Account reminders stay on while training reminders are paused.":
        "Kontopåminnelser er på mens treningspåminnelser er satt på pause.",
    "Next workout reminder": "Neste treningspåminnelse",
    "No upcoming workout reminder.": "Ingen kommende treningspåminnelse.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Påminnelser i stilletiden kommer når den er over.",
    "Quiet hours are off.": "Stilletid er av.",
    "Trial and renewal reminders": "Prøveperiode og fornyelse",
    "Get updates before your trial ends and when access changes.":
        "Få beskjed før prøveperioden slutter og når tilgangen endres.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Prøveperioden slutter snart. Abonnementet avsluttes uten fornyelse.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Prøveperioden slutter snart. Administrer eller si opp abonnementet i appbutikken før fornyelse.",
    "Choose a pause within the next 30 days.":
        "Velg en pause innen de neste 30 dagene.",
    "Remind me in 15 minutes": "Minn meg på om 15 minutter",
    "Reminder snoozed.": "Påminnelsen er utsatt.",
    "Open your scheduled workout when you’re ready.":
        "Åpne den planlagte økten når du er klar.",
    "Your weekly recap is ready": "Ukesammendraget er klart",
    "Rest alerts are unavailable on this device.":
        "Pausevarsler er ikke tilgjengelige på denne enheten.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Påminnelser er ikke tilgjengelige ennå. Pausetimervarsler fungerer fortsatt på denne telefonen.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Påminnelser er midlertidig utilgjengelige. Prøv igjen senere."
  },
  "da": {
    "Notifications are off.": "Notifikationer er slået fra.",
    "Notifications are on.": "Notifikationer er slået til.",
    "Paused until {date}, {time}.": "Sat på pause til {date}, {time}.",
    "Next: {date} · {time} workout": "Næste træning: {date} · {time}",
    "Turned off in phone settings": "Slået fra i telefonens indstillinger",
    "Tap to allow Setcraft notifications": "Tryk for at tillade notifikationer fra Setcraft",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Påmindelser er ikke tilgængelige i denne version. Beskeder fra pausetimer virker stadig.",
    "Couldn’t reach the notification service. Try again later.": "Kunne ikke få forbindelse til notifikationstjenesten. Prøv igen senere.",
    "Reminders": "Påmindelser",
    "Workout reminders": "Træningspåmindelser",
    "Training days · {time}": "Træningsdage · {time}",
    "Daily check-in": "Daglig check-in",
    "How you slept and feel · {time}": "Søvn og dagsform · {time}",
    "Meal reminder": "Måltidspåmindelse",
    "If breakfast isn’t logged · {time}": "Hvis morgenmaden ikke er logget · {time}",
    "If lunch isn’t logged · {time}": "Hvis frokosten ikke er logget · {time}",
    "If dinner isn’t logged · {time}": "Hvis aftensmaden ikke er logget · {time}",
    "If a snack isn’t logged · {time}": "Hvis der ikke er logget et mellemmåltid · {time}",
    "Weekly summary": "Ugeoversigt",
    "Sundays · {time}": "Søndage · {time}",
    "New weekly plan": "Ny ugeplan",
    "When next week’s plan is ready": "Når næste uges plan er klar",
    "Trial & billing": "Prøveperiode og betaling",
    "Before your trial ends or access changes": "Før prøveperioden slutter, eller din adgang ændres",
    "Trial ending · No automatic charge": "Prøveperioden slutter · Ingen automatisk opkrævning",
    "Trial ending · Renewal cancelled": "Prøveperioden slutter · Fornyelse annulleret",
    "Trial ending · Manage renewal in your app store": "Prøveperioden slutter · Administrer fornyelse i din appbutik",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Tryk på en påmindelse for at ændre tidspunktet. Du får højst 2 af dem om dagen, og træning kommer først. Beskeder om plan og betaling tæller ikke med.",
    "Quiet hours": "Stille timer",
    "Quiet from": "Stille fra",
    "Quiet until": "Stille til",
    "Quiet hours start": "Stille timer starter",
    "Quiet hours end": "Stille timer slutter",
    "Quiet hours are off. Set different times to turn them on.": "Stille timer er slået fra. Vælg forskellige tidspunkter for at slå dem til.",
    "Reminders due during quiet hours arrive when they end.": "Påmindelser i stille timer kommer, når de er slut.",
    "Trial & billing alerts still arrive": "Beskeder om prøveperiode og betaling kommer stadig",
    "Stop all reminders for 7 days": "Stop alle påmindelser i 7 dage",
    "When a rest timer you start ends": "Når en pausetimer, du starter, er færdig",
    "Allow alerts at the exact second": "Tillad beskeder på sekundet",
    "Send test notification": "Send testnotifikation",
    "Please wait…": "Vent venligst…",
    "Test sent. It should arrive shortly.": "Test sendt. Den burde komme snart.",
    "Snack": "Mellemmåltid",
    "Rest finished": "Pausen er slut",
    "Your next set is ready.": "Klar til næste sæt.",
    "Rest timer alerts": "Beskeder fra pausetimer",
    "Only for timers you start. Works while your phone is locked.":
        "Kun for timere, du starter. Virker, når telefonen er låst.",
    "During workouts": "Under træning",
    "Precise timer alerts": "Præcise timerbeskeder",
    "Allow alarms and reminders for on-time rest alerts.":
        "Tillad alarmer og påmindelser for hvilebeskeder til tiden.",
    "Pause reminders": "Sæt påmindelser på pause",
    "Resume reminders": "Genoptag påmindelser",
    "For 7 days": "I 7 dage",
    "Account reminders stay on while training reminders are paused.":
        "Kontopåmindelser er aktive, mens træningspåmindelser er sat på pause.",
    "Next workout reminder": "Næste træningspåmindelse",
    "No upcoming workout reminder.": "Ingen kommende træningspåmindelse.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Påmindelser i stilletiden kommer, når den er slut.",
    "Quiet hours are off.": "Stilletid er slået fra.",
    "Trial and renewal reminders": "Prøveperiode og fornyelse",
    "Get updates before your trial ends and when access changes.":
        "Få besked, før prøveperioden slutter, og når din adgang ændres.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Din prøveperiode slutter snart. Abonnementet afsluttes uden fornyelse.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Din prøveperiode slutter snart. Administrer eller opsig dit abonnement i appbutikken før fornyelsen.",
    "Choose a pause within the next 30 days.":
        "Vælg en pause inden for de næste 30 dage.",
    "Remind me in 15 minutes": "Mind mig om 15 minutter",
    "Reminder snoozed.": "Påmindelsen er udsat.",
    "Open your scheduled workout when you’re ready.":
        "Åbn din planlagte træning, når du er klar.",
    "Your weekly recap is ready": "Dit ugeoverblik er klar",
    "Rest alerts are unavailable on this device.":
        "Hvilebeskeder er ikke tilgængelige på denne enhed.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Påmindelser er ikke tilgængelige endnu. Pausetimerens beskeder virker stadig på denne telefon.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Påmindelser er midlertidigt utilgængelige. Prøv igen senere."
  },
  "nl": {
    "Notifications are off.": "Meldingen staan uit.",
    "Notifications are on.": "Meldingen staan aan.",
    "Paused until {date}, {time}.": "Gepauzeerd tot {date}, {time}.",
    "Next: {date} · {time} workout": "Volgende training: {date} · {time}",
    "Turned off in phone settings": "Uitgeschakeld in de telefooninstellingen",
    "Tap to allow Setcraft notifications": "Tik om meldingen van Setcraft toe te staan",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Herinneringen zijn niet beschikbaar in deze versie. Meldingen voor rusttimer werken nog steeds.",
    "Couldn’t reach the notification service. Try again later.": "De meldingsdienst is niet bereikbaar. Probeer het later opnieuw.",
    "Reminders": "Herinneringen",
    "Workout reminders": "Trainingsherinneringen",
    "Training days · {time}": "Trainingsdagen · {time}",
    "Daily check-in": "Dagelijkse check-in",
    "How you slept and feel · {time}": "Slaap en hoe je je voelt · {time}",
    "Meal reminder": "Maaltijdherinnering",
    "If breakfast isn’t logged · {time}": "Als je ontbijt niet is gelogd · {time}",
    "If lunch isn’t logged · {time}": "Als je lunch niet is gelogd · {time}",
    "If dinner isn’t logged · {time}": "Als je avondeten niet is gelogd · {time}",
    "If a snack isn’t logged · {time}": "Als er geen snack is gelogd · {time}",
    "Weekly summary": "Weekoverzicht",
    "Sundays · {time}": "Zondags · {time}",
    "New weekly plan": "Nieuw weekschema",
    "When next week’s plan is ready": "Als het schema voor volgende week klaar is",
    "Trial & billing": "Proefperiode en betaling",
    "Before your trial ends or access changes": "Voordat je proefperiode eindigt of je toegang verandert",
    "Trial ending · No automatic charge": "Proefperiode eindigt · Geen automatische afschrijving",
    "Trial ending · Renewal cancelled": "Proefperiode eindigt · Verlenging opgezegd",
    "Trial ending · Manage renewal in your app store": "Proefperiode eindigt · Beheer verlenging in je appstore",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Tik op een herinnering om de tijd te wijzigen. Je krijgt er maximaal 2 per dag en trainingen gaan voor. Meldingen over schema’s en betalingen tellen niet mee.",
    "Quiet hours": "Stille uren",
    "Quiet from": "Stil vanaf",
    "Quiet until": "Stil tot",
    "Quiet hours start": "Begin stille uren",
    "Quiet hours end": "Einde stille uren",
    "Quiet hours are off. Set different times to turn them on.": "Stille uren staan uit. Kies twee verschillende tijden om ze aan te zetten.",
    "Reminders due during quiet hours arrive when they end.": "Herinneringen tijdens stille uren komen zodra die voorbij zijn.",
    "Trial & billing alerts still arrive": "Meldingen over proefperiode en betaling komen nog steeds",
    "Stop all reminders for 7 days": "Alle herinneringen 7 dagen stoppen",
    "When a rest timer you start ends": "Als een rusttimer die je start afloopt",
    "Allow alerts at the exact second": "Meldingen op de seconde toestaan",
    "Send test notification": "Testmelding versturen",
    "Please wait…": "Even geduld…",
    "Test sent. It should arrive shortly.": "Test verstuurd. Hij komt zo binnen.",
    "Snack": "Snack",
    "Rest finished": "Rust voorbij",
    "Your next set is ready.": "Je volgende set staat klaar.",
    "Rest timer alerts": "Meldingen voor rusttimer",
    "Only for timers you start. Works while your phone is locked.":
        "Alleen voor timers die je start. Werkt ook met een vergrendelde telefoon.",
    "During workouts": "Tijdens trainingen",
    "Precise timer alerts": "Nauwkeurige timermeldingen",
    "Allow alarms and reminders for on-time rest alerts.":
        "Sta alarmen en herinneringen toe voor tijdige rustmeldingen.",
    "Pause reminders": "Herinneringen pauzeren",
    "Resume reminders": "Herinneringen hervatten",
    "For 7 days": "Voor 7 dagen",
    "Account reminders stay on while training reminders are paused.":
        "Accountmeldingen blijven aan terwijl trainingsherinneringen zijn gepauzeerd.",
    "Next workout reminder": "Volgende trainingsherinnering",
    "No upcoming workout reminder.": "Geen geplande trainingsherinnering.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Herinneringen tijdens stille uren komen na afloop.",
    "Quiet hours are off.": "Stille uren staan uit.",
    "Trial and renewal reminders": "Proefperiode en verlenging",
    "Get updates before your trial ends and when access changes.":
        "Ontvang een melding voor je proefperiode afloopt en bij wijzigingen in je toegang.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Je proefperiode loopt binnenkort af. Je abonnement wordt niet verlengd.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Je proefperiode loopt binnenkort af. Beheer of annuleer je abonnement in je appwinkel vóór de verlenging.",
    "Choose a pause within the next 30 days.":
        "Kies een pauze binnen de komende 30 dagen.",
    "Remind me in 15 minutes": "Herinner me over 15 minuten",
    "Reminder snoozed.": "Herinnering uitgesteld.",
    "Open your scheduled workout when you’re ready.":
        "Open je geplande training wanneer je klaar bent.",
    "Your weekly recap is ready": "Je weekoverzicht staat klaar",
    "Rest alerts are unavailable on this device.":
        "Rustmeldingen zijn niet beschikbaar op dit apparaat.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Herinneringen zijn nog niet beschikbaar. Rusttimermeldingen werken wel op deze telefoon.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Herinneringen zijn tijdelijk niet beschikbaar. Probeer het later opnieuw."
  },
  "es": {
    "Notifications are off.": "Las notificaciones están desactivadas.",
    "Notifications are on.": "Las notificaciones están activadas.",
    "Paused until {date}, {time}.": "En pausa hasta el {date}, {time}.",
    "Next: {date} · {time} workout": "Próximo entrenamiento: {date} · {time}",
    "Turned off in phone settings": "Desactivadas en los ajustes del teléfono",
    "Tap to allow Setcraft notifications": "Toca para permitir las notificaciones de Setcraft",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "Los recordatorios no están disponibles en esta versión. Los avisos del temporizador de descanso siguen funcionando.",
    "Couldn’t reach the notification service. Try again later.": "No se pudo conectar con el servicio de notificaciones. Inténtalo más tarde.",
    "Reminders": "Recordatorios",
    "Workout reminders": "Recordatorios de entrenamiento",
    "Training days · {time}": "Días de entrenamiento · {time}",
    "Daily check-in": "Registro diario",
    "How you slept and feel · {time}": "Cómo dormiste y cómo te sientes · {time}",
    "Meal reminder": "Recordatorio de comida",
    "If breakfast isn’t logged · {time}": "Si no has registrado el desayuno · {time}",
    "If lunch isn’t logged · {time}": "Si no has registrado el almuerzo · {time}",
    "If dinner isn’t logged · {time}": "Si no has registrado la cena · {time}",
    "If a snack isn’t logged · {time}": "Si no has registrado un tentempié · {time}",
    "Weekly summary": "Resumen semanal",
    "Sundays · {time}": "Los domingos · {time}",
    "New weekly plan": "Nuevo plan semanal",
    "When next week’s plan is ready": "Cuando el plan de la próxima semana esté listo",
    "Trial & billing": "Prueba y facturación",
    "Before your trial ends or access changes": "Antes de que termine tu prueba o cambie tu acceso",
    "Trial ending · No automatic charge": "La prueba termina · Sin cobro automático",
    "Trial ending · Renewal cancelled": "La prueba termina · Renovación cancelada",
    "Trial ending · Manage renewal in your app store": "La prueba termina · Gestiona la renovación en tu tienda de apps",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Toca un recordatorio para cambiar su hora. Recibes como máximo 2 al día y los entrenamientos van primero. Los avisos de planes y facturación no cuentan.",
    "Quiet hours": "Horas de silencio",
    "Quiet from": "Silencio desde",
    "Quiet until": "Silencio hasta",
    "Quiet hours start": "Inicio de las horas de silencio",
    "Quiet hours end": "Fin de las horas de silencio",
    "Quiet hours are off. Set different times to turn them on.": "Las horas de silencio están desactivadas. Elige horas distintas para activarlas.",
    "Reminders due during quiet hours arrive when they end.": "Los recordatorios previstos en horas de silencio llegan cuando terminan.",
    "Trial & billing alerts still arrive": "Los avisos de prueba y facturación siguen llegando",
    "Stop all reminders for 7 days": "Detener todos los recordatorios durante 7 días",
    "When a rest timer you start ends": "Cuando termina un temporizador de descanso que inicias",
    "Allow alerts at the exact second": "Permitir avisos al segundo exacto",
    "Send test notification": "Enviar notificación de prueba",
    "Please wait…": "Espera…",
    "Test sent. It should arrive shortly.": "Prueba enviada. Debería llegar en breve.",
    "Snack": "Tentempié",
    "Rest finished": "Descanso terminado",
    "Your next set is ready.": "Tu siguiente serie te espera.",
    "Rest timer alerts": "Avisos del temporizador de descanso",
    "Only for timers you start. Works while your phone is locked.":
        "Solo para temporizadores que inicies. Funciona con el teléfono bloqueado.",
    "During workouts": "Durante el entrenamiento",
    "Precise timer alerts": "Avisos precisos del temporizador",
    "Allow alarms and reminders for on-time rest alerts.":
        "Permite alarmas y recordatorios para recibir los avisos de descanso a tiempo.",
    "Pause reminders": "Pausar recordatorios",
    "Resume reminders": "Reanudar recordatorios",
    "For 7 days": "Durante 7 días",
    "Account reminders stay on while training reminders are paused.":
        "Los avisos de la cuenta siguen activos mientras pausas los de entrenamiento.",
    "Next workout reminder": "Próximo recordatorio de entrenamiento",
    "No upcoming workout reminder.":
        "No hay recordatorios de entrenamiento próximos.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "Los recordatorios durante el horario de silencio llegan al terminar.",
    "Quiet hours are off.": "El horario de silencio está desactivado.",
    "Trial and renewal reminders": "Avisos de prueba y renovación",
    "Get updates before your trial ends and when access changes.":
        "Recibe avisos antes de que termine tu prueba y cuando cambie tu acceso.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "Tu prueba termina pronto. Tu suscripción finalizará sin renovarse.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "Tu prueba termina pronto. Gestiona o cancela tu suscripción en la tienda de aplicaciones antes de la renovación.",
    "Choose a pause within the next 30 days.":
        "Elige una pausa dentro de los próximos 30 días.",
    "Remind me in 15 minutes": "Recordarme en 15 minutos",
    "Reminder snoozed.": "Recordatorio pospuesto.",
    "Open your scheduled workout when you’re ready.":
        "Abre tu entrenamiento programado cuando estés listo.",
    "Your weekly recap is ready": "Tu resumen semanal está listo",
    "Rest alerts are unavailable on this device.":
        "Los avisos de descanso no están disponibles en este dispositivo.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "Los recordatorios aún no están disponibles. Los avisos del temporizador de descanso siguen funcionando en este teléfono.",
    "Reminders are temporarily unavailable. Please try again later.":
        "Los recordatorios no están disponibles temporalmente. Inténtalo más tarde."
  },
  "it": {
    "Notifications are off.": "Le notifiche sono disattivate.",
    "Notifications are on.": "Le notifiche sono attive.",
    "Paused until {date}, {time}.": "In pausa fino al {date}, {time}.",
    "Next: {date} · {time} workout": "Prossimo allenamento: {date} · {time}",
    "Turned off in phone settings": "Disattivate nelle impostazioni del telefono",
    "Tap to allow Setcraft notifications": "Tocca per consentire le notifiche di Setcraft",
    "Reminders aren’t available in this version. Rest timer alerts still work.": "I promemoria non sono disponibili in questa versione. Gli avvisi del timer di recupero funzionano comunque.",
    "Couldn’t reach the notification service. Try again later.": "Impossibile raggiungere il servizio di notifiche. Riprova più tardi.",
    "Reminders": "Promemoria",
    "Workout reminders": "Promemoria di allenamento",
    "Training days · {time}": "Giorni di allenamento · {time}",
    "Daily check-in": "Check-in quotidiano",
    "How you slept and feel · {time}": "Sonno e come ti senti · {time}",
    "Meal reminder": "Promemoria pasto",
    "If breakfast isn’t logged · {time}": "Se la colazione non è registrata · {time}",
    "If lunch isn’t logged · {time}": "Se il pranzo non è registrato · {time}",
    "If dinner isn’t logged · {time}": "Se la cena non è registrata · {time}",
    "If a snack isn’t logged · {time}": "Se non hai registrato uno spuntino · {time}",
    "Weekly summary": "Riepilogo settimanale",
    "Sundays · {time}": "La domenica · {time}",
    "New weekly plan": "Nuovo piano settimanale",
    "When next week’s plan is ready": "Quando il piano della prossima settimana è pronto",
    "Trial & billing": "Prova e fatturazione",
    "Before your trial ends or access changes": "Prima della fine della prova o quando cambia l’accesso",
    "Trial ending · No automatic charge": "La prova sta per finire · Nessun addebito automatico",
    "Trial ending · Renewal cancelled": "La prova sta per finire · Rinnovo annullato",
    "Trial ending · Manage renewal in your app store": "La prova sta per finire · Gestisci il rinnovo nel tuo store",
    "Tap a reminder to change its time. You get at most 2 of these a day, and workouts come first. Plan and billing alerts don’t count.": "Tocca un promemoria per cambiarne l’orario. Ne ricevi al massimo 2 al giorno e gli allenamenti hanno la precedenza. Gli avvisi su piani e fatturazione non contano.",
    "Quiet hours": "Ore silenziose",
    "Quiet from": "Silenzio dalle",
    "Quiet until": "Silenzio fino alle",
    "Quiet hours start": "Inizio ore silenziose",
    "Quiet hours end": "Fine ore silenziose",
    "Quiet hours are off. Set different times to turn them on.": "Le ore silenziose sono disattivate. Imposta orari diversi per attivarle.",
    "Reminders due during quiet hours arrive when they end.": "I promemoria previsti nelle ore silenziose arrivano al loro termine.",
    "Trial & billing alerts still arrive": "Gli avvisi su prova e fatturazione arrivano comunque",
    "Stop all reminders for 7 days": "Sospendi tutti i promemoria per 7 giorni",
    "When a rest timer you start ends": "Quando finisce un timer di recupero che avvii",
    "Allow alerts at the exact second": "Consenti avvisi al secondo esatto",
    "Send test notification": "Invia notifica di prova",
    "Please wait…": "Attendi…",
    "Test sent. It should arrive shortly.": "Prova inviata. Dovrebbe arrivare a breve.",
    "Snack": "Spuntino",
    "Rest finished": "Recupero terminato",
    "Your next set is ready.": "È il momento della prossima serie.",
    "Rest timer alerts": "Avvisi del timer di recupero",
    "Only for timers you start. Works while your phone is locked.":
        "Solo per i timer che avvii. Funziona anche con il telefono bloccato.",
    "During workouts": "Durante gli allenamenti",
    "Precise timer alerts": "Avvisi precisi del timer",
    "Allow alarms and reminders for on-time rest alerts.":
        "Consenti sveglie e promemoria per ricevere puntualmente gli avvisi di recupero.",
    "Pause reminders": "Metti in pausa i promemoria",
    "Resume reminders": "Riprendi i promemoria",
    "For 7 days": "Per 7 giorni",
    "Account reminders stay on while training reminders are paused.":
        "Gli avvisi dell’account restano attivi mentre i promemoria di allenamento sono in pausa.",
    "Next workout reminder": "Prossimo promemoria di allenamento",
    "No upcoming workout reminder.":
        "Nessun promemoria di allenamento in programma.",
    "Reminders during quiet hours arrive after quiet time ends.":
        "I promemoria durante le ore silenziose arrivano al termine.",
    "Quiet hours are off.": "Le ore silenziose sono disattivate.",
    "Trial and renewal reminders": "Promemoria di prova e rinnovo",
    "Get updates before your trial ends and when access changes.":
        "Ricevi avvisi prima della fine della prova e quando cambia il tuo accesso.",
    "Your trial ends soon. Your subscription is set to end without renewal.":
        "La prova termina presto. Il tuo abbonamento terminerà senza rinnovo.",
    "Your trial ends soon. Manage or cancel your subscription in your app store before renewal.":
        "La prova termina presto. Gestisci o annulla l’abbonamento nel tuo store prima del rinnovo.",
    "Choose a pause within the next 30 days.":
        "Scegli una pausa entro i prossimi 30 giorni.",
    "Remind me in 15 minutes": "Ricordamelo tra 15 minuti",
    "Reminder snoozed.": "Promemoria posticipato.",
    "Open your scheduled workout when you’re ready.":
        "Apri l’allenamento programmato quando vuoi.",
    "Your weekly recap is ready": "Il riepilogo settimanale è pronto",
    "Rest alerts are unavailable on this device.":
        "Gli avvisi di recupero non sono disponibili su questo dispositivo.",
    "Remote reminders are not available yet. Rest timer alerts still work on this phone.":
        "I promemoria non sono ancora disponibili. Gli avvisi del timer di recupero funzionano comunque su questo telefono.",
    "Reminders are temporarily unavailable. Please try again later.":
        "I promemoria non sono temporaneamente disponibili. Riprova più tardi."
  }
};

// Section headers are shown upper-case ("QUIET HOURS"), so also match
// by lower-case key.
final _notificationCopyLower = {
  for (final locale in notificationCopyData.entries)
    locale.key: {
      for (final term in locale.value.entries)
        term.key.toLowerCase(): term.value
    }
};

String? notificationTranslation(String locale, String text) {
  final exact = notificationCopyData[locale]?[text];
  if (exact != null) return exact;
  final upperCase = text == text.toUpperCase() && text != text.toLowerCase();
  if (!upperCase) return null;
  final lower = _notificationCopyLower[locale];
  return lower == null ? null : lower[text.toLowerCase()];
}
String notificationCopy(String text) =>
    notificationTranslation(
        LanguageManager.shared.currentLanguage.code.split('-').first, text) ??
    text;
