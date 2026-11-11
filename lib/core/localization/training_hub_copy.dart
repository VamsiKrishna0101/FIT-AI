const _languages = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  'Generate plan': [
    'Plan erstellen',
    'Générer un programme',
    'Skapa plan',
    'Generer plan',
    'Generer plan',
    'Plan genereren',
    'Generar plan',
    'Genera programma'
  ],
  'Generating your plan…': [
    'Plan wird erstellt…',
    'Programme en cours de création…',
    'Planen skapas…',
    'Planen genereres…',
    'Planen genereres…',
    'Plan wordt gemaakt…',
    'Generando tu plan…',
    'Programma in creazione…'
  ],
  'No plan generated': [
    'Kein Plan erstellt',
    'Aucun programme généré',
    'Ingen plan skapad',
    'Ingen plan generert',
    'Ingen plan genereret',
    'Geen plan gegenereerd',
    'Ningún plan generado',
    'Nessun programma generato'
  ],
  'Or add exercise manually': [
    'Oder Übung manuell hinzufügen',
    'Ou ajouter un exercice manuellement',
    'Eller lägg till övning manuellt',
    'Eller legg til øvelse manuelt',
    'Eller tilføj øvelse manuelt',
    'Of voeg oefening handmatig toe',
    'O añadir ejercicio manualmente',
    'Oppure aggiungi esercizio manualmente'
  ],
  'Why this plan': [
    'Warum dieser Plan',
    'Pourquoi ce programme',
    'Varför detta program',
    'Hvorfor denne planen',
    'Hvorfor denne plan',
    'Waarom dit plan',
    'Por qué este plan',
    'Perché questo piano'
  ],
  '{count} steps': [
    '{count} Schritte',
    '{count} étapes',
    '{count} steg',
    '{count} trinn',
    '{count} trin',
    '{count} stappen',
    '{count} pasos',
    '{count} passaggi'
  ],
  'Before you begin': [
    'Bevor du beginnst',
    'Avant de commencer',
    'Innan du börjar',
    'Før du begynner',
    'Før du begynder',
    'Voordat je begint',
    'Antes de empezar',
    'Prima di iniziare'
  ],
  '{count} workout': [
    '{count} Workout',
    '{count} séance',
    '{count} pass',
    '{count} økt',
    '{count} træningspas',
    '{count} training',
    '{count} entrenamiento',
    '{count} allenamento'
  ],
  '{count} workouts': [
    '{count} Workouts',
    '{count} séances',
    '{count} pass',
    '{count} økter',
    '{count} træningspas',
    '{count} trainingen',
    '{count} entrenamientos',
    '{count} allenamenti'
  ],
  '{count} rest day': [
    '{count} Ruhetag',
    '{count} jour de repos',
    '{count} vilodag',
    '{count} hviledag',
    '{count} hviledag',
    '{count} rustdag',
    '{count} día de descanso',
    '{count} giorno di riposo'
  ],
  '{count} rest days': [
    '{count} Ruhetage',
    '{count} jours de repos',
    '{count} vilodagar',
    '{count} hviledager',
    '{count} hviledage',
    '{count} rustdagen',
    '{count} días de descanso',
    '{count} giorni di riposo'
  ],
  '{completed} of {total} complete': [
    '{completed} von {total} abgeschlossen',
    '{completed} sur {total} terminées',
    '{completed} av {total} klara',
    '{completed} av {total} fullført',
    '{completed} af {total} fuldført',
    '{completed} van {total} voltooid',
    '{completed} de {total} completados',
    '{completed} di {total} completati'
  ],
  'Active plan': [
    'Aktiver Plan',
    'Programme actif',
    'Aktivt program',
    'Aktiv plan',
    'Aktiv plan',
    'Actief plan',
    'Plan activo',
    'Piano attivo'
  ],
  'Archived plan': [
    'Archivierter Plan',
    'Programme archivé',
    'Arkiverat program',
    'Arkivert plan',
    'Arkiveret plan',
    'Gearchiveerd plan',
    'Plan archivado',
    'Piano archiviato'
  ],
  'Saved plan': [
    'Gespeicherter Plan',
    'Programme enregistré',
    'Sparat program',
    'Lagret plan',
    'Gemt plan',
    'Opgeslagen plan',
    'Plan guardado',
    'Piano salvato'
  ],
  'About this plan': [
    'Über diesen Plan',
    'À propos de ce programme',
    'Om detta program',
    'Om denne planen',
    'Om denne plan',
    'Over dit plan',
    'Acerca de este plan',
    'Informazioni sul piano'
  ],
  'Saved to My workouts': [
    'In Meine Workouts gespeichert',
    'Enregistré dans Mes séances',
    'Sparat i Mina pass',
    'Lagret i Mine økter',
    'Gemt i Mine træningspas',
    'Opgeslagen in Mijn trainingen',
    'Guardado en Mis entrenamientos',
    'Salvato in I miei allenamenti'
  ],
  'Not started': [
    'Nicht begonnen',
    'Non commencé',
    'Inte påbörjat',
    'Ikke startet',
    'Ikke startet',
    'Niet gestart',
    'Sin empezar',
    'Non iniziato'
  ],
  "Save to My workouts": [
    "In Meine Workouts speichern",
    "Enregistrer dans Mes séances",
    "Spara i Mina pass",
    "Lagre i Mine økter",
    "Gem i Mine træningspas",
    "Bewaren in Mijn trainingen",
    "Guardar en Mis entrenamientos",
    "Salva in I miei allenamenti"
  ],
  "Details": [
    "Details",
    "Détails",
    "Detaljer",
    "Detaljer",
    "Detaljer",
    "Details",
    "Detalles",
    "Dettagli"
  ],
  '{count} saved workout': [
    '{count} gespeichertes Workout',
    '{count} séance enregistrée',
    '{count} sparat pass',
    '{count} lagret økt',
    '{count} gemt træningspas',
    '{count} opgeslagen training',
    '{count} entrenamiento guardado',
    '{count} allenamento salvato'
  ],
  '{count} exercise': [
    '{count} Übung',
    '{count} exercice',
    '{count} övning',
    '{count} øvelse',
    '{count} øvelse',
    '{count} oefening',
    '{count} ejercicio',
    '{count} esercizio'
  ],
  'My workouts': [
    'Meine Workouts',
    'Mes séances',
    'Mina pass',
    'Mine økter',
    'Mine træningspas',
    'Mijn trainingen',
    'Mis entrenamientos',
    'I miei allenamenti'
  ],
  'Create workout': [
    'Workout erstellen',
    'Créer une séance',
    'Skapa pass',
    'Opprett økt',
    'Opret træningspas',
    'Training maken',
    'Crear entrenamiento',
    'Crea allenamento'
  ],
  'Save workout': [
    'Workout speichern',
    'Enregistrer la séance',
    'Spara pass',
    'Lagre økt',
    'Gem træningspas',
    'Training opslaan',
    'Guardar entrenamiento',
    'Salva allenamento'
  ],
  'Workout options': [
    'Workout-Optionen',
    'Options de la séance',
    'Passalternativ',
    'Øktalternativer',
    'Træningsmuligheder',
    'Trainingsopties',
    'Opciones del entrenamiento',
    'Opzioni allenamento'
  ],
  'Exercise library': [
    'Übungsbibliothek',
    'Bibliothèque d’exercices',
    'Övningsbibliotek',
    'Øvelsesbibliotek',
    'Øvelsesbibliotek',
    'Oefeningenbibliotheek',
    'Biblioteca de ejercicios',
    'Libreria esercizi'
  ],
  'Create your first workout': [
    'Erstelle dein erstes Workout',
    'Créez votre première séance',
    'Skapa ditt första pass',
    'Opprett din første økt',
    'Opret dit første træningspas',
    'Maak je eerste training',
    'Crea tu primer entrenamiento',
    'Crea il tuo primo allenamento'
  ],
  '{count} saved workouts': [
    '{count} gespeicherte Workouts',
    '{count} séances enregistrées',
    '{count} sparade pass',
    '{count} lagrede økter',
    '{count} gemte træningspas',
    '{count} opgeslagen trainingen',
    '{count} entrenamientos guardados',
    '{count} allenamenti salvati'
  ],
  'Workout name': [
    'Workout-Name',
    'Nom de la séance',
    'Passets namn',
    'Øktnavn',
    'Navn på træningspas',
    'Trainingsnaam',
    'Nombre del entrenamiento',
    'Nome allenamento'
  ],
  'e.g. Push day': [
    'z. B. Push-Tag',
    'ex. séance poussée',
    't.ex. presspass',
    'f.eks. pressøkt',
    'f.eks. presdag',
    'bijv. pushdag',
    'p. ej. día de empuje',
    'es. giorno di spinta'
  ],
  'Enter a workout name.': [
    'Gib einen Workout-Namen ein.',
    'Saisissez un nom de séance.',
    'Ange ett namn på passet.',
    'Skriv inn et øktnavn.',
    'Angiv et navn på træningspasset.',
    'Voer een trainingsnaam in.',
    'Introduce un nombre.',
    'Inserisci un nome per l’allenamento.'
  ],
  'Add at least one exercise.': [
    'Füge mindestens eine Übung hinzu.',
    'Ajoutez au moins un exercice.',
    'Lägg till minst en övning.',
    'Legg til minst én øvelse.',
    'Tilføj mindst én øvelse.',
    'Voeg minstens één oefening toe.',
    'Añade al menos un ejercicio.',
    'Aggiungi almeno un esercizio.'
  ],
  'Your workouts, ready to repeat': [
    'Deine Workouts zum Wiederholen',
    'Vos séances, prêtes à refaire',
    'Dina pass, redo att upprepa',
    'Dine økter, klare til å gjentas',
    'Dine træningspas, klar til gentagelse',
    'Je trainingen, klaar om te herhalen',
    'Tus entrenamientos, listos para repetir',
    'I tuoi allenamenti, pronti da ripetere'
  ],
  'Save your exercises and sets once. Use them whenever you train.': [
    'Speichere deine Übungen und Sätze einmal und nutze sie bei jedem Training.',
    'Enregistrez vos exercices et séries pour les réutiliser à chaque séance.',
    'Spara övningar och set en gång och använd dem när du tränar.',
    'Lagre øvelser og sett én gang, og bruk dem når du trener.',
    'Gem øvelser og sæt én gang, og brug dem, når du træner.',
    'Sla oefeningen en sets op en gebruik ze bij elke training.',
    'Guarda tus ejercicios y series y reutilízalos cuando entrenes.',
    'Salva esercizi e serie e riutilizzali quando ti alleni.'
  ],
  'Manage': [
    'Verwalten',
    'Gérer',
    'Hantera',
    'Administrer',
    'Administrer',
    'Beheren',
    'Gestionar',
    'Gestisci'
  ],
  'Delete workout': [
    'Workout löschen',
    'Supprimer la séance',
    'Ta bort pass',
    'Slett økt',
    'Slet træningspas',
    'Training verwijderen',
    'Eliminar entrenamiento',
    'Elimina allenamento'
  ],
  'Delete workout?': [
    'Workout löschen?',
    'Supprimer la séance ?',
    'Ta bort pass?',
    'Slette økt?',
    'Slet træningspas?',
    'Training verwijderen?',
    '¿Eliminar entrenamiento?',
    'Eliminare allenamento?'
  ],
  'Use workout': [
    'Workout verwenden',
    'Utiliser cette séance',
    'Använd pass',
    'Bruk økt',
    'Brug træningspas',
    'Training gebruiken',
    'Usar entrenamiento',
    'Usa allenamento'
  ],
  'Planned': [
    'Geplant',
    'Prévu',
    'Planerat',
    'Planlagt',
    'Planlagt',
    'Gepland',
    'Planificado',
    'Pianificato'
  ],
};

String? trainingHubTranslation(String locale, String text) {
  final index = _languages.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
