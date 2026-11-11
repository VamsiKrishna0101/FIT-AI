// Entry-screen copy shares the app's eight non-English language families.
const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "BUILT AROUND YOU": [
    "AUF DICH ABGESTIMMT",
    "CONÇU POUR VOUS",
    "ANPASSAT EFTER DIG",
    "TILPASSET DEG",
    "TILPASSET DIG",
    "AFGESTEMD OP JOU",
    "DISEÑADO PARA TI",
    "PENSATO PER TE"
  ],
  "Know exactly\nwhat to train.": [
    "Wisse genau,\nwas du trainierst.",
    "Sachez exactement\nquoi travailler.",
    "Vet precis\nvad du ska träna.",
    "Vit nøyaktig\nhva du skal trene.",
    "Vid præcis,\nhvad du skal træne.",
    "Weet precies\nwat je gaat trainen.",
    "Ten claro\nqué entrenar.",
    "Sai esattamente\ncosa allenare."
  ],
  "Personal workouts, nutrition & recovery.\nSee your progress, all in one place.":
      [
    "Persönliches Training, Ernährung und Erholung.\nDeine Fortschritte an einem Ort.",
    "Entraînement, nutrition et récupération adaptés.\nTous vos progrès au même endroit.",
    "Personlig träning, kost och återhämtning.\nAlla dina framsteg på ett ställe.",
    "Personlig trening, kost og restitusjon.\nSe fremgangen din på ett sted.",
    "Personlig træning, kost og restitution.\nSe dine fremskridt ét sted.",
    "Persoonlijke training, voeding en herstel.\nAl je vooruitgang op één plek.",
    "Entrenamiento, nutrición y recuperación.\nTodo tu progreso en un solo lugar.",
    "Allenamenti, nutrizione e recupero su misura.\nTutti i tuoi progressi in un unico posto."
  ],
  "Hi! I'm Mochi, your AI coach": [
    "Hi! Ich bin Mochi, dein KI-Coach",
    "Bonjour ! Je suis Mochi, votre coach IA",
    "Hej! Jag är Mochi, din AI-coach",
    "Hei! Jeg er Mochi, din AI-coach",
    "Hej! Jeg er Mochi, din AI-coach",
    "Hoi! Ik ben Mochi, je AI-coach",
    "¡Hola! Soy Mochi, tu coach de IA",
    "Ciao! Sono Mochi, il tuo coach IA"
  ],
  "Done! I built this week around your answers": [
    "Fertig! Ich habe diese Woche nach deinen Antworten geplant",
    "C’est prêt ! J’ai construit cette semaine selon vos réponses",
    "Klart! Jag byggde veckan utifrån dina svar",
    "Ferdig! Jeg bygde uken rundt svarene dine",
    "Færdig! Jeg byggede ugen ud fra dine svar",
    "Klaar! Ik heb deze week op jouw antwoorden afgestemd",
    "¡Listo! Armé esta semana según tus respuestas",
    "Fatto! Ho creato questa settimana in base alle tue risposte"
  ],
  "WORKOUT PREVIEW": [
    "TRAININGSVORSCHAU",
    "APERÇU D’ENTRAÎNEMENT",
    "TRÄNINGSFÖRHANDSVISNING",
    "FORHÅNDSVISNING AV ØKT",
    "FORHÅNDSVISNING AF TRÆNING",
    "TRAININGSVOORBEELD",
    "VISTA PREVIA DEL ENTRENO",
    "ANTEPRIMA ALLENAMENTO"
  ],
  "Dumbbell bench press": [
    "Kurzhantel-Bankdrücken",
    "Développé couché avec haltères",
    "Bänkpress med hantlar",
    "Benkpress med manualer",
    "Bænkpres med håndvægte",
    "Bankdrukken met dumbbells",
    "Press de banca con mancuernas",
    "Distensioni con manubri su panca"
  ],
  "3 sets · 10 reps": [
    "3 Sätze · 10 Wdh.",
    "3 séries · 10 rép.",
    "3 set · 10 reps",
    "3 sett · 10 reps",
    "3 sæt · 10 reps",
    "3 sets · 10 herh.",
    "3 series · 10 rep.",
    "3 serie · 10 rip."
  ],
};

String? welcomePresentationTranslation(String locale, String text) {
  final index = _locales.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
