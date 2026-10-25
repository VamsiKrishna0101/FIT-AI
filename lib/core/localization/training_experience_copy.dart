// New UI copy, separate from the generated catalogue translations.
const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
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
