// New UI copy, separate from the generated catalogue translations.
const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  'Set': ['Satz', 'Série', 'Set', 'Sett', 'Sæt', 'Set', 'Serie', 'Serie'],
  'Target (kg)': [
    'Ziel (kg)',
    'Cible (kg)',
    'Mål (kg)',
    'Mål (kg)',
    'Mål (kg)',
    'Doel (kg)',
    'Objetivo (kg)',
    'Obiettivo (kg)'
  ],
  'Choose your working weight when you start.': [
    'Wähle dein Trainingsgewicht beim Start.',
    'Choisissez votre charge au début de la séance.',
    'Välj din arbetsvikt när du börjar.',
    'Velg arbeidsvekten når du starter.',
    'Vælg din træningsvægt, når du starter.',
    'Kies je trainingsgewicht wanneer je begint.',
    'Elige tu peso de trabajo al empezar.',
    'Scegli il peso di lavoro quando inizi.'
  ],
  'About {minutes} min': [
    'Ca. {minutes} Min.',
    'Env. {minutes} min',
    'Cirka {minutes} min',
    'Ca. {minutes} min',
    'Ca. {minutes} min',
    'Ongeveer {minutes} min',
    'Unos {minutes} min',
    'Circa {minutes} min'
  ],
  'Routine options': [
    'Routinenoptionen',
    'Options de la routine',
    'Rutinalternativ',
    'Rutinevalg',
    'Rutinevalg',
    'Routineopties',
    'Opciones de rutina',
    'Opzioni della routine'
  ],
  'Adding routine…': [
    'Routine wird hinzugefügt…',
    'Ajout de la routine…',
    'Lägger till rutin…',
    'Legger til rutine…',
    'Tilføjer rutine…',
    'Routine toevoegen…',
    'Añadiendo rutina…',
    'Aggiunta della routine…'
  ],
  'Discard changes?': [
    'Änderungen verwerfen?',
    'Abandonner les modifications ?',
    'Kasta ändringar?',
    'Forkaste endringene?',
    'Kassér ændringer?',
    'Wijzigingen verwerpen?',
    '¿Descartar los cambios?',
    'Scartare le modifiche?'
  ],
  'Your routine edits have not been saved.': [
    'Deine Änderungen an der Routine wurden nicht gespeichert.',
    'Les modifications de votre routine ne sont pas enregistrées.',
    'Dina rutinändringar har inte sparats.',
    'Rutineendringene dine er ikke lagret.',
    'Dine rutineændringer er ikke gemt.',
    'Je routinewijzigingen zijn niet opgeslagen.',
    'Los cambios de tu rutina no se han guardado.',
    'Le modifiche alla routine non sono state salvate.'
  ],
  'Keep editing': [
    'Weiter bearbeiten',
    'Continuer à modifier',
    'Fortsätt redigera',
    'Fortsett å redigere',
    'Fortsæt redigering',
    'Verder bewerken',
    'Seguir editando',
    'Continua a modificare'
  ],
  'Discard': [
    'Verwerfen',
    'Abandonner',
    'Kasta',
    'Forkast',
    'Kassér',
    'Verwerpen',
    'Descartar',
    'Scarta'
  ],
  'Training readiness': [
    'Trainingsbereitschaft',
    'Forme pour l’entraînement',
    'Träningsberedskap',
    'Treningsberedskap',
    'Træningsparathed',
    'Trainingsbereidheid',
    'Disposición para entrenar',
    'Prontezza per l’allenamento',
  ],
  'Targets are visible on the other side.': [
    'Die Zielmuskeln sind auf der anderen Seite sichtbar.',
    'Les muscles ciblés sont visibles de l’autre côté.',
    'Målmusklerna syns på andra sidan.',
    'Målmusklene er synlige på den andre siden.',
    'Målmusklerne er synlige på den anden side.',
    'De doelspieren zijn aan de andere kant zichtbaar.',
    'Los músculos objetivo se ven por el otro lado.',
    'I muscoli interessati sono visibili dall’altro lato.',
  ],
};
String? trainingExperienceTranslation(String locale, String source) {
  final index = _locales.indexOf(locale);
  final row = _copy[source];
  return index < 0 || row == null ? null : row[index];
}
