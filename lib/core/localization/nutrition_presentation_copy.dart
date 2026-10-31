const _languages = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "Use 2–100 characters for the name.": [
    "Der Name muss 2–100 Zeichen lang sein.",
    "Le nom doit contenir 2 à 100 caractères.",
    "Använd 2–100 tecken för namnet.",
    "Bruk 2–100 tegn i navnet.",
    "Brug 2–100 tegn til navnet.",
    "Gebruik 2–100 tekens voor de naam.",
    "Usa entre 2 y 100 caracteres para el nombre.",
    "Usa da 2 a 100 caratteri per il nome."
  ],
  "Enter a portion size greater than zero.": [
    "Gib eine Portionsgröße größer als null ein.",
    "Saisissez une portion supérieure à zéro.",
    "Ange en portionsstorlek större än noll.",
    "Angi en porsjonsstørrelse større enn null.",
    "Angiv en portionsstørrelse større end nul.",
    "Voer een portiegrootte groter dan nul in.",
    "Introduce una porción mayor que cero.",
    "Inserisci una porzione maggiore di zero."
  ],
  "Enter all four nutrition values. Use 0 if needed.": [
    "Gib alle vier Nährwerte ein. Bei Bedarf 0 eingeben.",
    "Saisissez les quatre valeurs nutritionnelles, même si elles valent 0.",
    "Ange alla fyra näringsvärden. Använd 0 vid behov.",
    "Angi alle fire næringsverdier. Bruk 0 ved behov.",
    "Angiv alle fire næringsværdier. Brug 0 efter behov.",
    "Vul alle vier voedingswaarden in. Gebruik zo nodig 0.",
    "Introduce los cuatro valores nutricionales. Usa 0 si es necesario.",
    "Inserisci tutti e quattro i valori nutrizionali. Usa 0 se necessario."
  ],
  "Add at least one food.": [
    "Füge mindestens ein Lebensmittel hinzu.",
    "Ajoutez au moins un aliment.",
    "Lägg till minst ett livsmedel.",
    "Legg til minst én matvare.",
    "Tilføj mindst én madvare.",
    "Voeg minstens één voedingsmiddel toe.",
    "Añade al menos un alimento.",
    "Aggiungi almeno un alimento."
  ],
  "Enter a valid fibre amount.": [
    "Gib eine gültige Ballaststoffmenge ein.",
    "Saisissez une quantité de fibres valide.",
    "Ange en giltig fibermängd.",
    "Angi en gyldig fibermengde.",
    "Angiv en gyldig fibermængde.",
    "Voer een geldige hoeveelheid vezels in.",
    "Introduce una cantidad de fibra válida.",
    "Inserisci una quantità valida di fibre."
  ],
  "Add your own": [
    "Eigenes hinzufügen",
    "Ajouter le vôtre",
    "Lägg till eget",
    "Legg til eget",
    "Tilføj dit eget",
    "Zelf toevoegen",
    "Añadir el tuyo",
    "Aggiungi il tuo"
  ],
  "Quick entry": [
    "Schnelleintrag",
    "Saisie rapide",
    "Snabbinmatning",
    "Hurtigregistrering",
    "Hurtig registrering",
    "Snel invoeren",
    "Registro rápido",
    "Inserimento rapido"
  ],
  "Combine foods": [
    "Lebensmittel kombinieren",
    "Combiner des aliments",
    "Kombinera livsmedel",
    "Kombiner matvarer",
    "Kombiner madvarer",
    "Voeding combineren",
    "Combinar alimentos",
    "Combina alimenti"
  ],
  "Use values from a label or recipe.": [
    "Werte vom Etikett oder Rezept eingeben.",
    "Utilisez les valeurs d’une étiquette ou d’une recette.",
    "Använd värden från en etikett eller ett recept.",
    "Bruk verdier fra en etikett eller oppskrift.",
    "Brug værdier fra en etiket eller opskrift.",
    "Gebruik waarden van een etiket of recept.",
    "Usa los valores de una etiqueta o receta.",
    "Usa i valori di un’etichetta o ricetta."
  ],
  "Choose foods to build a meal.": [
    "Lebensmittel für deine Mahlzeit auswählen.",
    "Choisissez les aliments de votre repas.",
    "Välj livsmedel till en måltid.",
    "Velg matvarer til et måltid.",
    "Vælg madvarer til et måltid.",
    "Kies voeding voor je maaltijd.",
    "Elige alimentos para crear una comida.",
    "Scegli gli alimenti per creare un pasto."
  ],
  "Food or meal name": [
    "Name des Lebensmittels oder Gerichts",
    "Nom de l’aliment ou du repas",
    "Livsmedlets eller måltidens namn",
    "Navn på matvare eller måltid",
    "Navn på madvare eller måltid",
    "Naam van voeding of maaltijd",
    "Nombre del alimento o comida",
    "Nome dell’alimento o del pasto"
  ],
  "Log to": [
    "Eintragen als",
    "Ajouter à",
    "Logga som",
    "Registrer som",
    "Registrer som",
    "Registreren bij",
    "Registrar en",
    "Registra in"
  ],
  "Save in My meals": [
    "In Meine Mahlzeiten speichern",
    "Enregistrer dans Mes repas",
    "Spara i Mina måltider",
    "Lagre i Mine måltider",
    "Gem i Mine måltider",
    "Bewaren in Mijn maaltijden",
    "Guardar en Mis comidas",
    "Salva in I miei pasti"
  ],
  "New meal": [
    "Neue Mahlzeit",
    "Nouveau repas",
    "Ny måltid",
    "Nytt måltid",
    "Nyt måltid",
    "Nieuwe maaltijd",
    "Nueva comida",
    "Nuovo pasto"
  ],
  'Food library': [
    'Lebensmittel',
    'Bibliothèque alimentaire',
    'Matbibliotek',
    'Matbibliotek',
    'Madbibliotek',
    'Voedingsbibliotheek',
    'Biblioteca de alimentos',
    'Catalogo alimenti'
  ],
  'Show': [
    'Anzeigen',
    'Afficher',
    'Visa',
    'Vis',
    'Vis',
    'Tonen',
    'Mostrar',
    'Mostra'
  ],
  'All categories': [
    'Alle Kategorien',
    'Toutes les catégories',
    'Alla kategorier',
    'Alle kategorier',
    'Alle kategorier',
    'Alle categorieën',
    'Todas las categorías',
    'Tutte le categorie'
  ],
  'New': ['Neu', 'Nouveau', 'Ny', 'Ny', 'Ny', 'Nieuw', 'Nuevo', 'Nuovo'],
  'Choose food': [
    'Lebensmittel auswählen',
    'Choisir un aliment',
    'Välj mat',
    'Velg mat',
    'Vælg mad',
    'Kies voeding',
    'Elegir alimento',
    'Scegli alimento'
  ],
  'Could not load foods.': [
    'Lebensmittel konnten nicht geladen werden.',
    'Impossible de charger les aliments.',
    'Kunde inte ladda maten.',
    'Kunne ikke laste matvarer.',
    'Kunne ikke indlæse madvarer.',
    'Voeding kon niet worden geladen.',
    'No se pudieron cargar los alimentos.',
    'Impossibile caricare gli alimenti.'
  ],
  'Planned for you': [
    'Für dich geplant',
    'Prévu pour vous',
    'Planerat för dig',
    'Planlagt for deg',
    'Planlagt til dig',
    'Voor jou gepland',
    'Planificado para ti',
    'Pianificato per te'
  ],
  'Meals & routine': [
    'Mahlzeiten & Routine',
    'Repas et routine',
    'Måltider och rutin',
    'Måltider og rutine',
    'Måltider og rutine',
    'Maaltijden en routine',
    'Comidas y rutina',
    'Pasti e routine'
  ],
  'Your routine': [
    'Deine Routine',
    'Votre routine',
    'Din rutin',
    'Din rutine',
    'Din rutine',
    'Jouw routine',
    'Tu rutina',
    'La tua routine'
  ],
  'Suggested': [
    'Empfohlen',
    'Suggestion',
    'Föreslaget',
    'Foreslått',
    'Foreslået',
    'Voorgesteld',
    'Sugerido',
    'Suggerito'
  ],
  'Add food': [
    'Essen hinzufügen',
    'Ajouter un aliment',
    'Lägg till mat',
    'Legg til mat',
    'Tilføj mad',
    'Voeding toevoegen',
    'Añadir alimento',
    'Aggiungi alimento'
  ],
  'Diary': [
    'Tagebuch',
    'Journal',
    'Dagbok',
    'Dagbok',
    'Dagbog',
    'Dagboek',
    'Diario',
    'Diario'
  ],
  'Meal plan': [
    'Essensplan',
    'Plan repas',
    'Måltidsplan',
    'Måltidsplan',
    'Madplan',
    'Maaltijdplan',
    'Plan de comidas',
    'Piano pasti'
  ],
  'Recorded intake': [
    'Erfasste Ernährung',
    'Apports enregistrés',
    'Registrerat intag',
    'Registrert inntak',
    'Registreret indtag',
    'Geregistreerde inname',
    'Consumo registrado',
    'Apporto registrato'
  ],
  'Not logged': [
    'Nicht erfasst',
    'Non enregistré',
    'Inte loggat',
    'Ikke logget',
    'Ikke registreret',
    'Niet geregistreerd',
    'Sin registrar',
    'Non registrato'
  ],
  'No meals planned': [
    'Keine Mahlzeiten geplant',
    'Aucun repas prévu',
    'Inga planerade måltider',
    'Ingen planlagte måltider',
    'Ingen planlagte måltider',
    'Geen maaltijden gepland',
    'Sin comidas planificadas',
    'Nessun pasto pianificato'
  ],
  'Water saved': [
    'Wasser gespeichert',
    'Eau enregistrée',
    'Vatten sparat',
    'Vann lagret',
    'Vand gemt',
    'Water opgeslagen',
    'Agua guardada',
    'Acqua salvata'
  ],
  'Could not load water.': [
    'Wasser konnte nicht geladen werden.',
    'Impossible de charger l’eau.',
    'Kunde inte läsa in vatten.',
    'Kunne ikke laste vann.',
    'Kunne ikke indlæse vand.',
    'Water kon niet worden geladen.',
    'No se pudo cargar el agua.',
    'Impossibile caricare l’acqua.'
  ],
  'Showing last saved intake.': [
    'Zuletzt gespeicherte Menge.',
    'Dernière quantité enregistrée.',
    'Senast sparade intag.',
    'Sist lagrede inntak.',
    'Sidst gemte indtag.',
    'Laatst opgeslagen inname.',
    'Última cantidad guardada.',
    'Ultima quantità salvata.'
  ],
  'Read-only': [
    'Nur ansehen',
    'Lecture seule',
    'Skrivskyddad',
    'Skrivebeskyttet',
    'Skrivebeskyttet',
    'Alleen lezen',
    'Solo lectura',
    'Sola lettura'
  ],
  'Save a routine or explore meal suggestions.': [
    'Speichere eine Routine oder entdecke Mahlzeitenvorschläge.',
    'Enregistrez une routine ou découvrez des idées de repas.',
    'Spara en rutin eller utforska måltidsförslag.',
    'Lagre en rutine eller utforsk måltidsforslag.',
    'Gem en rutine eller udforsk måltidsforslag.',
    'Sla een routine op of bekijk maaltijdsuggesties.',
    'Guarda una rutina o descubre sugerencias de comidas.',
    'Salva una routine o scopri suggerimenti per i pasti.'
  ],
  'Log meals as you go.': [
    'Erfasse deine Mahlzeiten im Alltag.',
    'Enregistrez vos repas au fil de la journée.',
    'Logga måltider under dagen.',
    'Logg måltider gjennom dagen.',
    'Registrer måltider i løbet af dagen.',
    'Registreer je maaltijden gedurende de dag.',
    'Registra tus comidas durante el día.',
    'Registra i pasti durante la giornata.'
  ],
  'Fibre': [
    'Ballaststoffe',
    'Fibres',
    'Fiber',
    'Fiber',
    'Kostfibre',
    'Vezels',
    'Fibra',
    'Fibre'
  ],
  'Carbs': [
    'Kohlenhydrate',
    'Glucides',
    'Kolhydrater',
    'Karbohydrater',
    'Kulhydrater',
    'Koolhydraten',
    'Carbohidratos',
    'Carboidrati'
  ],
};

String? nutritionPresentationTranslation(String locale, String text) {
  final index = _languages.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
