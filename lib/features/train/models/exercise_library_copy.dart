import 'package:flutter/widgets.dart';
import '../../../core/localization/fitness_copy.dart';

const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  'Add {count} exercise': [
    '{count} Übung hinzufügen',
    'Ajouter {count} exercice',
    'Lägg till {count} övning',
    'Legg til {count} øvelse',
    'Tilføj {count} øvelse',
    '{count} oefening toevoegen',
    'Añadir {count} ejercicio',
    'Aggiungi {count} esercizio'
  ],
  'Add {count} exercises': [
    '{count} Übungen hinzufügen',
    'Ajouter {count} exercices',
    'Lägg till {count} övningar',
    'Legg til {count} øvelser',
    'Tilføj {count} øvelser',
    '{count} oefeningen toevoegen',
    'Añadir {count} ejercicios',
    'Aggiungi {count} esercizi'
  ],
  'Search exercises': [
    'Übungen suchen',
    'Rechercher un exercice',
    'Sök övningar',
    'Søk etter øvelser',
    'Søg øvelser',
    'Zoek oefeningen',
    'Buscar ejercicios',
    'Cerca esercizi'
  ],
  'All muscles': [
    'Alle Muskeln',
    'Tous les muscles',
    'Alla muskler',
    'Alle muskler',
    'Alle muskler',
    'Alle spieren',
    'Todos los músculos',
    'Tutti i muscoli'
  ],
  'Any equipment': [
    'Alle Geräte',
    'Tout équipement',
    'All utrustning',
    'Alt utstyr',
    'Alt udstyr',
    'Alle apparatuur',
    'Cualquier equipo',
    'Qualsiasi attrezzo'
  ],
  'Muscle group': [
    'Muskelgruppe',
    'Groupe musculaire',
    'Muskelgrupp',
    'Muskelgruppe',
    'Muskelgruppe',
    'Spiergroep',
    'Grupo muscular',
    'Gruppo muscolare'
  ],
  'Profile': [
    'Profil',
    'Profil',
    'Profil',
    'Profil',
    'Profil',
    'Profiel',
    'Perfil',
    'Profilo'
  ],
  'New': ['Neu', 'Nouveau', 'Ny', 'Ny', 'Ny', 'Nieuw', 'Nuevo', 'Nuovo'],
  'Select exercise': [
    'Übung auswählen',
    'Choisir cet exercice',
    'Välj övning',
    'Velg øvelse',
    'Vælg øvelse',
    'Selecteer oefening',
    'Seleccionar ejercicio',
    'Seleziona esercizio'
  ],
  'Deselect exercise': [
    'Übung abwählen',
    'Désélectionner',
    'Avmarkera övning',
    'Fjern øvelsesvalg',
    'Fravælg øvelse',
    'Deselecteer oefening',
    'Deseleccionar ejercicio',
    'Deseleziona esercizio'
  ],
  'Preview exercise': [
    'Übung ansehen',
    'Voir l’exercice',
    'Visa övning',
    'Se øvelse',
    'Se øvelse',
    'Bekijk oefening',
    'Ver ejercicio',
    'Vedi esercizio'
  ],
  'Select exercises': [
    'Übungen auswählen',
    'Choisir des exercices',
    'Välj övningar',
    'Velg øvelser',
    'Vælg øvelser',
    'Selecteer oefeningen',
    'Selecciona ejercicios',
    'Seleziona esercizi'
  ],
  'Select an exercise': [
    'Eine Übung auswählen',
    'Choisir un exercice',
    'Välj en övning',
    'Velg en øvelse',
    'Vælg en øvelse',
    'Selecteer een oefening',
    'Selecciona un ejercicio',
    'Seleziona un esercizio'
  ],
  'Could not load more exercises.': [
    'Weitere Übungen konnten nicht geladen werden.',
    'Impossible de charger la suite.',
    'Kunde inte läsa in fler övningar.',
    'Kunne ikke laste flere øvelser.',
    'Kunne ikke indlæse flere øvelser.',
    'Meer oefeningen laden is mislukt.',
    'No se pudieron cargar más ejercicios.',
    'Impossibile caricare altri esercizi.'
  ],
  'Some exercises could not be added. Try again.': [
    'Einige Übungen konnten nicht hinzugefügt werden. Versuche es erneut.',
    'Certains exercices n’ont pas été ajoutés. Réessayez.',
    'Vissa övningar kunde inte läggas till. Försök igen.',
    'Noen øvelser kunne ikke legges til. Prøv igjen.',
    'Nogle øvelser kunne ikke tilføjes. Prøv igen.',
    'Sommige oefeningen zijn niet toegevoegd. Probeer opnieuw.',
    'No se pudieron añadir algunos ejercicios. Inténtalo de nuevo.',
    'Alcuni esercizi non sono stati aggiunti. Riprova.'
  ],
  "Find your next movement": [
    "Finde deine nächste Übung",
    "Trouvez votre prochain exercice",
    "Hitta din nästa övning",
    "Finn din neste øvelse",
    "Find din næste øvelse",
    "Vind je volgende oefening",
    "Encuentra tu próximo ejercicio",
    "Trova il tuo prossimo esercizio"
  ],
  "Filters": [
    "Filter",
    "Filtres",
    "Filter",
    "Filtre",
    "Filtre",
    "Filters",
    "Filtros",
    "Filtri"
  ],
  "Demonstration": [
    "Demonstration",
    "Démonstration",
    "Demonstration",
    "Demonstrasjon",
    "Demonstration",
    "Demonstratie",
    "Demostración",
    "Dimostrazione"
  ],
  "Male": ["Männlich", "Homme", "Man", "Mann", "Mand", "Man", "Hombre", "Uomo"],
  "Female": [
    "Weiblich",
    "Femme",
    "Kvinna",
    "Kvinne",
    "Kvinde",
    "Vrouw",
    "Mujer",
    "Donna"
  ],
};

String exerciseLibraryText(BuildContext context, String text,
    {Map<String, Object> values = const {}}) {
  final index = _locales.indexOf(Localizations.localeOf(context).languageCode);
  final translated = _copy[text];
  var label = index >= 0 && translated != null
      ? translated[index]
      : fitnessText(context, text, values: values);
  for (final entry in values.entries) {
    label = label.replaceAll('{${entry.key}}', entry.value.toString());
  }
  return label;
}
