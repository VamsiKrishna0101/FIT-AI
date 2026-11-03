const _locales = ['de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'it'];
const _copy = <String, List<String>>{
  "Unlock full plan": [
    "Vollständigen Plan freischalten",
    "Débloquer le programme complet",
    "Lås upp hela planen",
    "Lås opp hele planen",
    "Lås hele planen op",
    "Ontgrendel het volledige plan",
    "Desbloquear el plan completo",
    "Sblocca il piano completo"
  ],
  "Day 1": [
    "Tag 1",
    "Jour 1",
    "Dag 1",
    "Dag 1",
    "Dag 1",
    "Dag 1",
    "Día 1",
    "Giorno 1"
  ],
  "Day 12": [
    "Tag 12",
    "Jour 12",
    "Dag 12",
    "Dag 12",
    "Dag 12",
    "Dag 12",
    "Día 12",
    "Giorno 12"
  ],
  "Explore your full plan": [
    "Entdecke deinen vollständigen Plan",
    "Découvrez votre programme complet",
    "Utforska hela din plan",
    "Utforsk hele planen din",
    "Udforsk hele din plan",
    "Ontdek je volledige plan",
    "Explora tu plan completo",
    "Esplora il tuo piano completo"
  ],
  "Two days left in your trial": [
    "Noch zwei Tage kostenlos testen",
    "Encore deux jours d’essai",
    "Två dagar kvar av provperioden",
    "To dager igjen av prøveperioden",
    "To dage tilbage af prøveperioden",
    "Nog twee dagen proefperiode",
    "Quedan dos días de prueba",
    "Restano due giorni di prova"
  ],
  "Your membership begins": [
    "Deine Mitgliedschaft beginnt",
    "Votre abonnement commence",
    "Ditt medlemskap börjar",
    "Medlemskapet ditt begynner",
    "Dit medlemskab starter",
    "Je lidmaatschap begint",
    "Comienza tu suscripción",
    "Inizia il tuo abbonamento"
  ],
  "Your plan is ready": [
    "Dein Plan ist bereit",
    "Votre programme est prêt",
    "Din plan är klar",
    "Planen din er klar",
    "Din plan er klar",
    "Je plan is klaar",
    "Tu plan está listo",
    "Il tuo piano è pronto"
  ],
  "View full week": [
    "Ganze Woche ansehen",
    "Voir toute la semaine",
    "Visa hela veckan",
    "Se hele uken",
    "Se hele ugen",
    "Bekijk de hele week",
    "Ver toda la semana",
    "Vedi tutta la settimana"
  ],
  "Choose your membership": [
    "Wähle deine Mitgliedschaft",
    "Choisissez votre abonnement",
    "Välj ditt medlemskap",
    "Velg medlemskap",
    "Vælg dit medlemskab",
    "Kies je lidmaatschap",
    "Elige tu suscripción",
    "Scegli il tuo abbonamento"
  ],
  "Train with Setcraft": [
    "Trainiere mit Setcraft",
    "Entraînez-vous avec Setcraft",
    "Träna med Setcraft",
    "Tren med Setcraft",
    "Træn med Setcraft",
    "Train met Setcraft",
    "Entrena con Setcraft",
    "Allenati con Setcraft"
  ],
  "Personalized weekly plans": [
    "Persönliche Wochenpläne",
    "Programmes hebdomadaires personnalisés",
    "Personliga veckoplaner",
    "Personlige ukeplaner",
    "Personlige ugeplaner",
    "Persoonlijke weekplannen",
    "Planes semanales personalizados",
    "Piani settimanali personalizzati"
  ],
  "Exercise guidance and workout tracking": [
    "Übungsanleitungen und Trainingsprotokoll",
    "Conseils et suivi des entraînements",
    "Övningsguider och träningslogg",
    "Øvelsesveiledning og treningslogg",
    "Øvelsesvejledning og træningslog",
    "Oefeninstructies en trainingslogboek",
    "Guías de ejercicios y registro de entrenamientos",
    "Guide agli esercizi e registro allenamenti"
  ],
  "Open my plan": [
    "Meinen Plan öffnen",
    "Ouvrir mon programme",
    "Öppna min plan",
    "Åpne planen min",
    "Åbn min plan",
    "Open mijn plan",
    "Abrir mi plan",
    "Apri il mio piano"
  ],
  "Opening your plan": [
    "Dein Plan wird geöffnet",
    "Ouverture du programme",
    "Öppnar din plan",
    "Åpner planen din",
    "Åbner din plan",
    "Je plan openen",
    "Abriendo tu plan",
    "Apertura del piano"
  ],
  "Start my 14-day trial": [
    "14 Tage kostenlos starten",
    "Commencer mes 14 jours gratuits",
    "Starta mina 14 gratisdagar",
    "Start mine 14 gratisdager",
    "Start mine 14 gratisdage",
    "Start mijn 14 gratis dagen",
    "Empezar mis 14 días gratis",
    "Inizia i miei 14 giorni gratis"
  ],
  "Continue with yearly": [
    "Jährlich fortfahren",
    "Continuer avec l’offre annuelle",
    "Fortsätt med årsplan",
    "Fortsett med årsplan",
    "Fortsæt med årsplan",
    "Ga verder met jaarlijks",
    "Continuar con el plan anual",
    "Continua con il piano annuale"
  ],
  "Continue with monthly": [
    "Monatlich fortfahren",
    "Continuer avec l’offre mensuelle",
    "Fortsätt med månadsplan",
    "Fortsett med månedsplan",
    "Fortsæt med månedsplan",
    "Ga verder met maandelijks",
    "Continuar con el plan mensual",
    "Continua con il piano mensile"
  ],
  "Billed {price} · auto-renews": [
    "Abrechnung {price} · verlängert sich automatisch",
    "Facturé {price} · renouvellement automatique",
    "Debiteras {price} · förnyas automatiskt",
    "Belastes {price} · fornyes automatisk",
    "Faktureres {price} · fornyes automatisk",
    "Gefactureerd {price} · automatisch verlengd",
    "Se cobra {price} · renovación automática",
    "Addebito {price} · rinnovo automatico"
  ],
  "{price}/month, billed yearly": [
    "{price}/Monat, jährlich abgerechnet",
    "{price}/mois, facturé annuellement",
    "{price}/månad, debiteras årsvis",
    "{price}/måned, betales årlig",
    "{price}/måned, betales årligt",
    "{price}/maand, jaarlijks gefactureerd",
    "{price}/mes, facturado anualmente",
    "{price}/mese, addebito annuale"
  ],
  "/year": ["/Jahr", "/an", "/år", "/år", "/år", "/jaar", "/año", "/anno"],
  "/month": [
    "/Monat",
    "/mois",
    "/månad",
    "/måned",
    "/måned",
    "/maand",
    "/mes",
    "/mese"
  ],
  "Payment is unavailable right now": [
    "Zahlung ist gerade nicht verfügbar",
    "Le paiement est indisponible pour le moment",
    "Betalning är inte tillgänglig just nu",
    "Betaling er utilgjengelig akkurat nå",
    "Betaling er ikke tilgængelig lige nu",
    "Betalen is momenteel niet beschikbaar",
    "El pago no está disponible ahora",
    "Il pagamento non è disponibile al momento"
  ],
  "Your plan is saved. Please try again later.": [
    "Dein Plan ist gespeichert. Versuche es später erneut.",
    "Votre programme est enregistré. Réessayez plus tard.",
    "Din plan är sparad. Försök igen senare.",
    "Planen din er lagret. Prøv igjen senere.",
    "Din plan er gemt. Prøv igen senere.",
    "Je plan is opgeslagen. Probeer het later opnieuw.",
    "Tu plan está guardado. Inténtalo más tarde.",
    "Il tuo piano è salvato. Riprova più tardi."
  ],
  "How old are you?": [
    "Wie alt bist du?",
    "Quel âge avez-vous ?",
    "Hur gammal är du?",
    "Hvor gammel er du?",
    "Hvor gammel er du?",
    "Hoe oud ben je?",
    "¿Cuántos años tienes?",
    "Quanti anni hai?"
  ],
  "Enter an age from 13 to 100": [
    "Gib ein Alter von 13 bis 100 ein",
    "Saisissez un âge entre 13 et 100 ans",
    "Ange en ålder mellan 13 och 100",
    "Angi en alder fra 13 til 100",
    "Angiv en alder fra 13 til 100",
    "Voer een leeftijd van 13 tot 100 in",
    "Introduce una edad entre 13 y 100",
    "Inserisci un’età tra 13 e 100"
  ]
};
String? planCheckoutTranslation(String language, String text) {
  final index = _locales.indexOf(language);
  return index < 0 ? null : _copy[text]?[index];
}
