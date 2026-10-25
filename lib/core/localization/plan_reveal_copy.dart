const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  'Signing in': [
    'Anmeldung läuft',
    'Connexion en cours',
    'Loggar in',
    'Logger inn',
    'Logger ind',
    'Bezig met inloggen',
    'Iniciando sesión',
    'Accesso in corso'
  ],
  'Creating account': [
    'Konto wird erstellt',
    'Création du compte',
    'Skapar konto',
    'Oppretter konto',
    'Opretter konto',
    'Account aanmaken',
    'Creando cuenta',
    'Creazione account'
  ],
  'Your plan, your progress, together': [
    'Dein Plan, dein Fortschritt, alles zusammen',
    'Votre programme et vos progrès, réunis',
    'Din plan och dina framsteg, samlade',
    'Planen din og fremgangen din, samlet',
    'Din plan og dine fremskridt, samlet',
    'Je plan en je voortgang, bij elkaar',
    'Tu plan y tu progreso, juntos',
    'Il tuo piano e i tuoi progressi, insieme'
  ],
  'Coming soon': [
    'Demnächst',
    'Bientôt',
    'Kommer snart',
    'Kommer snart',
    'Kommer snart',
    'Binnenkort',
    'Próximamente',
    'Prossimamente'
  ],
  'Continue with email': [
    'Mit E-Mail fortfahren',
    'Continuer avec un e-mail',
    'Fortsätt med e-post',
    'Fortsett med e-post',
    'Fortsæt med e-mail',
    'Doorgaan met e-mail',
    'Continuar con correo',
    'Continua con email'
  ],
  'Muscle focus days': [
    'Training mit Muskelfokus',
    'Séances par groupe musculaire',
    'Muskelfokuserade pass',
    'Økter med muskelfokus',
    'Træning med muskelfokus',
    'Dagen met spierfocus',
    'Días de enfoque muscular',
    'Giorni con focus muscolare'
  ],
  'Your training style': [
    'Dein Trainingsstil',
    'Votre style d’entraînement',
    'Ditt träningsupplägg',
    'Din treningsstil',
    'Din træningsstil',
    'Jouw trainingsstijl',
    'Tu estilo de entrenamiento',
    'Il tuo stile di allenamento'
  ],
  'Final details': [
    'Letzte Details',
    'Derniers détails',
    'Sista detaljerna',
    'Siste detaljer',
    'De sidste detaljer',
    'Laatste details',
    'Últimos detalles',
    'Ultimi dettagli'
  ],
  'Training style': [
    'Trainingsstil',
    'Style d’entraînement',
    'Träningsupplägg',
    'Treningsstil',
    'Træningsstil',
    'Trainingsstijl',
    'Estilo de entrenamiento',
    'Stile di allenamento'
  ],
  'Recommended plan': [
    'Empfohlener Plan',
    'Programme recommandé',
    'Rekommenderat upplägg',
    'Anbefalt plan',
    'Anbefalet plan',
    'Aanbevolen plan',
    'Plan recomendado',
    'Piano consigliato'
  ],
  'Full body sessions': [
    'Ganzkörpertraining',
    'Séances corps entier',
    'Helkroppspass',
    'Helkroppsøkter',
    'Helkropstræning',
    'Volledige lichaamstraining',
    'Sesiones de cuerpo completo',
    'Sessioni per tutto il corpo'
  ],
  'Chest & back / legs': [
    'Brust und Rücken / Beine',
    'Pectoraux et dos / jambes',
    'Bröst och rygg / ben',
    'Bryst og rygg / bein',
    'Bryst og ryg / ben',
    'Borst en rug / benen',
    'Pecho y espalda / piernas',
    'Petto e schiena / gambe'
  ],
  'Chest / back / legs': [
    'Brust / Rücken / Beine',
    'Pectoraux / dos / jambes',
    'Bröst / rygg / ben',
    'Bryst / rygg / bein',
    'Bryst / ryg / ben',
    'Borst / rug / benen',
    'Pecho / espalda / piernas',
    'Petto / schiena / gambe'
  ],
  'One muscle group a day': [
    'Eine Muskelgruppe pro Tag',
    'Un groupe musculaire par jour',
    'En muskelgrupp per dag',
    'Én muskelgruppe per dag',
    'Én muskelgruppe om dagen',
    'Eén spiergroep per dag',
    'Un grupo muscular al día',
    'Un gruppo muscolare al giorno'
  ],
  'Choose each day': [
    'Jeden Tag selbst wählen',
    'Choisir chaque jour',
    'Välj för varje dag',
    'Velg for hver dag',
    'Vælg for hver dag',
    'Kies per dag',
    'Elegir cada día',
    'Scegli per ogni giorno'
  ],
  'Day {number}': [
    'Tag {number}',
    'Jour {number}',
    'Dag {number}',
    'Dag {number}',
    'Dag {number}',
    'Dag {number}',
    'Día {number}',
    'Giorno {number}'
  ],
  'Include chest, back and legs across your week': [
    'Plane Brust, Rücken und Beine über die Woche ein',
    'Incluez pectoraux, dos et jambes dans votre semaine',
    'Ta med bröst, rygg och ben under veckan',
    'Ta med bryst, rygg og bein i løpet av uken',
    'Få bryst, ryg og ben med i løbet af ugen',
    'Neem borst, rug en benen op in je week',
    'Incluye pecho, espalda y piernas durante la semana',
    'Includi petto, schiena e gambe nella settimana'
  ],
  'Change training style': [
    'Trainingsstil ändern',
    'Changer de style',
    'Byt träningsupplägg',
    'Endre treningsstil',
    'Skift træningsstil',
    'Trainingsstijl wijzigen',
    'Cambiar estilo',
    'Cambia stile'
  ],
  'Movements to avoid': [
    'Bewegungen, die du meiden sollst',
    'Mouvements à éviter',
    'Rörelser att undvika',
    'Bevegelser du bør unngå',
    'Bevægelser du skal undgå',
    'Bewegingen om te vermijden',
    'Movimientos que debes evitar',
    'Movimenti da evitare'
  ],
  'Choose as many as you like': [
    'Wähle so viele aus, wie du möchtest',
    'Choisissez-en autant que vous voulez',
    'Välj så många du vill',
    'Velg så mange du vil',
    'Vælg så mange, du vil',
    'Kies er zoveel als je wilt',
    'Elige tantos como quieras',
    'Scegli quanti ne vuoi'
  ],
  'Your goals, your plan': [
    'Deine Ziele, dein Plan',
    'Vos objectifs, votre programme',
    'Dina mål, din plan',
    'Dine mål, din plan',
    'Dine mål, din plan',
    'Jouw doelen, jouw plan',
    'Tus objetivos, tu plan',
    'I tuoi obiettivi, il tuo piano'
  ],
  'Membership required': [
    'Mitgliedschaft erforderlich',
    'Abonnement requis',
    'Medlemskap krävs',
    'Medlemskap kreves',
    'Medlemskab påkrævet',
    'Lidmaatschap vereist',
    'Requiere suscripción',
    'Abbonamento richiesto'
  ],
  'Choose your membership next': [
    'Wähle als Nächstes deine Mitgliedschaft',
    'Choisissez ensuite votre abonnement',
    'Välj ditt medlemskap i nästa steg',
    'Velg medlemskap i neste steg',
    'Vælg dit medlemskab i næste trin',
    'Kies hierna je lidmaatschap',
    'Elige tu suscripción a continuación',
    'Scegli il tuo abbonamento al prossimo passo'
  ],
  'Start my first workout': [
    'Mein erstes Training starten',
    'Commencer ma première séance',
    'Starta mitt första pass',
    'Start min første økt',
    'Start min første træning',
    'Start mijn eerste training',
    'Empezar mi primer entrenamiento',
    'Inizia il mio primo allenamento'
  ],
  'View my first workout': [
    'Mein erstes Training ansehen',
    'Voir ma première séance',
    'Visa mitt första pass',
    'Se min første økt',
    'Se min første træning',
    'Bekijk mijn eerste training',
    'Ver mi primer entrenamiento',
    'Vedi il mio primo allenamento'
  ],
  'Get started': [
    'Los geht’s',
    'Commencer',
    'Kom igång',
    'Kom i gang',
    'Kom i gang',
    'Aan de slag',
    'Empezar',
    'Inizia'
  ],
  'Ready for your next chapter?': [
    'Bereit für dein nächstes Kapitel?',
    'Prêt pour la prochaine étape ?',
    'Redo för nästa kapitel?',
    'Klar for neste kapittel?',
    'Klar til dit næste kapitel?',
    'Klaar voor je volgende hoofdstuk?',
    '¿Listo para tu siguiente etapa?',
    'Pronto per il prossimo capitolo?'
  ],
  'Build muscle': [
    'Muskeln aufbauen',
    'Développez vos muscles',
    'Bygg muskler',
    'Bygg muskler',
    'Opbyg muskler',
    'Bouw spieren op',
    'Gana músculo',
    'Sviluppa i muscoli'
  ],
  'Get stronger': [
    'Stärker werden',
    'Gagnez en force',
    'Bli starkare',
    'Bli sterkere',
    'Bliv stærkere',
    'Word sterker',
    'Gana fuerza',
    'Diventa più forte'
  ],
  'Stay consistent': [
    'Dranbleiben',
    'Gardez le rythme',
    'Håll i träningen',
    'Hold treningen i gang',
    'Hold fast i træningen',
    'Blijf consequent',
    'Mantén la constancia',
    'Mantieni la costanza'
  ],
  'Personalized workouts for your goals, experience and equipment.': [
    'Persönliches Training für deine Ziele, Erfahrung und Ausrüstung.',
    'Des séances adaptées à vos objectifs, votre expérience et votre matériel.',
    'Personliga pass för dina mål, din erfarenhet och utrustning.',
    'Personlige økter for målene, erfaringen og utstyret ditt.',
    'Personlige træninger til dine mål, din erfaring og dit udstyr.',
    'Trainingen afgestemd op je doelen, ervaring en materiaal.',
    'Entrenamientos adaptados a tus objetivos, experiencia y equipo.',
    'Allenamenti adatti ai tuoi obiettivi, esperienza e attrezzatura.'
  ],
  'Personalized training. Membership required.': [
    'Persönliches Training. Mitgliedschaft erforderlich.',
    'Entraînement personnalisé. Abonnement requis.',
    'Personlig träning. Medlemskap krävs.',
    'Personlig trening. Medlemskap kreves.',
    'Personlig træning. Medlemskab påkrævet.',
    'Persoonlijke training. Lidmaatschap vereist.',
    'Entrenamiento personalizado. Requiere suscripción.',
    'Allenamento personalizzato. Abbonamento richiesto.'
  ],
  '{name}, your plan is ready': [
    '{name}, dein Plan ist bereit',
    '{name}, votre programme est prêt',
    '{name}, din plan är klar',
    '{name}, planen din er klar',
    '{name}, din plan er klar',
    '{name}, je plan is klaar',
    '{name}, tu plan está listo',
    '{name}, il tuo piano è pronto'
  ],
  'Your plan is ready': [
    'Dein Plan ist bereit',
    'Votre programme est prêt',
    'Din plan är klar',
    'Planen din er klar',
    'Din plan er klar',
    'Je plan is klaar',
    'Tu plan está listo',
    'Il tuo piano è pronto'
  ],
  'Your plan': [
    'Dein Plan',
    'Votre programme',
    'Din plan',
    'Planen din',
    'Din plan',
    'Je plan',
    'Tu plan',
    'Il tuo piano'
  ],
  'Unlock my plan': [
    'Meinen Plan freischalten',
    'Débloquer mon programme',
    'Lås upp min plan',
    'Lås opp planen min',
    'Lås min plan op',
    'Ontgrendel mijn plan',
    'Desbloquear mi plan',
    'Sblocca il mio piano'
  ],
  'Your weekly muscle coverage': [
    'Deine Muskelgruppen für die Woche',
    'Vos groupes musculaires de la semaine',
    'Veckans muskelgrupper',
    'Ukens muskelgrupper',
    'Ugens muskelgrupper',
    'Je spiergroepen deze week',
    'Tus grupos musculares de la semana',
    'I tuoi gruppi muscolari della settimana'
  ],
  'Full exercise details unlock with your membership.': [
    'Alle Übungsdetails werden mit deiner Mitgliedschaft freigeschaltet.',
    'Votre abonnement débloque tous les détails des exercices.',
    'Medlemskapet låser upp alla övningsdetaljer.',
    'Medlemskapet låser opp alle øvelsesdetaljene.',
    'Dit medlemskab låser alle øvelsesdetaljer op.',
    'Je lidmaatschap ontgrendelt alle oefendetails.',
    'Tu suscripción desbloquea todos los detalles de los ejercicios.',
    'L’abbonamento sblocca tutti i dettagli degli esercizi.'
  ],
  'From your week': [
    'Aus deiner Woche',
    'Dans votre semaine',
    'Från din vecka',
    'Fra uken din',
    'Fra din uge',
    'Uit je week',
    'De tu semana',
    'Dalla tua settimana'
  ],
  'Why this fits you': [
    'Warum das zu dir passt',
    'Pourquoi ce programme vous convient',
    'Därför passar det dig',
    'Derfor passer dette deg',
    'Derfor passer det til dig',
    'Waarom dit bij je past',
    'Por qué se adapta a ti',
    'Perché è adatto a te'
  ],
  'Built from your goals, experience, equipment and available training days.': [
    'Auf deine Ziele, Erfahrung, Ausrüstung und verfügbaren Trainingstage abgestimmt.',
    'Conçu selon vos objectifs, votre expérience, votre matériel et vos jours disponibles.',
    'Byggt utifrån dina mål, din erfarenhet, din utrustning och dina tillgängliga träningsdagar.',
    'Bygget på målene, erfaringen, utstyret og de tilgjengelige treningsdagene dine.',
    'Tilpasset dine mål, din erfaring, dit udstyr og dine ledige træningsdage.',
    'Gebaseerd op je doelen, ervaring, materiaal en beschikbare trainingsdagen.',
    'Basado en tus objetivos, experiencia, equipo y días disponibles para entrenar.',
    'Creato in base ai tuoi obiettivi, esperienza, attrezzatura e giorni disponibili.'
  ],
  'Gym & home': [
    'Studio und zu Hause',
    'Salle et domicile',
    'Gym och hemma',
    'Treningssenter og hjemme',
    'Fitnesscenter og hjemme',
    'Sportschool en thuis',
    'Gimnasio y casa',
    'Palestra e casa'
  ],
};
String? planRevealTranslation(String locale, String source) {
  final index = _locales.indexOf(locale);
  final row = _copy[source];
  return index < 0 || row == null ? null : row[index];
}
