const _languages = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];

String? manualEntriesTranslation(String locale, String text) {
  final index = _languages.indexOf(locale.split('-').first);
  return index < 0 ? null : _copy[text]?[index];
}

const _copy = <String, List<String>>{
  'Add a photo now, or later from Today → Update your stats.': [
    'Füge jetzt ein Foto hinzu oder später unter Heute → Werte aktualisieren.',
    'Ajoutez une photo maintenant ou plus tard via Aujourd’hui → Mettre à jour mes données.',
    'Lägg till en bild nu eller senare via Idag → Uppdatera dina värden.',
    'Legg til et bilde nå eller senere via I dag → Oppdater verdiene dine.',
    'Tilføj et billede nu eller senere via I dag → Opdater dine tal.',
    'Voeg nu een foto toe, of later via Vandaag → Je gegevens bijwerken.',
    'Añade una foto ahora o después desde Hoy → Actualizar tus datos.',
    'Aggiungi una foto ora o più tardi da Oggi → Aggiorna i tuoi dati.'
  ],
  'Progress photo': [
    'Fortschrittsfoto',
    'Photo de progression',
    'Framstegsbild',
    'Fremgangsbilde',
    'Fremskridtsbillede',
    'Voortgangsfoto',
    'Foto de progreso',
    'Foto dei progressi'
  ],
  'Delete photo': [
    'Foto löschen',
    'Supprimer la photo',
    'Ta bort bild',
    'Slett bilde',
    'Slet billede',
    'Foto verwijderen',
    'Eliminar foto',
    'Elimina foto'
  ],
  'Could not refresh. Tap to retry.': [
    'Aktualisierung fehlgeschlagen. Tippe zum Wiederholen.',
    'Actualisation impossible. Touchez pour réessayer.',
    'Kunde inte uppdatera. Tryck för att försöka igen.',
    'Kunne ikke oppdatere. Trykk for å prøve igjen.',
    'Kunne ikke opdatere. Tryk for at prøve igen.',
    'Vernieuwen mislukt. Tik om opnieuw te proberen.',
    'No se pudo actualizar. Toca para reintentar.',
    'Aggiornamento non riuscito. Tocca per riprovare.'
  ],
  'This photo couldn’t load.': [
    'Dieses Foto konnte nicht geladen werden.',
    'Impossible de charger cette photo.',
    'Bilden kunde inte laddas.',
    'Bildet kunne ikke lastes.',
    'Billedet kunne ikke indlæses.',
    'Deze foto kon niet worden geladen.',
    'No se pudo cargar esta foto.',
    'Impossibile caricare questa foto.'
  ],
  'Could not delete this photo. Try again.': [
    'Dieses Foto konnte nicht gelöscht werden. Versuche es erneut.',
    'Impossible de supprimer cette photo. Réessayez.',
    'Kunde inte ta bort bilden. Försök igen.',
    'Kunne ikke slette bildet. Prøv igjen.',
    'Kunne ikke slette billedet. Prøv igen.',
    'Deze foto kon niet worden verwijderd. Probeer opnieuw.',
    'No se pudo eliminar la foto. Reintenta.',
    'Impossibile eliminare la foto. Riprova.'
  ],
  'Your photos are unavailable. Please try again.': [
    'Deine Fotos sind nicht verfügbar. Versuche es erneut.',
    'Vos photos sont indisponibles. Réessayez.',
    'Dina bilder är inte tillgängliga. Försök igen.',
    'Bildene dine er utilgjengelige. Prøv igjen.',
    'Dine billeder er ikke tilgængelige. Prøv igen.',
    'Je foto’s zijn niet beschikbaar. Probeer opnieuw.',
    'Tus fotos no están disponibles. Reintenta.',
    'Le tue foto non sono disponibili. Riprova.'
  ],
  'Could not load your measurements. Please try again.': [
    'Deine Maße konnten nicht geladen werden. Versuche es erneut.',
    'Impossible de charger vos mensurations. Réessayez.',
    'Kunde inte ladda dina mått. Försök igen.',
    'Kunne ikke laste målene dine. Prøv igjen.',
    'Kunne ikke indlæse dine mål. Prøv igen.',
    'Je maten konden niet worden geladen. Probeer opnieuw.',
    'No se pudieron cargar tus medidas. Reintenta.',
    'Impossibile caricare le tue misure. Riprova.'
  ],
  'Your photo could not be saved. Your workout is saved. Try again.': [
    'Dein Foto konnte nicht gespeichert werden. Dein Training ist gespeichert. Versuche es erneut.',
    'Votre photo n’a pas pu être enregistrée. Votre séance est enregistrée. Réessayez.',
    'Bilden kunde inte sparas. Ditt pass är sparat. Försök igen.',
    'Bildet kunne ikke lagres. Økten er lagret. Prøv igjen.',
    'Billedet kunne ikke gemmes. Din træning er gemt. Prøv igen.',
    'Je foto kon niet worden opgeslagen. Je training is opgeslagen. Probeer opnieuw.',
    'No se pudo guardar la foto. Tu entrenamiento está guardado. Reintenta.',
    'Impossibile salvare la foto. Il tuo allenamento è salvato. Riprova.'
  ],
  'Could not open this photo. Check camera or photo permissions and try again.':
      [
    'Dieses Foto konnte nicht geöffnet werden. Prüfe die Kamera- oder Fotoberechtigungen und versuche es erneut.',
    'Impossible d’ouvrir cette photo. Vérifiez les autorisations de caméra ou de photos et réessayez.',
    'Kunde inte öppna bilden. Kontrollera kamera- eller bildbehörigheter och försök igen.',
    'Kunne ikke åpne bildet. Sjekk kamera- eller bildetillatelser og prøv igjen.',
    'Kunne ikke åbne billedet. Tjek kamera- eller billedtilladelser, og prøv igen.',
    'Deze foto kon niet worden geopend. Controleer camera- of fototoegang en probeer opnieuw.',
    'No se pudo abrir la foto. Revisa los permisos de cámara o fotos y reintenta.',
    'Impossibile aprire la foto. Controlla i permessi della fotocamera o delle foto e riprova.'
  ],
  'Update your stats': [
    'Werte aktualisieren',
    'Mettre à jour mes données',
    'Uppdatera dina värden',
    'Oppdater verdiene dine',
    'Opdater dine tal',
    'Je gegevens bijwerken',
    'Actualizar tus datos',
    'Aggiorna i tuoi dati'
  ],
  'Sleep & recovery': [
    'Schlaf & Erholung',
    'Sommeil et récupération',
    'Sömn och återhämtning',
    'Søvn og restitusjon',
    'Søvn og restitution',
    'Slaap en herstel',
    'Sueño y recuperación',
    'Sonno e recupero'
  ],
  'Body measurements': [
    'Körpermaße',
    'Mensurations',
    'Kroppsmått',
    'Kroppsmål',
    'Kropsmål',
    'Lichaamsmaten',
    'Medidas corporales',
    'Misure corporee'
  ],
  'Water intake': [
    'Wasserzufuhr',
    'Hydratation',
    'Vattenintag',
    'Vanninntak',
    'Vandindtag',
    'Waterinname',
    'Consumo de agua',
    'Acqua bevuta'
  ],
  'Read only': [
    'Nur Lesen',
    'Lecture seule',
    'Skrivskyddad',
    'Skrivebeskyttet',
    'Skrivebeskyttet',
    'Alleen lezen',
    'Solo lectura',
    'Sola lettura'
  ],
  'Preview · read only': [
    'Vorschau · nur Lesen',
    'Aperçu · lecture seule',
    'Förhandsvisning · skrivskyddad',
    'Forhåndsvisning · skrivebeskyttet',
    'Forhåndsvisning · skrivebeskyttet',
    'Voorbeeld · alleen lezen',
    'Vista previa · solo lectura',
    'Anteprima · sola lettura'
  ],
  'Future date · read only': [
    'Zukünftiges Datum · nur Lesen',
    'Date future · lecture seule',
    'Framtida datum · skrivskyddad',
    'Fremtidig dato · skrivebeskyttet',
    'Fremtidig dato · skrivebeskyttet',
    'Toekomstige datum · alleen lezen',
    'Fecha futura · solo lectura',
    'Data futura · sola lettura'
  ],
  'Could not refresh · Retry': [
    'Aktualisierung fehlgeschlagen · Erneut versuchen',
    'Actualisation impossible · Réessayer',
    'Kunde inte uppdatera · Försök igen',
    'Kunne ikke oppdatere · Prøv igjen',
    'Kunne ikke opdatere · Prøv igen',
    'Vernieuwen mislukt · Opnieuw',
    'No se pudo actualizar · Reintentar',
    'Aggiornamento non riuscito · Riprova'
  ],
  'Progress photos': [
    'Fortschrittsfotos',
    'Photos de progression',
    'Framstegsbilder',
    'Fremgangsbilder',
    'Fremskridtsbilleder',
    'Voortgangsfoto’s',
    'Fotos de progreso',
    'Foto dei progressi'
  ],
  'Add progress photo': [
    'Fortschrittsfoto hinzufügen',
    'Ajouter une photo',
    'Lägg till framstegsbild',
    'Legg til fremgangsbilde',
    'Tilføj fremskridtsbillede',
    'Voortgangsfoto toevoegen',
    'Añadir foto de progreso',
    'Aggiungi foto dei progressi'
  ],
  'View all progress photos': [
    'Alle Fortschrittsfotos ansehen',
    'Voir toutes les photos',
    'Visa alla framstegsbilder',
    'Se alle fremgangsbilder',
    'Se alle fremskridtsbilleder',
    'Alle voortgangsfoto’s bekijken',
    'Ver todas las fotos',
    'Vedi tutte le foto'
  ],
  'Your journey starts here': [
    'Dein Weg beginnt hier',
    'Votre parcours commence ici',
    'Din resa börjar här',
    'Reisen din starter her',
    'Din rejse starter her',
    'Je reis begint hier',
    'Tu camino empieza aquí',
    'Il tuo percorso inizia qui'
  ],
  'Add your first photo and watch your progress unfold.': [
    'Füge dein erstes Foto hinzu und verfolge deinen Fortschritt.',
    'Ajoutez votre première photo pour suivre vos progrès.',
    'Lägg till din första bild och följ dina framsteg.',
    'Legg til ditt første bilde og følg fremgangen din.',
    'Tilføj dit første billede, og følg dine fremskridt.',
    'Voeg je eerste foto toe en volg je vooruitgang.',
    'Añade tu primera foto y sigue tu progreso.',
    'Aggiungi la tua prima foto e segui i tuoi progressi.'
  ],
  'Your photos couldn’t load': [
    'Deine Fotos konnten nicht geladen werden',
    'Impossible de charger vos photos',
    'Dina bilder kunde inte laddas',
    'Bildene dine kunne ikke lastes',
    'Dine billeder kunne ikke indlæses',
    'Je foto’s konden niet worden geladen',
    'No se pudieron cargar tus fotos',
    'Impossibile caricare le tue foto'
  ],
  'Try again to see your photo journal.': [
    'Versuche es erneut, um dein Fototagebuch zu sehen.',
    'Réessayez pour voir votre journal photo.',
    'Försök igen för att se din bilddagbok.',
    'Prøv igjen for å se bildedagboken din.',
    'Prøv igen for at se din billeddagbog.',
    'Probeer opnieuw om je fotodagboek te bekijken.',
    'Reintenta para ver tu diario de fotos.',
    'Riprova per vedere il tuo diario fotografico.'
  ],
  'Capture your progress.': [
    'Halte deinen Fortschritt fest.',
    'Capturez vos progrès.',
    'Föreviga dina framsteg.',
    'Fang fremgangen din.',
    'Fang dine fremskridt.',
    'Leg je vooruitgang vast.',
    'Captura tu progreso.',
    'Cattura i tuoi progressi.'
  ],
  'Your effort. Captured.': [
    'Dein Einsatz. Festgehalten.',
    'Vos efforts. En image.',
    'Din insats. Förevigad.',
    'Innsatsen din. Foreviget.',
    'Din indsats. Foreviget.',
    'Jouw inzet. Vastgelegd.',
    'Tu esfuerzo. Capturado.',
    'Il tuo impegno. Catturato.'
  ],
  'A moment worth keeping.': [
    'Ein Moment zum Festhalten.',
    'Un moment à garder.',
    'Ett ögonblick att spara.',
    'Et øyeblikk å ta vare på.',
    'Et øjeblik at gemme.',
    'Een moment om te bewaren.',
    'Un momento para guardar.',
    'Un momento da conservare.'
  ],
  'Take a photo': [
    'Foto aufnehmen',
    'Prendre une photo',
    'Ta en bild',
    'Ta et bilde',
    'Tag et billede',
    'Foto maken',
    'Hacer una foto',
    'Scatta una foto'
  ],
  'Choose from library': [
    'Aus Mediathek wählen',
    'Choisir dans la photothèque',
    'Välj från bildbiblioteket',
    'Velg fra bildebiblioteket',
    'Vælg fra billedbiblioteket',
    'Kies uit fotobibliotheek',
    'Elegir de la galería',
    'Scegli dalla galleria'
  ],
  'Maybe later': [
    'Vielleicht später',
    'Plus tard',
    'Kanske senare',
    'Kanskje senere',
    'Måske senere',
    'Misschien later',
    'Quizás más tarde',
    'Magari più tardi'
  ],
  'Save photo': [
    'Foto speichern',
    'Enregistrer la photo',
    'Spara bild',
    'Lagre bilde',
    'Gem billede',
    'Foto opslaan',
    'Guardar foto',
    'Salva foto'
  ],
  'Retake': [
    'Neu aufnehmen',
    'Reprendre',
    'Ta om',
    'Ta på nytt',
    'Tag om',
    'Opnieuw maken',
    'Volver a tomar',
    'Scatta di nuovo'
  ],
  'Progress photo saved.': [
    'Fortschrittsfoto gespeichert.',
    'Photo enregistrée.',
    'Framstegsbild sparad.',
    'Fremgangsbilde lagret.',
    'Fremskridtsbillede gemt.',
    'Voortgangsfoto opgeslagen.',
    'Foto de progreso guardada.',
    'Foto dei progressi salvata.'
  ],
  'Save this photo to your progress journal.': [
    'Speichere dieses Foto in deinem Fortschrittstagebuch.',
    'Enregistrez cette photo dans votre journal de progression.',
    'Spara bilden i din framstegsdagbok.',
    'Lagre bildet i fremgangsdagboken din.',
    'Gem billedet i din fremskridtsdagbog.',
    'Bewaar deze foto in je voortgangsdagboek.',
    'Guarda esta foto en tu diario de progreso.',
    'Salva questa foto nel tuo diario dei progressi.'
  ],
  'Small changes add up. Give yourself something to look back on.': [
    'Kleine Veränderungen summieren sich. Halte deinen Weg fest.',
    'Les petits changements comptent. Gardez une trace de votre parcours.',
    'Små förändringar gör skillnad. Spara något att se tillbaka på.',
    'Små endringer teller. Ta vare på noe å se tilbake på.',
    'Små ændringer tæller. Gem noget at se tilbage på.',
    'Kleine veranderingen tellen op. Bewaar iets om op terug te kijken.',
    'Los pequeños cambios suman. Guarda algo para recordar tu camino.',
    'I piccoli cambiamenti contano. Conserva un ricordo del tuo percorso.'
  ],
  'Workout complete. Add a progress photo to look back on how far you’ve come.':
      [
    'Training geschafft. Halte deinen Fortschritt mit einem Foto fest.',
    'Séance terminée. Ajoutez une photo pour suivre le chemin parcouru.',
    'Passet är klart. Lägg till en bild för att se hur långt du har kommit.',
    'Økten er fullført. Legg til et bilde for å se hvor langt du har kommet.',
    'Træningen er færdig. Tilføj et billede for at se dine fremskridt.',
    'Training voltooid. Voeg een foto toe om je vooruitgang te zien.',
    'Entrenamiento completado. Añade una foto para ver cuánto has avanzado.',
    'Allenamento completato. Aggiungi una foto per vedere i tuoi progressi.'
  ],
  'Optional. Photos are stored online and can be viewed by anyone with the link.':
      [
    'Optional. Fotos werden online gespeichert und sind für alle mit dem Link sichtbar.',
    'Facultatif. Les photos sont stockées en ligne et accessibles à toute personne disposant du lien.',
    'Valfritt. Bilder lagras online och kan ses av alla med länken.',
    'Valgfritt. Bilder lagres på nett og kan ses av alle med lenken.',
    'Valgfrit. Billeder gemmes online og kan ses af alle med linket.',
    'Optioneel. Foto’s worden online opgeslagen en zijn zichtbaar voor iedereen met de link.',
    'Opcional. Las fotos se guardan en línea y cualquiera con el enlace puede verlas.',
    'Facoltativo. Le foto sono salvate online e visibili a chiunque abbia il link.'
  ],
  'Delete progress photo?': [
    'Fortschrittsfoto löschen?',
    'Supprimer la photo ?',
    'Ta bort framstegsbild?',
    'Slette fremgangsbildet?',
    'Slet fremskridtsbillede?',
    'Voortgangsfoto verwijderen?',
    '¿Eliminar foto de progreso?',
    'Eliminare la foto dei progressi?'
  ],
  'This photo will be permanently removed from your journal.': [
    'Dieses Foto wird dauerhaft aus deinem Tagebuch entfernt.',
    'Cette photo sera définitivement supprimée de votre journal.',
    'Bilden tas bort permanent från din dagbok.',
    'Bildet fjernes permanent fra dagboken din.',
    'Billedet fjernes permanent fra din dagbog.',
    'Deze foto wordt definitief uit je dagboek verwijderd.',
    'Esta foto se eliminará permanentemente de tu diario.',
    'Questa foto verrà rimossa definitivamente dal tuo diario.'
  ],
  'Load more': [
    'Mehr laden',
    'Afficher plus',
    'Ladda fler',
    'Last inn flere',
    'Indlæs flere',
    'Meer laden',
    'Cargar más',
    'Carica altre'
  ],
  '{hours}h {minutes}m': [
    '{hours} Std. {minutes} Min.',
    '{hours} h {minutes} min',
    '{hours} h {minutes} min',
    '{hours} t {minutes} min',
    '{hours} t {minutes} min',
    '{hours} u {minutes} min',
    '{hours} h {minutes} min',
    '{hours} h {minutes} min'
  ],
};
