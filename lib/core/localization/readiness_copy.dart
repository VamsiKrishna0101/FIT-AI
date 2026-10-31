const _languages = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  'Update': [
    'Aktualisieren',
    'Modifier',
    'Uppdatera',
    'Oppdater',
    'Opdater',
    'Bijwerken',
    'Actualizar',
    'Aggiorna'
  ],
  'Finish': [
    'Abschließen',
    'Terminer',
    'Slutför',
    'Fullfør',
    'Fuldfør',
    'Afronden',
    'Completar',
    'Completa'
  ],
  'Check in': [
    'Einchecken',
    'Faire le bilan',
    'Checka in',
    'Sjekk inn',
    'Tjek ind',
    'Inchecken',
    'Registrar',
    'Check-in'
  ],
  'Check-in saved': [
    'Check-in gespeichert',
    'Bilan enregistré',
    'Incheckning sparad',
    'Innsjekk lagret',
    'Indtjekning gemt',
    'Check-in opgeslagen',
    'Registro guardado',
    'Check-in salvato'
  ],
  'Progress saved': [
    'Fortschritt gespeichert',
    'Progression enregistrée',
    'Framsteg sparade',
    'Fremdrift lagret',
    'Fremskridt gemt',
    'Voortgang opgeslagen',
    'Progreso guardado',
    'Progressi salvati'
  ],
  'Sleep saved': [
    'Schlaf gespeichert',
    'Sommeil enregistré',
    'Sömn sparad',
    'Søvn lagret',
    'Søvn gemt',
    'Slaap opgeslagen',
    'Sueño guardado',
    'Sonno salvato'
  ],
  'Finish check-in': [
    'Check-in abschließen',
    'Terminer le bilan',
    'Slutför incheckning',
    'Fullfør innsjekk',
    'Fuldfør indtjekning',
    'Check-in afronden',
    'Completar registro',
    'Completa check-in'
  ],
  'Save progress': [
    'Fortschritt speichern',
    'Enregistrer la progression',
    'Spara framsteg',
    'Lagre fremdrift',
    'Gem fremskridt',
    'Voortgang opslaan',
    'Guardar progreso',
    'Salva progressi'
  ],
  'Save sleep': [
    'Schlaf speichern',
    'Enregistrer le sommeil',
    'Spara sömn',
    'Lagre søvn',
    'Gem søvn',
    'Slaap opslaan',
    'Guardar sueño',
    'Salva sonno'
  ],
  'On your phone': [
    'Auf deinem Handy',
    'Sur votre téléphone',
    'På din mobil',
    'På telefonen',
    'På din telefon',
    'Op je telefoon',
    'En tu móvil',
    'Sul telefono'
  ],
  'Steps': [
    'Schritte',
    'Pas',
    'Steg',
    'Skritt',
    'Skridt',
    'Stappen',
    'Pasos',
    'Passi'
  ],
  'Set up steps': [
    'Schritte einrichten',
    'Configurer les pas',
    'Ställ in steg',
    'Sett opp skritt',
    'Indstil skridt',
    'Stappen instellen',
    'Configurar pasos',
    'Configura passi'
  ],
  'Health settings': [
    'Gesundheitseinstellungen',
    'Réglages santé',
    'Hälsoinställningar',
    'Helseinnstillinger',
    'Sundhedsindstillinger',
    'Gezondheidsinstellingen',
    'Ajustes de salud',
    'Impostazioni salute'
  ],
  'Connect your health app to import steps.': [
    'Verbinde deine Gesundheits-App, um Schritte zu importieren.',
    'Connectez votre application de santé pour importer les pas.',
    'Anslut din hälsoapp för att importera steg.',
    'Koble til helseappen for å importere skritt.',
    'Forbind din sundhedsapp for at importere skridt.',
    'Koppel je gezondheidsapp om stappen te importeren.',
    'Conecta tu app de salud para importar pasos.',
    'Collega la tua app Salute per importare i passi.'
  ],
  'Connect your health app on your phone to see steps.': [
    'Verbinde deine Gesundheits-App auf dem Handy, um Schritte zu sehen.',
    'Connectez votre application de santé sur votre téléphone pour voir les pas.',
    'Anslut hälsoappen på mobilen för att se steg.',
    'Koble til helseappen på telefonen for å se skritt.',
    'Forbind sundhedsappen på din telefon for at se skridt.',
    'Koppel je gezondheidsapp op je telefoon om stappen te zien.',
    'Conecta tu app de salud en el móvil para ver los pasos.',
    'Collega la tua app Salute sul telefono per vedere i passi.'
  ],
  'No steps recorded for this day.': [
    'Für diesen Tag wurden keine Schritte erfasst.',
    'Aucun pas enregistré pour ce jour.',
    'Inga steg registrerade denna dag.',
    'Ingen skritt registrert denne dagen.',
    'Ingen skridt registreret denne dag.',
    'Voor deze dag zijn geen stappen vastgelegd.',
    'No hay pasos registrados para este día.',
    'Nessun passo registrato per questo giorno.'
  ],
  'No steps shared yet. Review step access.': [
    'Noch keine Schritte geteilt. Prüfe den Schrittzugriff.',
    'Aucun pas partagé. Vérifiez l’accès aux pas.',
    'Inga steg delade ännu. Kontrollera åtkomsten.',
    'Ingen skritt delt ennå. Kontroller tilgangen.',
    'Ingen skridt delt endnu. Tjek adgangen.',
    'Nog geen stappen gedeeld. Controleer de toegang.',
    'Aún no se comparten pasos. Revisa el acceso.',
    'Nessun passo condiviso. Controlla l’accesso ai passi.'
  ],
  'Could not refresh steps. Open health settings to try again.': [
    'Schritte konnten nicht aktualisiert werden. Versuche es in den Gesundheitseinstellungen erneut.',
    'Impossible d’actualiser les pas. Réessayez dans les réglages santé.',
    'Kunde inte uppdatera steg. Försök igen i hälsoinställningarna.',
    'Kunne ikke oppdatere skritt. Prøv igjen i helseinnstillingene.',
    'Kunne ikke opdatere skridt. Prøv igen i sundhedsindstillingerne.',
    'Stappen bijwerken is mislukt. Probeer het opnieuw in de gezondheidsinstellingen.',
    'No se pudieron actualizar los pasos. Inténtalo en los ajustes de salud.',
    'Impossibile aggiornare i passi. Riprova nelle impostazioni salute.'
  ],
  'Check-in estimate': [
    'Check-in-Schätzung',
    'Estimation du bilan',
    'Uppskattning från incheckning',
    'Anslag fra innsjekk',
    'Estimat fra indtjekning',
    'Schatting op basis van je check-in',
    'Estimación del registro',
    'Stima del check-in'
  ],
  'Your check-in': [
    'Dein Check-in',
    'Votre bilan',
    'Din incheckning',
    'Din innsjekk',
    'Din indtjekning',
    'Je check-in',
    'Tu registro',
    'Il tuo check-in'
  ],
  'Rested': [
    'Erholt',
    'Repos',
    'Utvilad',
    'Uthvilt',
    'Udhvilet',
    'Uitgerust',
    'Descanso',
    'Riposo'
  ],
  'Muscle soreness': [
    'Muskelkater',
    'Courbatures',
    'Träningsvärk',
    'Muskelstølhet',
    'Muskelømhed',
    'Spierpijn',
    'Dolor muscular',
    'Indolenzimento muscolare'
  ],
  'Not added': [
    'Nicht eingetragen',
    'Non renseigné',
    'Inte angivet',
    'Ikke lagt til',
    'Ikke tilføjet',
    'Niet ingevuld',
    'Sin añadir',
    'Non inserito'
  ],
  'Not synced': [
    'Nicht synchronisiert',
    'Non synchronisé',
    'Inte synkat',
    'Ikke synkronisert',
    'Ikke synkroniseret',
    'Niet gesynchroniseerd',
    'Sin sincronizar',
    'Non sincronizzato'
  ],
  'Active energy': [
    'Aktivitätsenergie',
    'Énergie active',
    'Aktiv energi',
    'Aktiv energi',
    'Aktiv energi',
    'Actieve energie',
    'Energía activa',
    'Energia attiva'
  ],
  'View check-in': [
    'Check-in ansehen',
    'Voir le bilan',
    'Visa incheckning',
    'Vis innsjekk',
    'Se indtjekning',
    'Check-in bekijken',
    'Ver registro',
    'Vedi check-in'
  ],
  'No check-in recorded': [
    'Kein Check-in erfasst',
    'Aucun bilan enregistré',
    'Ingen incheckning registrerad',
    'Ingen innsjekk registrert',
    'Ingen indtjekning registreret',
    'Geen check-in vastgelegd',
    'Sin registro',
    'Nessun check-in registrato'
  ],
  'No check-in was recorded for this day.': [
    'Für diesen Tag wurde kein Check-in erfasst.',
    'Aucun bilan n’a été enregistré pour ce jour.',
    'Ingen incheckning registrerades denna dag.',
    'Ingen innsjekk ble registrert denne dagen.',
    'Der blev ikke registreret en indtjekning denne dag.',
    'Voor deze dag is geen check-in vastgelegd.',
    'No se guardó un registro para este día.',
    'Non è stato registrato un check-in per questo giorno.'
  ],
  'A quick check-in helps you plan your session.': [
    'Ein kurzer Check-in hilft dir, dein Training zu planen.',
    'Un bilan rapide vous aide à préparer votre séance.',
    'En snabb incheckning hjälper dig planera passet.',
    'En rask innsjekk hjelper deg å planlegge økten.',
    'En hurtig indtjekning hjælper dig med at planlægge træningen.',
    'Een korte check-in helpt je je training te plannen.',
    'Un registro rápido te ayuda a planificar la sesión.',
    'Un breve check-in ti aiuta a pianificare la sessione.'
  ],
  'Sleep saved. Add how you feel.': [
    'Schlaf gespeichert. Ergänze dein Befinden.',
    'Sommeil enregistré. Ajoutez votre ressenti.',
    'Sömn sparad. Lägg till hur du mår.',
    'Søvn lagret. Legg til hvordan du føler deg.',
    'Søvn gemt. Tilføj, hvordan du har det.',
    'Slaap opgeslagen. Vul in hoe je je voelt.',
    'Sueño guardado. Añade cómo te sientes.',
    'Sonno salvato. Aggiungi come ti senti.'
  ],
  'Use your warm-up to check how you feel.': [
    'Prüfe beim Aufwärmen, wie du dich fühlst.',
    'Évaluez vos sensations pendant l’échauffement.',
    'Känn efter under uppvärmningen.',
    'Kjenn etter under oppvarmingen.',
    'Mærk efter under opvarmningen.',
    'Voel tijdens je warming-up hoe het gaat.',
    'Observa cómo te sientes durante el calentamiento.',
    'Valuta come ti senti durante il riscaldamento.'
  ],
  'Keep your effort comfortable today.': [
    'Trainiere heute in einem angenehmen Tempo.',
    'Gardez une intensité confortable aujourd’hui.',
    'Håll en behaglig intensitet idag.',
    'Hold innsatsen behagelig i dag.',
    'Hold en behagelig intensitet i dag.',
    'Houd je inspanning vandaag comfortabel.',
    'Mantén un esfuerzo cómodo hoy.',
    'Mantieni uno sforzo confortevole oggi.'
  ],
  'Give yourself more recovery today.': [
    'Gönne dir heute mehr Erholung.',
    'Accordez-vous plus de récupération aujourd’hui.',
    'Ge dig mer återhämtning idag.',
    'Gi deg selv mer restitusjon i dag.',
    'Giv dig selv mere restitution i dag.',
    'Geef jezelf vandaag meer herstel.',
    'Date más recuperación hoy.',
    'Concediti più recupero oggi.'
  ],
};

String? readinessTranslation(String locale, String text) {
  final index = _languages.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
