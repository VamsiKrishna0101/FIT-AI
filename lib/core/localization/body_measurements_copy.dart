const _languages = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "Time range": [
    "Zeitraum",
    "Période",
    "Tidsperiod",
    "Tidsperiode",
    "Tidsperiode",
    "Periode",
    "Período",
    "Periodo"
  ],
  "Choose dates": [
    "Datum auswählen",
    "Choisir des dates",
    "Välj datum",
    "Velg datoer",
    "Vælg datoer",
    "Kies datums",
    "Elegir fechas",
    "Scegli le date"
  ],
  "This month": [
    "Dieser Monat",
    "Ce mois-ci",
    "Denna månad",
    "Denne måneden",
    "Denne måned",
    "Deze maand",
    "Este mes",
    "Questo mese"
  ],
  "Month": ["Monat", "Mois", "Månad", "Måned", "Måned", "Maand", "Mes", "Mese"],
  "Year": ["Jahr", "Année", "År", "År", "År", "Jaar", "Año", "Anno"],
  "Select a day to choose its week.": [
    "Wähle einen Tag, um die Woche auszuwählen.",
    "Sélectionnez un jour pour choisir sa semaine.",
    "Välj en dag för att välja dess vecka.",
    "Velg en dag for å velge uken.",
    "Vælg en dag for at vælge dens uge.",
    "Selecteer een dag om de week te kiezen.",
    "Selecciona un día para elegir su semana.",
    "Seleziona un giorno per scegliere la settimana."
  ],
  "Sets per muscle": [
    "Sätze pro Muskel",
    "Séries par muscle",
    "Set per muskel",
    "Sett per muskel",
    "Sæt per muskel",
    "Sets per spier",
    "Series por músculo",
    "Serie per muscolo"
  ],
  "{count}+ sets": [
    "{count}+ Sätze",
    "{count}+ séries",
    "{count}+ set",
    "{count}+ sett",
    "{count}+ sæt",
    "{count}+ sets",
    "{count}+ series",
    "{count}+ serie"
  ],
  "An exercise can work more than one muscle.": [
    "Eine Übung kann mehrere Muskeln beanspruchen.",
    "Un exercice peut solliciter plusieurs muscles.",
    "En övning kan träna flera muskler.",
    "En øvelse kan jobbe med flere muskler.",
    "En øvelse kan træne flere muskler.",
    "Een oefening kan meerdere spieren trainen.",
    "Un ejercicio puede trabajar varios músculos.",
    "Un esercizio può coinvolgere più muscoli."
  ],
  "{count} set": [
    "{count} Satz",
    "{count} série",
    "{count} set",
    "{count} sett",
    "{count} sæt",
    "{count} set",
    "{count} serie",
    "{count} serie"
  ],
  "Sets involving each muscle": [
    "Sätze mit Beteiligung des Muskels",
    "Séries sollicitant chaque muscle",
    "Set som involverar varje muskel",
    "Sett som involverer hver muskel",
    "Sæt der involverer hver muskel",
    "Sets waarbij elke spier meewerkt",
    "Series que trabajan cada músculo",
    "Serie che coinvolgono ogni muscolo"
  ],
  "Sets involving this muscle": [
    "Sätze mit Beteiligung dieses Muskels",
    "Séries sollicitant ce muscle",
    "Set som involverar denna muskel",
    "Sett som involverer denne muskelen",
    "Sæt der involverer denne muskel",
    "Sets waarbij deze spier meewerkt",
    "Series que trabajan este músculo",
    "Serie che coinvolgono questo muscolo"
  ],
  "{count} focused on this muscle": [
    "{count} gezielt für diesen Muskel",
    "{count} ciblant ce muscle",
    "{count} med fokus på muskeln",
    "{count} med fokus på denne muskelen",
    "{count} med fokus på denne muskel",
    "{count} gericht op deze spier",
    "{count} centradas en este músculo",
    "{count} mirate a questo muscolo"
  ],
  "{count} where this muscle helped": [
    "{count} mit unterstützender Beteiligung",
    "{count} où ce muscle a aidé",
    "{count} där muskeln hjälpte till",
    "{count} der muskelen hjalp til",
    "{count} hvor musklen hjalp til",
    "{count} waarbij deze spier hielp",
    "{count} donde este músculo ayudó",
    "{count} in cui questo muscolo ha aiutato"
  ],
  "Focused here": [
    "Hier gezielt trainiert",
    "Muscle ciblé",
    "Fokus här",
    "Fokus her",
    "Fokus her",
    "Hierop gericht",
    "Foco principal",
    "Muscolo principale"
  ],
  "Also worked here": [
    "Hier ebenfalls beteiligt",
    "Également sollicité",
    "Arbetade också här",
    "Jobbet også her",
    "Arbejdede også her",
    "Werkte ook mee",
    "También trabajado",
    "Coinvolto anche qui"
  ],
  "{first}–{last} sets": [
    "{first}–{last} Sätze",
    "{first}–{last} séries",
    "{first}–{last} set",
    "{first}–{last} sett",
    "{first}–{last} sæt",
    "{first}–{last} sets",
    "{first}–{last} series",
    "{first}–{last} serie"
  ],
  "Muscles worked: {muscles} · Active days: {sessions}": [
    "Trainierte Muskeln: {muscles} · Trainingstage: {sessions}",
    "Muscles sollicités : {muscles} · Jours actifs : {sessions}",
    "Tränade muskler: {muscles} · Aktiva dagar: {sessions}",
    "Muskler jobbet: {muscles} · Aktive dager: {sessions}",
    "Trænede muskler: {muscles} · Aktive dage: {sessions}",
    "Getrainde spieren: {muscles} · Actieve dagen: {sessions}",
    "Músculos trabajados: {muscles} · Días activos: {sessions}",
    "Muscoli coinvolti: {muscles} · Giorni attivi: {sessions}"
  ],
  "Muscles: {muscles} · Training days: {sessions}": [
    "Muskeln: {muscles} · Trainingstage: {sessions}",
    "Muscles : {muscles} · Jours d’entraînement : {sessions}",
    "Muskler: {muscles} · Träningsdagar: {sessions}",
    "Muskler: {muscles} · Treningsdager: {sessions}",
    "Muskler: {muscles} · Træningsdage: {sessions}",
    "Spieren: {muscles} · Trainingsdagen: {sessions}",
    "Músculos: {muscles} · Días de entrenamiento: {sessions}",
    "Muscoli: {muscles} · Giorni di allenamento: {sessions}"
  ],
  "Training dates": [
    "Trainingstage",
    "Dates d’entraînement",
    "Träningsdatum",
    "Treningsdatoer",
    "Træningsdatoer",
    "Trainingsdatums",
    "Fechas de entrenamiento",
    "Date di allenamento"
  ],
  "Single day": [
    "Einzelner Tag",
    "Un jour",
    "En dag",
    "Én dag",
    "En dag",
    "Eén dag",
    "Un día",
    "Un giorno"
  ],
  "Multiple days": [
    "Mehrere Tage",
    "Plusieurs jours",
    "Flera dagar",
    "Flere dager",
    "Flere dage",
    "Meerdere dagen",
    "Varios días",
    "Più giorni"
  ],
  "Date range": [
    "Zeitraum",
    "Période",
    "Datumintervall",
    "Datointervall",
    "Datointerval",
    "Datumbereik",
    "Intervalo de fechas",
    "Intervallo di date"
  ],
  "{count} days": [
    "{count} Tage",
    "{count} jours",
    "{count} dagar",
    "{count} dager",
    "{count} dage",
    "{count} dagen",
    "{count} días",
    "{count} giorni"
  ],
  "{muscles} muscles · {sessions} training days": [
    "{muscles} Muskeln · {sessions} Trainingstage",
    "{muscles} muscles · {sessions} jours d’entraînement",
    "{muscles} muskler · {sessions} träningsdagar",
    "{muscles} muskler · {sessions} treningsdager",
    "{muscles} muskler · {sessions} træningsdage",
    "{muscles} spieren · {sessions} trainingsdagen",
    "{muscles} músculos · {sessions} días de entrenamiento",
    "{muscles} muscoli · {sessions} giorni di allenamento"
  ],
  "Exercises performed": [
    "Ausgeführte Übungen",
    "Exercices effectués",
    "Utförda övningar",
    "Utførte øvelser",
    "Udførte øvelser",
    "Uitgevoerde oefeningen",
    "Ejercicios realizados",
    "Esercizi eseguiti"
  ],
  "Planned exercises": [
    "Geplante Übungen",
    "Exercices prévus",
    "Planerade övningar",
    "Planlagte øvelser",
    "Planlagte øvelser",
    "Geplande oefeningen",
    "Ejercicios planificados",
    "Esercizi previsti"
  ],
  "No exercises logged for these dates.": [
    "Für diese Tage sind keine Übungen erfasst.",
    "Aucun exercice enregistré à ces dates.",
    "Inga övningar loggade för dessa datum.",
    "Ingen øvelser loggført for disse datoene.",
    "Ingen øvelser registreret for disse datoer.",
    "Geen oefeningen gelogd voor deze datums.",
    "No hay ejercicios registrados en estas fechas.",
    "Nessun esercizio registrato per queste date."
  ],
  "Last trained · {date}": [
    "Zuletzt trainiert · {date}",
    "Dernier entraînement · {date}",
    "Senast tränad · {date}",
    "Sist trent · {date}",
    "Sidst trænet · {date}",
    "Laatst getraind · {date}",
    "Último entrenamiento · {date}",
    "Ultimo allenamento · {date}"
  ],
  "Last · {reading}": [
    "Zuletzt · {reading}",
    "Dernière mesure · {reading}",
    "Senast · {reading}",
    "Sist · {reading}",
    "Senest · {reading}",
    "Vorige · {reading}",
    "Anterior · {reading}",
    "Ultima · {reading}"
  ],
  "Plan": [
    "Plan",
    "Programme",
    "Plan",
    "Plan",
    "Plan",
    "Plan",
    "Plan",
    "Piano"
  ],
  "Logged": [
    "Erfasst",
    "Enregistré",
    "Loggat",
    "Loggført",
    "Registreret",
    "Gelogd",
    "Registrado",
    "Registrato"
  ],
  "Choose week": [
    "Woche wählen",
    "Choisir une semaine",
    "Välj vecka",
    "Velg uke",
    "Vælg uge",
    "Kies week",
    "Elegir semana",
    "Scegli settimana"
  ],
  "{count} sets planned": [
    "{count} Sätze geplant",
    "{count} séries prévues",
    "{count} planerade set",
    "{count} planlagte sett",
    "{count} planlagte sæt",
    "{count} sets gepland",
    "{count} series planificadas",
    "{count} serie previste"
  ],
  "{count} sets logged": [
    "{count} Sätze erfasst",
    "{count} séries enregistrées",
    "{count} loggade set",
    "{count} loggførte sett",
    "{count} registrerede sæt",
    "{count} sets gelogd",
    "{count} series registradas",
    "{count} serie registrate"
  ],
  "{done} of {total} sets completed": [
    "{done} von {total} Sätzen geschafft",
    "{done} séries sur {total} terminées",
    "{done} av {total} set klara",
    "{done} av {total} sett fullført",
    "{done} af {total} sæt gennemført",
    "{done} van {total} sets voltooid",
    "{done} de {total} series completadas",
    "{done} serie su {total} completate"
  ],
  "{done} direct sets logged": [
    "{done} direkte Sätze erfasst",
    "{done} séries directes enregistrées",
    "{done} direkta set loggade",
    "{done} direkte sett loggført",
    "{done} direkte sæt registreret",
    "{done} directe sets gelogd",
    "{done} series directas registradas",
    "{done} serie dirette registrate"
  ],
  "{count} assisting sets": [
    "{count} unterstützende Sätze",
    "{count} séries en assistance",
    "{count} assisterande set",
    "{count} assisterende sett",
    "{count} assisterende sæt",
    "{count} ondersteunende sets",
    "{count} series de asistencia",
    "{count} serie di supporto"
  ],
  "No exercises planned for this muscle.": [
    "Keine Übungen für diesen Muskel geplant.",
    "Aucun exercice prévu pour ce muscle.",
    "Inga övningar planerade för muskeln.",
    "Ingen øvelser planlagt for denne muskelen.",
    "Ingen øvelser planlagt til denne muskel.",
    "Geen oefeningen gepland voor deze spier.",
    "No hay ejercicios planificados para este músculo.",
    "Nessun esercizio previsto per questo muscolo."
  ],
  "No plan for this week": [
    "Kein Plan für diese Woche",
    "Aucun programme cette semaine",
    "Ingen plan för den här veckan",
    "Ingen plan for denne uken",
    "Ingen plan for denne uge",
    "Geen plan voor deze week",
    "Sin plan para esta semana",
    "Nessun piano per questa settimana"
  ],
  "Create plan": [
    "Plan erstellen",
    "Créer un programme",
    "Skapa plan",
    "Lag plan",
    "Opret plan",
    "Plan maken",
    "Crear plan",
    "Crea piano"
  ],
  "Logged sets · {count}": [
    "Erfasste Sätze · {count}",
    "Séries enregistrées · {count}",
    "Loggade set · {count}",
    "Loggførte sett · {count}",
    "Registrerede sæt · {count}",
    "Gelogde sets · {count}",
    "Series registradas · {count}",
    "Serie registrate · {count}"
  ],
  "Muscle map": [
    "Muskelkarte",
    "Carte musculaire",
    "Muskelkarta",
    "Muskelkart",
    "Muskelkort",
    "Spierkaart",
    "Mapa muscular",
    "Mappa muscolare"
  ],
  "Trained": [
    "Trainiert",
    "Entraînés",
    "Tränade",
    "Trente",
    "Trænet",
    "Getraind",
    "Entrenados",
    "Allenati"
  ],
  "No logged sets": [
    "Keine Sätze erfasst",
    "Aucune série enregistrée",
    "Inga loggade set",
    "Ingen loggførte sett",
    "Ingen registrerede sæt",
    "Geen sets gelogd",
    "Sin series registradas",
    "Nessuna serie registrata"
  ],
  "{muscles} muscles · {sets} sets": [
    "{muscles} Muskeln · {sets} Sätze",
    "{muscles} muscles · {sets} séries",
    "{muscles} muskler · {sets} set",
    "{muscles} muskler · {sets} sett",
    "{muscles} muskler · {sets} sæt",
    "{muscles} spieren · {sets} sets",
    "{muscles} músculos · {sets} series",
    "{muscles} muscoli · {sets} serie"
  ],
  "Retry training data": [
    "Trainingsdaten erneut laden",
    "Recharger les données",
    "Ladda träningsdata igen",
    "Last treningsdata på nytt",
    "Indlæs træningsdata igen",
    "Trainingsgegevens opnieuw laden",
    "Cargar datos de nuevo",
    "Ricarica i dati"
  ],
  "Training data is unavailable. Please retry.": [
    "Trainingsdaten nicht verfügbar. Bitte erneut versuchen.",
    "Données indisponibles. Réessayez.",
    "Träningsdata saknas. Försök igen.",
    "Treningsdata er utilgjengelig. Prøv igjen.",
    "Træningsdata er utilgængelige. Prøv igen.",
    "Trainingsgegevens niet beschikbaar. Probeer opnieuw.",
    "Datos no disponibles. Inténtalo de nuevo.",
    "Dati non disponibili. Riprova."
  ],
  "View workouts": [
    "Workouts ansehen",
    "Voir les séances",
    "Visa träningspass",
    "Vis treningsøkter",
    "Se træningspas",
    "Trainingen bekijken",
    "Ver entrenamientos",
    "Vedi allenamenti"
  ],
  "Your measurements": [
    "Deine Maße",
    "Vos mesures",
    "Dina mått",
    "Dine mål",
    "Dine mål",
    "Je metingen",
    "Tus medidas",
    "Le tue misure"
  ],
  "Your progress": [
    "Dein Fortschritt",
    "Vos progrès",
    "Din utveckling",
    "Din fremgang",
    "Din fremgang",
    "Je voortgang",
    "Tu progreso",
    "I tuoi progressi"
  ],
  "Measurement history": [
    "Messverlauf",
    "Historique des mesures",
    "Mäthistorik",
    "Målehistorikk",
    "Målehistorik",
    "Meetgeschiedenis",
    "Historial de medidas",
    "Cronologia misure"
  ],
  "Start with your baseline": [
    "Erfasse deine Ausgangswerte",
    "Enregistrez vos mesures de départ",
    "Börja med dina startmått",
    "Start med utgangsmålene dine",
    "Start med dine udgangsmål",
    "Begin met je startmetingen",
    "Registra tus medidas iniciales",
    "Registra le misure iniziali"
  ],
  "Add your measurements before creating your plan.": [
    "Erfasse deine Maße, bevor du deinen Plan erstellst.",
    "Ajoutez vos mesures avant de créer votre programme.",
    "Lägg till dina mått innan du skapar din plan.",
    "Legg til målene dine før du lager planen.",
    "Tilføj dine mål, før du opretter din plan.",
    "Voeg je metingen toe voordat je je plan maakt.",
    "Añade tus medidas antes de crear tu plan.",
    "Aggiungi le misure prima di creare il piano."
  ],
  "First measurement saved": [
    "Erster Messwert gespeichert",
    "Première mesure enregistrée",
    "Första mätningen sparad",
    "Første måling lagret",
    "Første måling gemt",
    "Eerste meting opgeslagen",
    "Primera medida guardada",
    "Prima misura salvata"
  ],
  "Add a reading to start": [
    "Ersten Messwert hinzufügen",
    "Ajoutez une première mesure",
    "Lägg till ett första mått",
    "Legg til en første måling",
    "Tilføj en første måling",
    "Voeg je eerste meting toe",
    "Añade tu primera medida",
    "Aggiungi la prima misura"
  ],
  "Your next reading will show your change.": [
    "Dein nächster Messwert zeigt die Veränderung.",
    "La prochaine mesure montrera votre évolution.",
    "Nästa mätning visar din förändring.",
    "Neste måling viser endringen din.",
    "Din næste måling viser din ændring.",
    "Je volgende meting laat je verandering zien.",
    "Tu próxima medida mostrará el cambio.",
    "La prossima misura mostrerà il cambiamento."
  ],
  "Update measurements": [
    "Maße aktualisieren",
    "Actualiser les mesures",
    "Uppdatera mått",
    "Oppdater mål",
    "Opdater mål",
    "Metingen bijwerken",
    "Actualizar medidas",
    "Aggiorna misure"
  ],
  "All measurements": [
    "Alle Maße",
    "Toutes les mesures",
    "Alla mått",
    "Alle mål",
    "Alle mål",
    "Alle metingen",
    "Todas las medidas",
    "Tutte le misure"
  ],
  "No reading yet": [
    "Noch kein Messwert",
    "Aucune mesure",
    "Inget mått ännu",
    "Ingen måling ennå",
    "Ingen måling endnu",
    "Nog geen meting",
    "Sin medidas aún",
    "Nessuna misura"
  ],
  "Baseline saved": [
    "Ausgangswert gespeichert",
    "Mesure de départ enregistrée",
    "Startmått sparat",
    "Utgangsmål lagret",
    "Udgangsmål gemt",
    "Startmeting opgeslagen",
    "Medida inicial guardada",
    "Misura iniziale salvata"
  ],
  "Ready when you are": [
    "Bereit, wenn du es bist",
    "À votre rythme",
    "När du är redo",
    "Når du er klar",
    "Når du er klar",
    "Wanneer jij klaar bent",
    "Cuando quieras",
    "Quando vuoi"
  ],
  "Since": [
    "Seit",
    "Depuis",
    "Sedan",
    "Siden",
    "Siden",
    "Sinds",
    "Desde",
    "Dal"
  ],
  "Complete your baseline": [
    "Ausgangswerte vervollständigen",
    "Complétez vos mesures de départ",
    "Fyll i dina startmått",
    "Fullfør utgangsmålene dine",
    "Udfyld dine udgangsmål",
    "Vul je startmetingen aan",
    "Completa tus medidas iniciales",
    "Completa le misure iniziali"
  ],
  "Complete your measurements": [
    "Maße vervollständigen",
    "Complétez vos mesures",
    "Fyll i dina mått",
    "Fullfør målene dine",
    "Udfyld dine mål",
    "Vul je metingen aan",
    "Completa tus medidas",
    "Completa le tue misure"
  ],
  "A new check-in": [
    "Neue Messung",
    "Une nouvelle mesure",
    "En ny mätning",
    "En ny måling",
    "En ny måling",
    "Een nieuwe meting",
    "Una nueva medición",
    "Una nuova misurazione"
  ],
  "Add the missing measurements to create your plan.": [
    "Ergänze die fehlenden Maße für deinen Plan.",
    "Ajoutez les mesures manquantes pour créer votre programme.",
    "Lägg till måtten som saknas för att skapa din plan.",
    "Legg til manglende mål for å lage planen.",
    "Tilføj de manglende mål for at oprette din plan.",
    "Vul de ontbrekende metingen in om je plan te maken.",
    "Añade las medidas que faltan para crear tu plan.",
    "Aggiungi le misure mancanti per creare il piano."
  ],
  "Record what you measured today.": [
    "Trage deine heutigen Messwerte ein.",
    "Enregistrez vos mesures du jour.",
    "Spara det du mätte idag.",
    "Registrer det du målte i dag.",
    "Registrer det, du målte i dag.",
    "Noteer wat je vandaag hebt gemeten.",
    "Registra lo que has medido hoy.",
    "Registra le misure di oggi."
  ],
  "Required for your plan": [
    "Für deinen Plan erforderlich",
    "Requis pour votre programme",
    "Krävs för din plan",
    "Kreves for planen din",
    "Påkrævet til din plan",
    "Nodig voor je plan",
    "Necesario para tu plan",
    "Richiesto per il piano"
  ],
  "Already saved · update when measured": [
    "Bereits erfasst · bei neuer Messung ändern",
    "Déjà enregistré · actualisez après mesure",
    "Redan sparat · uppdatera vid mätning",
    "Allerede lagret · oppdater ved måling",
    "Allerede gemt · opdater ved måling",
    "Al opgeslagen · bijwerken na meting",
    "Ya guardado · actualiza al medir",
    "Già salvato · aggiorna dopo la misurazione"
  ],
  "From your scale": [
    "Von deiner Waage",
    "Sur votre balance",
    "Från din våg",
    "Fra vekten din",
    "Fra din vægt",
    "Van je weegschaal",
    "De tu báscula",
    "Dalla bilancia"
  ],
  "Tape around your waist": [
    "Maßband um die Taille",
    "Mètre ruban autour de la taille",
    "Måttband runt midjan",
    "Målebånd rundt midjen",
    "Målebånd rundt taljen",
    "Meetlint rond je taille",
    "Cinta alrededor de la cintura",
    "Metro intorno alla vita"
  ],
  "More measurements": [
    "Weitere Maße",
    "Autres mesures",
    "Fler mått",
    "Flere mål",
    "Flere mål",
    "Meer metingen",
    "Más medidas",
    "Altre misure"
  ],
  "Edit measurements": [
    "Maße bearbeiten",
    "Modifier les mesures",
    "Redigera mått",
    "Rediger mål",
    "Rediger mål",
    "Metingen bewerken",
    "Editar medidas",
    "Modifica misure"
  ],
  "No measurements yet": [
    "Noch keine Maße",
    "Aucune mesure enregistrée",
    "Inga mått ännu",
    "Ingen mål ennå",
    "Ingen mål endnu",
    "Nog geen metingen",
    "Aún no hay medidas",
    "Nessuna misura registrata"
  ],
  "Muscles trained": [
    "Trainierte Muskeln",
    "Muscles entraînés",
    "Tränade muskler",
    "Trente muskler",
    "Trænede muskler",
    "Getrainde spieren",
    "Músculos entrenados",
    "Muscoli allenati"
  ],
  "What do I need for my plan?": [
    "Was brauche ich für meinen Plan?",
    "Que faut-il pour mon programme ?",
    "Vad behövs för min plan?",
    "Hva trenger jeg til planen?",
    "Hvad skal jeg bruge til min plan?",
    "Wat heb ik nodig voor mijn plan?",
    "¿Qué necesito para mi plan?",
    "Cosa serve per il mio piano?"
  ],
  "Complete your height, weight and waist measurements before creating a plan.":
      [
    "Erfasse Größe, Gewicht und Taillenumfang, bevor du einen Plan erstellst.",
    "Renseignez votre taille, poids et tour de taille avant de créer un programme.",
    "Fyll i längd, vikt och midjemått innan du skapar en plan.",
    "Fyll inn høyde, vekt og midjemål før du lager en plan.",
    "Udfyld højde, vægt og taljemål, før du opretter en plan.",
    "Vul je lengte, gewicht en tailleomtrek in voordat je een plan maakt.",
    "Indica tu altura, peso y cintura antes de crear un plan.",
    "Inserisci altezza, peso e circonferenza vita prima di creare un piano."
  ]
};

String? bodyMeasurementsTranslation(String locale, String text) {
  final index = _languages.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
