const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "Log set {number}": [
    "Satz {number} erfassen",
    "Enregistrer la série {number}",
    "Logga set {number}",
    "Registrer sett {number}",
    "Registrer sæt {number}",
    "Set {number} registreren",
    "Registrar serie {number}",
    "Registra serie {number}"
  ],
  "Set details": [
    "Satzdetails",
    "Détails de la série",
    "Setdetaljer",
    "Settdetaljer",
    "Sætdetaljer",
    "Setdetails",
    "Detalles de la serie",
    "Dettagli della serie"
  ],
  "Set {number}": [
    "Satz {number}",
    "Série {number}",
    "Set {number}",
    "Sett {number}",
    "Sæt {number}",
    "Set {number}",
    "Serie {number}",
    "Serie {number}"
  ],
  "How hard was that set?": [
    "Wie anstrengend war dieser Satz?",
    "Quelle était la difficulté de cette série ?",
    "Hur tungt kändes setet?",
    "Hvor tungt føltes settet?",
    "Hvor hårdt føltes sættet?",
    "Hoe zwaar voelde deze set?",
    "¿Qué tan difícil fue esta serie?",
    "Quanto è stata difficile questa serie?"
  ],
  "Optional · 1 is very easy, 10 is maximum effort.": [
    "Optional · 1 ist sehr leicht, 10 ist maximale Anstrengung.",
    "Facultatif · 1 est très facile, 10 est l’effort maximal.",
    "Valfritt · 1 är mycket lätt, 10 är maximal ansträngning.",
    "Valgfritt · 1 er veldig lett, 10 er maksimal innsats.",
    "Valgfrit · 1 er meget let, 10 er maksimal indsats.",
    "Optioneel · 1 is heel makkelijk, 10 is maximale inspanning.",
    "Opcional · 1 es muy fácil, 10 es esfuerzo máximo.",
    "Facoltativo · 1 è molto facile, 10 è lo sforzo massimo."
  ],
  "Not rated": [
    "Nicht bewertet",
    "Non évalué",
    "Inte bedömt",
    "Ikke vurdert",
    "Ikke vurderet",
    "Niet beoordeeld",
    "Sin valorar",
    "Non valutata"
  ],
  "Clear rating": [
    "Bewertung löschen",
    "Effacer la note",
    "Ta bort bedömning",
    "Fjern vurdering",
    "Fjern vurdering",
    "Beoordeling wissen",
    "Borrar valoración",
    "Cancella valutazione"
  ],
  "Added weight (kg)": [
    "Zusatzgewicht (kg)",
    "Charge ajoutée (kg)",
    "Extra vikt (kg)",
    "Ekstra vekt (kg)",
    "Ekstra vægt (kg)",
    "Extra gewicht (kg)",
    "Peso añadido (kg)",
    "Peso aggiunto (kg)"
  ],
  "Weight (kg)": [
    "Gewicht (kg)",
    "Charge (kg)",
    "Vikt (kg)",
    "Vekt (kg)",
    "Vægt (kg)",
    "Gewicht (kg)",
    "Peso (kg)",
    "Peso (kg)"
  ],
  "Hide demo": [
    "Demo ausblenden",
    "Masquer la démo",
    "Dölj demo",
    "Skjul demo",
    "Skjul demo",
    "Demo verbergen",
    "Ocultar demo",
    "Nascondi demo"
  ],
  "Show demo": [
    "Demo anzeigen",
    "Afficher la démo",
    "Visa demo",
    "Vis demo",
    "Vis demo",
    "Demo tonen",
    "Mostrar demo",
    "Mostra demo"
  ],
  "Instructions unavailable": [
    "Anleitung nicht verfügbar",
    "Instructions indisponibles",
    "Instruktioner saknas",
    "Instruksjoner utilgjengelige",
    "Vejledning er ikke tilgængelig",
    "Instructies niet beschikbaar",
    "Instrucciones no disponibles",
    "Istruzioni non disponibili"
  ],
  "Exercise options": [
    "Übungsoptionen",
    "Options de l’exercice",
    "Övningsalternativ",
    "Øvelsesvalg",
    "Øvelsesmuligheder",
    "Oefeningsopties",
    "Opciones del ejercicio",
    "Opzioni esercizio"
  ],
  "Skip exercise": [
    "Übung überspringen",
    "Passer cet exercice",
    "Hoppa över övning",
    "Hopp over øvelsen",
    "Spring øvelsen over",
    "Oefening overslaan",
    "Omitir ejercicio",
    "Salta esercizio"
  ],
  "Reopen exercise": [
    "Übung wieder öffnen",
    "Rouvrir l’exercice",
    "Öppna övningen igen",
    "Åpne øvelsen igjen",
    "Åbn øvelsen igen",
    "Oefening heropenen",
    "Reabrir ejercicio",
    "Riapri esercizio"
  ],
  "Previous": [
    "Zuletzt",
    "Précédent",
    "Tidigare",
    "Forrige",
    "Tidligere",
    "Vorige",
    "Anterior",
    "Precedente"
  ],
  '{count} set': [
    '{count} Satz',
    '{count} série',
    '{count} set',
    '{count} sett',
    '{count} sæt',
    '{count} set',
    '{count} serie',
    '{count} serie'
  ],
  '{count} sets': [
    '{count} Sätze',
    '{count} séries',
    '{count} set',
    '{count} sett',
    '{count} sæt',
    '{count} sets',
    '{count} series',
    '{count} serie'
  ],
  'Best set': [
    'Bester Satz',
    'Meilleure série',
    'Bästa set',
    'Beste sett',
    'Bedste sæt',
    'Beste set',
    'Mejor serie',
    'Serie migliore'
  ],
  'Log your first set to see your progress.': [
    'Erfasse deinen ersten Satz, um deinen Fortschritt zu sehen.',
    'Enregistrez votre première série pour voir vos progrès.',
    'Logga ditt första set för att se dina framsteg.',
    'Registrer ditt første sett for å se fremgangen din.',
    'Registrer dit første sæt for at se dine fremskridt.',
    'Registreer je eerste set om je voortgang te zien.',
    'Registra tu primera serie para ver tu progreso.',
    'Registra la tua prima serie per vedere i tuoi progressi.'
  ],
  'Finish exercise': [
    'Übung abschließen',
    'Terminer l’exercice',
    'Slutför övning',
    'Fullfør øvelsen',
    'Afslut øvelsen',
    'Oefening afronden',
    'Terminar ejercicio',
    'Termina esercizio'
  ],
  'Next exercise': [
    'Nächste Übung',
    'Exercice suivant',
    'Nästa övning',
    'Neste øvelse',
    'Næste øvelse',
    'Volgende oefening',
    'Siguiente ejercicio',
    'Prossimo esercizio'
  ],
  'Exercise {current} of {total}': [
    'Übung {current} von {total}',
    'Exercice {current} sur {total}',
    'Övning {current} av {total}',
    'Øvelse {current} av {total}',
    'Øvelse {current} af {total}',
    'Oefening {current} van {total}',
    'Ejercicio {current} de {total}',
    'Esercizio {current} di {total}'
  ],
  '{done} of {total} sets logged': [
    '{done} von {total} Sätzen erfasst',
    '{done} séries sur {total} enregistrées',
    '{done} av {total} set loggade',
    '{done} av {total} sett logget',
    '{done} af {total} sæt registreret',
    '{done} van {total} sets gelogd',
    '{done} de {total} series registradas',
    '{done} di {total} serie registrate'
  ],
  'Enter the weight you lifted before saving this set.': [
    'Trage vor dem Speichern das verwendete Gewicht ein.',
    'Saisissez la charge utilisée avant d’enregistrer cette série.',
    'Ange vikten du lyfte innan du sparar setet.',
    'Angi vekten du løftet før du lagrer settet.',
    'Angiv den løftede vægt, før du gemmer sættet.',
    'Vul het gebruikte gewicht in voordat je deze set opslaat.',
    'Introduce el peso utilizado antes de guardar esta serie.',
    'Inserisci il peso sollevato prima di salvare questa serie.'
  ],
  'Add effort': [
    'Anstrengung ergänzen',
    'Ajouter l’effort',
    'Lägg till ansträngning',
    'Legg til innsats',
    'Tilføj anstrengelse',
    'Inspanning toevoegen',
    'Añadir esfuerzo',
    'Aggiungi sforzo'
  ],
  'Add weight': [
    'Zusatzgewicht',
    'Ajouter une charge',
    'Lägg till vikt',
    'Legg til vekt',
    'Tilføj vægt',
    'Gewicht toevoegen',
    'Añadir peso',
    'Aggiungi peso'
  ],
  'Set options': [
    'Satzoptionen',
    'Options de série',
    'Setalternativ',
    'Settalternativer',
    'Sætindstillinger',
    'Setopties',
    'Opciones de serie',
    'Opzioni serie'
  ],
  'Reps logged': [
    'Erfasste Wiederholungen',
    'Répétitions enregistrées',
    'Loggade repetitioner',
    'Loggede repetisjoner',
    'Registrerede gentagelser',
    'Gelogde herhalingen',
    'Repeticiones registradas',
    'Ripetizioni registrate'
  ],
  'Bodyweight session': [
    'Training mit Körpergewicht',
    'Séance au poids du corps',
    'Kroppsviktspass',
    'Kroppsvektøkt',
    'Kropsvægtstræning',
    'Lichaamsgewichttraining',
    'Sesión con peso corporal',
    'Sessione a corpo libero'
  ],
  'Exercise breakdown': [
    'Übungsübersicht',
    'Détail des exercices',
    'Övningsöversikt',
    'Øvelsesoversikt',
    'Øvelsesoversigt',
    'Oefeningsoverzicht',
    'Detalle de ejercicios',
    'Dettaglio esercizi'
  ],
  'Exercises completed': [
    'Abgeschlossene Übungen',
    'Exercices terminés',
    'Slutförda övningar',
    'Fullførte øvelser',
    'Afsluttede øvelser',
    'Voltooide oefeningen',
    'Ejercicios completados',
    'Esercizi completati'
  ],
  'Some sets have no recorded load. Edit your sets to complete the volume.': [
    'Bei einigen Sätzen fehlt das Gewicht. Bearbeite sie, um das Volumen zu vervollständigen.',
    'La charge manque pour certaines séries. Modifiez-les pour compléter le volume.',
    'Vissa set saknar vikt. Redigera dem för fullständig volym.',
    'Noen sett mangler vekt. Rediger dem for fullstendig volum.',
    'Nogle sæt mangler vægt. Ret dem for fuld volumen.',
    'Bij sommige sets ontbreekt het gewicht. Bewerk ze voor het volledige volume.',
    'Algunas series no tienen peso registrado. Edítalas para completar el volumen.',
    'Alcune serie non hanno un carico registrato. Modificale per completare il volume.'
  ],
};
String? workoutSessionTranslation(String locale, String text) {
  final index = _locales.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
