const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  'Recorded sleep': [
    'Erfasster Schlaf',
    'Sommeil enregistré',
    'Registrerad sömn',
    'Registrert søvn',
    'Registreret søvn',
    'Geregistreerde slaap',
    'Sueño registrado',
    'Sonno registrato'
  ],
  'Last 6 days': [
    'Letzte 6 Tage',
    '6 derniers jours',
    'Senaste 6 dagarna',
    'Siste 6 dager',
    'Seneste 6 dage',
    'Afgelopen 6 dagen',
    'Últimos 6 días',
    'Ultimi 6 giorni'
  ],
  'Calendar': [
    'Kalender',
    'Calendrier',
    'Kalender',
    'Kalender',
    'Kalender',
    'Kalender',
    'Calendario',
    'Calendario'
  ],
  'Previous': [
    'Zurück',
    'Précédent',
    'Föregående',
    'Forrige',
    'Forrige',
    'Vorige',
    'Anterior',
    'Precedente'
  ],
  'Next': [
    'Weiter',
    'Suivant',
    'Nästa',
    'Neste',
    'Næste',
    'Volgende',
    'Siguiente',
    'Successivo'
  ],
  'Choose a week': [
    'Woche auswählen',
    'Choisir une semaine',
    'Välj en vecka',
    'Velg en uke',
    'Vælg en uge',
    'Kies een week',
    'Elige una semana',
    'Scegli una settimana'
  ],
  'View week': [
    'Woche ansehen',
    'Voir la semaine',
    'Visa vecka',
    'Vis uke',
    'Vis uge',
    'Week bekijken',
    'Ver semana',
    'Vedi settimana'
  ],
  'This week': [
    'Diese Woche',
    'Cette semaine',
    'Denna vecka',
    'Denne uken',
    'Denne uge',
    'Deze week',
    'Esta semana',
    'Questa settimana'
  ],
  'Previous month': [
    'Vorheriger Monat',
    'Mois précédent',
    'Föregående månad',
    'Forrige måned',
    'Forrige måned',
    'Vorige maand',
    'Mes anterior',
    'Mese precedente'
  ],
  'Next month': [
    'Nächster Monat',
    'Mois suivant',
    'Nästa månad',
    'Neste måned',
    'Næste måned',
    'Volgende maand',
    'Mes siguiente',
    'Mese successivo'
  ],
  'Sleep · Read-only': [
    'Schlaf · Schreibgeschützt',
    'Sommeil · Lecture seule',
    'Sömn · Skrivskyddad',
    'Søvn · Skrivebeskyttet',
    'Søvn · Skrivebeskyttet',
    'Slaap · Alleen bekijken',
    'Sueño · Solo lectura',
    'Sonno · Sola lettura'
  ],
  'Past week · Read-only': [
    'Vergangene Woche · Schreibgeschützt',
    'Semaine passée · Lecture seule',
    'Tidigare vecka · Skrivskyddad',
    'Tidligere uke · Skrivebeskyttet',
    'Tidligere uge · Skrivebeskyttet',
    'Vorige week · Alleen bekijken',
    'Semana anterior · Solo lectura',
    'Settimana passata · Sola lettura'
  ],
  'Sleep entries from previous weeks are read-only.': [
    'Schlafeinträge vergangener Wochen sind schreibgeschützt.',
    'Les données de sommeil des semaines passées sont en lecture seule.',
    'Sömn från tidigare veckor kan bara visas.',
    'Søvn fra tidligere uker kan bare vises.',
    'Søvn fra tidligere uger kan kun vises.',
    'Slaapgegevens van afgelopen weken kun je alleen bekijken.',
    'Los registros de sueño de semanas anteriores son de solo lectura.',
    'I dati sul sonno delle settimane passate sono di sola lettura.'
  ],
  'Sleep can only be edited for today or earlier this week.': [
    'Schlaf kann nur für heute oder frühere Tage dieser Woche bearbeitet werden.',
    'Le sommeil peut être modifié pour aujourd’hui ou les jours précédents de cette semaine.',
    'Sömn kan bara ändras för idag eller tidigare dagar denna vecka.',
    'Søvn kan bare endres for i dag eller tidligere dager denne uken.',
    'Søvn kan kun ændres for i dag eller tidligere dage i denne uge.',
    'Je kunt slaap alleen voor vandaag of eerdere dagen van deze week wijzigen.',
    'Solo puedes editar el sueño de hoy o de días anteriores de esta semana.',
    'Puoi modificare il sonno solo per oggi o per i giorni precedenti di questa settimana.'
  ],
};
String? weeklyRhythmTranslation(String locale, String text) {
  final index = _locales.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
