import 'package:flutter/material.dart';
import '../../features/onboarding/models/experience_level.dart';
import '../../features/onboarding/models/training_schedule_models.dart';
import '../../features/onboarding/models/working_toward_goal.dart';

// MARK: - Top 10 European Fitness & Gym Powerhouse Markets
enum AppLanguage {
  uk('en', 'GB', '🇬🇧', 'English', 'United Kingdom', Color(0xFFD0EBFF)),
  germany('de', 'DE', '🇩🇪', 'Deutsch', 'Deutschland', Color(0xFFFFF3BF)),
  switzerland(
      'de-CH', 'CH', '🇨🇭', 'Deutsch (Schweiz)', 'Schweiz', Color(0xFFD3F9D8)),
  france('fr', 'FR', '🇫🇷', 'Français', 'France', Color(0xFFE3FAFC)),
  sweden('sv', 'SE', '🇸🇪', 'Svenska', 'Sverige', Color(0xFFC5F6FA)),
  norway('no', 'NO', '🇳🇴', 'Norsk', 'Norge', Color(0xFFE5DBFF)),
  denmark('da', 'DK', '🇩🇰', 'Dansk', 'Danmark', Color(0xFFFFD8D8)),
  netherlands('nl', 'NL', '🇳🇱', 'Nederlands', 'Nederland', Color(0xFFFFE8CC)),
  spain('es', 'ES', '🇪🇸', 'Español', 'España', Color(0xFFFFF9DB)),
  italy('it', 'IT', '🇮🇹', 'Italiano', 'Italia', Color(0xFFD8F5A2));

  final String code;
  final String countryCode;
  final String flag;
  final String nativeName;
  final String countryName;
  final Color pastelColor;

  const AppLanguage(
    this.code,
    this.countryCode,
    this.flag,
    this.nativeName,
    this.countryName,
    this.pastelColor,
  );

  Locale get locale {
    final languageAndRegion = code.split('-');
    return Locale.fromSubtags(
      languageCode: languageAndRegion.first,
      countryCode:
          languageAndRegion.length > 1 ? languageAndRegion[1] : countryCode,
    );
  }

