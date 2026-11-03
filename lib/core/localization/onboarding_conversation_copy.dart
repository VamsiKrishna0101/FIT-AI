const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "Your body stats": [
    "Deine Werte",
    "Vos mesures",
    "Dina mått",
    "Dine mål",
    "Dine mål",
    "Je maten",
    "Tus medidas",
    "Le tue misure"
  ],
  "Choose the equipment available to you": [
    "Wähle deine verfügbare Ausrüstung",
    "Choisissez le matériel disponible",
    "Välj utrustningen du har tillgång till",
    "Velg utstyret du har tilgang til",
    "Vælg det udstyr, du har adgang til",
    "Kies het materiaal dat je kunt gebruiken",
    "Elige el equipo que tienes disponible",
    "Scegli l’attrezzatura che hai a disposizione"
  ],
  "Do you have a preferred training split?": [
    "Hast du einen bevorzugten Trainingssplit?",
    "Avez-vous une répartition préférée ?",
    "Har du en föredragen träningssplit?",
    "Har du en foretrukket treningssplitt?",
    "Har du en foretrukken træningssplit?",
    "Heb je een favoriete trainingssplit?",
    "¿Tienes una división de entrenamiento preferida?",
    "Hai una suddivisione di allenamento preferita?"
  ],
  "More training styles": [
    "Weitere Trainingsstile",
    "Autres styles d’entraînement",
    "Fler träningsstilar",
    "Flere treningsstiler",
    "Flere træningsstile",
    "Meer trainingsstijlen",
    "Más estilos de entrenamiento",
    "Altri stili di allenamento"
  ],
  "Preview your week": [
    "Wochenvorschau",
    "Aperçu de votre semaine",
    "Förhandsvisa din vecka",
    "Forhåndsvis uken din",
    "Se din uge",
    "Bekijk je week",
    "Vista previa de tu semana",
    "Anteprima della settimana"
  ],
  "Review your equipment": [
    "Prüfe deine Ausrüstung",
    "Vérifiez votre matériel",
    "Granska din utrustning",
    "Se over utstyret ditt",
    "Gennemgå dit udstyr",
    "Bekijk je materiaal",
    "Revisa tu equipo",
    "Controlla la tua attrezzatura"
  ],
  "Select what you can use. You can change this later.": [
    "Wähle, was dir zur Verfügung steht. Du kannst das später ändern.",
    "Sélectionnez le matériel disponible. Vous pourrez le modifier plus tard.",
    "Välj det du har tillgång till. Du kan ändra det senare.",
    "Velg det du har tilgang til. Du kan endre dette senere.",
    "Vælg det, du har adgang til. Du kan ændre det senere.",
    "Kies wat je kunt gebruiken. Je kunt dit later wijzigen.",
    "Selecciona lo que puedes usar. Puedes cambiarlo después.",
    "Seleziona ciò che puoi usare. Puoi modificarlo in seguito."
  ],
  "Search equipment": [
    "Ausrüstung suchen",
    "Rechercher du matériel",
    "Sök utrustning",
    "Søk etter utstyr",
    "Søg efter udstyr",
    "Materiaal zoeken",
    "Buscar equipo",
    "Cerca attrezzatura"
  ],
  "Done": [
    "Fertig",
    "Terminé",
    "Klart",
    "Ferdig",
    "Færdig",
    "Gereed",
    "Listo",
    "Fatto"
  ],
  "Free weights": [
    "Freie Gewichte",
    "Poids libres",
    "Fria vikter",
    "Frivekter",
    "Frie vægte",
    "Vrije gewichten",
    "Pesos libres",
    "Pesi liberi"
  ],
  "Benches & racks": [
    "Bänke & Racks",
    "Bancs et racks",
    "Bänkar och ställningar",
    "Benker og stativer",
    "Bænke og stativer",
    "Banken en rekken",
    "Bancos y soportes",
    "Panche e rack"
  ],
  "Machines & cables": [
    "Maschinen & Kabelzüge",
    "Machines et poulies",
    "Maskiner och kablar",
    "Maskiner og kabler",
    "Maskiner og kabler",
    "Machines en kabels",
    "Máquinas y poleas",
    "Macchine e cavi"
  ],
  "Bands & bodyweight": [
    "Bänder & Körpergewicht",
    "Élastiques et poids du corps",
    "Band och kroppsvikt",
    "Strikker og kroppsvekt",
    "Elastikker og kropsvægt",
    "Banden en lichaamsgewicht",
    "Bandas y peso corporal",
    "Elastici e corpo libero"
  ],
  "No equipment found": [
    "Keine Ausrüstung gefunden",
    "Aucun matériel trouvé",
    "Ingen utrustning hittades",
    "Fant ikke noe utstyr",
    "Intet udstyr fundet",
    "Geen materiaal gevonden",
    "No se encontró equipo",
    "Nessuna attrezzatura trovata"
  ],
  "Try another name.": [
    "Versuche einen anderen Namen.",
    "Essayez un autre nom.",
    "Prova ett annat namn.",
    "Prøv et annet navn.",
    "Prøv et andet navn.",
    "Probeer een andere naam.",
    "Prueba con otro nombre.",
    "Prova un altro nome."
  ],
  "What should we call you?": [
    "Wie sollen wir dich nennen?",
    "Comment vous appelez-vous ?",
    "Vad ska vi kalla dig?",
    "Hva skal vi kalle deg?",
    "Hvad skal vi kalde dig?",
    "Hoe mogen we je noemen?",
    "¿Cómo te llamas?",
    "Come ti chiami?"
  ],
  "Which profile fits you?": [
    "Welches Profil passt zu dir?",
    "Quel profil vous correspond ?",
    "Vilken profil passar dig?",
    "Hvilken profil passer deg?",
    "Hvilken profil passer til dig?",
    "Welk profiel past bij je?",
    "¿Qué perfil se ajusta a ti?",
    "Quale profilo ti descrive?"
  ],
  "What are your measurements?": [
    "Wie sind deine Körpermaße?",
    "Quelles sont vos mensurations ?",
    "Vilka är dina kroppsmått?",
    "Hva er kroppsmålene dine?",
    "Hvad er dine kropsmål?",
    "Wat zijn je lichaamsmaten?",
    "¿Cuáles son tus medidas?",
    "Quali sono le tue misure?"
  ],
  "Anything else we should know?": [
    "Was sollten wir noch wissen?",
    "Autre chose à nous dire ?",
    "Något mer vi bör veta?",
    "Er det noe mer vi bør vite?",
    "Er der andet, vi bør vide?",
    "Moeten we nog iets weten?",
    "¿Algo más que debamos saber?",
    "C’è altro che dovremmo sapere?"
  ],
  "Optional. Add training needs or food preferences.": [
    "Optional. Ergänze Trainingsbedürfnisse oder Ernährungswünsche.",
    "Facultatif. Ajoutez vos besoins sportifs ou préférences alimentaires.",
    "Valfritt. Lägg till träningsbehov eller matpreferenser.",
    "Valgfritt. Legg til treningsbehov eller matpreferanser.",
    "Valgfrit. Tilføj træningsbehov eller madpræferencer.",
    "Optioneel. Voeg trainingsbehoeften of voedingsvoorkeuren toe.",
    "Opcional. Añade necesidades de entrenamiento o preferencias alimentarias.",
    "Facoltativo. Aggiungi esigenze di allenamento o preferenze alimentari."
  ],
  "Think about your day outside the gym.": [
    "Denke an deinen Alltag außerhalb des Fitnessstudios.",
    "Pensez à votre journée en dehors de la salle.",
    "Tänk på din dag utanför gymmet.",
    "Tenk på dagen din utenfor treningssenteret.",
    "Tænk på din dag uden for træningscentret.",
    "Denk aan je dag buiten de sportschool.",
    "Piensa en tu día fuera del gimnasio.",
    "Pensa alla tua giornata fuori dalla palestra."
  ],
  "View full week": [
    "Ganze Woche ansehen",
    "Voir toute la semaine",
    "Visa hela veckan",
    "Vis hele uken",
    "Vis hele ugen",
    "Hele week bekijken",
    "Ver semana completa",
    "Vedi tutta la settimana"
  ],
  "Show less": [
    "Weniger anzeigen",
    "Afficher moins",
    "Visa mindre",
    "Vis mindre",
    "Vis mindre",
    "Minder tonen",
    "Mostrar menos",
    "Mostra meno"
  ],
  "What’s your main\nfitness goal?": [
    "Was ist dein wichtigstes\nFitnessziel?",
    "Quel est votre principal\nobjectif fitness ?",
    "Vad är ditt främsta\nträningsmål?",
    "Hva er ditt viktigste\ntreningsmål?",
    "Hvad er dit vigtigste\ntræningsmål?",
    "Wat is je belangrijkste\nfitnessdoel?",
    "¿Cuál es tu principal\nobjetivo de fitness?",
    "Qual è il tuo principale\nobiettivo fitness?"
  ],
  "Let’s build your training plan.": [
    "Lass uns deinen Trainingsplan erstellen.",
    "Créons votre programme d’entraînement.",
    "Låt oss skapa din träningsplan.",
    "La oss lage treningsplanen din.",
    "Lad os lave din træningsplan.",
    "Laten we je trainingsplan maken.",
    "Vamos a crear tu plan de entrenamiento.",
    "Creiamo il tuo piano di allenamento."
  ],
  "You can change this later.": [
    "Du kannst das später ändern.",
    "Vous pourrez changer cela plus tard.",
    "Du kan ändra detta senare.",
    "Du kan endre dette senere.",
    "Du kan ændre dette senere.",
    "Je kunt dit later wijzigen.",
    "Puedes cambiarlo más adelante.",
    "Puoi modificarlo in seguito."
  ],
  "We’ll start at your level.": [
    "Wir starten auf deinem Niveau.",
    "Nous partons de votre niveau.",
    "Vi börjar på din nivå.",
    "Vi starter på ditt nivå.",
    "Vi starter på dit niveau.",
    "We beginnen op jouw niveau.",
    "Empezaremos a tu nivel.",
    "Partiamo dal tuo livello."
  ],
  "A few details to make it yours.": [
    "Ein paar Angaben machen es persönlich.",
    "Quelques détails pour vous connaître.",
    "Några detaljer gör planen personlig.",
    "Noen detaljer gjør planen personlig.",
    "Et par detaljer gør planen personlig.",
    "Een paar details maken het persoonlijk.",
    "Unos detalles para hacerlo tuyo.",
    "Qualche dettaglio per renderlo tuo."
  ],
  "Review your measurements and units.": [
    "Prüfe deine Maße und Einheiten.",
    "Vérifiez vos mesures et vos unités.",
    "Kontrollera dina mått och enheter.",
    "Sjekk målene og enhetene dine.",
    "Tjek dine mål og enheder.",
    "Controleer je maten en eenheden.",
    "Revisa tus medidas y unidades.",
    "Controlla misure e unità."
  ],
  "Let’s work with what you have.": [
    "Wir arbeiten mit dem, was du hast.",
    "Partons de ce que vous avez.",
    "Vi utgår från det du har.",
    "Vi jobber med det du har.",
    "Vi arbejder med det, du har.",
    "We werken met wat je hebt.",
    "Trabajemos con lo que tienes.",
    "Lavoriamo con ciò che hai."
  ],
  "A plan that fits your week.": [
    "Ein Plan, der zu deiner Woche passt.",
    "Un programme adapté à votre semaine.",
    "En plan som passar din vecka.",
    "En plan som passer uken din.",
    "En plan, der passer til din uge.",
    "Een plan dat bij je week past.",
    "Un plan que encaja en tu semana.",
    "Un piano adatto alla tua settimana."
  ],
  "Equipment saved": [
    "Ausrüstung gespeichert",
    "Matériel enregistré",
    "Utrustning sparad",
    "Utstyr lagret",
    "Udstyr gemt",
    "Materiaal opgeslagen",
    "Equipo guardado",
    "Attrezzatura salvata"
  ],
  "Your week is set": [
    "Deine Woche steht",
    "Votre semaine est définie",
    "Din vecka är klar",
    "Uken din er klar",
    "Din uge er klar",
    "Je week staat klaar",
    "Tu semana está lista",
    "La tua settimana è pronta"
  ],
  "Training preferences saved": [
    "Trainingswünsche gespeichert",
    "Préférences d’entraînement enregistrées",
    "Träningspreferenser sparade",
    "Treningspreferanser lagret",
    "Træningspræferencer gemt",
    "Trainingsvoorkeuren opgeslagen",
    "Preferencias de entrenamiento guardadas",
    "Preferenze di allenamento salvate"
  ],
  "Preferences saved": [
    "Einstellungen gespeichert",
    "Préférences enregistrées",
    "Preferenser sparade",
    "Preferanser lagret",
    "Præferencer gemt",
    "Voorkeuren opgeslagen",
    "Preferencias guardadas",
    "Preferenze salvate"
  ],
  "Keep what you have. Remove what you don’t.": [
    "Behalte, was du hast. Entferne den Rest.",
    "Gardez votre matériel. Retirez le reste.",
    "Behåll det du har. Ta bort resten.",
    "Behold det du har. Fjern resten.",
    "Behold det, du har. Fjern resten.",
    "Behoud wat je hebt. Verwijder de rest.",
    "Conserva lo que tienes. Quita lo demás.",
    "Tieni ciò che hai. Rimuovi il resto."
  ],
  "Let’s check your equipment.": [
    "Prüfen wir deine Ausrüstung.",
    "Vérifions votre matériel.",
    "Vi kollar din utrustning.",
    "La oss sjekke utstyret ditt.",
    "Lad os tjekke dit udstyr.",
    "Laten we je materiaal bekijken.",
    "Revisemos tu equipo.",
    "Controlliamo la tua attrezzatura."
  ],
  "Here’s how your week comes together.": [
    "So setzt sich deine Woche zusammen.",
    "Voici comment votre semaine s’organise.",
    "Så här ser din vecka ut.",
    "Slik settes uken din sammen.",
    "Sådan hænger din uge sammen.",
    "Zo ziet je week eruit.",
    "Así se organiza tu semana.",
    "Ecco come si organizza la tua settimana."
  ],
  "Your setup is almost ready.": [
    "Deine Einrichtung ist fast fertig.",
    "Votre configuration est presque prête.",
    "Dina inställningar är snart klara.",
    "Oppsettet ditt er nesten klart.",
    "Din opsætning er næsten klar.",
    "Je instellingen zijn bijna klaar.",
    "Tu configuración está casi lista.",
    "La configurazione è quasi pronta."
  ],
  "Let’s make the plan yours.": [
    "Machen wir den Plan zu deinem.",
    "Personnalisons votre programme.",
    "Låt oss göra planen till din.",
    "La oss gjøre planen til din.",
    "Lad os gøre planen til din.",
    "Laten we het jouw plan maken.",
    "Hagamos que el plan sea tuyo.",
    "Rendiamo tuo questo piano."
  ],
  "Choose a focus, or keep a balanced full-body plan.": [
    "Wähle einen Fokus oder trainiere ausgewogen den ganzen Körper.",
    "Choisissez une priorité ou travaillez tout le corps.",
    "Välj ett fokus eller träna hela kroppen balanserat.",
    "Velg et fokus eller tren hele kroppen balansert.",
    "Vælg et fokus, eller træn hele kroppen afbalanceret.",
    "Kies een focus of train je hele lichaam in balans.",
    "Elige un enfoque o entrena todo el cuerpo de forma equilibrada.",
    "Scegli un focus o allena tutto il corpo in modo equilibrato."
  ],
  "Add anything else you’d like us to account for.": [
    "Ergänze alles, was wir berücksichtigen sollen.",
    "Ajoutez ce que nous devons prendre en compte.",
    "Lägg till annat vi bör ta hänsyn till.",
    "Legg til annet vi bør ta hensyn til.",
    "Tilføj andet, vi bør tage hensyn til.",
    "Voeg toe waar we rekening mee moeten houden.",
    "Añade lo que debamos tener en cuenta.",
    "Aggiungi ciò che dovremmo considerare."
  ],
  "Training works best with the rest of your day.": [
    "Dein Training passt zu deinem Alltag.",
    "Votre entraînement s’adapte à votre quotidien.",
    "Träningen ska passa resten av din dag.",
    "Treningen skal passe resten av dagen din.",
    "Træningen skal passe til resten af din dag.",
    "Training moet bij de rest van je dag passen.",
    "El entrenamiento debe encajar en tu día.",
    "L’allenamento deve adattarsi alla tua giornata."
  ],
  "Select any areas we should account for.": [
    "Wähle die Bereiche, die wir berücksichtigen sollen.",
    "Sélectionnez les zones à prendre en compte.",
    "Välj områden vi bör ta hänsyn till.",
    "Velg områder vi bør ta hensyn til.",
    "Vælg områder, vi bør tage hensyn til.",
    "Kies gebieden om rekening mee te houden.",
    "Selecciona las zonas que debamos tener en cuenta.",
    "Seleziona le zone da considerare."
  ],
  "Pick up where you left off.": [
    "Mach dort weiter, wo du aufgehört hast.",
    "Reprenez là où vous en étiez.",
    "Fortsätt där du slutade.",
    "Fortsett der du slapp.",
    "Fortsæt, hvor du slap.",
    "Ga verder waar je gebleven was.",
    "Continúa donde lo dejaste.",
    "Riprendi da dove avevi lasciato."
  ],
  "Save your setup and keep going.": [
    "Speichere deine Angaben und mach weiter.",
    "Enregistrez vos choix et continuez.",
    "Spara dina val och fortsätt.",
    "Lagre valgene dine og fortsett.",
    "Gem dine valg og fortsæt.",
    "Sla je keuzes op en ga verder.",
    "Guarda tu configuración y continúa.",
    "Salva le tue scelte e continua."
  ],
  "Build muscle": [
    "Muskelaufbau",
    "Prendre du muscle",
    "Bygga muskler",
    "Bygge muskler",
    "Opbygge muskler",
    "Spieren opbouwen",
    "Ganar músculo",
    "Aumentare la massa muscolare"
  ],
  "Lose body fat": [
    "Körperfett abbauen",
    "Réduire la masse grasse",
    "Minska kroppsfett",
    "Redusere kroppsfett",
    "Reducere kropsfedt",
    "Lichaamsvet verliezen",
    "Reducir grasa corporal",
    "Ridurre il grasso corporeo"
  ],
  "Build consistency": [
    "Eine Routine aufbauen",
    "Créer une routine",
    "Skapa en rutin",
    "Bygge en rutine",
    "Skabe en rutine",
    "Een routine opbouwen",
    "Crear una rutina",
    "Creare una routine"
  ],
  "Train smarter.\nGet stronger.": [
    "Trainiere smarter.\nWerde stärker.",
    "Entraînez-vous mieux.\nDevenez plus fort.",
    "Träna smartare.\nBli starkare.",
    "Tren smartere.\nBli sterkere.",
    "Træn smartere.\nBliv stærkere.",
    "Train slimmer.\nWord sterker.",
    "Entrena mejor.\nGana fuerza.",
    "Allenati meglio.\nDiventa più forte."
  ],
  "Log in": [
    "Anmelden",
    "Se connecter",
    "Logga in",
    "Logg inn",
    "Log ind",
    "Inloggen",
    "Iniciar sesión",
    "Accedi"
  ],
};
String? onboardingConversationTranslation(String locale, String text) {
  final index = _locales.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
