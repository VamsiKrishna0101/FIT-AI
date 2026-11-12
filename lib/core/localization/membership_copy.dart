// Display copy only. Store prices, dates and account data stay untouched.
const membershipCopyLocales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const membershipCopy = <String, List<String>>{
  "Your first 14 days are free": [
    "Deine ersten 14 Tage sind kostenlos",
    "Vos 14 premiers jours sont gratuits",
    "Dina första 14 dagar är gratis",
    "De første 14 dagene er gratis",
    "Dine første 14 dage er gratis",
    "Je eerste 14 dagen zijn gratis",
    "Tus primeros 14 días son gratis",
    "I tuoi primi 14 giorni sono gratis"
  ],
  "Unlock your full plan": [
    "Schalte deinen vollständigen Plan frei",
    "Débloquez votre programme complet",
    "Lås upp hela din plan",
    "Lås opp hele planen din",
    "Lås op for hele din plan",
    "Ontgrendel je volledige plan",
    "Desbloquea tu plan completo",
    "Sblocca il tuo piano completo"
  ],
  "Try for {price}": [
    "Für {price} testen",
    "Essayer pour {price}",
    "Prova för {price}",
    "Prøv for {price}",
    "Prøv for {price}",
    "Probeer voor {price}",
    "Prueba por {price}",
    "Prova a {price}"
  ],
  "We'll email you a reminder": [
    "Wir erinnern dich per E-Mail",
    "Nous vous enverrons un rappel par e-mail",
    "Vi påminner dig via e-post",
    "Vi minner deg på det via e-post",
    "Vi minder dig om det via e-mail",
    "We sturen je een herinnering per e-mail",
    "Te enviaremos un recordatorio por correo",
    "Ti invieremo un promemoria via email"
  ],
  "14 days free, then {price}. Auto-renews.": [
    "14 Tage kostenlos, danach {price}. Automatische Verlängerung.",
    "14 jours gratuits, puis {price}. Renouvellement automatique.",
    "14 dagar gratis, sedan {price}. Förnyas automatiskt.",
    "14 dager gratis, deretter {price}. Fornyes automatisk.",
    "14 dage gratis, derefter {price}. Fornyes automatisk.",
    "14 dagen gratis, daarna {price}. Wordt automatisch verlengd.",
    "14 días gratis, después {price}. Renovación automática.",
    "14 giorni gratis, poi {price}. Rinnovo automatico."
  ],
  "Cancel anytime in {store}.": [
    "Jederzeit im {store} kündbar.",
    "Annulez à tout moment dans {store}.",
    "Avsluta när som helst i {store}.",
    "Avslutt når som helst i {store}.",
    "Opsig når som helst i {store}.",
    "Annuleer op elk moment in {store}.",
    "Cancela cuando quieras en {store}.",
    "Annulla quando vuoi su {store}."
  ],
  "Cancel in {store}.": [
    "Im {store} kündigen.",
    "Annulez dans {store}.",
    "Avsluta i {store}.",
    "Avslutt i {store}.",
    "Opsig i {store}.",
    "Annuleer in {store}.",
    "Cancela en {store}.",
    "Annulla su {store}."
  ],
  "Start your free trial": [
    "Starte deine kostenlose Testphase",
    "Commencez votre essai gratuit",
    "Starta din gratis provperiod",
    "Start gratis prøveperiode",
    "Start din gratis prøveperiode",
    "Start je gratis proefperiode",
    "Empieza tu prueba gratis",
    "Inizia la prova gratuita"
  ],
  "Anytime": [
    "Jederzeit",
    "À tout moment",
    "När som helst",
    "Når som helst",
    "Når som helst",
    "Altijd",
    "Cuando quieras",
    "Quando vuoi"
  ],
  "Day 14": [
    "Tag 14",
    "Jour 14",
    "Dag 14",
    "Dag 14",
    "Dag 14",
    "Dag 14",
    "Día 14",
    "Giorno 14"
  ],
  "This is included": [
    "Das ist enthalten",
    "Ce qui est inclus",
    "Det här ingår",
    "Dette er inkludert",
    "Dette er inkluderet",
    "Dit is inbegrepen",
    "Esto está incluido",
    "Ecco cosa è incluso"
  ],
  "Preview": [
    "Vorschau",
    "Aperçu",
    "Förhandsvisning",
    "Forhåndsvisning",
    "Forhåndsvisning",
    "Voorbeeld",
    "Vista previa",
    "Anteprima"
  ],
  "Premium": [
    "Premium",
    "Premium",
    "Premium",
    "Premium",
    "Premium",
    "Premium",
    "Premium",
    "Premium"
  ],
  "More options": [
    "Weitere Optionen",
    "Plus d’options",
    "Fler alternativ",
    "Flere alternativer",
    "Flere muligheder",
    "Meer opties",
    "Más opciones",
    "Altre opzioni"
  ],
  "Opening checkout…": [
    "Kasse wird geöffnet…",
    "Ouverture du paiement…",
    "Öppnar betalning…",
    "Åpner betaling…",
    "Åbner betaling…",
    "Betaling openen…",
    "Abriendo pago…",
    "Apertura del pagamento…"
  ],
  "Trial active until {date}": [
    "Testphase aktiv bis {date}",
    "Essai actif jusqu’au {date}",
    "Provperiod aktiv till {date}",
    "Prøveperiode aktiv til {date}",
    "Prøveperiode aktiv til {date}",
    "Proefperiode actief tot {date}",
    "Prueba activa hasta {date}",
    "Prova attiva fino al {date}"
  ],
  "Membership active until {date}": [
    "Mitgliedschaft aktiv bis {date}",
    "Abonnement actif jusqu’au {date}",
    "Medlemskap aktivt till {date}",
    "Medlemskap aktivt til {date}",
    "Medlemskab aktivt til {date}",
    "Lidmaatschap actief tot {date}",
    "Membresía activa hasta {date}",
    "Abbonamento attivo fino al {date}"
  ],
  "Continue on your phone": [
    "Auf deinem Handy fortfahren",
    "Continuez sur votre téléphone",
    "Fortsätt på din telefon",
    "Fortsett på telefonen",
    "Fortsæt på din telefon",
    "Ga verder op je telefoon",
    "Continúa en tu teléfono",
    "Continua sul telefono"
  ],
  "Membership opens soon": [
    "Die Mitgliedschaft ist bald verfügbar",
    "L’abonnement sera bientôt disponible",
    "Medlemskap öppnar snart",
    "Medlemskap åpner snart",
    "Medlemskab åbner snart",
    "Lidmaatschap is binnenkort beschikbaar",
    "La membresía estará disponible pronto",
    "L’abbonamento sarà disponibile a breve"
  ],
  "Connect to {store}": [
    "Mit {store} verbinden",
    "Connectez-vous à {store}",
    "Anslut till {store}",
    "Koble til {store}",
    "Opret forbindelse til {store}",
    "Verbind met {store}",
    "Conéctate a {store}",
    "Collegati a {store}"
  ],
  "Membership is unavailable right now": [
    "Die Mitgliedschaft ist gerade nicht verfügbar",
    "L’abonnement est indisponible pour le moment",
    "Medlemskap är inte tillgängligt just nu",
    "Medlemskap er ikke tilgjengelig nå",
    "Medlemskab er ikke tilgængeligt lige nu",
    "Lidmaatschap is nu niet beschikbaar",
    "La membresía no está disponible ahora",
    "L’abbonamento non è disponibile al momento"
  ],
  "Check your connection": [
    "Prüfe deine Verbindung",
    "Vérifiez votre connexion",
    "Kontrollera din anslutning",
    "Sjekk tilkoblingen",
    "Tjek din forbindelse",
    "Controleer je verbinding",
    "Comprueba tu conexión",
    "Controlla la connessione"
  ],
  "Membership is available in the iOS and Android app.": [
    "Die Mitgliedschaft ist in der iOS- und Android-App verfügbar.",
    "L’abonnement est disponible dans l’application iOS et Android.",
    "Medlemskap finns i iOS- och Android-appen.",
    "Medlemskap er tilgjengelig i iOS- og Android-appen.",
    "Medlemskab er tilgængeligt i iOS- og Android-appen.",
    "Lidmaatschap is beschikbaar in de iOS- en Android-app.",
    "La membresía está disponible en la app de iOS y Android.",
    "L’abbonamento è disponibile nell’app iOS e Android."
  ],
  "Your plan is saved. Check back shortly.": [
    "Dein Plan ist gespeichert. Schau bald wieder vorbei.",
    "Votre programme est enregistré. Revenez bientôt.",
    "Din plan är sparad. Kom tillbaka snart.",
    "Planen din er lagret. Kom tilbake snart.",
    "Din plan er gemt. Kom tilbage snart.",
    "Je plan is opgeslagen. Kom binnenkort terug.",
    "Tu plan está guardado. Vuelve pronto.",
    "Il tuo piano è salvato. Torna a breve."
  ],
  "Open {store} and try again.": [
    "Öffne {store} und versuche es erneut.",
    "Ouvrez {store} et réessayez.",
    "Öppna {store} och försök igen.",
    "Åpne {store} og prøv igjen.",
    "Åbn {store} og prøv igen.",
    "Open {store} en probeer opnieuw.",
    "Abre {store} e inténtalo de nuevo.",
    "Apri {store} e riprova."
  ],
  "Please try again shortly.": [
    "Bitte versuche es in Kürze erneut.",
    "Veuillez réessayer dans un instant.",
    "Försök igen om en stund.",
    "Prøv igjen om litt.",
    "Prøv igen om lidt.",
    "Probeer het zo opnieuw.",
    "Inténtalo de nuevo en breve.",
    "Riprova tra poco."
  ],
  "Available in the mobile app": [
    "In der mobilen App verfügbar",
    "Disponible dans l’application mobile",
    "Tillgängligt i mobilappen",
    "Tilgjengelig i mobilappen",
    "Tilgængeligt i mobilappen",
    "Beschikbaar in de mobiele app",
    "Disponible en la app móvil",
    "Disponibile nell’app mobile"
  ],
  "Check availability": [
    "Verfügbarkeit prüfen",
    "Vérifier la disponibilité",
    "Kontrollera tillgänglighet",
    "Sjekk tilgjengelighet",
    "Tjek tilgængelighed",
    "Controleer beschikbaarheid",
    "Comprobar disponibilidad",
    "Verifica disponibilità"
  ],
  'Your first 14 days\nare on us.': [
    'Deine ersten 14 Tage\nsind kostenlos.',
    'Vos 14 premiers jours\nsont offerts.',
    'Dina första 14 dagar\när gratis.',
    'De første 14 dagene\ner gratis.',
    'Dine første 14 dage\ner gratis.',
    'Je eerste 14 dagen\nzijn gratis.',
    'Tus primeros 14 días\nson gratis.',
    'I primi 14 giorni\nsono gratis.'
  ],
  'Make every\nworkout count.': [
    'Mach jedes\nTraining wertvoll.',
    'Donnez du sens\nà chaque séance.',
    'Få ut mer av\nvarje träningspass.',
    'Få mer ut av\nhver treningsøkt.',
    'Få mere ud af\nhver træning.',
    'Haal meer uit\nelke training.',
    'Aprovecha\ncada entrenamiento.',
    'Dai valore a\nogni allenamento.'
  ],
  'YOUR PLAN. YOUR PROGRESS.': [
    'DEIN PLAN. DEIN FORTSCHRITT.',
    'VOTRE PLAN. VOS PROGRÈS.',
    'DIN PLAN. DINA FRAMSTEG.',
    'DIN PLAN. DIN FREMGANG.',
    'DIN PLAN. DINE FREMSKRIDT.',
    'JOUW PLAN. JOUW VOORUITGANG.',
    'TU PLAN. TU PROGRESO.',
    'IL TUO PIANO. I TUOI PROGRESSI.'
  ],
  'year': ['Jahr', 'an', 'år', 'år', 'år', 'jaar', 'año', 'anno'],
  'month': ['Monat', 'mois', 'månad', 'måned', 'måned', 'maand', 'mes', 'mese'],
  'Try your complete training and nutrition plan. Then {price}, unless you cancel.':
      [
    'Teste deinen vollständigen Trainings- und Ernährungsplan. Danach {price}, sofern du nicht kündigst.',
    'Essayez votre programme complet de sport et de nutrition. Puis {price}, sauf annulation.',
    'Prova hela din tränings- och kostplan. Därefter {price} om du inte säger upp.',
    'Prøv hele trenings- og kostholdsplanen. Deretter {price} hvis du ikke sier opp.',
    'Prøv din komplette trænings- og kostplan. Derefter {price}, medmindre du opsiger.',
    'Probeer je volledige trainings- en voedingsplan. Daarna {price}, tenzij je opzegt.',
    'Prueba tu plan completo de entrenamiento y nutrición. Después {price}, salvo cancelación.',
    'Prova il piano completo di allenamento e nutrizione. Poi {price}, salvo disdetta.'
  ],
  '14 days free, then {price}': [
    '14 Tage kostenlos, danach {price}',
    '14 jours offerts, puis {price}',
    '14 dagar gratis, sedan {price}',
    '14 dager gratis, deretter {price}',
    '14 dage gratis, derefter {price}',
    '14 dagen gratis, daarna {price}',
    '14 días gratis, después {price}',
    '14 giorni gratis, poi {price}'
  ],
  '{price} · auto-renewing': [
    '{price} · automatische Verlängerung',
    '{price} · renouvellement automatique',
    '{price} · förnyas automatiskt',
    '{price} · fornyes automatisk',
    '{price} · automatisk fornyelse',
    '{price} · automatische verlenging',
    '{price} · renovación automática',
    '{price} · rinnovo automatico'
  ],
  'Start my 14-day free trial': [
    '14 Tage kostenlos testen',
    'Commencer mes 14 jours offerts',
    'Starta min gratisperiod på 14 dagar',
    'Start min gratis prøveperiode på 14 dager',
    'Start mine 14 gratis prøvedage',
    'Start mijn 14 gratis dagen',
    'Iniciar mis 14 días gratis',
    'Inizia i miei 14 giorni gratis'
  ],
  'Subscribe & continue': [
    'Abonnieren und fortfahren',
    'S’abonner et continuer',
    'Prenumerera och fortsätt',
    'Abonner og fortsett',
    'Abonnér og fortsæt',
    'Abonneren en doorgaan',
    'Suscribirme y continuar',
    'Abbonati e continua'
  ],
  'Continue to my plan': [
    'Weiter zu meinem Plan',
    'Accéder à mon programme',
    'Fortsätt till min plan',
    'Fortsett til planen min',
    'Fortsæt til min plan',
    'Doorgaan naar mijn plan',
    'Continuar a mi plan',
    'Continua al mio piano'
  ],
  'No charge today. Cancel in {store} before your trial ends to avoid payment.':
      [
    'Heute keine Zahlung. Kündige vor Ablauf des Tests in {store}, um eine Zahlung zu vermeiden.',
    'Aucun paiement aujourd’hui. Annulez dans {store} avant la fin de l’essai pour éviter le paiement.',
    'Ingen debitering idag. Säg upp i {store} innan provperioden tar slut för att undvika betalning.',
    'Ingen betaling i dag. Si opp i {store} før prøveperioden slutter for å unngå betaling.',
    'Ingen betaling i dag. Opsig i {store} før prøveperioden slutter for at undgå betaling.',
    'Vandaag betaal je niets. Zeg vóór het einde van je proefperiode op in {store} om betaling te voorkomen.',
    'Hoy no pagas nada. Cancela en {store} antes de que termine la prueba para evitar el cobro.',
    'Oggi non paghi nulla. Annulla in {store} prima della fine della prova per evitare l’addebito.'
  ],
  'Cancel in {store}. Access continues until the end of your billing period.': [
    'Kündige in {store}. Dein Zugang bleibt bis zum Ende des Abrechnungszeitraums bestehen.',
    'Annulez dans {store}. L’accès reste actif jusqu’à la fin de la période facturée.',
    'Säg upp i {store}. Åtkomsten gäller till betalningsperiodens slut.',
    'Si opp i {store}. Tilgangen varer ut betalingsperioden.',
    'Opsig i {store}. Adgangen fortsætter til betalingsperiodens udløb.',
    'Zeg op in {store}. Je toegang blijft tot het einde van je betaalperiode.',
    'Cancela en {store}. El acceso continúa hasta el final del período de facturación.',
    'Annulla in {store}. L’accesso continua fino alla fine del periodo di fatturazione.'
  ],
  'Save {percent}%': [
    '{percent}% sparen',
    'Économisez {percent} %',
    'Spara {percent} %',
    'Spar {percent} %',
    'Spar {percent} %',
    'Bespaar {percent}%',
    'Ahorra un {percent} %',
    'Risparmia il {percent}%'
  ],
  '{price}/month, billed yearly after your trial': [
    '{price}/Monat, jährliche Zahlung nach dem Test',
    '{price}/mois, facturé annuellement après l’essai',
    '{price}/månad, debiteras årsvis efter provperioden',
    '{price}/måned, faktureres årlig etter prøveperioden',
    '{price}/måned, årlig betaling efter prøveperioden',
    '{price}/maand, jaarlijks betaald na je proefperiode',
    '{price}/mes, facturación anual tras la prueba',
    '{price}/mese, addebito annuale dopo la prova'
  ],
  '{price}/month, billed yearly': [
    '{price}/Monat, jährliche Zahlung',
    '{price}/mois, facturé annuellement',
    '{price}/månad, debiteras årsvis',
    '{price}/måned, faktureres årlig',
    '{price}/måned, årlig betaling',
    '{price}/maand, jaarlijks betaald',
    '{price}/mes, facturación anual',
    '{price}/mese, addebito annuale'
  ],
  '14 days free, then billed monthly': [
    '14 Tage kostenlos, danach monatliche Zahlung',
    '14 jours offerts, puis facturation mensuelle',
    '14 dagar gratis, sedan månadsbetalning',
    '14 dager gratis, deretter månedlig betaling',
    '14 dage gratis, derefter månedlig betaling',
    '14 dagen gratis, daarna maandelijks betaald',
    '14 días gratis, después facturación mensual',
    '14 giorni gratis, poi addebito mensile'
  ],
  'Billed monthly': [
    'Monatliche Zahlung',
    'Facturé mensuellement',
    'Debiteras månadsvis',
    'Faktureres månedlig',
    'Månedlig betaling',
    'Maandelijks betaald',
    'Facturación mensual',
    'Addebito mensile'
  ],
  'How your trial works': [
    'So funktioniert dein Test',
    'Comment fonctionne l’essai',
    'Så fungerar provperioden',
    'Slik fungerer prøveperioden',
    'Sådan fungerer prøveperioden',
    'Zo werkt je proefperiode',
    'Cómo funciona tu prueba',
    'Come funziona la prova'
  ],
  'Unlock your full plan and every included feature.': [
    'Erhalte deinen vollständigen Plan und alle enthaltenen Funktionen.',
    'Accédez à votre programme complet et à toutes les fonctions incluses.',
    'Få hela din plan och alla inkluderade funktioner.',
    'Få hele planen og alle inkluderte funksjoner.',
    'Få hele din plan og alle inkluderede funktioner.',
    'Krijg je volledige plan en alle inbegrepen functies.',
    'Accede a tu plan completo y a todas las funciones incluidas.',
    'Accedi al piano completo e a tutte le funzioni incluse.'
  ],
  'You’re in control': [
    'Du entscheidest',
    'Vous gardez le contrôle',
    'Du bestämmer',
    'Du bestemmer',
    'Du bestemmer',
    'Jij hebt de controle',
    'Tú tienes el control',
    'Decidi tu'
  ],
  'Manage or cancel anytime in {store}.': [
    'Jederzeit in {store} verwalten oder kündigen.',
    'Gérez ou annulez à tout moment dans {store}.',
    'Hantera eller säg upp när som helst i {store}.',
    'Administrer eller si opp når som helst i {store}.',
    'Administrér eller opsig når som helst i {store}.',
    'Beheer of zeg op wanneer je wilt in {store}.',
    'Gestiona o cancela cuando quieras en {store}.',
    'Gestisci o annulla quando vuoi in {store}.'
  ],
  'After 14 days': [
    'Nach 14 Tagen',
    'Après 14 jours',
    'Efter 14 dagar',
    'Etter 14 dager',
    'Efter 14 dage',
    'Na 14 dagen',
    'Después de 14 días',
    'Dopo 14 giorni'
  ],
  '{price}. Renews automatically unless canceled.': [
    '{price}. Verlängert sich automatisch, sofern nicht gekündigt.',
    '{price}. Renouvellement automatique sauf annulation.',
    '{price}. Förnyas automatiskt om du inte säger upp.',
    '{price}. Fornyes automatisk med mindre du sier opp.',
    '{price}. Fornyes automatisk, medmindre du opsiger.',
    '{price}. Wordt automatisch verlengd, tenzij je opzegt.',
    '{price}. Se renueva automáticamente salvo cancelación.',
    '{price}. Si rinnova automaticamente salvo disdetta.'
  ],
  'See what’s included.': [
    'Das ist enthalten.',
    'Découvrez ce qui est inclus.',
    'Se vad som ingår.',
    'Se hva som er inkludert.',
    'Se, hvad der er inkluderet.',
    'Bekijk wat is inbegrepen.',
    'Descubre qué incluye.',
    'Scopri cosa è incluso.'
  ],
  'Every feature below is included in your trial and paid membership.': [
    'Alle folgenden Funktionen sind im Test und im kostenpflichtigen Abo enthalten.',
    'Toutes ces fonctions sont incluses pendant l’essai et dans l’abonnement payant.',
    'Alla funktioner nedan ingår i provperioden och den betalda prenumerationen.',
    'Alle funksjonene nedenfor er inkludert i prøveperioden og det betalte abonnementet.',
    'Alle funktioner nedenfor er med i prøveperioden og det betalte abonnement.',
    'Alle functies hieronder zijn inbegrepen tijdens je proefperiode en betaalde abonnement.',
    'Todas estas funciones están incluidas en la prueba y en la suscripción de pago.',
    'Tutte queste funzioni sono incluse nella prova e nell’abbonamento a pagamento.'
  ],
  'Your membership': [
    'Dein Abo',
    'Votre abonnement',
    'Din prenumeration',
    'Abonnementet ditt',
    'Dit abonnement',
    'Je abonnement',
    'Tu suscripción',
    'Il tuo abbonamento'
  ],
  'With\nSetcraft': [
    'Mit\nSetcraft',
    'Avec\nSetcraft',
    'Med\nSetcraft',
    'Med\nSetcraft',
    'Med\nSetcraft',
    'Met\nSetcraft',
    'Con\nSetcraft',
    'Con\nSetcraft'
  ],
  'Without\nSetcraft': [
    'Ohne\nSetcraft',
    'Sans\nSetcraft',
    'Utan\nSetcraft',
    'Uten\nSetcraft',
    'Uden\nSetcraft',
    'Zonder\nSetcraft',
    'Sin\nSetcraft',
    'Senza\nSetcraft'
  ],
  'Personalized weekly workouts': [
    'Persönliche Wochen-Trainingspläne',
    'Séances hebdomadaires personnalisées',
    'Personliga veckopass',
    'Personlige ukentlige treningsøkter',
    'Personlige ugentlige træninger',
    'Persoonlijke wekelijkse trainingen',
    'Entrenamientos semanales personalizados',
    'Allenamenti settimanali personalizzati'
  ],
  'Nutrition around your goals': [
    'Ernährung passend zu deinen Zielen',
    'Nutrition adaptée à vos objectifs',
    'Kost utifrån dina mål',
    'Kosthold tilpasset målene dine',
    'Kost tilpasset dine mål',
    'Voeding afgestemd op je doelen',
    'Nutrición para tus objetivos',
    'Nutrizione in base ai tuoi obiettivi'
  ],
  'Exercise videos & instructions': [
    'Übungsvideos und Anleitungen',
    'Vidéos et consignes d’exercice',
    'Övningsvideor och instruktioner',
    'Øvelsesvideoer og instruksjoner',
    'Øvelsesvideoer og vejledninger',
    'Oefenvideo’s en instructies',
    'Vídeos e instrucciones de ejercicios',
    'Video e istruzioni degli esercizi'
  ],
  'Workout logging & history': [
    'Trainingserfassung und Verlauf',
    'Suivi et historique des séances',
    'Träningslogg och historik',
    'Treningslogg og historikk',
    'Træningslog og historik',
    'Trainingen vastleggen en terugzien',
    'Registro e historial de entrenamientos',
    'Registro e storico degli allenamenti'
  ],
  'Muscle maps & strength trends': [
    'Muskelkarten und Kraftentwicklung',
    'Cartes musculaires et évolution de la force',
    'Muskelkartor och styrketrender',
    'Muskelkart og styrketrender',
    'Muskelkort og styrkeudvikling',
    'Spierkaarten en krachtontwikkeling',
    'Mapas musculares y evolución de fuerza',
    'Mappe muscolari e progressi di forza'
  ],
  'Body measurements & progress': [
    'Körpermaße und Fortschritt',
    'Mensurations et progrès',
    'Kroppsmått och framsteg',
    'Kroppsmål og fremgang',
    'Kropsmål og fremskridt',
    'Lichaamsmaten en voortgang',
    'Medidas corporales y progreso',
    'Misure corporee e progressi'
  ],
  'Your training. Built around you.': [
    'Dein Training. Auf dich abgestimmt.',
    'Votre entraînement. Pensé pour vous.',
    'Din träning. Anpassad för dig.',
    'Din trening. Tilpasset deg.',
    'Din træning. Tilpasset dig.',
    'Jouw training. Afgestemd op jou.',
    'Tu entrenamiento. Hecho para ti.',
    'Il tuo allenamento. Pensato per te.'
  ],
  'Know what to train. Know how to progress.': [
    'Wisse, was du trainierst und wie du vorankommst.',
    'Sachez quoi travailler et comment progresser.',
    'Vet vad du ska träna och hur du utvecklas.',
    'Vit hva du skal trene og hvordan du utvikler deg.',
    'Vid, hvad du skal træne, og hvordan du udvikler dig.',
    'Weet wat je traint en hoe je vooruitgaat.',
    'Ten claro qué entrenar y cómo progresar.',
    'Sai cosa allenare e come progredire.'
  ],
  'A workout plan that fits you': [
    'Ein Trainingsplan, der zu dir passt',
    'Un programme qui vous correspond',
    'En träningsplan som passar dig',
    'En treningsplan som passer deg',
    'En træningsplan, der passer dig',
    'Een trainingsplan dat bij je past',
    'Un plan de entrenamiento a tu medida',
    'Un piano di allenamento adatto a te'
  ],
  'Your experience, equipment and schedule.': [
    'Deine Erfahrung, Ausrüstung und Zeit.',
    'Votre expérience, votre matériel et vos horaires.',
    'Din erfarenhet, utrustning och ditt schema.',
    'Din erfaring, ditt utstyr og din timeplan.',
    'Din erfaring, dit udstyr og din tidsplan.',
    'Jouw ervaring, materiaal en planning.',
    'Tu experiencia, equipo y horario.',
    'La tua esperienza, attrezzatura e disponibilità.'
  ],
  'Nutrition with a clear purpose': [
    'Ernährung mit einem klaren Ziel',
    'Une nutrition avec un objectif clair',
    'Kost med ett tydligt mål',
    'Kosthold med et tydelig mål',
    'Kost med et klart mål',
    'Voeding met een duidelijk doel',
    'Nutrición con un propósito claro',
    'Nutrizione con un obiettivo chiaro'
  ],
  'Practical guidance around your goals.': [
    'Praktische Empfehlungen für deine Ziele.',
    'Des conseils pratiques selon vos objectifs.',
    'Praktiska råd utifrån dina mål.',
    'Praktiske råd ut fra målene dine.',
    'Praktisk vejledning ud fra dine mål.',
    'Praktische begeleiding bij je doelen.',
    'Consejos prácticos para tus objetivos.',
    'Indicazioni pratiche per i tuoi obiettivi.'
  ],
  'Progress you can actually follow': [
    'Fortschritt, den du verfolgen kannst',
    'Des progrès que vous pouvez suivre',
    'Framsteg du kan följa',
    'Fremgang du kan følge',
    'Fremskridt, du kan følge',
    'Vooruitgang die je kunt volgen',
    'Un progreso que puedes seguir',
    'Progressi che puoi seguire'
  ],
  'Your lifts, muscle coverage and history.': [
    'Deine Übungen, Muskelabdeckung und dein Verlauf.',
    'Vos charges, les muscles travaillés et votre historique.',
    'Dina lyft, tränade muskler och din historik.',
    'Dine løft, trente muskler og din historikk.',
    'Dine løft, trænede muskler og din historik.',
    'Je oefeningen, getrainde spieren en historie.',
    'Tus levantamientos, músculos trabajados e historial.',
    'I tuoi sollevamenti, muscoli allenati e storico.'
  ],
  '14-day trial for eligible members. Subscription required afterwards.': [
    '14 Tage Test für berechtigte Mitglieder. Danach ist ein kostenpflichtiges Abo nötig.',
    'Essai de 14 jours pour les membres éligibles. Abonnement payant ensuite.',
    '14 dagars provperiod för behöriga medlemmar. Därefter krävs betald prenumeration.',
    '14 dagers prøveperiode for kvalifiserte medlemmer. Deretter kreves betalt abonnement.',
    '14 dages prøveperiode for berettigede medlemmer. Derefter kræves betalt abonnement.',
    '14 dagen proberen voor leden die in aanmerking komen. Daarna is een betaald abonnement nodig.',
    'Prueba de 14 días para miembros que cumplan los requisitos. Después se requiere suscripción de pago.',
    'Prova di 14 giorni per i membri idonei. Poi è richiesto un abbonamento a pagamento.'
  ],
  'Retry loading plans': [
    'Pläne erneut laden',
    'Réessayer de charger les offres',
    'Ladda planerna igen',
    'Last inn planene på nytt',
    'Indlæs planerne igen',
    'Plannen opnieuw laden',
    'Volver a cargar los planes',
    'Riprova a caricare i piani'
  ],
  'Loading plans': [
    'Pläne werden geladen',
    'Chargement des offres',
    'Laddar planer',
    'Laster planer',
    'Indlæser planer',
    'Plannen laden',
    'Cargando planes',
    'Caricamento dei piani'
  ],
  'Sets, reps & weight guidance': [
    'Orientierung für Sätze, Wiederholungen und Gewichte',
    'Conseils pour les séries, répétitions et charges',
    'Vägledning för set, repetitioner och vikter',
    'Veiledning for sett, repetisjoner og vekter',
    'Vejledning til sæt, gentagelser og vægte',
    'Advies voor sets, herhalingen en gewichten',
    'Orientación sobre series, repeticiones y pesos',
    'Indicazioni su serie, ripetizioni e carichi'
  ],
  'Warm-ups for your workout': [
    'Aufwärmen passend zum Training',
    'Échauffements pour vos séances',
    'Uppvärmning för ditt pass',
    'Oppvarming til treningsøkten',
    'Opvarmning til din træning',
    'Warming-ups voor je training',
    'Calentamientos para tus sesiones',
    'Riscaldamento per i tuoi allenamenti'
  ],
  'Saved routines & custom exercises': [
    'Gespeicherte Routinen und eigene Übungen',
    'Routines enregistrées et exercices personnalisés',
    'Sparade rutiner och egna övningar',
    'Lagrede rutiner og egne øvelser',
    'Gemte rutiner og egne øvelser',
    'Opgeslagen routines en eigen oefeningen',
    'Rutinas guardadas y ejercicios personalizados',
    'Routine salvate ed esercizi personalizzati'
  ],
  'Personal records & exercise progress': [
    'Persönliche Rekorde und Übungsfortschritte',
    'Records personnels et progression par exercice',
    'Personliga rekord och övningsutveckling',
    'Personlige rekorder og øvelsesfremgang',
    'Personlige rekorder og fremgang i øvelser',
    'Persoonlijke records en voortgang per oefening',
    'Récords personales y progreso por ejercicio',
    'Record personali e progressi per esercizio'
  ],
  'Calories, macros & water logging': [
    'Kalorien, Makros und Wasser erfassen',
    'Suivi des calories, macronutriments et de l’eau',
    'Loggning av kalorier, makron och vatten',
    'Logging av kalorier, makroer og vann',
    'Registrering af kalorier, makroer og vand',
    'Calorieën, macro’s en water bijhouden',
    'Registro de calorías, macros y agua',
    'Registro di calorie, macronutrienti e acqua'
  ],
  'Training readiness & sleep check-ins': [
    'Trainingsbereitschaft und Schlaf-Check-ins',
    'Forme pour l’entraînement et bilans du sommeil',
    'Träningsberedskap och sömnkoll',
    'Treningsberedskap og søvnsjekk',
    'Træningsparathed og søvntjek',
    'Trainingsbereidheid en slaapcheck-ins',
    'Disposición para entrenar y registro del sueño',
    'Prontezza per l’allenamento e controllo del sonno'
  ],
  'Progress photos & comparisons': [
    'Fortschrittsfotos und Vergleiche',
    'Photos de progression et comparaisons',
    'Framstegsbilder och jämförelser',
    'Fremgangsbilder og sammenligninger',
    'Fremskridtsbilleder og sammenligninger',
    'Voortgangsfoto’s en vergelijkingen',
    'Fotos de progreso y comparaciones',
    'Foto dei progressi e confronti'
  ],
  'Waiting for confirmation': [
    'Bestätigung ausstehend',
    'En attente de confirmation',
    'Väntar på bekräftelse',
    'Venter på bekreftelse',
    'Venter på bekræftelse',
    'Wachten op bevestiging',
    'Esperando confirmación',
    'In attesa di conferma'
  ],
};
String? membershipTranslation(String locale, String source) {
  final index = membershipCopyLocales.indexOf(locale);
  final row = membershipCopy[source];
  return index < 0 || row == null ? null : row[index];
}