  String get continueButtonTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Continue';
      case AppLanguage.germany:
        return "LOS GEHT'S";
      case AppLanguage.switzerland:
        return "LOS GAHT'S";
      case AppLanguage.france:
        return "C'EST PARTI";
      case AppLanguage.sweden:
        return "NU KÖR VI";
      case AppLanguage.norway:
        return "LA OSS GÅ";
      case AppLanguage.denmark:
        return "LAD OS GÅ";
      case AppLanguage.netherlands:
        return "LATEN WE GAAN";
      case AppLanguage.spain:
        return "VAMOS";
      case AppLanguage.italy:
        return "ANDIAMO";
    }
  }

  String get settingsNote {
    switch (this) {
      case AppLanguage.uk:
        return 'Change it up anytime in Settings';
      case AppLanguage.germany:
        return 'Jederzeit in den Einstellungen ändern';
      case AppLanguage.switzerland:
        return 'Jederziit i de Iistellige änderbar';
      case AppLanguage.france:
        return 'Modifiable à tout moment dans Réglages';
      case AppLanguage.sweden:
        return 'Ändra när som helst i Inställningar';
      case AppLanguage.norway:
        return 'Endre når som helst i Innstillinger';
      case AppLanguage.denmark:
        return 'Skift når som helst i Indstillinger';
      case AppLanguage.netherlands:
        return 'Altijd te wijzigen in Instellingen';
      case AppLanguage.spain:
        return 'Cámbialo en cualquier momento en Ajustes';
      case AppLanguage.italy:
        return 'Modificalo in qualsiasi momento nelle Impostazioni';
    }
  }

  String get headline {
    switch (this) {
      case AppLanguage.uk:
        return 'Speak Your Language';
      case AppLanguage.germany:
        return 'Deine Sprache, Dein Coach';
      case AppLanguage.switzerland:
        return 'Dini Spraach, Din Coach';
      case AppLanguage.france:
        return 'Parlez Votre Langue';
      case AppLanguage.sweden:
        return 'Tala Ditt Språk';
      case AppLanguage.norway:
        return 'Snakk Ditt Språk';
      case AppLanguage.denmark:
        return 'Tal Dit Sprog';
      case AppLanguage.netherlands:
        return 'Spreek Jouw Taal';
      case AppLanguage.spain:
        return 'Habla Tu Idioma';
      case AppLanguage.italy:
        return 'Parla La Tua Lingua';
    }
  }

  String get subtitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Pick your daily driver for personalized coaching. Your FitAI, your vibe.';
      case AppLanguage.germany:
        return 'Wähle Deinen Favoriten für personalisiertes Coaching. Dein FitAI, Dein Vibe.';
      case AppLanguage.switzerland:
        return 'Wähl din Favorit für dis Coaching. Dis FitAI, din Vibe.';
      case AppLanguage.france:
        return 'Choisissez votre langue pour un coaching sur-mesure. Votre FitAI, votre vibe.';
      case AppLanguage.sweden:
        return 'Välj ditt språk för personlig coachning. Din FitAI, din vibe.';
      case AppLanguage.norway:
        return 'Velg ditt daglige språk for personlig veiledning. Din FitAI, din vibe.';
      case AppLanguage.denmark:
        return 'Vælg dit foretrukne sprog til personlig coaching. Din FitAI, dit vibe.';
      case AppLanguage.netherlands:
        return 'Kies jouw taal voor persoonlijke coaching. Jouw FitAI, jouw vibe.';
      case AppLanguage.spain:
        return 'Elige tu idioma para un entrenamiento a tu medida. Tu FitAI, tu vibra.';
      case AppLanguage.italy:
        return 'Scegli la tua lingua per un coaching personalizzato. Il tuo FitAI, il tuo vibe.';
    }
  }

  // MARK: - Screen 01: Your Goal Translations
  String get headlineGoal {
    switch (this) {
      case AppLanguage.uk:
        return 'What are you working toward?';
      case AppLanguage.germany:
        return 'Was ist Dein Hauptziel?';
      case AppLanguage.switzerland:
        return 'Was isch dis Hauptziel?';
      case AppLanguage.france:
        return 'Quel est votre objectif ?';
      case AppLanguage.sweden:
        return 'Vad strävar du mot?';
      case AppLanguage.norway:
        return 'Hva jobber du mot?';
      case AppLanguage.denmark:
        return 'Hvad er dit hovedmål?';
      case AppLanguage.netherlands:
        return 'Waar werk je naartoe?';
      case AppLanguage.spain:
        return '¿Cuál es tu objetivo?';
      case AppLanguage.italy:
        return 'Qual è il tuo obiettivo?';
    }
  }

  String get subtitleGoal {
    switch (this) {
      case AppLanguage.uk:
        return 'Pick your primary fitness focus. FitAI personalizes your program around this.';
      case AppLanguage.germany:
        return 'Wähle Deinen Trainingsfokus. FitAI passt Dein Programm maßgeschneidert an.';
      case AppLanguage.switzerland:
        return 'Wähl din Trainingsfokus. FitAI passt dis Coaching genau uf dich aa.';
      case AppLanguage.france:
        return 'Sélectionnez votre priorité sportive. FitAI personnalise vos entraînements sur mesure.';
      case AppLanguage.sweden:
        return 'Välj ditt främsta träningsmål. FitAI anpassar din träning därefter.';
      case AppLanguage.norway:
        return 'Velg ditt viktigste treningsmål. FitAI skreddersyr treningen for deg.';
      case AppLanguage.denmark:
        return 'Vælg dit primære fitnessfokus. FitAI skræddersyr din træning til dig.';
      case AppLanguage.netherlands:
        return 'Kies jouw belangrijkste fitnessfocus. FitAI stemt je schema hierop af.';
      case AppLanguage.spain:
        return 'Elige tu enfoque principal. FitAI adaptará tus entrenamientos a tu medida.';
      case AppLanguage.italy:
        return 'Scegli il tuo focus principale. FitAI personalizzerà i tuoi allenamenti.';
    }
  }

  String goalTitle(WorkingTowardGoal goal) {
    switch (this) {
      case AppLanguage.uk:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Build Muscle';
          case WorkingTowardGoal.loseBodyFat:
            return 'Lose Body Fat';
          case WorkingTowardGoal.loseWeight:
            return 'Lose Weight';
          case WorkingTowardGoal.getFitter:
            return 'Get Fitter';
          case WorkingTowardGoal.buildConsistency:
            return 'Build Consistency';
        }
      case AppLanguage.germany:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Muskelaufbau';
          case WorkingTowardGoal.loseBodyFat:
            return 'Körperfett abbauen';
          case WorkingTowardGoal.loseWeight:
            return 'Gewicht verlieren';
          case WorkingTowardGoal.getFitter:
            return 'Fitter werden';
          case WorkingTowardGoal.buildConsistency:
            return 'Routine aufbauen';
        }
      case AppLanguage.switzerland:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Muskelufbau';
          case WorkingTowardGoal.loseBodyFat:
            return 'Chörperfett abboue';
          case WorkingTowardGoal.loseWeight:
            return 'Gwicht verlüre';
          case WorkingTowardGoal.getFitter:
            return 'Fitter werde';
          case WorkingTowardGoal.buildConsistency:
            return 'Routine ufbaue';
        }
      case AppLanguage.france:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Prendre du muscle';
          case WorkingTowardGoal.loseBodyFat:
            return 'Brûler les graisses';
          case WorkingTowardGoal.loseWeight:
            return 'Perdre du poids';
          case WorkingTowardGoal.getFitter:
            return 'Être en forme';
          case WorkingTowardGoal.buildConsistency:
            return 'Créer une routine';
        }
      case AppLanguage.sweden:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Bygga muskler';
          case WorkingTowardGoal.loseBodyFat:
            return 'Minska kroppsfett';
          case WorkingTowardGoal.loseWeight:
            return 'Gå ner i vikt';
          case WorkingTowardGoal.getFitter:
            return 'Bli mer vältränad';
          case WorkingTowardGoal.buildConsistency:
            return 'Skapa goda vanor';
        }
      case AppLanguage.norway:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Bygge muskler';
          case WorkingTowardGoal.loseBodyFat:
            return 'Bli kvitt kroppsfett';
          case WorkingTowardGoal.loseWeight:
            return 'Gå ned i vekt';
          case WorkingTowardGoal.getFitter:
            return 'Bli i bedre form';
          case WorkingTowardGoal.buildConsistency:
            return 'Bygge kontinuitet';
        }
      case AppLanguage.denmark:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Opbygge muskler';
          case WorkingTowardGoal.loseBodyFat:
            return 'Forbrænde fedt';
          case WorkingTowardGoal.loseWeight:
            return 'Tabe sig';
          case WorkingTowardGoal.getFitter:
            return 'Komme i form';
          case WorkingTowardGoal.buildConsistency:
            return 'Skabe en vane';
        }
      case AppLanguage.netherlands:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Spieren opbouwen';
          case WorkingTowardGoal.loseBodyFat:
            return 'Vetpercentage verlagen';
          case WorkingTowardGoal.loseWeight:
            return 'Gewicht verliezen';
          case WorkingTowardGoal.getFitter:
            return 'Fitter worden';
          case WorkingTowardGoal.buildConsistency:
            return 'Gewoonte opbouwen';
        }
      case AppLanguage.spain:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Ganar músculo';
          case WorkingTowardGoal.loseBodyFat:
            return 'Perder grasa corporal';
          case WorkingTowardGoal.loseWeight:
            return 'Bajar de peso';
          case WorkingTowardGoal.getFitter:
            return 'Ponerse en forma';
          case WorkingTowardGoal.buildConsistency:
            return 'Crear constancia';
        }
      case AppLanguage.italy:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Aumentare massa muscolare';
          case WorkingTowardGoal.loseBodyFat:
            return 'Ridurre grasso corporeo';
          case WorkingTowardGoal.loseWeight:
            return 'Perdere peso';
          case WorkingTowardGoal.getFitter:
            return 'Migliorare la forma';
          case WorkingTowardGoal.buildConsistency:
            return 'Costruire costanza';
        }
    }
  }

  String goalSubtitle(WorkingTowardGoal goal) {
    switch (this) {
      case AppLanguage.uk:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrophy, raw strength & gains';
          case WorkingTowardGoal.loseBodyFat:
            return 'Lean definition & metabolic boost';
          case WorkingTowardGoal.loseWeight:
            return 'Sustainable deficit & scale progress';
          case WorkingTowardGoal.getFitter:
            return 'Stamina, endurance & everyday energy';
          case WorkingTowardGoal.buildConsistency:
            return 'Solid daily habits that stick forever';
        }
      case AppLanguage.germany:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrophie, Kraft & Muskelmasse';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definition & aktiver Stoffwechsel';
          case WorkingTowardGoal.loseWeight:
            return 'Nachhaltiges Defizit & Gewichtsabnahme';
          case WorkingTowardGoal.getFitter:
            return 'Ausdauer, Kondition & mehr Energie';
          case WorkingTowardGoal.buildConsistency:
            return 'Feste Gewohnheiten, die bleiben';
        }
      case AppLanguage.switzerland:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrophi, Chraft & Muskle';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definizioon & Stoffwächsel-Boost';
          case WorkingTowardGoal.loseWeight:
            return 'Nachhaltigs Defizit & Gwichtsverluscht';
          case WorkingTowardGoal.getFitter:
            return 'Uusduur, Kondizioon & Energie';
          case WorkingTowardGoal.buildConsistency:
            return 'Feschti Gwohnheite, wo hebed';
        }
      case AppLanguage.france:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrophie, force pure & volume';
          case WorkingTowardGoal.loseBodyFat:
            return 'Définition sèche & métabolisme vif';
          case WorkingTowardGoal.loseWeight:
            return 'Déficit durable & progrès réguliers';
          case WorkingTowardGoal.getFitter:
            return 'Endurance, vitalité & dynamisme';
          case WorkingTowardGoal.buildConsistency:
            return 'Des habitudes solides et durables';
        }
      case AppLanguage.sweden:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrofi, styrka & muskelmassa';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definition & högre förbränning';
          case WorkingTowardGoal.loseWeight:
            return 'Hållbart underskott & viktnedgång';
          case WorkingTowardGoal.getFitter:
            return 'Kondition, uthållighet & energi';
          case WorkingTowardGoal.buildConsistency:
            return 'Stabila träningsvanor som håller';
        }
      case AppLanguage.norway:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrofi, styrke & muskelmasse';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definisjon & aktiv forbrenning';
          case WorkingTowardGoal.loseWeight:
            return 'Bærekraftig underskudd & vektnedgang';
          case WorkingTowardGoal.getFitter:
            return 'Kondisjon, utholdenhet & overskudd';
          case WorkingTowardGoal.buildConsistency:
            return 'Gode rutiner som varer';
        }
      case AppLanguage.denmark:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hypertrofi, styrke & muskelvækst';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definition & forbrændingsboost';
          case WorkingTowardGoal.loseWeight:
            return 'Bæredygtigt underskud & vægttab';
          case WorkingTowardGoal.getFitter:
            return 'Kondition, udholdenhed & energi';
          case WorkingTowardGoal.buildConsistency:
            return 'Faste vaner, der holder ved';
        }
      case AppLanguage.netherlands:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Spiermassa, kracht & progressie';
          case WorkingTowardGoal.loseBodyFat:
            return 'Droogtrainen & snelle stofwisseling';
          case WorkingTowardGoal.loseWeight:
            return 'Duurzaam calorietekort & progressie';
          case WorkingTowardGoal.getFitter:
            return 'Conditie, uithoudingsvermogen & fitheid';
          case WorkingTowardGoal.buildConsistency:
            return 'IJzersterke routines die blijven';
        }
      case AppLanguage.spain:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Hipertrofia, fuerza y masa muscular';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definición magra y quema activa';
          case WorkingTowardGoal.loseWeight:
            return 'Déficit sostenible y progreso real';
          case WorkingTowardGoal.getFitter:
            return 'Resistencia, agilidad y vitalidad diaria';
          case WorkingTowardGoal.buildConsistency:
            return 'Hábitos sólidos que duran para siempre';
        }
      case AppLanguage.italy:
        switch (goal) {
          case WorkingTowardGoal.buildMuscle:
            return 'Ipertrofia, forza pura e massa magra';
          case WorkingTowardGoal.loseBodyFat:
            return 'Definizione pulita e boost metabolico';
          case WorkingTowardGoal.loseWeight:
            return 'Deficit sostenibile e calo controllato';
          case WorkingTowardGoal.getFitter:
            return 'Resistenza, fiato e massima energia';
          case WorkingTowardGoal.buildConsistency:
            return 'Abitudini solide e costanza duratura';
        }
    }
  }

  // MARK: - Screen 02 & 03: About You & Experience Translations
  String get headlineAboutYou {
    switch (this) {
      case AppLanguage.uk:
        return 'About You';
      case AppLanguage.germany:
        return 'Über Dich';
      case AppLanguage.switzerland:
        return 'Über Dich';
      case AppLanguage.france:
        return 'À propos de vous';
      case AppLanguage.sweden:
        return 'Om dig';
      case AppLanguage.norway:
        return 'Om deg';
      case AppLanguage.denmark:
        return 'Om dig';
      case AppLanguage.netherlands:
        return 'Over jou';
      case AppLanguage.spain:
        return 'Sobre ti';
      case AppLanguage.italy:
        return 'Su di te';
    }
  }

  String get subtitleAboutYou {
    switch (this) {
      case AppLanguage.uk:
        return 'Personalize your biometric baselines and coaching targets.';
      case AppLanguage.germany:
        return 'Optimiere Deine biometrischen Daten für individuelles Coaching.';
      case AppLanguage.switzerland:
        return 'Pass dini biometrische Date für diini Trainingsziel aa.';
      case AppLanguage.france:
        return 'Personnalisez vos données biométriques et objectifs d’entraînement.';
      case AppLanguage.sweden:
        return 'Anpassa dina biometriska data och träningsmål.';
      case AppLanguage.norway:
        return 'Tilpass dine biometriske data og treningsmål.';
      case AppLanguage.denmark:
        return 'Tilpas dine biometriske data og træningsmål.';
      case AppLanguage.netherlands:
        return 'Personaliseer je biometrische gegevens en trainingsdoelen.';
      case AppLanguage.spain:
        return 'Personaliza tus datos biométricos y metas de entrenamiento.';
      case AppLanguage.italy:
        return 'Personalizza i tuoi dati biometrici e obiettivi di coaching.';
    }
  }

  String get nameLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Name';
      case AppLanguage.germany:
        return 'Name';
      case AppLanguage.switzerland:
        return 'Name';
      case AppLanguage.france:
        return 'Nom';
      case AppLanguage.sweden:
        return 'Namn';
      case AppLanguage.norway:
        return 'Navn';
      case AppLanguage.denmark:
        return 'Navn';
      case AppLanguage.netherlands:
        return 'Naam';
      case AppLanguage.spain:
        return 'Nombre';
      case AppLanguage.italy:
        return 'Nome';
    }
  }

  String get namePlaceholder {
    switch (this) {
      case AppLanguage.uk:
        return 'Enter your name';
      case AppLanguage.germany:
        return 'Gib Deinen Namen ein';
      case AppLanguage.switzerland:
        return 'Gib din Name ii';
      case AppLanguage.france:
        return 'Entrez votre nom';
      case AppLanguage.sweden:
        return 'Ange ditt namn';
      case AppLanguage.norway:
        return 'Skriv inn navnet ditt';
      case AppLanguage.denmark:
        return 'Indtast dit navn';
      case AppLanguage.netherlands:
        return 'Voer je naam in';
      case AppLanguage.spain:
        return 'Introduce tu nombre';
      case AppLanguage.italy:
        return 'Inserisci il tuo nome';
    }
  }

  String get genderLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Gender';
      case AppLanguage.germany:
        return 'Geschlecht';
      case AppLanguage.switzerland:
        return 'Gschlächt';
      case AppLanguage.france:
        return 'Genre';
      case AppLanguage.sweden:
        return 'Kön';
      case AppLanguage.norway:
        return 'Kjønn';
      case AppLanguage.denmark:
        return 'Køn';
      case AppLanguage.netherlands:
        return 'Geslacht';
      case AppLanguage.spain:
        return 'Género';
      case AppLanguage.italy:
        return 'Genere';
    }
  }

  String get genderMale {
    switch (this) {
      case AppLanguage.uk:
        return 'Male';
      case AppLanguage.germany:
        return 'Männlich';
      case AppLanguage.switzerland:
        return 'Männlich';
      case AppLanguage.france:
        return 'Homme';
      case AppLanguage.sweden:
        return 'Man';
      case AppLanguage.norway:
        return 'Mann';
      case AppLanguage.denmark:
        return 'Mand';
      case AppLanguage.netherlands:
        return 'Man';
      case AppLanguage.spain:
        return 'Hombre';
      case AppLanguage.italy:
        return 'Uomo';
    }
  }

  String get genderFemale {
    switch (this) {
      case AppLanguage.uk:
        return 'Female';
      case AppLanguage.germany:
        return 'Weiblich';
      case AppLanguage.switzerland:
        return 'Wiiblich';
      case AppLanguage.france:
        return 'Femme';
      case AppLanguage.sweden:
        return 'Kvinna';
      case AppLanguage.norway:
        return 'Kvinne';
      case AppLanguage.denmark:
        return 'Kvinde';
      case AppLanguage.netherlands:
        return 'Vrouw';
      case AppLanguage.spain:
        return 'Mujer';
      case AppLanguage.italy:
        return 'Donna';
    }
  }

  String get ageLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Age';
      case AppLanguage.germany:
        return 'Alter';
      case AppLanguage.switzerland:
        return 'Alter';
      case AppLanguage.france:
        return 'Âge';
      case AppLanguage.sweden:
        return 'Ålder';
      case AppLanguage.norway:
        return 'Alder';
      case AppLanguage.denmark:
        return 'Alder';
      case AppLanguage.netherlands:
        return 'Leeftijd';
      case AppLanguage.spain:
        return 'Edad';
      case AppLanguage.italy:
        return 'Età';
    }
  }

  String get yearsUnit {
    switch (this) {
      case AppLanguage.uk:
        return 'yrs';
      case AppLanguage.germany:
        return 'Jahre';
      case AppLanguage.switzerland:
        return 'Jöhr';
      case AppLanguage.france:
        return 'ans';
      case AppLanguage.sweden:
        return 'år';
      case AppLanguage.norway:
        return 'år';
      case AppLanguage.denmark:
        return 'år';
      case AppLanguage.netherlands:
        return 'jr';
      case AppLanguage.spain:
        return 'años';
      case AppLanguage.italy:
        return 'anni';
    }
  }

  String get heightLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Height';
      case AppLanguage.germany:
        return 'Größe';
      case AppLanguage.switzerland:
        return 'Grössi';
      case AppLanguage.france:
        return 'Taille';
      case AppLanguage.sweden:
        return 'Längd';
      case AppLanguage.norway:
        return 'Høyde';
      case AppLanguage.denmark:
        return 'Højde';
      case AppLanguage.netherlands:
        return 'Lengte';
      case AppLanguage.spain:
        return 'Altura';
      case AppLanguage.italy:
        return 'Altezza';
    }
  }

  String get weightLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Current Weight';
      case AppLanguage.germany:
        return 'Aktuelles Gewicht';
      case AppLanguage.switzerland:
        return 'Aktuells Gwicht';
      case AppLanguage.france:
        return 'Poids actuel';
      case AppLanguage.sweden:
        return 'Nuvarande vikt';
      case AppLanguage.norway:
        return 'Nåværende vekt';
      case AppLanguage.denmark:
        return 'Nuværende vægt';
      case AppLanguage.netherlands:
        return 'Huidig gewicht';
      case AppLanguage.spain:
        return 'Peso actual';
      case AppLanguage.italy:
        return 'Peso attuale';
    }
  }

  String get targetWeightLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Target Weight';
      case AppLanguage.germany:
        return 'Zielgewicht';
      case AppLanguage.switzerland:
        return 'Zielgwicht';
      case AppLanguage.france:
        return 'Poids cible';
      case AppLanguage.sweden:
        return 'Målvikt';
      case AppLanguage.norway:
        return 'Målvekt';
      case AppLanguage.denmark:
        return 'Målvægt';
      case AppLanguage.netherlands:
        return 'Streefgewicht';
      case AppLanguage.spain:
        return 'Peso objetivo';
      case AppLanguage.italy:
        return 'Peso obiettivo';
    }
  }

  String get unitImperialLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'ft / lb';
      case AppLanguage.germany:
        return 'ft / lb';
      case AppLanguage.switzerland:
        return 'ft / lb';
      case AppLanguage.france:
        return 'ft / lb';
      case AppLanguage.sweden:
        return 'ft / lb';
      case AppLanguage.norway:
        return 'ft / lb';
      case AppLanguage.denmark:
        return 'ft / lb';
      case AppLanguage.netherlands:
        return 'ft / lb';
      case AppLanguage.spain:
        return 'ft / lb';
      case AppLanguage.italy:
        return 'ft / lb';
    }
  }

  String get unitMetricLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'cm / kg';
      case AppLanguage.germany:
        return 'cm / kg';
      case AppLanguage.switzerland:
        return 'cm / kg';
      case AppLanguage.france:
        return 'cm / kg';
      case AppLanguage.sweden:
        return 'cm / kg';
      case AppLanguage.norway:
        return 'cm / kg';
      case AppLanguage.denmark:
        return 'cm / kg';
      case AppLanguage.netherlands:
        return 'cm / kg';
      case AppLanguage.spain:
        return 'cm / kg';
      case AppLanguage.italy:
        return 'cm / kg';
    }
  }

  String get biometricsSectionTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Biometrics';
      case AppLanguage.germany:
        return 'Biometrie';
      case AppLanguage.switzerland:
        return 'Biometrii';
      case AppLanguage.france:
        return 'Biométrie';
      case AppLanguage.sweden:
        return 'Biometri';
      case AppLanguage.norway:
        return 'Biometri';
      case AppLanguage.denmark:
        return 'Biometri';
      case AppLanguage.netherlands:
        return 'Biometrie';
      case AppLanguage.spain:
        return 'Biometría';
      case AppLanguage.italy:
        return 'Biometria';
    }
  }

  String get nameValidationPrompt {
    switch (this) {
      case AppLanguage.uk:
        return 'Please enter your name (at least 2 characters).';
      case AppLanguage.germany:
        return 'Bitte gib Deinen Namen ein (mind. 2 Zeichen).';
      case AppLanguage.switzerland:
        return 'Bitte gib din Name ii (mind. 2 Zeiche).';
      case AppLanguage.france:
        return 'Veuillez saisir votre nom (au moins 2 caractères).';
      case AppLanguage.sweden:
        return 'Ange ditt namn (minst 2 tecken).';
      case AppLanguage.norway:
        return 'Vennligst oppgi navnet ditt (minst 2 tegn).';
      case AppLanguage.denmark:
        return 'Indtast venligst dit navn (mindst 2 tegn).';
      case AppLanguage.netherlands:
        return 'Voer je naam in (minimaal 2 tekens).';
      case AppLanguage.spain:
        return 'Por favor, introduce tu nombre (mínimo 2 caracteres).';
      case AppLanguage.italy:
        return 'Inserisci il tuo nome (almeno 2 caratteri).';
    }
  }

  String get experienceSectionTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'How experienced are you?';
      case AppLanguage.germany:
        return 'Wie viel Trainingserfahrung hast Du?';
      case AppLanguage.switzerland:
        return 'Wie viel Trainingserfahrig häsch?';
      case AppLanguage.france:
        return 'Quel est votre niveau d’expérience ?';
      case AppLanguage.sweden:
        return 'Hur erfaren är du?';
      case AppLanguage.norway:
        return 'Hvor erfaren er du?';
      case AppLanguage.denmark:
        return 'Hvor erfaren er du?';
      case AppLanguage.netherlands:
        return 'Hoeveel ervaring heb je?';
      case AppLanguage.spain:
        return '¿Cuál es tu experiencia?';
      case AppLanguage.italy:
        return 'Quanta esperienza hai?';
    }
  }

  String experienceTitle(ExperienceLevel level) {
    switch (this) {
      case AppLanguage.uk:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Beginner';
          case ExperienceLevel.intermediate:
            return 'Intermediate';
          case ExperienceLevel.advanced:
            return 'Advanced';
        }
      case AppLanguage.germany:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Anfänger';
          case ExperienceLevel.intermediate:
            return 'Fortgeschritten';
          case ExperienceLevel.advanced:
            return 'Profi';
        }
      case AppLanguage.switzerland:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Aafänger';
          case ExperienceLevel.intermediate:
            return 'Fortgschritte';
          case ExperienceLevel.advanced:
            return 'Erfahre';
        }
      case AppLanguage.france:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Débutant';
          case ExperienceLevel.intermediate:
            return 'Intermédiaire';
          case ExperienceLevel.advanced:
            return 'Avancé';
        }
      case AppLanguage.sweden:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Nybörjare';
          case ExperienceLevel.intermediate:
            return 'Medelnivå';
          case ExperienceLevel.advanced:
            return 'Erfaren';
        }
      case AppLanguage.norway:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Nybegynner';
          case ExperienceLevel.intermediate:
            return 'Mellomnivå';
          case ExperienceLevel.advanced:
            return 'Erfaren';
        }
      case AppLanguage.denmark:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Begynder';
          case ExperienceLevel.intermediate:
            return 'Let øvet';
          case ExperienceLevel.advanced:
            return 'Erfaren';
        }
      case AppLanguage.netherlands:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Beginner';
          case ExperienceLevel.intermediate:
            return 'Gevorderd';
          case ExperienceLevel.advanced:
            return 'Ervaren';
        }
      case AppLanguage.spain:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Principiante';
          case ExperienceLevel.intermediate:
            return 'Intermedio';
          case ExperienceLevel.advanced:
            return 'Avanzado';
        }
      case AppLanguage.italy:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Principiante';
          case ExperienceLevel.intermediate:
            return 'Intermedio';
          case ExperienceLevel.advanced:
            return 'Avanzato';
        }
    }
  }

  String experienceSubtitle(ExperienceLevel level) {
    switch (this) {
      case AppLanguage.uk:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'New to working out';
          case ExperienceLevel.intermediate:
            return 'I train regularly';
          case ExperienceLevel.advanced:
            return "I've trained for years";
        }
      case AppLanguage.germany:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Neu im Fitnesstraining';
          case ExperienceLevel.intermediate:
            return 'Ich trainiere regelmäßig';
          case ExperienceLevel.advanced:
            return 'Trainiere seit Jahren';
        }
      case AppLanguage.switzerland:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Neu bim Trainiere';
          case ExperienceLevel.intermediate:
            return 'Ich trainiere regelmässig';
          case ExperienceLevel.advanced:
            return 'Trainiere sit Jahre';
        }
      case AppLanguage.france:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Nouveau dans le sport';
          case ExperienceLevel.intermediate:
            return 'Je m’entraîne régulièrement';
          case ExperienceLevel.advanced:
            return 'Des années de pratique';
        }
      case AppLanguage.sweden:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Ny inom träning';
          case ExperienceLevel.intermediate:
            return 'Tränar regelbundet';
          case ExperienceLevel.advanced:
            return 'Har tränat i flera år';
        }
      case AppLanguage.norway:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Ny til trening';
          case ExperienceLevel.intermediate:
            return 'Trener jevnlig';
          case ExperienceLevel.advanced:
            return 'Har trent i mange år';
        }
      case AppLanguage.denmark:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Ny til fitness';
          case ExperienceLevel.intermediate:
            return 'Træner regelmæssigt';
          case ExperienceLevel.advanced:
            return 'Har trænet i flere år';
        }
      case AppLanguage.netherlands:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Nieuw met fitness';
          case ExperienceLevel.intermediate:
            return 'Ik train regelmatig';
          case ExperienceLevel.advanced:
            return 'Train al jarenlang';
        }
      case AppLanguage.spain:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Empezando a entrenar';
          case ExperienceLevel.intermediate:
            return 'Entreno con regularidad';
          case ExperienceLevel.advanced:
            return 'Llevo años entrenando';
        }
      case AppLanguage.italy:
        switch (level) {
          case ExperienceLevel.beginner:
            return 'Nuovo all’allenamento';
          case ExperienceLevel.intermediate:
            return 'Mi alleno con costanza';
          case ExperienceLevel.advanced:
            return 'Mi alleno da anni';
        }
    }
  }

  // MARK: - Screen 04 & 05: Schedule & Location Translations
  String get headlineScheduleAndLocation {
    switch (this) {
      case AppLanguage.uk:
        return 'Your Schedule & Space';
      case AppLanguage.germany:
        return 'Dein Zeitplan & Raum';
      case AppLanguage.switzerland:
        return 'Din Ziitplan & Ruum';
      case AppLanguage.france:
        return 'Votre Planning & Lieu';
      case AppLanguage.sweden:
        return 'Ditt Schema & Plats';
      case AppLanguage.norway:
        return 'Din Timeplan & Plass';
      case AppLanguage.denmark:
        return 'Din Tidsplan & Træningssted';
      case AppLanguage.netherlands:
        return 'Jouw Schema & Ruimte';
      case AppLanguage.spain:
        return 'Tu Horario y Lugar';
      case AppLanguage.italy:
        return 'Il Tuo Programma e Spazio';
    }
  }

  String get weeklyCommitmentQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Days per week?';
      case AppLanguage.germany:
        return 'Tage pro Woche?';
      case AppLanguage.switzerland:
        return 'Täg pro Wuche?';
      case AppLanguage.france:
        return 'Jours par semaine ?';
      case AppLanguage.sweden:
        return 'Dagar per vecka?';
      case AppLanguage.norway:
        return 'Dager per uke?';
      case AppLanguage.denmark:
        return 'Dage om ugen?';
      case AppLanguage.netherlands:
        return 'Dagen per week?';
      case AppLanguage.spain:
        return '¿Días por semana?';
      case AppLanguage.italy:
        return 'Giorni a settimana?';
    }
  }

  String get sessionDurationQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'How long per workout?';
      case AppLanguage.germany:
        return 'Wie lange pro Workout?';
      case AppLanguage.switzerland:
        return 'Wie lang pro Workout?';
      case AppLanguage.france:
        return 'Durée par séance ?';
      case AppLanguage.sweden:
        return 'Hur långt per pass?';
      case AppLanguage.norway:
        return 'Hvor lenge per økt?';
      case AppLanguage.denmark:
        return 'Hvor længe per træning?';
      case AppLanguage.netherlands:
        return 'Hoe lang per workout?';
      case AppLanguage.spain:
        return '¿Cuánto por sesión?';
      case AppLanguage.italy:
        return 'Quanto dura ogni sessione?';
    }
  }

  String get trainingLocationQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Where do you train?';
      case AppLanguage.germany:
        return 'Wo trainierst Du?';
      case AppLanguage.switzerland:
        return 'Wo trainiersch du?';
      case AppLanguage.france:
        return 'Où vous entraînez-vous ?';
      case AppLanguage.sweden:
        return 'Var tränar du?';
      case AppLanguage.norway:
        return 'Hvor trener du?';
      case AppLanguage.denmark:
        return 'Hvor træner du?';
      case AppLanguage.netherlands:
        return 'Waar train je?';
      case AppLanguage.spain:
        return '¿Dónde entrenas?';
      case AppLanguage.italy:
        return 'Dove ti alleni?';
    }
  }

  String durationOptionTitle(WorkoutDurationOption opt) {
    switch (opt) {
      case WorkoutDurationOption.min20:
        return '20 min';
      case WorkoutDurationOption.min30:
        return '30 min';
      case WorkoutDurationOption.min45:
        return '45 min';
      case WorkoutDurationOption.min60Plus:
        return '60+ min';
    }
  }

  String locationOptionTitle(TrainingLocationOption opt) {
    switch (this) {
      case AppLanguage.uk:
        switch (opt) {
          case TrainingLocationOption.gym:
            return 'Gym';
          case TrainingLocationOption.home:
            return 'Home';
          case TrainingLocationOption.outdoors:
            return 'Outdoors';
          case TrainingLocationOption.mix:
            return 'Mix';
        }
      case AppLanguage.germany:
      case AppLanguage.switzerland:
        switch (opt) {
          case TrainingLocationOption.gym:
            return 'Fitnessstudio';
          case TrainingLocationOption.home:
            return 'Zuhause';
          case TrainingLocationOption.outdoors:
            return 'Im Freien';
          case TrainingLocationOption.mix:
            return 'Mix';
        }
      case AppLanguage.france:
        switch (opt) {
          case TrainingLocationOption.gym:
            return 'Salle';
          case TrainingLocationOption.home:
            return 'Maison';
          case TrainingLocationOption.outdoors:
            return 'Plein Air';
          case TrainingLocationOption.mix:
            return 'Mixte';
        }
      case AppLanguage.spain:
        switch (opt) {
          case TrainingLocationOption.gym:
            return 'Gimnasio';
          case TrainingLocationOption.home:
            return 'Casa';
          case TrainingLocationOption.outdoors:
            return 'Aire Libre';
          case TrainingLocationOption.mix:
            return 'Mixto';
        }
      case AppLanguage.italy:
        switch (opt) {
          case TrainingLocationOption.gym:
            return 'Palestra';
          case TrainingLocationOption.home:
            return 'Casa';
          case TrainingLocationOption.outdoors:
            return 'All’Aperto';
          case TrainingLocationOption.mix:
            return 'Misto';
        }
      default:
        return opt.defaultTitle;
    }
  }

  // MARK: - Screen 06, 07 & 08: Lifestyle, Nutrition & Limitations Translations
  String get headlineLifestyleAndNutrition {
    switch (this) {
      case AppLanguage.uk:
        return 'Your Lifestyle';
      case AppLanguage.germany:
        return 'Dein Alltag';
      case AppLanguage.switzerland:
        return 'Din Alltag';
      case AppLanguage.france:
        return 'Votre quotidien';
      case AppLanguage.sweden:
        return 'Din livsstil';
      case AppLanguage.norway:
        return 'Din livsstil';
      case AppLanguage.denmark:
        return 'Din livsstil';
      case AppLanguage.netherlands:
        return 'Jouw leefstijl';
      case AppLanguage.spain:
        return 'Tu estilo de vida';
      case AppLanguage.italy:
        return 'Il tuo stile di vita';
    }
  }

  String get subtitleLifestyleAndNutrition {
    switch (this) {
      case AppLanguage.uk:
        return 'Fine-tune recovery, meal budgeting, and injury-tailored workouts.';
      case AppLanguage.germany:
        return 'Optimiere Regeneration, Ernährungsbudget und verletzungssichere Pläne.';
      case AppLanguage.switzerland:
        return 'Optimiere Erholig, Ernährigsbudget und verletzigssicheri Plän.';
      case AppLanguage.france:
        return 'Ajustez votre récupération, budget repas et prévention des blessures.';
      case AppLanguage.sweden:
        return 'Optimera återhämtning, matbudget och skadeanpassade pass.';
      case AppLanguage.norway:
        return 'Optimaliser restitusjon, matbudsjett og skadeforebygging.';
      case AppLanguage.denmark:
        return 'Optimer restitution, madbudget og skadeforebyggende træning.';
      case AppLanguage.netherlands:
        return 'Optimaliseer herstel, maaltijdbudget en blessurepreventie.';
      case AppLanguage.spain:
        return 'Optimiza tu recuperación, presupuesto y prevención de lesiones.';
      case AppLanguage.italy:
        return 'Ottimizza recupero, budget pasti e prevenzione infortuni.';
    }
  }

  String get recoverySectionTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Recovery & Daily Energy';
      case AppLanguage.germany:
        return 'Regeneration & Energie';
      case AppLanguage.switzerland:
        return 'Erholig & Energie';
      case AppLanguage.france:
        return 'Récupération & Énergie';
      case AppLanguage.sweden:
        return 'Återhämtning & Energi';
      case AppLanguage.norway:
        return 'Restitusjon & Energi';
      case AppLanguage.denmark:
        return 'Restitution & Energi';
      case AppLanguage.netherlands:
        return 'Herstel & Energie';
      case AppLanguage.spain:
        return 'Recuperación y Energía';
      case AppLanguage.italy:
        return 'Recupero ed Energia';
    }
  }

  String get activityLevelQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Activity outside workouts?';
      case AppLanguage.germany:
        return 'Aktivität außerhalb des Trainings?';
      case AppLanguage.switzerland:
        return 'Aktivität usserhalb vom Training?';
      case AppLanguage.france:
        return 'Activité hors entraînement ?';
      case AppLanguage.sweden:
        return 'Aktivitet utanför träning?';
      case AppLanguage.norway:
        return 'Aktivitet utenom trening?';
      case AppLanguage.denmark:
        return 'Aktivitet uden for træning?';
      case AppLanguage.netherlands:
        return 'Activiteit buiten workouts?';
      case AppLanguage.spain:
        return '¿Actividad fuera del entrenamiento?';
      case AppLanguage.italy:
        return 'Attività fuori dagli allenamenti?';
    }
  }

  String get sleepDurationQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Sleep per night?';
      case AppLanguage.germany:
        return 'Schlaf pro Nacht?';
      case AppLanguage.switzerland:
        return 'Schlaff pro Nacht?';
      case AppLanguage.france:
        return 'Sommeil par nuit ?';
      case AppLanguage.sweden:
        return 'Sömn per natt?';
      case AppLanguage.norway:
        return 'Søvn per natt?';
      case AppLanguage.denmark:
        return 'Søvn pr. nat?';
      case AppLanguage.netherlands:
        return 'Slaap per nacht?';
      case AppLanguage.spain:
        return '¿Sueño por noche?';
      case AppLanguage.italy:
        return 'Sonno per notte?';
    }
  }

  String get nutritionSectionTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Nutrition & Food Budget';
      case AppLanguage.germany:
        return 'Ernährung & Budget';
      case AppLanguage.switzerland:
        return 'Ernährig & Budget';
      case AppLanguage.france:
        return 'Nutrition & Budget';
      case AppLanguage.sweden:
        return 'Kost & Matbudget';
      case AppLanguage.norway:
        return 'Kosthold & Matbudsjett';
      case AppLanguage.denmark:
        return 'Ernæring & Madbudget';
      case AppLanguage.netherlands:
        return 'Voeding & Maaltijdbudget';
      case AppLanguage.spain:
        return 'Nutrición y Presupuesto';
      case AppLanguage.italy:
        return 'Nutrizione e Budget';
    }
  }

  String get eatingStyleQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Eating style';
      case AppLanguage.germany:
        return 'Ernährungsweise';
      case AppLanguage.switzerland:
        return 'Ernährigswiis';
      case AppLanguage.france:
        return 'Régime alimentaire';
      case AppLanguage.sweden:
        return 'Kosthållning';
      case AppLanguage.norway:
        return 'Kostholdsstil';
      case AppLanguage.denmark:
        return 'Koststil';
      case AppLanguage.netherlands:
        return 'Eetstijl';
      case AppLanguage.spain:
        return 'Estilo de alimentación';
      case AppLanguage.italy:
        return 'Stile alimentare';
    }
  }

  String eatingStyleLabel(String value) {
    switch (this) {
      case AppLanguage.uk:
        return switch (value) {
          'NO_PREFERENCE' => 'No preference',
          'NON_VEGETARIAN' => 'Non-vegetarian',
          'VEGETARIAN' => 'Vegetarian',
          'VEGAN' => 'Vegan',
          _ => 'Other',
        };
      case AppLanguage.germany:
        return switch (value) {
          'NO_PREFERENCE' => 'Keine Einschränkungen',
          'NON_VEGETARIAN' => 'Nicht vegetarisch',
          'VEGETARIAN' => 'Vegetarisch',
          'VEGAN' => 'Vegan',
          _ => 'Andere',
        };
      case AppLanguage.switzerland:
        return switch (value) {
          'NO_PREFERENCE' => 'Keine Einschränkige',
          'NON_VEGETARIAN' => 'Nöd vegetarisch',
          'VEGETARIAN' => 'Vegetarisch',
          'VEGAN' => 'Vegan',
          _ => 'Anderi',
        };
      case AppLanguage.france:
        return switch (value) {
          'NO_PREFERENCE' => 'Sans préférence',
          'NON_VEGETARIAN' => 'Non végétarien',
          'VEGETARIAN' => 'Végétarien',
          'VEGAN' => 'Végane',
          _ => 'Autre',
        };
      case AppLanguage.sweden:
        return switch (value) {
          'NO_PREFERENCE' => 'Inga preferenser',
          'NON_VEGETARIAN' => 'Icke-vegetarisk',
          'VEGETARIAN' => 'Vegetarisk',
          'VEGAN' => 'Vegansk',
          _ => 'Annat',
        };
      case AppLanguage.norway:
        return switch (value) {
          'NO_PREFERENCE' => 'Ingen preferanse',
          'NON_VEGETARIAN' => 'Ikke-vegetarisk',
          'VEGETARIAN' => 'Vegetarisk',
          'VEGAN' => 'Vegansk',
          _ => 'Annet',
        };
      case AppLanguage.denmark:
        return switch (value) {
          'NO_PREFERENCE' => 'Ingen præference',
          'NON_VEGETARIAN' => 'Ikke-vegetarisk',
          'VEGETARIAN' => 'Vegetarisk',
          'VEGAN' => 'Vegansk',
          _ => 'Andet',
        };
      case AppLanguage.netherlands:
        return switch (value) {
          'NO_PREFERENCE' => 'Geen voorkeur',
          'NON_VEGETARIAN' => 'Niet-vegetarisch',
          'VEGETARIAN' => 'Vegetarisch',
          'VEGAN' => 'Veganistisch',
          _ => 'Anders',
        };
      case AppLanguage.spain:
        return switch (value) {
          'NO_PREFERENCE' => 'Sin preferencia',
          'NON_VEGETARIAN' => 'No vegetariano',
          'VEGETARIAN' => 'Vegetariano',
          'VEGAN' => 'Vegano',
          _ => 'Otro',
        };
      case AppLanguage.italy:
        return switch (value) {
          'NO_PREFERENCE' => 'Nessuna preferenza',
          'NON_VEGETARIAN' => 'Non vegetariano',
          'VEGETARIAN' => 'Vegetariano',
          'VEGAN' => 'Vegano',
          _ => 'Altro',
        };
    }
  }

  String get foodBudgetQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Weekly grocery budget';
      case AppLanguage.germany:
        return 'Wöchentliches Lebensmittelbudget';
      case AppLanguage.switzerland:
        return 'Wöchentlichs Esse-Budget';
      case AppLanguage.france:
        return 'Budget courses hebdomadaire';
      case AppLanguage.sweden:
        return 'Veckobudget för matvaror';
      case AppLanguage.norway:
        return 'Ukentlig matbudsjett';
      case AppLanguage.denmark:
        return 'Ugentligt indkøbsbudget';
      case AppLanguage.netherlands:
        return 'Wekelijks boodschappenbudget';
      case AppLanguage.spain:
        return 'Presupuesto semanal de comida';
      case AppLanguage.italy:
        return 'Budget spesa settimanale';
    }
  }

  String get customDietLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Custom diet / preferences';
      case AppLanguage.germany:
        return 'Individuelle Diät / Vorlieben';
      case AppLanguage.switzerland:
        return 'Individuelli Diät / Vorliebe';
      case AppLanguage.france:
        return 'Régime sur mesure / préférences';
      case AppLanguage.spain:
        return 'Dieta personalizada / preferencias';
      case AppLanguage.italy:
        return 'Dieta personalizzata / preferenze';
      default:
        return 'Custom diet / preferences';
    }
  }

  String get customDietPlaceholder {
    switch (this) {
      case AppLanguage.uk:
        return 'Enter custom diet (e.g. Keto, Halal, Pescatarian)...';
      case AppLanguage.germany:
        return 'Z.B. Keto, Halal, Pescetarisch, Glutenfrei...';
      case AppLanguage.switzerland:
        return 'Z.B. Keto, Halal, Pescetarisch, Glutenfrei...';
      case AppLanguage.france:
        return 'Ex: Céto, Halal, Pescétarien, Sans gluten...';
      case AppLanguage.sweden:
        return 'T.ex. pescetariskt, halal eller glutenfritt...';
      case AppLanguage.norway:
        return 'F.eks. pescetarisk, halal eller glutenfritt...';
      case AppLanguage.denmark:
        return 'F.eks. pescetarisk, halal eller glutenfri...';
      case AppLanguage.netherlands:
        return 'Bijv. pescotarisch, halal of glutenvrij...';
      case AppLanguage.spain:
        return 'Ej: Keto, Halal, Pescetariano, Sin gluten...';
      case AppLanguage.italy:
        return 'Es: Cheto, Halal, Pescetariano, Senza glutine...';
    }
  }

  String get limitationsSectionTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Body Limitations & Joint Care';
      case AppLanguage.germany:
        return 'Körperliche Einschränkungen & Gelenkschutz';
      case AppLanguage.switzerland:
        return 'Körperlichi Ischränkige & Glenkschutz';
      case AppLanguage.france:
        return 'Limitations & Soin des Articulations';
      case AppLanguage.sweden:
        return 'Fysiska Begränsningar & Ledvård';
      case AppLanguage.norway:
        return 'Fysiske Begrensninger & Leddhelse';
      case AppLanguage.denmark:
        return 'Fysiske Begrænsninger & Ledpleje';
      case AppLanguage.netherlands:
        return 'Fysieke Beperkingen & Gewrichtszorg';
      case AppLanguage.spain:
        return 'Limitaciones Físicas y Articulaciones';
      case AppLanguage.italy:
        return 'Limitazioni Fisiche e Cura Articolare';
    }
  }

  String get limitationsQuestion {
    switch (this) {
      case AppLanguage.uk:
        return 'Anything to protect?';
      case AppLanguage.germany:
        return 'Etwas zu schützen?';
      case AppLanguage.switzerland:
        return 'Öppis z’schütze?';
      case AppLanguage.france:
        return 'Une zone à protéger ?';
      case AppLanguage.sweden:
        return 'Något att ta hänsyn till?';
      case AppLanguage.norway:
        return 'Noe å ta hensyn til?';
      case AppLanguage.denmark:
        return 'Noget, vi skal tage hensyn til?';
      case AppLanguage.netherlands:
        return 'Iets om rekening mee te houden?';
      case AppLanguage.spain:
        return '¿Algo que debamos cuidar?';
      case AppLanguage.italy:
        return 'C’è qualcosa da proteggere?';
    }
  }

  String get limitationsSubtext {
    switch (this) {
      case AppLanguage.uk:
        return 'We tailor exercise selection to keep you safe.';
      case AppLanguage.germany:
        return 'Wir passen Übungen automatisch an, um Dich zu schützen.';
      case AppLanguage.switzerland:
        return 'Mir passed d’Üebige a, zum dich optimal z’schütze.';
      case AppLanguage.france:
        return 'Nous adaptons les exercices pour éviter la douleur.';
      case AppLanguage.spain:
        return 'Adaptamos los ejercicios para evitar molestias.';
      case AppLanguage.italy:
        return 'Adattiamo gli esercizi per proteggere il tuo corpo.';
      default:
        return 'We tailor exercise selection to keep you safe.';
    }
  }

  String get customLimitationPlaceholder {
    switch (this) {
      case AppLanguage.uk:
        return 'Describe injury or movement to avoid (e.g. L4-L5 disc, rotator cuff)...';
      case AppLanguage.germany:
        return 'Verletzung beschreiben (z.B. Bandscheibe L4-L5, Rotatorenmanschette)...';
      case AppLanguage.switzerland:
        return 'Verletzig beschriibe (z.B. Bandschiibe L4-L5, Schulter-Impingement)...';
      case AppLanguage.france:
        return 'Décrivez la blessure (ex: hernie L4-L5, coiffe des rotateurs)...';
      case AppLanguage.spain:
        return 'Describe la lesión (ej: hernia discal L4-L5, manguito rotador)...';
      case AppLanguage.italy:
        return 'Descrivi l’infortunio (es: ernia L4-L5, cuffia dei rotatori)...';
      default:
        return 'Describe injury or movement to avoid (e.g. L4-L5 disc, rotator cuff)...';
    }
  }

  String get customBudgetChipLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Custom';
      case AppLanguage.germany:
        return 'Eigener Betrag';
      case AppLanguage.switzerland:
        return 'Eignigs Budget';
      case AppLanguage.france:
        return 'Personnalisé';
      case AppLanguage.spain:
        return 'Personalizado';
      case AppLanguage.italy:
        return 'Personalizzato';
      default:
        return 'Custom';
    }
  }

  String lifestyleAiSummary(String activity, String sleep, String diet,
      List<String> limitationLabels) {
    final injuryText = limitationLabels.contains('None') ||
            limitationLabels.contains('Keine') ||
            limitationLabels.isEmpty
        ? 'Full Joint Mobility'
        : '${limitationLabels.join(", ")} Protection Shield';

    switch (this) {
      case AppLanguage.uk:
        return '⚡ $activity Activity • $sleep Sleep • $diet Plan • $injuryText';
      case AppLanguage.germany:
      case AppLanguage.switzerland:
        return '⚡ $activity Aktivität • $sleep Schlaf • $diet • $injuryText';
      case AppLanguage.france:
        return '⚡ Activité $activity • Sommeil $sleep • $diet • $injuryText';
      case AppLanguage.spain:
        return '⚡ Actividad $activity • Sueño $sleep • $diet • $injuryText';
      case AppLanguage.italy:
        return '⚡ Attività $activity • Sonno $sleep • $diet • $injuryText';
      default:
        return '⚡ $activity Activity • $sleep Sleep • $diet Plan • $injuryText';
    }
  }

  String scheduleRhythmSummary(int days, int minutes, String location) {
    final hrs = ((days * minutes) / 60.0).toStringAsFixed(1);
    switch (this) {
      case AppLanguage.uk:
        return '$days days × $minutes min = $hrs hrs/wk • Optimized for $location';
      case AppLanguage.germany:
      case AppLanguage.switzerland:
        return '$days Tage × $minutes Min = $hrs Std/Woche • Optimiert für $location';
      case AppLanguage.france:
        return '$days jours × $minutes min = $hrs h/semaine • Optimisé pour $location';
      case AppLanguage.spain:
        return '$days días × $minutes min = $hrs h/sem • Optimizado para $location';
      case AppLanguage.italy:
        return '$days giorni × $minutes min = $hrs ore/sett • Ottimizzato per $location';
      default:
        return '$days days × $minutes min = $hrs hrs/wk • Optimized for $location';
    }
  }

  // MARK: - Screen 09: 3D Body Scan Showcase Localizations
  String get headlineBodyScan {
    switch (this) {
      case AppLanguage.uk:
        return 'Your 3D Body Scan';
      case AppLanguage.germany:
        return 'Dein 3D-Körperscan';
      case AppLanguage.switzerland:
        return 'Dä 3D-Körperscan';
      case AppLanguage.france:
        return 'Ton Scan Corporel 3D';
      case AppLanguage.sweden:
        return 'Din 3D-Kroppsskanning';
      case AppLanguage.norway:
        return 'Din 3D-Kroppsskanning';
      case AppLanguage.denmark:
        return 'Din 3D-Kropsskanning';
      case AppLanguage.netherlands:
        return 'Jouw 3D-Lichaamsscan';
      case AppLanguage.spain:
        return 'Tu Escáner Corporal 3D';
      case AppLanguage.italy:
        return 'La Tua Scansione Corporea 3D';
    }
  }

  String get bodyScanSubtext {
    switch (this) {
      case AppLanguage.uk:
        return 'Drag the sample model to explore it. Your personal scan starts after sign-up.';
      case AppLanguage.germany:
        return 'Ziehe das Beispielmodell. Dein persönlicher Scan beginnt nach der Registrierung.';
      case AppLanguage.switzerland:
        return 'Zieh s’Vorschau-Modell ume. Di persönliche Scan startet nach em Aamelde.';
      case AppLanguage.france:
        return 'Faites pivoter le modèle d’exemple. Votre scan personnel commence après l’inscription.';
      case AppLanguage.sweden:
        return 'Dra i exempelmodellen. Din personliga skanning börjar efter registreringen.';
      case AppLanguage.norway:
        return 'Dra i eksempelmodellen. Din personlige skanning starter etter registrering.';
      case AppLanguage.denmark:
        return 'Træk i eksempelmodellen. Din personlige scanning starter efter oprettelse af konto.';
      case AppLanguage.netherlands:
        return 'Sleep het voorbeeldmodel rond. Je persoonlijke scan begint na registratie.';
      case AppLanguage.spain:
        return 'Gira el modelo de ejemplo. Tu escaneo personal empieza después de registrarte.';
      case AppLanguage.italy:
        return 'Ruota il modello di esempio. La tua scansione personale inizia dopo la registrazione.';
    }
  }

  String get accountSetupNextTitle {
    switch (this) {
      case AppLanguage.uk:
        return 'Next up: your account';
      case AppLanguage.germany:
        return 'Als Nächstes: dein Konto';
      case AppLanguage.switzerland:
        return 'Als Nächsts: dis Konto';
      case AppLanguage.france:
        return 'Prochaine étape : votre compte';
      case AppLanguage.sweden:
        return 'Nästa steg: ditt konto';
      case AppLanguage.norway:
        return 'Neste steg: kontoen din';
      case AppLanguage.denmark:
        return 'Næste trin: din konto';
      case AppLanguage.netherlands:
        return 'Volgende stap: je account';
      case AppLanguage.spain:
        return 'Siguiente: tu cuenta';
      case AppLanguage.italy:
        return 'Prossimo passo: il tuo account';
    }
  }

  String get accountSetupNextDescription {
    switch (this) {
      case AppLanguage.uk:
        return 'Your answers are saved. After creating an account, upload photos to start your personal scan and plan.';
      case AppLanguage.germany:
        return 'Deine Antworten sind gespeichert. Nach der Kontoerstellung kannst du Fotos für deinen persönlichen Scan und Plan hochladen.';
      case AppLanguage.switzerland:
        return 'Dini Antworte sind gspeicheret. Nach em Konto chasch Föteli für diin persönliche Scan und Plan ufelade.';
      case AppLanguage.france:
        return 'Vos réponses sont enregistrées. Après la création du compte, importez des photos pour lancer votre scan et votre plan.';
      case AppLanguage.sweden:
        return 'Dina svar är sparade. När du har skapat ett konto kan du ladda upp foton för din personliga skanning och plan.';
      case AppLanguage.norway:
        return 'Svarene dine er lagret. Når du har opprettet en konto, kan du laste opp bilder for din personlige skanning og plan.';
      case AppLanguage.denmark:
        return 'Dine svar er gemt. Når du har oprettet en konto, kan du uploade billeder til din personlige scanning og plan.';
      case AppLanguage.netherlands:
        return 'Je antwoorden zijn opgeslagen. Na het aanmaken van een account kun je foto’s uploaden voor je persoonlijke scan en plan.';
      case AppLanguage.spain:
        return 'Tus respuestas están guardadas. Después de crear una cuenta, podrás subir fotos para iniciar tu escaneo y plan personal.';
      case AppLanguage.italy:
        return 'Le tue risposte sono salvate. Dopo aver creato un account, potrai caricare foto per avviare la scansione e il piano personali.';
    }
  }

  String get heatmapModeNormalLabel {
    switch (this) {
      case AppLanguage.uk:
        return 'Blueprint';
      case AppLanguage.germany:
        return 'Bauplan';
      case AppLanguage.switzerland:
        return 'Bauplan';
      case AppLanguage.france:
        return 'Structure';
      case AppLanguage.sweden:
        return 'Struktur';
      case AppLanguage.norway:
        return 'Struktur';
      case AppLanguage.denmark:
        return 'Struktur';
      case AppLanguage.netherlands:
        return 'Structuur';
      case AppLanguage.spain:
        return 'Estructura';
      case AppLanguage.italy:
        return 'Struttura';
    }
  }

  String get heatmapModeFatLabel {
    switch (this) {
      case AppLanguage.uk:
        return '🔥 Fat Map';
      case AppLanguage.germany:
        return '🔥 Fettverteilung';
      case AppLanguage.switzerland:
        return '🔥 Fett-Charte';
      case AppLanguage.france:
        return '🔥 Carte Graisse';
      case AppLanguage.sweden:
        return '🔥 Fettkarta';
      case AppLanguage.norway:
        return '🔥 Fettkart';
      case AppLanguage.denmark:
        return '🔥 Fedtkort';
      case AppLanguage.netherlands:
        return '🔥 Vetkaart';
      case AppLanguage.spain:
        return '🔥 Mapa Grasa';
      case AppLanguage.italy:
        return '🔥 Mappa Grasso';
    }
  }

  String get heatmapModeMuscleLabel {
    switch (this) {
      case AppLanguage.uk:
        return '💪 Muscle Tone';
      case AppLanguage.germany:
        return '💪 Muskeltonus';
      case AppLanguage.switzerland:
        return '💪 Muskeltonus';
      case AppLanguage.france:
        return '💪 Tonus';
      case AppLanguage.sweden:
        return '💪 Muskelton';
      case AppLanguage.norway:
        return '💪 Muskeltonus';
      case AppLanguage.denmark:
        return '💪 Muskeltonus';
      case AppLanguage.netherlands:
        return '💪 Spiertonus';
      case AppLanguage.spain:
        return '💪 Músculo';
      case AppLanguage.italy:
        return '💪 Tono';
    }
  }

  String get heatmapModeJointsLabel {
    switch (this) {
      case AppLanguage.uk:
        return '🛡️ Shields';
      case AppLanguage.germany:
        return '🛡️ Gelenkschutz';
      case AppLanguage.switzerland:
        return '🛡️ Gelenkschutz';
      case AppLanguage.france:
        return '🛡️ Protection';
      case AppLanguage.sweden:
        return '🛡️ Ledskydd';
      case AppLanguage.norway:
        return '🛡️ Leddbeskyttelse';
      case AppLanguage.denmark:
        return '🛡️ Ledbeskyttelse';
      case AppLanguage.netherlands:
        return '🛡️ Gewrichten';
      case AppLanguage.spain:
        return '🛡️ Protección';
      case AppLanguage.italy:
        return '🛡️ Protezione';
    }
  }
}

const appCountries = <String, String>{
  'GB': 'United Kingdom',
  'DE': 'Germany',
  'CH': 'Switzerland',
  'FR': 'France',
  'SE': 'Sweden',
  'NO': 'Norway',
  'DK': 'Denmark',
  'NL': 'Netherlands',
  'ES': 'Spain',
  'IT': 'Italy',
  'AT': 'Austria',
  'BE': 'Belgium',
  'FI': 'Finland',
  'IE': 'Ireland',
  'PL': 'Poland',
  'PT': 'Portugal',
  'CZ': 'Czechia',
  'GR': 'Greece',
  'RO': 'Romania',
  'IN': 'India',
  'US': 'United States',
  'ZZ': 'Other',
};
