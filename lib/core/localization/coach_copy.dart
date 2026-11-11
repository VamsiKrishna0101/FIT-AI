// Mochi's in-app lines share the app's eight non-English language families.
const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "Workout done! That's how progress is made": [
    "Training geschafft! So entsteht Fortschritt",
    "Séance terminée ! C’est comme ça qu’on progresse",
    "Passet klart! Det är så framsteg skapas",
    "Økta er ferdig! Det er sånn fremgang skapes",
    "Træningen er klaret! Sådan skabes fremskridt",
    "Training klaar! Zo boek je vooruitgang",
    "¡Entreno hecho! Así se progresa",
    "Allenamento fatto! È così che si progredisce"
  ],
  "Rest day. Recovery builds muscle too": [
    "Ruhetag. Auch Erholung baut Muskeln auf",
    "Jour de repos. La récupération construit aussi le muscle",
    "Vilodag. Återhämtning bygger också muskler",
    "Hviledag. Restitusjon bygger også muskler",
    "Hviledag. Restitution bygger også muskler",
    "Rustdag. Herstel bouwt ook spieren op",
    "Día de descanso. Recuperarse también construye músculo",
    "Giorno di riposo. Anche il recupero costruisce muscoli"
  ],
  "Workout done today. Proud of you!": [
    "Heute trainiert. Ich bin stolz auf dich!",
    "Séance faite aujourd’hui. Bravo à vous !",
    "Dagens pass är klart. Jag är stolt över dig!",
    "Dagens økt er gjort. Jeg er stolt av deg!",
    "Dagens træning er klaret. Jeg er stolt af dig!",
    "Training van vandaag gedaan. Ik ben trots op je!",
    "Entreno de hoy hecho. ¡Qué orgullo!",
    "Allenamento di oggi fatto. Che orgoglio!"
  ],
  "Let's build your plan for this week": [
    "Lass uns deinen Plan für diese Woche erstellen",
    "Créons votre plan pour cette semaine",
    "Nu bygger vi din plan för veckan",
    "La oss lage planen din for denne uken",
    "Lad os lave din plan for denne uge",
    "Laten we je plan voor deze week maken",
    "Vamos a crear tu plan para esta semana",
    "Creiamo il tuo piano per questa settimana"
  ],
  "I'm building your week right now": [
    "Ich erstelle gerade deine Woche",
    "Je prépare votre semaine en ce moment",
    "Jag bygger din vecka just nu",
    "Jeg lager uken din akkurat nå",
    "Jeg bygger din uge lige nu",
    "Ik maak je week nu klaar",
    "Estoy preparando tu semana ahora mismo",
    "Sto preparando la tua settimana proprio ora"
  ],
  "Got it ✓": [
    "Verstanden ✓",
    "C’est noté ✓",
    "Uppfattat ✓",
    "Skjønner ✓",
    "Forstået ✓",
    "Begrepen ✓",
    "Entendido ✓",
    "Capito ✓"
  ],
  "Nice pick 👌": [
    "Gute Wahl 👌",
    "Bon choix 👌",
    "Bra val 👌",
    "Godt valg 👌",
    "Godt valg 👌",
    "Goede keuze 👌",
    "Buena elección 👌",
    "Ottima scelta 👌"
  ],
  "Love that 💪": [
    "Stark 💪",
    "J’adore 💪",
    "Gillar det 💪",
    "Elsker det 💪",
    "Elsker det 💪",
    "Top 💪",
    "Me encanta 💪",
    "Mi piace 💪"
  ],
  "Noted ✨": [
    "Notiert ✨",
    "Noté ✨",
    "Noterat ✨",
    "Notert ✨",
    "Noteret ✨",
    "Genoteerd ✨",
    "Anotado ✨",
    "Annotato ✨"
  ],
  "Nice to meet you, {name}! 👋": [
    "Schön, dich kennenzulernen, {name}! 👋",
    "Ravi de vous rencontrer, {name} ! 👋",
    "Kul att träffas, {name}! 👋",
    "Hyggelig å møte deg, {name}! 👋",
    "Dejligt at møde dig, {name}! 👋",
    "Leuk je te ontmoeten, {name}! 👋",
    "¡Encantado de conocerte, {name}! 👋",
    "Piacere di conoscerti, {name}! 👋"
  ],
  "{count} days in a row. Who even are you 🔥": [
    "{count} Tage am Stück. Wer bist du bitte? 🔥",
    "{count} jours d’affilée. Mais qui êtes-vous ? 🔥",
    "{count} dagar i rad. Vem är du ens? 🔥",
    "{count} dager på rad. Hvem er du egentlig? 🔥",
    "{count} dage i træk. Hvem er du lige? 🔥",
    "{count} dagen op rij. Wie ben jij eigenlijk? 🔥",
    "{count} días seguidos. ¿Quién eres? 🔥",
    "{count} giorni di fila. Ma chi sei? 🔥"
  ],
  "+{amount} kg more than last time 💪": [
    "+{amount} kg mehr als letztes Mal 💪",
    "+{amount} kg de plus que la dernière fois 💪",
    "+{amount} kg mer än förra gången 💪",
    "+{amount} kg mer enn sist 💪",
    "+{amount} kg mere end sidst 💪",
    "+{amount} kg meer dan vorige keer 💪",
    "+{amount} kg más que la última vez 💪",
    "+{amount} kg in più dell’ultima volta 💪"
  ],
  "{count} more reps than last time 💪": [
    "{count} Wiederholungen mehr als letztes Mal 💪",
    "{count} répétitions de plus que la dernière fois 💪",
    "{count} fler reps än förra gången 💪",
    "{count} flere reps enn sist 💪",
    "{count} flere gentagelser end sidst 💪",
    "{count} herhalingen meer dan vorige keer 💪",
    "{count} repeticiones más que la última vez 💪",
    "{count} ripetizioni in più dell’ultima volta 💪"
  ],
  "First one logged. Great start ✅": [
    "Das erste ist geschafft. Starker Anfang ✅",
    "Première séance enregistrée. Excellent début ✅",
    "Första passet loggat. Bra start ✅",
    "Første økt logget. God start ✅",
    "Første træning logget. God start ✅",
    "Eerste training gelogd. Goed begin ✅",
    "Primer entreno registrado. Gran comienzo ✅",
    "Primo allenamento registrato. Ottimo inizio ✅"
  ],
};

String? coachTranslation(String locale, String text) {
  final index = _locales.indexOf(locale);
  return index < 0 ? null : _copy[text]?[index];
}
