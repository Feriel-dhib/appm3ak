/// Chaînes localisées pour Ma3ak (ar / fr / en).
class AppStrings {
  AppStrings(this.locale);

  final String locale;
  bool get isAr => locale == 'ar';
  bool get isEn => locale == 'en';

  static AppStrings fr() => AppStrings('fr');
  static AppStrings ar() => AppStrings('ar');
  static AppStrings en() => AppStrings('en');

  /// Utilise 'ar' si lang == 'ar', 'en' si lang == 'en', sinon 'fr'.
  static AppStrings fromPreferredLanguage(String? lang) {
    switch (lang?.toLowerCase()) {
      case 'ar':
        return ar();
      case 'en':
        return en();
      default:
        return fr();
    }
  }

  String _t({required String ar, required String en, required String fr}) {
    if (isAr) return ar;
    if (isEn) return en;
    return fr;
  }

  // ─── App ───────────────────────────────────────────────────────────────────
  String get appTitle => _t(ar: 'معاك', en: 'Ma3ak', fr: 'Ma3ak');
  String get splashLoading =>
      _t(ar: 'جاري التحميل...', en: 'Loading...', fr: 'Chargement...');

  // ─── Auth ──────────────────────────────────────────────────────────────────
  String get login => _t(ar: 'تسجيل الدخول', en: 'Login', fr: 'Connexion');
  String get register => _t(ar: 'التسجيل', en: 'Sign Up', fr: 'Inscription');
  String get email => _t(ar: 'البريد الإلكتروني', en: 'Email', fr: 'Email');
  String get password =>
      _t(ar: 'كلمة المرور', en: 'Password', fr: 'Mot de passe');
  String get loginButton =>
      _t(ar: 'دخول', en: 'Log In', fr: 'Se connecter');
  String get registerButton =>
      _t(ar: 'إنشاء حساب', en: 'Create Account', fr: 'Créer un compte');
  String get loginWithGoogle =>
      _t(ar: 'المتابعة مع Google', en: 'Continue with Google', fr: 'Continuer avec Google');
  String get noAccount =>
      _t(ar: 'ليس لديك حساب؟', en: "Don't have an account?", fr: 'Pas encore de compte ?');
  String get haveAccount =>
      _t(ar: 'لديك حساب؟', en: 'Already have an account?', fr: 'Déjà un compte ?');
  String get tagline =>
      _t(ar: 'تنقل شامل للجميع', en: 'Inclusive mobility for all', fr: 'Mobilité inclusive pour tous');
  String get emailOrPhone =>
      _t(ar: 'البريد أو الهاتف', en: 'Email / Phone', fr: 'E-mail / Téléphone');
  String get hintEmailOrPhone =>
      _t(ar: 'أدخل بريدك أو رقم هاتفك', en: 'Enter your email or phone', fr: 'Entrez votre e-mail ou téléphone');
  String get hintPassword =>
      _t(ar: 'أدخل كلمة المرور', en: 'Enter your password', fr: 'Entrez votre mot de passe');
  String get connexion => _t(ar: 'دخول', en: 'Login', fr: 'Connexion');
  String get forgotPassword =>
      _t(ar: 'كلمة المرور منسية؟', en: 'Forgot password?', fr: 'Mot de passe oublié ?');
  String get or => _t(ar: 'أو', en: 'OR', fr: 'OU');
  String get signInWithGoogle =>
      _t(ar: 'المتابعة مع Google', en: 'Sign in with Google', fr: 'Se connecter avec Google');
  String get signUp => _t(ar: 'التسجيل', en: 'Sign up', fr: "S'inscrire");
  String get welcomeBack =>
      _t(ar: 'مرحباً بعودتك', en: 'Welcome back', fr: 'Ravi de vous revoir');
  String get welcomeBackSubtitle => _t(
    ar: 'سجّل دخولك لمتابعة رحلتك نحو تنقل أسهل مع معاك.',
    en: 'Sign in to continue your inclusive mobility journey with Ma3ak.',
    fr: 'Connectez-vous pour poursuivre votre mobilité inclusive avec Ma3ak.',
  );
  String get rememberMe =>
      _t(ar: 'تذكرني', en: 'Remember me', fr: 'Se souvenir de moi');
  String get loginRequiresValidEmail => _t(
    ar: 'يُرجى إدخال بريد إلكتروني صالح لتسجيل الدخول.',
    en: 'Please enter a valid email address to sign in.',
    fr: 'Veuillez entrer une adresse e-mail valide pour vous connecter.',
  );
  String get googleSignInPendingConfig => _t(
    ar: 'تسجيل الدخول عبر Google قيد الإعداد.',
    en: 'Google Sign-In is not configured yet.',
    fr: 'Connexion Google à configurer (voir README).',
  );

  String get welcomeHeroTitle =>
      _t(ar: 'مرحباً :)', en: 'Welcome :)', fr: 'Bienvenue :)');
  String get welcomeHeroHi =>
      _t(ar: 'أهلاً بك!', en: 'Hi there!', fr: 'Bonjour !');
  String get welcomeHeroLine2 => _t(
    ar: 'معاك من أجل تنقل أسهل وأكثر شمولية في تونس.',
    en: 'Ma3ak is here for more inclusive mobility in Tunisia.',
    fr: 'Ma3ak vous accompagne pour une mobilité plus inclusive en Tunisie.',
  );
  String get welcomeHeroChoiceLead => _t(
    ar: 'الخيار لك:',
    en: 'The choice is yours:',
    fr: 'À vous de choisir :',
  );
  String get welcomeHeroChoiceOr =>
      _t(ar: ' أو ', en: ' or ', fr: ' ou ');
  String get welcomeHeroChoiceEnd =>
      _t(ar: '.', en: '.', fr: '.');

  // ─── Register ──────────────────────────────────────────────────────────────
  String get createAccount =>
      _t(ar: 'إنشاء حسابك', en: 'Create your account', fr: 'Créez votre compte');
  String get registerPageTitle =>
      _t(ar: 'إنشاء حساب', en: 'Create account', fr: 'Créer un compte');
  String get registerSubtitle => _t(
    ar: 'انضم إلى مجتمع معاك من أجل تنقل شامل في تونس.',
    en: 'Join the Ma3ak community for inclusive mobility in Tunisia.',
    fr: 'Rejoignez la communauté Ma3ak pour une mobilité inclusive en Tunisie.',
  );
  String get dataSecurityMessage => _t(
    ar: 'بياناتك محمية وتُستخدم فقط لتسهيل تنقلك.',
    en: 'Your data is secure and used only to facilitate your transport.',
    fr: 'Vos données sont sécurisées et utilisées uniquement pour faciliter votre transport.',
  );
  String get iAm => _t(ar: 'أنا...', en: 'I am...', fr: 'Je suis...');
  String get roleHandicap =>
      _t(ar: 'ذو إعاقة', en: 'Person with disability', fr: 'Handicapé');
  String get registerAlready =>
      _t(ar: 'مسجل بالفعل؟', en: 'Already registered?', fr: 'Déjà inscrit ?');
  String get registerWelcome => _t(
    ar: 'مرحباً بكم في معاك. قدم معلوماتك لمساعدتنا في تخصيص تجربة الوصول في تونس.',
    en: "Welcome to Ma3ak. Please provide your information to help us personalise your accessibility experience in Tunisia.",
    fr: "Bienvenue sur Ma3ak. Veuillez fournir vos informations pour nous aider à personnaliser votre expérience d'accessibilité en Tunisie.",
  );
  String get fullName =>
      _t(ar: 'الاسم الكامل', en: 'Full name', fr: 'Nom complet');
  String get fullNameHint =>
      _t(ar: 'مثال: سامي منصور', en: 'e.g. Sami Mansour', fr: 'ex. Sami Mansour');
  String get handicapTypeOptional => _t(
    ar: 'نوع الإعاقة (اختياري)',
    en: 'Disability type (Optional)',
    fr: 'Type de handicap (Optionnel)',
  );
  String get typeHandicapHint =>
      _t(ar: 'اختر النوع', en: 'Choose the type', fr: 'Choisissez le type');
  String get selectOption =>
      _t(ar: 'اختر', en: 'Select an option', fr: 'Sélectionnez une option');
  String get handicapHelper => _t(
    ar: 'يساعدنا في اقتراح مسارات ووظائف مناسبة.',
    en: 'This helps us suggest suitable routes and features.',
    fr: 'Cela nous aide à suggérer des itinéraires et des fonctionnalités adaptés.',
  );
  String get emailOrPhoneRequired => _t(
    ar: 'البريد أو رقم الهاتف *',
    en: 'Email or phone number *',
    fr: 'Email ou Numéro de téléphone *',
  );
  String get emailOrPhoneHint => _t(
    ar: 'البريد أو +216...',
    en: 'email@example.com or +216...',
    fr: 'email@exemple.com ou +216...',
  );
  String get continueBtn =>
      _t(ar: 'متابعة', en: 'Continue', fr: 'Continuer');
  String get alreadyHaveAccount =>
      _t(ar: 'لديك حساب؟', en: 'Already have an account?', fr: 'Vous avez déjà un compte?');

  // ─── Profil ────────────────────────────────────────────────────────────────
  String get nom => _t(ar: 'الاسم', en: 'Name', fr: 'Nom');
  String get contact => _t(ar: 'الاتصال', en: 'Contact', fr: 'Contact');
  String get ville => _t(ar: 'المدينة', en: 'City', fr: 'Ville');
  String get role => _t(ar: 'الدور', en: 'Role', fr: 'Rôle');
  String get bio => _t(ar: 'السيرة الذاتية', en: 'Biography', fr: 'Biographie');
  String get preferredLanguage =>
      _t(ar: 'اللغة المفضلة', en: 'Preferred Language', fr: 'Langue préférée');
  String get handicapTypes =>
      _t(ar: 'أنواع الإعاقة', en: 'Disability Types', fr: 'Types de handicap');
  String get beneficiary =>
      _t(ar: 'مستفيد', en: 'Beneficiary', fr: 'Bénéficiaire');
  String get companion =>
      _t(ar: 'مرافق', en: 'Companion', fr: 'Accompagnant');
  String get home => _t(ar: 'الرئيسية', en: 'Home', fr: 'Accueil');
  String get profile =>
      _t(ar: 'الملف الشخصي', en: 'Profile', fr: 'Profil');
  String get personalInfo =>
      _t(ar: 'المعلومات الشخصية', en: 'PERSONAL INFORMATION', fr: 'INFORMATIONS PERSONNELLES');
  String get securitySupport =>
      _t(ar: 'الأمان والدعم', en: 'SECURITY & SUPPORT', fr: 'SÉCURITÉ ET SUPPORT');
  String get emergencyContacts =>
      _t(ar: 'جهات الاتصال الطارئة', en: 'Emergency contacts', fr: "Contacts d'urgence");
  String get assistanceHistory =>
      _t(ar: 'سجل المساعدة', en: 'Assistance history', fr: "Historique d'assistance");
  String get settings =>
      _t(ar: 'الإعدادات', en: 'Settings', fr: 'Paramètres');
  String get verifiedUser =>
      _t(ar: 'مستخدم موثق', en: 'Verified user', fr: 'Utilisateur vérifié');
  String get memberSince =>
      _t(ar: 'عضو منذ', en: 'Member since', fr: 'Membre depuis');
  String get assistedTrips =>
      _t(ar: 'رحلات مساعدة', en: 'ASSISTED TRIPS', fr: 'TRAJETS ASSISTÉS');
  String get communityRating =>
      _t(ar: 'تقييم المجتمع', en: 'COMMUNITY RATING', fr: 'NOTE COMMUNAUTÉ');
  String get myProfile => _t(ar: 'ملفي', en: 'My Profile', fr: 'Mon Profil');
  String get logout =>
      _t(ar: 'تسجيل الخروج', en: 'Logout', fr: 'Déconnexion');
  String get save => _t(ar: 'حفظ', en: 'Save', fr: 'Enregistrer');
  String get editProfile =>
      _t(ar: 'تعديل الملف', en: 'Edit profile', fr: 'Modifier le profil');
  String get changePhoto =>
      _t(ar: 'تغيير الصورة', en: 'Change photo', fr: 'Changer la photo');
  String get removeProfilePhoto => _t(
        ar: 'حذف الصورة',
        en: 'Remove photo',
        fr: 'Supprimer la photo',
      );
  String get profilePhotoTooLarge => _t(
        ar: 'الصورة كبيرة جداً (الحد 5 ميجابايت).',
        en: 'Image is too large (max 5 MB).',
        fr: 'Image trop volumineuse (5 Mo max).',
      );
  String get profilePhotoInvalidType => _t(
        ar: 'يُسمح بـ JPEG أو PNG أو GIF أو WebP فقط.',
        en: 'Only JPEG, PNG, GIF, or WebP is allowed.',
        fr: 'Formats acceptés : JPEG, PNG, GIF, WebP.',
      );
  String get profilePhotoActionFailed => _t(
        ar: 'تعذّر تحديث الصورة. حاول مرة أخرى.',
        en: 'Could not update the photo. Please try again.',
        fr: 'Impossible de mettre à jour la photo. Réessayez.',
      );
  String get phoneNumber =>
      _t(ar: 'رقم الهاتف', en: 'Phone number', fr: 'Numéro de Téléphone');
  String get errorGeneric =>
      _t(ar: 'حدث خطأ', en: 'An error occurred', fr: "Une erreur s'est produite");
  String get errorInvalidCredentials => _t(
    ar: 'البريد أو كلمة المرور غير صحيحة',
    en: 'Incorrect email or password',
    fr: 'Email ou mot de passe incorrect',
  );

  // ─── Relations ─────────────────────────────────────────────────────────────
  String get myAccompagnants =>
      _t(ar: 'مرافقوني', en: 'My companions', fr: 'Mes accompagnants');
  String get myBeneficiaires =>
      _t(ar: 'مستفيدوني', en: 'My beneficiaries', fr: 'Mes bénéficiaires');
  String get addAccompagnant =>
      _t(ar: 'إضافة مرافق', en: 'Add a companion', fr: 'Ajouter un accompagnant');
  String get addHandicape =>
      _t(ar: 'إضافة مستفيد', en: 'Add a beneficiary', fr: 'Ajouter un handicapé');
  String get removeAccompagnant =>
      _t(ar: 'إزالة', en: 'Remove', fr: 'Retirer');
  String get relationStatusPending =>
      _t(ar: 'في الانتظار', en: 'Pending', fr: 'En attente');
  String get relationStatusAccepted =>
      _t(ar: 'مقبولة', en: 'Accepted', fr: 'Acceptée');
  String get acceptRelation =>
      _t(ar: 'قبول الطلب', en: 'Accept request', fr: 'Accepter la demande');
  String get deleteRelation =>
      _t(ar: 'إلغاء الرابط', en: 'Delete link', fr: 'Supprimer la liaison');
  String get addAccompagnantById =>
      _t(ar: 'إضافة مرافق بالمعرّف', en: 'Add companion by ID', fr: 'Ajouter par ID accompagnant');
  String get addHandicapeById =>
      _t(ar: 'إضافة مستفيد بالمعرّف', en: 'Add beneficiary by ID', fr: 'Ajouter par ID handicapé');
  String get idPlaceholder =>
      _t(ar: 'معرّف المستخدم (MongoDB)', en: 'User ID (MongoDB)', fr: 'ID utilisateur (MongoDB)');
  String get relationAlreadyExists =>
      _t(ar: 'الرابط موجود مسبقاً', en: 'This link already exists', fr: 'Cette liaison existe déjà');
  String get relationNotFound =>
      _t(ar: 'الرابط غير موجود', en: 'Link not found', fr: 'Liaison introuvable');
  String get myHandicapes =>
      _t(ar: 'مستفيدوني', en: 'My beneficiaries', fr: 'Mes handicapés');
  String get noAccompagnantsYet =>
      _t(ar: 'لا مرافقين بعد', en: 'No companions yet', fr: "Aucun accompagnant pour l'instant");
  String get noHandicapesYet =>
      _t(ar: 'لا مستفيدين بعد', en: 'No beneficiaries yet', fr: "Aucun handicapé pour l'instant");
  String get relationsSubtitle => _t(
    ar: 'الأشخاص المرتبطين بك في التطبيق',
    en: 'People linked to you in the app',
    fr: "Les personnes liées à vous dans l'app",
  );

  // ─── Accueil ───────────────────────────────────────────────────────────────
  String get transport => _t(ar: 'النقل', en: 'Transport', fr: 'Transport');
  String get places => _t(ar: 'أماكن', en: 'Places', fr: 'Milieux');
  String get navLieux => isAr ? 'الأماكن' : 'Lieux';
  String get nearbyPlacesNav => isAr ? 'أماكن قريبة' : 'Lieux proches';
  /// Grille d’accueil : uniquement lieux / milieux accessibles.
  String get homePlacesServicesSection => _t(
    ar: 'الأماكن والبيئات',
    en: 'Places & environments',
    fr: 'Lieux & milieux',
  );
  String get health => _t(ar: 'الصحة', en: 'Health', fr: 'Santé');
  String get medicalRecordMenu => _t(
        ar: 'الملف الطبي',
        en: 'Medical record',
        fr: 'Dossier médical',
      );

  // ─── Santé (onglet + assistant IA) ───────────────────────────────────────
  String get healthAssistantTitle => _t(
        ar: 'مساعد الصحة الذكي',
        en: 'AI health assistant',
        fr: 'Assistant santé IA',
      );
  String get healthAssistantSubtitle => _t(
        ar: 'دردشة وصوت بالفرنسية أو الإنجليزية',
        en: 'Chat & voice — French or English',
        fr: 'Chat & voix — français ou anglais',
      );
  String get healthOpenChat =>
      _t(ar: 'فتح المساعد', en: 'Open assistant', fr: 'Ouvrir l’assistant');
  String get healthFabChat =>
      _t(ar: 'مساعد صحي', en: 'Health chat', fr: 'Chat IA santé');
  String get healthScoreTitle =>
      _t(ar: 'مؤشر الصحة', en: 'Health score', fr: 'Score santé');
  String get healthScoreHint => _t(
        ar: 'مؤشر تعليمي فقط — ليس تشخيصاً طبياً',
        en: 'Educational indicator — not a medical diagnosis',
        fr: 'Indicateur éducatif — pas un diagnostic médical',
      );
  String get healthGlycemiaTitle => _t(
        ar: 'تحليل السكر في الدم',
        en: 'Blood glucose analysis',
        fr: 'Analyse glycémie',
      );
  String get healthGlycemiaValueLabel =>
      _t(ar: 'القيمة (مغ/دل)', en: 'Value (mg/dL)', fr: 'Valeur (mg/dL)');
  String get healthGlycemiaFasting => _t(
        ar: 'قياس على الريق (صائم)',
        en: 'Fasting measurement',
        fr: 'À jeun (mesure)',
      );
  String get healthGlycemiaAnalyze =>
      _t(ar: 'تحليل ذكي', en: 'Analyze', fr: 'Analyser');
  String get healthGlycemiaInvalid => _t(
        ar: 'أدخل رقماً صالحاً',
        en: 'Enter a valid number',
        fr: 'Entrez un nombre valide',
      );
  String get healthMedsTitle =>
      _t(ar: 'تذكيرات الأدوية', en: 'Medication reminders', fr: 'Rappels médicaments');
  String get healthMedsEmpty => _t(
        ar: 'لا توجد تذكيرات. أضف دواءً ووقته.',
        en: 'No reminders. Add a medication and time.',
        fr: 'Aucun rappel. Ajoutez un médicament et son heure.',
      );
  String get healthMedsAdd =>
      _t(ar: 'إضافة دواء', en: 'Add medication', fr: 'Ajouter un médicament');
  String get healthMedName =>
      _t(ar: 'اسم الدواء', en: 'Medication name', fr: 'Nom du médicament');
  String get healthMedTime => _t(ar: 'الوقت', en: 'Time', fr: 'Heure');
  String get healthNextReminders =>
      _t(ar: 'التذكيرات القادمة', en: 'Upcoming reminders', fr: 'Prochains rappels');
  String get healthSosTitle => _t(
        ar: 'مساعد طوارئ (SOS)',
        en: 'SOS assistant',
        fr: 'Aide SOS intelligente',
      );
  String get healthSosBody => _t(
        ar: 'يفتح المساعد للإجابة الصوتية والنصية. في الخطر الحقيقي اتصل بالنجدة.',
        en: 'Opens the assistant for voice and text. In real danger, call emergency services.',
        fr: 'Ouvre l’assistant vocal et texte. En danger réel, appelez les secours.',
      );
  String get healthSosButton =>
      _t(ar: 'فتح مساعد SOS', en: 'Open SOS assistant', fr: 'Ouvrir assistant SOS');
  String get healthDisclaimerShort => _t(
        ar: 'المعلومات عامة — استشر طبيبك.',
        en: 'General information — consult your doctor.',
        fr: 'Infos générales — consultez votre médecin.',
      );
  String get healthChatTitle =>
      _t(ar: 'مساعد الصحة', en: 'Health assistant', fr: 'Assistant santé');
  String get healthChatHint => _t(
        ar: 'اكتب أو استخدم الميكروفون…',
        en: 'Type or use the microphone…',
        fr: 'Écrivez ou utilisez le micro…',
      );
  String get healthChatSend =>
      _t(ar: 'إرسال', en: 'Send', fr: 'Envoyer');
  String get healthVoiceLang =>
      _t(ar: 'لغة الصوت', en: 'Voice language', fr: 'Langue vocale');
  String get healthVoiceAuto =>
      _t(ar: 'قراءة تلقائية', en: 'Auto read-aloud', fr: 'Lecture auto');
  String get healthMicListen =>
      _t(ar: 'استماع', en: 'Listen', fr: 'Écouter');
  String get healthMicStop => _t(ar: 'إيقاف', en: 'Stop', fr: 'Stop');
  String get healthVoiceUnavailable => _t(
        ar: 'الصوت غير متاح على هذا المتصفح',
        en: 'Voice unavailable on this platform',
        fr: 'Voix indisponible sur ce navigateur',
      );
  String get healthMicNeedPermission => _t(
        ar: 'يُرجى السماح بالوصول إلى الميكروفون للتحدث إلى المساعد.',
        en: 'Allow microphone access to talk to the assistant.',
        fr: 'Autorisez l’accès au microphone pour parler à l’assistant.',
      );
  String get healthSpeechEngineUnavailable => _t(
        ar: 'التعرف على الكلام غير متاح. استخدم محاكيًا يحتوي على Google Play أو اكتب رسالتك.',
        en: 'Speech recognition unavailable. Use a Google Play emulator or type your message.',
        fr: 'Reconnaissance vocale indisponible. Utilisez un émulateur « Google Play » ou saisissez le texte.',
      );
  String get healthChatThinking => _t(
        ar: 'يردّ المساعد…',
        en: 'Assistant is replying…',
        fr: 'Réponse en cours…',
      );
  String get healthChatNothingHeard => _t(
        ar: 'لم يُسمع نص. حاول مرة أخرى أو اكتب سؤالك.',
        en: 'No speech detected. Try again or type your question.',
        fr: 'Aucune phrase reconnue. Réessayez ou écrivez votre question.',
      );

  /// Transcription du dialogue de l’interlocuteur (sourds / malentendants).
  String get conversationCaptionsTitle => _t(
        ar: 'كتابة الحوار المباشر',
        en: 'Live conversation captions',
        fr: 'Dialogue en texte (direct)',
      );
  String get conversationCaptionsMenu => _t(
        ar: 'تحويل كلام المحاور إلى نص',
        en: 'Turn speaker’s speech into text',
        fr: 'Paroles de l’interlocuteur → texte',
      );
  String get conversationCaptionsIntro => _t(
        ar: 'وجّه ميكروفون الهاتف نحو الشخص الذي يتحدث معك. يظهر النص على الشاشة باستمرار.',
        en: 'Point the phone’s microphone toward the person speaking. Text appears on screen as they talk.',
        fr: 'Orientez le micro du téléphone vers la personne en face : sa voix s’affiche en texte, phrase par phrase.',
      );
  String get conversationCaptionsToggle => _t(
        ar: 'تفعيل النسخ المباشر',
        en: 'Enable live transcription',
        fr: 'Activer la transcription en direct',
      );
  String get conversationCaptionsLang => _t(
        ar: 'لغة التعرف على الكلام',
        en: 'Speech recognition language',
        fr: 'Langue de reconnaissance vocale',
      );
  String get conversationCaptionsClear => _t(
        ar: 'مسح النص',
        en: 'Clear text',
        fr: 'Effacer le texte',
      );
  String get conversationCaptionsListening => _t(
        ar: 'جاري الاستماع…',
        en: 'Listening…',
        fr: 'Écoute en cours…',
      );
  String get conversationCaptionsPaused => _t(
        ar: 'متوقف مؤقتاً',
        en: 'Paused',
        fr: 'En pause',
      );
  String get conversationCaptionsNeedMic => _t(
        ar: 'يلزم إذن الميكروفون.',
        en: 'Microphone permission is required.',
        fr: 'L’autorisation microphone est nécessaire.',
      );
  String get conversationCaptionsEngineUnavailable => _t(
        ar: 'التعرف على الكلام غير متاح على هذا الجهاز.',
        en: 'Speech recognition is not available on this device.',
        fr: 'La reconnaissance vocale n’est pas disponible sur cet appareil.',
      );
  String get conversationCaptionsEmpty => _t(
        ar: 'لا يوجد نص بعد. فعّل النسخ المباشر لبدء الاستماع.',
        en: 'No text yet. Turn on live transcription to start.',
        fr: 'Pas encore de texte. Activez la transcription pour commencer.',
      );
  String get conversationCaptionsMicBannerBody => _t(
        ar: 'يُستخدم الميكروفون فقط لعرض كلام الشخص أمامك كنص.',
        en: 'The microphone is only used to show the other person’s speech as text.',
        fr: 'Le microphone sert uniquement à afficher la voix de l’interlocuteur en texte.',
      );
  String get conversationCaptionsAllowMicButton => _t(
        ar: 'السماح بالميكروفون',
        en: 'Allow microphone',
        fr: 'Autoriser le microphone',
      );
  String get conversationCaptionsOpenSettingsButton => _t(
        ar: 'فتح الإعدادات',
        en: 'Open settings',
        fr: 'Ouvrir les réglages',
      );

  String get healthVoiceSafetyCardTitle => _t(
        ar: 'الأمان الصوتي الذكي',
        en: 'Voice safety AI',
        fr: 'Sécurité IA vocale',
      );
  String get healthVoiceSafetyCardBody => _t(
        ar: 'عند اكتشاف ضغط أو خطر في محادثة الصحة، يتصل التطبيق تلقائيًا بأحد المقرّبين (اختيار ذكي على الخادم إن وُجد).',
        en: 'If stress or danger is detected in the health chat, the app can call a contact (server-side matching when available).',
        fr: 'Si stress ou danger est détecté dans le chat santé (voix ou texte), l’app appelle automatiquement un proche — le serveur choisit le contact si l’API est disponible.',
      );
  String get healthVoiceSafetyAutoCall => _t(
        ar: 'اتصال تلقائي بجهة الاتصال',
        en: 'Auto-call contact',
        fr: 'Appel automatique vers un contact',
      );
  String get healthVoiceSafetyDetected => _t(
        ar: 'تم اكتشاف حالة طارئة — جاري التنبيه…',
        en: 'Emergency detected — alerting…',
        fr: 'Situation d’urgence détectée — alerte en cours…',
      );
  String get healthVoiceSafetyNoPhone => _t(
        ar: 'لا يوجد رقم. أضف جهة اتصال في «إدارة المقرّبين».',
        en: 'No number. Add a contact in emergency contacts.',
        fr: 'Aucun numéro. Ajoutez un proche dans Gérer les contacts d’urgence.',
      );
  String healthVoiceSafetyCalling(String nameOrPhone) => _t(
        ar: 'جاري الاتصال بـ $nameOrPhone…',
        en: 'Calling $nameOrPhone…',
        fr: 'Appel vers $nameOrPhone…',
      );
  String get healthVoiceSafetyCallFailed => _t(
        ar: 'تعذّر إجراء المكالمة. اسمح بإذن الهاتف أو اتصل يدويًا.',
        en: 'Could not place the call. Allow phone permission or dial manually.',
        fr: 'Impossible de lancer l’appel. Autorisez le téléphone ou appelez manuellement.',
      );

  // ─── Santé humaine (onglet calendrier / SOS) ───────────────────────────────
  String get sosMedical =>
      _t(ar: 'SOS طبي', en: 'Medical SOS', fr: 'SOS Médical');
  String get sosMedicalSubtitle => _t(
        ar: 'تنبيه فوري واتصال الطوارئ',
        en: 'Immediate alert & emergency contact',
        fr: 'Alerte immédiate & contact urgence',
      );
  String get healthSmartSosTitle => _t(
        ar: 'الأمان الذكي',
        en: 'Smart safety & matching',
        fr: 'Sécurité IA & Smart Matching',
      );
  String get healthSmartSosSubtitle => _t(
        ar: 'دمج الإشارات واختيار من يُتصل به',
        en: 'Fuse signals (text, motion, location) + who to alert',
        fr: 'Fusion signaux (texte, mouvement, lieu) + qui alerter',
      );
  String get myAppointments =>
      _t(ar: 'مواعيدي', en: 'My appointments', fr: 'Mes Rendez-vous');
  String get reminders =>
      _t(ar: 'التذكيرات', en: 'Reminders', fr: 'Rappels');
  String get add => _t(ar: 'إضافة', en: 'Add', fr: 'Ajouter');
  String get todayLabel =>
      _t(ar: 'اليوم', en: 'TODAY', fr: 'AUJOURD\'HUI');
  String get stepsToday => _t(
        ar: 'الخطوات اليوم',
        en: 'Steps today',
        fr: 'Pas aujourd\'hui',
      );
  String get sleep => _t(ar: 'النوم', en: 'Sleep', fr: 'Sommeil');
  String get insulin =>
      _t(ar: 'أنسولين', en: 'Insulin', fr: 'Insuline');
  String get insulinReminder =>
      _t(ar: 'قبل الوجبة', en: 'Before meal', fr: 'Avant repas');
  String get bloodGlucoseCheck => _t(
        ar: 'مراقبة السكر',
        en: 'Blood glucose check',
        fr: 'Contrôle Glycémie',
      );
  String get daily =>
      _t(ar: 'يومي', en: 'Daily', fr: 'Quotidien');
  String get hydration =>
      _t(ar: 'ترطيب', en: 'Hydration', fr: 'Hydratation');
  String get everyTwoHours => _t(
        ar: 'كل ساعتين',
        en: 'Every 2 hours',
        fr: 'Toutes les 2 heures',
      );

  String get hello => _t(ar: 'مرحباً', en: 'Hello', fr: 'Bonjour');
  String get whereToGoToday => _t(
    ar: 'أين تود الذهاب اليوم؟',
    en: 'Where would you like to go today?',
    fr: "Où aimeriez-vous aller aujourd'hui ?",
  );
  String get searchAccessiblePlaces =>
      _t(ar: 'البحث عن أماكن متاحة', en: 'Search accessible places', fr: 'Rechercher des lieux accessibles');
  String get mainServices =>
      _t(ar: 'الخدمات الرئيسية', en: 'Main Services', fr: 'Services Principaux');
  String get mobilityTransport =>
      _t(ar: 'التنقل والنقل', en: 'Mobility & Transport', fr: 'Mobilité & Transport');
  String get findAssistant =>
      _t(ar: 'البحث عن مساعد', en: 'Find an assistant', fr: 'Trouver un assistant');
  String get accessibilityCard =>
      _t(ar: 'بطاقة إمكانية الوصول', en: 'Accessibility card', fr: "Carte d'accessibilité");
  String get learningCenter =>
      _t(ar: 'مركز التعلم', en: 'Learning center', fr: "Centre d'apprentissage");
  String get nearbyAndActive =>
      _t(ar: 'بالقرب ونشط', en: 'Nearby & Active', fr: 'À proximité & Actif');
  String get seeAll => _t(ar: 'عرض الكل', en: 'See all', fr: 'Voir tout');
  String get exploreNearby =>
      _t(ar: 'استكشف الجوار', en: 'Explore nearby', fr: 'Explorer à proximité');
  String get available => _t(ar: 'متاح', en: 'AVAILABLE', fr: 'DISPONIBLE');
  String get open => _t(ar: 'مفتوح', en: 'OPEN', fr: 'OUVERT');

  // ─── Accompagnant (home) ───────────────────────────────────────────────────
  String get companionRole =>
      _t(ar: 'مرافق', en: 'COMPANION', fr: 'ACCOMPAGNANT');
  String get followedUsers =>
      _t(ar: 'المستخدمون المتابعون', en: 'Followed users', fr: 'Utilisateurs suivis');
  String get atHome => _t(ar: 'في المنزل', en: 'AT HOME', fr: 'À DOMICILE');
  String get calm => _t(ar: 'هادئ', en: 'CALM', fr: 'CALME');
  String get atDistance => _t(ar: 'على بعد', en: 'AT 500M', fr: 'À 500M');
  String get active => _t(ar: 'نشط', en: 'ACTIVE', fr: 'ACTIF');
  String get assistanceRequests =>
      _t(ar: 'طلبات المساعدة', en: "Assistance requests", fr: "Demandes d'assistance");
  String get newLabel => _t(ar: 'جديد', en: 'NEW', fr: 'NOUVEAU');
  String get urgentTransport =>
      _t(ar: 'نقل عاجل', en: 'URGENT TRANSPORT', fr: 'TRANSPORT URGENT');
  String get accept => _t(ar: 'قبول', en: 'Accept', fr: 'Accepter');
  String get ignore => _t(ar: 'تجاهل', en: 'Ignore', fr: 'Ignorer');
  String get mySchedule =>
      _t(ar: 'جدولي', en: 'My schedule', fr: 'Mon planning');
  String get medicalAccompaniment =>
      _t(ar: 'مرافقة طبية', en: 'Medical accompaniment', fr: 'Accompagnement médical');
  String get groceryHelp =>
      _t(ar: 'مساعدة في التسوق', en: 'Grocery help', fr: 'Aide aux courses');
  String get resourcesAndGuide =>
      _t(ar: 'الموارد والدليل', en: 'Resources & Guide', fr: 'Ressources & Guide');
  String get goodPracticesGuide =>
      _t(ar: 'دليل الممارسات الجيدة', en: 'Good practices guide', fr: 'Guide des bonnes pratiques');
  String get firstAid =>
      _t(ar: 'الإسعافات الأولية', en: 'First aid', fr: 'Premiers secours');

  // ─── Transport hub ─────────────────────────────────────────────────────────
  String get transportHubTitle =>
      _t(ar: 'مركز النقل', en: 'Transport Hub', fr: 'Centre Transport');
  String get transportHubSubtitle => _t(
    ar: 'الوصول السريع إلى جميع خدمات النقل',
    en: 'Quick access to all transport services',
    fr: 'Accès rapide à toutes les fonctionnalités transport',
  );
  String get quickActionsTitle =>
      _t(ar: 'إجراءات سريعة', en: 'Quick Actions', fr: 'Actions rapides');
  String get activeTripsTitle =>
      _t(ar: 'رحلات نشطة', en: 'Active trips', fr: 'Trajets actifs');
  String get availableRequestsTitle =>
      _t(ar: 'طلبات متاحة', en: 'Available requests', fr: 'Demandes disponibles');
  String get noActiveTripsMessage =>
      _t(ar: 'لا توجد رحلات نشطة حالياً', en: 'No active trips at the moment', fr: 'Aucun trajet actif pour le moment');
  String get noAvailableRequestsMessage =>
      _t(ar: 'لا توجد طلبات متاحة الآن', en: 'No available requests at the moment', fr: 'Aucune demande disponible actuellement');
  /// Liste filtrée : demandes ouvertes + courses sur *vos* véhicules (chauffeur solidaire).
  String get noAvailableRequestsChauffeurScopedMessage => _t(
    ar: 'لا طلبات مفتوحة أو حجوزات على مركباتك حالياً. الطلبات الموجهة لمركبة محددة تظهر فقط لمالكها.',
    en: 'No open requests or bookings on your vehicles right now. Requests tied to a specific vehicle only appear for that owner.',
    fr: 'Aucune demande ouverte ni réservation sur vos véhicules pour le moment. Les courses liées à un véhicule précis sont visibles surtout pour son propriétaire.',
  );
  String get tripFromVehicleReservationBadge => _t(
    ar: 'حجز مركبة',
    en: 'Vehicle booking',
    fr: 'Réservation véhicule',
  );
  String get openLinkedTransportTrip => _t(
    ar: 'عرض مسار النقل',
    en: 'View transport trip',
    fr: 'Voir la course transport',
  );
  String get openVehicleReservationFromTrip => _t(
    ar: 'عرض حجز المركبة',
    en: 'View vehicle booking',
    fr: 'Voir la réservation véhicule',
  );
  String get urgentAlertsTitle =>
      _t(ar: 'تنبيهات عاجلة', en: 'Urgent alerts', fr: 'Alertes urgentes');
  String get myTripsLabel =>
      _t(ar: 'رحلاتي', en: 'My trips', fr: 'Mes trajets');
  String get liveMapLabel =>
      _t(ar: 'خريطة مباشرة', en: 'Live map', fr: 'Carte en direct');

  // ─── Types de handicap ─────────────────────────────────────────────────────
  String typeHandicapLabel(String backendValue) {
    switch (backendValue) {
      case 'Handicap moteur':
        return _t(ar: 'إعاقة حركية', en: 'Motor disability', fr: 'Handicap moteur');
      case 'Handicap visuel':
        return _t(ar: 'إعاقة بصرية', en: 'Visual disability', fr: 'Handicap visuel');
      case 'Handicap auditif':
        return _t(ar: 'إعاقة سمعية', en: 'Hearing disability', fr: 'Handicap auditif');
      default:
        return backendValue;
    }
  }

  // ─── Types d'accompagnant ──────────────────────────────────────────────────
  String typeAccompagnantLabel(String backendValue) {
    switch (backendValue) {
      case 'Membres de la famille':
        return _t(ar: 'أعضاء العائلة', en: 'Family members', fr: 'Membres de la famille');
      case 'Aides-soignants':
        return _t(ar: 'مساعدو التمريض', en: 'Care workers', fr: 'Aides-soignants');
      case 'Bénévoles':
        return _t(ar: 'متطوعون', en: 'Volunteers', fr: 'Bénévoles');
      case 'Chauffeurs solidaires':
        return _t(ar: 'سائقي التضامن', en: 'Solidarity drivers', fr: 'Chauffeurs solidaires');
      default:
        return backendValue;
    }
  }

  String get typeAccompagnantRequired =>
      _t(ar: 'نوع المرافق *', en: 'Companion type *', fr: "Type d'accompagnant *");
  String get typeAccompagnantHint =>
      _t(ar: 'اختر نوعك', en: 'Choose your type', fr: 'Choisissez votre type');
  String get typeAccompagnantRequiredError => _t(
    ar: 'الرجاء اختيار نوع المرافق',
    en: 'Please choose a companion type',
    fr: "Veuillez choisir un type d'accompagnant",
  );
  String get companionAccountIsChauffeurSolidaireOnly => _t(
    ar: 'حساب المرافق مخصص لسائقي التضامن الذين ينقلون المستخدمين على التطبيق.',
    en: 'Companion accounts are for volunteer drivers who transport users via the app.',
    fr: 'Le compte accompagnant sur Ma3ak est réservé aux chauffeurs solidaires qui assurent le transport des usagers.',
  );

  // ─── Thème ─────────────────────────────────────────────────────────────────
  String get theme => _t(ar: 'المظهر', en: 'Theme', fr: 'Thème');
  String get themeLight => _t(ar: 'فاتح', en: 'Light', fr: 'Clair');
  String get themeDark => _t(ar: 'داكن', en: 'Dark', fr: 'Sombre');
  String get themeSystem => _t(ar: 'حسب الجهاز', en: 'System', fr: 'Système');
  /// Libellé de repère pour la barre de navigation principale (TalkBack / VoiceOver).
  String get mainNavigationLandmark => _t(
        ar: 'التنقل الرئيسي',
        en: 'Main tab navigation',
        fr: 'Navigation principale par onglets',
      );

  /// Indication accessibilité : la recherche ouvre le transport.
  String get a11ySearchOpensTransport => _t(
        ar: 'ينقل إلى تبويب النقل',
        en: 'Goes to the Transport tab',
        fr: "Ouvre l'onglet Transport",
      );

  /// Bouton d’accès rapide aux alertes SOS (carte accueil).
  String get a11yOpenSosAlerts => _t(
        ar: 'تنبيهات الطوارئ والاستغاثة',
        en: 'SOS and emergency alerts',
        fr: 'Alertes SOS et urgences',
      );

  String get notifications => _t(
        ar: 'الإشعارات',
        en: 'Notifications',
        fr: 'Notifications',
      );

  String get themeToggleHint => _t(
        ar: 'اضغط للتبديل بين الوضع النهاري والليلي.',
        en: 'Tap the switch to choose light or dark appearance.',
        fr: "Touchez l'interrupteur pour passer en clair ou en sombre.",
      );

  // ─── Véhicules ─────────────────────────────────────────────────────────────
  String get myVehicles =>
      _t(ar: 'مركباتي', en: 'My vehicles', fr: 'Mes véhicules');
  String get vehicles => _t(ar: 'المركبات', en: 'Vehicles', fr: 'Véhicules');
  String get addVehicle =>
      _t(ar: 'إضافة مركبة', en: 'Add a vehicle', fr: 'Ajouter un véhicule');
  String get vehicleDetails =>
      _t(ar: 'تفاصيل المركبة', en: 'Vehicle details', fr: 'Détails du véhicule');
  String get editVehicle =>
      _t(ar: 'تعديل المركبة', en: 'Edit vehicle', fr: 'Modifier le véhicule');
  String get deleteVehicle =>
      _t(ar: 'حذف المركبة', en: 'Delete vehicle', fr: 'Supprimer le véhicule');
  String get marque =>
      _t(ar: 'العلامة التجارية', en: 'Make', fr: 'Marque');
  String get modele => _t(ar: 'النموذج', en: 'Model', fr: 'Modèle');
  String get immatriculation =>
      _t(ar: 'رقم التسجيل', en: 'License plate', fr: 'Immatriculation');
  String get accessibilite =>
      _t(ar: 'إمكانية الوصول', en: 'Accessibility', fr: 'Accessibilité');
  String get photos => _t(ar: 'الصور', en: 'Photos', fr: 'Photos');
  String get statut => _t(ar: 'الحالة', en: 'Status', fr: 'Statut');
  String get coffreVaste =>
      _t(ar: 'صندوق واسع', en: 'Large trunk', fr: 'Coffre vaste');
  String get rampeAcces =>
      _t(ar: 'منحدر الوصول', en: 'Access ramp', fr: "Rampe d'accès");
  String get siegePivotant =>
      _t(ar: 'مقعد دوار', en: 'Pivoting seat', fr: 'Siège pivotant');
  String get climatisation =>
      _t(ar: 'تكييف الهواء', en: 'Air conditioning', fr: 'Climatisation');
  String get animalAccepte =>
      _t(ar: 'قبول الحيوانات', en: 'Animals accepted', fr: 'Animal accepté');
  String get vehicleCreated =>
      _t(ar: 'تم إنشاء المركبة بنجاح', en: 'Vehicle created successfully', fr: 'Véhicule créé avec succès');
  String get vehicleUpdated =>
      _t(ar: 'تم تحديث المركبة بنجاح', en: 'Vehicle updated successfully', fr: 'Véhicule mis à jour avec succès');
  String get vehicleDeleted =>
      _t(ar: 'تم حذف المركبة بنجاح', en: 'Vehicle deleted successfully', fr: 'Véhicule supprimé avec succès');
  String get confirmDeleteVehicle => _t(
    ar: 'هل أنت متأكد من حذف هذه المركبة؟',
    en: 'Are you sure you want to delete this vehicle?',
    fr: 'Êtes-vous sûr de vouloir supprimer ce véhicule ?',
  );
  String get noVehicles =>
      _t(ar: 'لا توجد مركبات', en: 'No vehicles', fr: 'Aucun véhicule');
  String get vehicleNotFound =>
      _t(ar: 'المركبة غير موجودة', en: 'Vehicle not found', fr: 'Véhicule non trouvé');
  String get immatriculationExists => _t(
    ar: 'هذه اللوحة مسجلة بالفعل',
    en: 'This license plate is already registered',
    fr: 'Cette immatriculation est déjà enregistrée',
  );
  String get requiredField =>
      _t(ar: 'هذا الحقل مطلوب', en: 'This field is required', fr: 'Ce champ est requis');
  String get vehicleDetailsTitle =>
      _t(ar: 'تفاصيل المركبة', en: 'Vehicle details', fr: 'Détails du véhicule');
  String get vehicleDetailsDescription => _t(
    ar: 'يرجى ملء معلومات مركبتك المكيفة للتنقل الشامل.',
    en: 'Please fill in your adapted vehicle information for inclusive mobility.',
    fr: 'Veuillez remplir les informations de votre véhicule adapté pour la mobilité inclusive.',
  );
  String get vehiclePhoto =>
      _t(ar: 'صورة المركبة', en: 'Vehicle photo', fr: 'Photo du véhicule');
  String get addPhoto =>
      _t(ar: 'إضافة صورة', en: 'Add a photo', fr: 'Ajouter une photo');
  String get photoFormats =>
      _t(ar: 'PNG، JPG حتى 10MB', en: 'PNG, JPG up to 10MB', fr: "PNG, JPG jusqu'à 10MB");
  String get marqueAndModele =>
      _t(ar: 'العلامة التجارية والنموذج', en: 'Make & Model', fr: 'Marque & Modèle');
  String get marqueModeleHint =>
      _t(ar: 'مثال: فولكس فاجن كادي', en: 'e.g. Volkswagen Caddy', fr: 'Ex: Volkswagen Caddy');
  String get invalidImmatriculationFormat => _t(
    ar: 'تنسيق التسجيل غير صالح',
    en: 'Invalid license plate format',
    fr: "Format d'immatriculation invalide",
  );
  String get specializedEquipment =>
      _t(ar: 'المعدات المتخصصة', en: 'Specialised equipment', fr: 'Équipements spécialisés');
  String get rampeAccesDescription =>
      _t(ar: 'يدوي أو تلقائي', en: 'Manual or automatic', fr: 'Manuelle ou automatique');
  String get siegePivotantDescription =>
      _t(ar: 'يسهل النقل', en: 'Facilitates transfer', fr: 'Facilite le transfert');
  String get espaceFauteuilRoulant =>
      _t(ar: 'مساحة الكرسي المتحرك', en: 'Wheelchair space', fr: 'Espace fauteuil roulant');
  String get espaceFauteuilRoulantDescription =>
      _t(ar: 'تثبيتات الأمان متضمنة', en: 'Safety fixings included', fr: 'Fixations de sécurité incluses');
  String get commandesVolant =>
      _t(ar: 'أوامر على عجلة القيادة', en: 'Steering wheel controls', fr: 'Commandes au volant');
  String get commandesVolantDescription =>
      _t(ar: 'تسريع وفرامل يدوية', en: 'Manual accelerator and brake', fr: 'Accélérateur et frein manuels');
  String get coffreVasteDescription =>
      _t(ar: 'مساحة تخزين كبيرة', en: 'Large storage space', fr: 'Grand espace de stockage');
  String get climatisationDescription =>
      _t(ar: 'تحكم في درجة الحرارة', en: 'Temperature control', fr: 'Contrôle de la température');
  String get animalAccepteDescription =>
      _t(ar: 'يسمح بالحيوانات المساعدة', en: 'Assistance animals allowed', fr: "Autorise les animaux d'assistance");

  // ─── Filtres véhicules ─────────────────────────────────────────────────────
  String get all => _t(ar: 'الكل', en: 'All', fr: 'Tous');
  String get favorites =>
      _t(ar: 'المفضلة', en: 'Favourites', fr: 'Favoris');
  String get inService =>
      _t(ar: 'في الخدمة', en: 'In service', fr: 'En service');
  String get maintenance =>
      _t(ar: 'صيانة', en: 'MAINTENANCE', fr: 'MAINTENANCE');
  String get lastMaintenance =>
      _t(ar: 'آخر صيانة', en: 'Last maintenance', fr: 'Dernière maintenance');
  String get scheduledFor =>
      _t(ar: 'مقرر ل', en: 'Scheduled for', fr: 'Prévu pour');
  String get plate => _t(ar: 'اللوحة', en: 'Plate', fr: 'Plaque');
  String get details =>
      _t(ar: 'التفاصيل', en: 'Details', fr: 'Détails');
  String get capacity => _t(ar: 'السعة', en: 'CAPACITY', fr: 'CAPACITÉ');
  String get capacityPlaces =>
      _t(ar: 'أماكن', en: 'Seats', fr: 'Places');
  String get servicesIncluded =>
      _t(ar: 'خدمات متضمنة', en: 'services included', fr: 'services inclus');
  String get checkAvailabilities =>
      _t(ar: 'التحقق من التوفر', en: 'Check availabilities', fr: 'Vérifier les disponibilités');
  String get spacious => _t(ar: 'واسع', en: 'Spacious', fr: 'Spacieux');
  String get pmrOptimized =>
      _t(ar: 'محسّن للأشخاص ذوي الإعاقة', en: 'PRM optimised', fr: 'PMR optimisé');
  String get comfortable =>
      _t(ar: 'مريح', en: 'Comfortable', fr: 'Confortable');
  String get dualZone =>
      _t(ar: 'منطقتان', en: 'Dual-zone', fr: 'Bi-zone');
  String get assistanceDogsWelcome =>
      _t(ar: 'كلاب المساعدة مرحب بها', en: "Assistance dogs welcome", fr: "Chiens d'assistance bienvenus");

  // ─── Véhicules adaptés ─────────────────────────────────────────────────────
  String get adaptedVehicles =>
      _t(ar: 'مركبات متكيفة', en: 'Adapted Vehicles', fr: 'Véhicules Adaptés');
  String get searchVehicle =>
      _t(ar: 'البحث عن مركبة...', en: 'Search a vehicle...', fr: 'Rechercher un véhicule...');
  String get vehiclesListNeedLocation10km => _t(
        ar: 'لعرض المركبات على بعد 10 كم كحد أقصى، فعّل الموقع أو حدّث موقعك في الملف الشخصي.',
        en: 'To see vehicles within 10 km, turn on location or set your position in your profile.',
        fr:
            'Pour voir les véhicules à moins de 10 km, activez la localisation ou renseignez votre position dans le profil.',
      );
  String get seeMoreVehicles =>
      _t(ar: 'عرض المزيد من المركبات', en: 'See more vehicles', fr: 'Voir plus de véhicules');
  String get soonAvailable =>
      _t(ar: 'قريباً متاح', en: 'SOON AVAILABLE', fr: 'BIENTÔT LIBRE');
  String get pricePerDay =>
      _t(ar: 'د.ت/يوم', en: 'TND/day', fr: 'TND/jr');
  String get tunis => _t(ar: 'تونس', en: 'Tunis', fr: 'Tunis');
  String get sousse => _t(ar: 'سوسة', en: 'Sousse', fr: 'Sousse');
  String get wheelchairSpace =>
      _t(ar: 'مساحة كرسي متحرك', en: 'Wheelchair space', fr: 'Espace Fauteuil');
  String get liftingPlatform =>
      _t(ar: 'منصة رفع', en: 'Lifting platform', fr: 'Plateforme Élévatrice');
  String get wheelchairsAndPlaces =>
      _t(ar: 'كرسيان + 5 أماكن', en: '2 Wheelchairs + 5 seats', fr: '2 Fauteuils + 5 places');

  // ─── Réservations de véhicules ─────────────────────────────────────────────
  String get myVehicleReservations => _t(
    ar: 'حجوزاتي للمركبات',
    en: 'My vehicle reservations',
    fr: 'Mes réservations de véhicules',
  );
  String get createReservation =>
      _t(ar: 'إنشاء حجز', en: 'Create reservation', fr: 'Créer une réservation');
  String get reservationDetails =>
      _t(ar: 'تفاصيل الحجز', en: 'Reservation details', fr: 'Détails de la réservation');
  String get departurePlace =>
      _t(ar: 'مكان المغادرة', en: 'Departure place', fr: 'Lieu de départ');
  String get destinationPlace =>
      _t(ar: 'مكان الوصول', en: 'Destination place', fr: 'Lieu de destination');
  String get specificNeeds =>
      _t(ar: 'احتياجات خاصة', en: 'Specific needs', fr: 'Besoins spécifiques');
  String get reservationCreated =>
      _t(ar: 'تم إنشاء الحجز بنجاح', en: 'Reservation created successfully', fr: 'Réservation créée avec succès');
  String get reservationCancelled =>
      _t(ar: 'تم إلغاء الحجز', en: 'Reservation cancelled', fr: 'Réservation annulée');
  String get vehicleNotAvailableForDate => _t(
    ar: 'هذا المركبة غير متاحة في هذا التاريخ والوقت',
    en: 'This vehicle is not available at this date and time',
    fr: "Ce véhicule n'est pas disponible à cette date et heure",
  );
  String get cancelReservation =>
      _t(ar: 'إلغاء الحجز', en: 'Cancel reservation', fr: 'Annuler la réservation');
  String get confirmCancelReservation => _t(
    ar: 'هل أنت متأكد من إلغاء هذه الحجز؟',
    en: 'Are you sure you want to cancel this reservation?',
    fr: "Êtes-vous sûr d'annuler cette réservation ?",
  );
  String get bookVehicle => _t(ar: 'حجز', en: 'Book', fr: 'Réserver');
  String get noReservations =>
      _t(ar: 'لا توجد حجوزات', en: 'No reservations', fr: 'Aucune réservation');
  String get dateRequired =>
      _t(ar: 'التاريخ مطلوب', en: 'Date is required', fr: 'La date est requise');
  String get timeRequired =>
      _t(ar: 'الوقت مطلوب', en: 'Time is required', fr: "L'heure est requise");
  String get timeFormatHint =>
      _t(ar: 'مثال: 14:30', en: 'e.g. 14:30', fr: 'Ex: 14:30');

  // ─── Permissions véhicule ──────────────────────────────────────────────────
  String get validateVehicle =>
      _t(ar: 'التحقق من المركبة', en: 'Validate', fr: 'Valider');
  String get rejectVehicle =>
      _t(ar: 'رفض', en: 'Reject', fr: 'Refuser');
  String get vehicleStatusUpdated => _t(
    ar: 'تم تحديث حالة المركبة بنجاح',
    en: 'Vehicle status updated successfully',
    fr: 'Statut du véhicule mis à jour avec succès',
  );
  String get cannotModifyVehicle => _t(
    ar: 'ليس لديك إذن لتعديل هذه المركبة',
    en: 'You do not have permission to edit this vehicle',
    fr: "Vous n'avez pas l'autorisation de modifier ce véhicule",
  );
  String get cannotModifyVehicleStatus => _t(
    ar: 'ليس لديك إذن لتعديل حالة هذه المركبة',
    en: "You do not have permission to edit this vehicle's status",
    fr: "Vous n'avez pas l'autorisation de modifier le statut de ce véhicule",
  );
  String get onlyStatusCanBeModified => _t(
    ar: 'يمكن تعديل الحالة فقط من قبل سائق متضامن',
    en: 'Only the status can be modified by a solidarity driver',
    fr: 'Seul le statut peut être modifié par un Chauffeur solidaire',
  );
  String get changeStatus =>
      _t(ar: 'تغيير الحالة', en: 'Change status', fr: 'Changer le statut');
  String get vehicleStatus =>
      _t(ar: 'حالة المركبة', en: 'Vehicle status', fr: 'Statut du véhicule');

  // ─── Carte & itinéraires ───────────────────────────────────────────────────
  String get searchAddress =>
      _t(ar: 'البحث عن عنوان...', en: 'Search for an address...', fr: 'Rechercher une adresse...');
  String get calculateRoute =>
      _t(ar: 'حساب المسار', en: 'Calculate route', fr: "Calcul de l'itinéraire");
  String get fillAddressesFirst =>
      _t(ar: 'أدخل عنواني المغادرة والوصول', en: 'Fill in departure and arrival addresses', fr: 'Remplissez les adresses');
  String get routeDistance =>
      _t(ar: 'المسافة', en: 'Distance', fr: 'Distance');
  String get routeDuration =>
      _t(ar: 'المدة', en: 'Duration', fr: 'Durée');
  String get chooseOnMap =>
      _t(ar: 'اختيار على الخريطة', en: 'Choose on map', fr: 'Choisir sur la carte');

  // ─── Carte dynamique ───────────────────────────────────────────────────────
  String get searchAccessiblePlace =>
      _t(ar: 'البحث عن مكان متاح...', en: 'Search accessible place...', fr: 'Chercher un lieu accessible...');
  /// Écran catalogue + détail (carte / analyse IA).
  String get accessibilityMapPlacesTitle => _t(
    ar: 'خريطة الإتاحة والأماكن',
    en: 'Accessibility Map & Places',
    fr: 'Carte d’accessibilité & lieux',
  );
  String get contributeFromAccessiblePlace => _t(
    ar: 'ساهم',
    en: 'Contribute',
    fr: 'Contribuer',
  );
  String get createPostHintFromChosenPlace => _t(
    ar: 'صف تجربتك في هذا المكان…',
    en: 'Share your experience at this place…',
    fr: 'Partagez votre expérience sur ce lieu…',
  );
  String get ramps => _t(ar: 'منحدرات', en: 'Ramps', fr: 'Rampes');
  String get toilets => _t(ar: 'مراحيض', en: 'Toilets', fr: 'Toilettes');
  String get parking =>
      _t(ar: 'موقف سيارات', en: 'Parking', fr: 'Parking');
  String get placeOfInterest =>
      _t(ar: 'مكان الاهتمام', en: 'Place of interest', fr: "Lieu d'intérêt");
  String get verified => _t(ar: 'موثق', en: 'Verified', fr: 'Vérifié');
  String get wheelchairAccess =>
      _t(ar: 'وصول بالكرسي', en: 'Wheelchair access', fr: 'Accès Fauteuil');
  String get brailleMenus =>
      _t(ar: 'قوائم برايل', en: 'Braille menus', fr: 'Menus Braille');
  String get bookAssistance =>
      _t(ar: 'حجز المساعدة', en: 'Book assistance', fr: 'Réserver Assistance');
  String get reserveVehicle =>
      _t(ar: 'حجز مركبة', en: 'Reserve vehicle', fr: 'Réserver un véhicule');
  String distanceKm(String km) =>
      _t(ar: 'على بعد $km كم', en: '$km km away', fr: 'à $km km');
  String get seeAdaptedVehicles =>
      _t(ar: 'عرض المركبات المتكيفة', en: 'See adapted vehicles', fr: 'Voir les véhicules adaptés');

  // ─── Transport (demande) ───────────────────────────────────────────────────
  String get whereAreYouGoing =>
      _t(ar: 'أين تذهب؟', en: 'Where are you going?', fr: 'Où allez-vous ?');
  String get driversNearby =>
      _t(ar: 'سائقون قريبون', en: 'Drivers nearby', fr: 'Chauffeurs à proximité');
  String get filters => _t(ar: 'فلاتر', en: 'Filters', fr: 'Filtres');
  String get bookNow =>
      _t(ar: 'احجز الآن', en: 'Book now', fr: 'Réserver maintenant');
  String get ramp => _t(ar: 'منحدر', en: 'Ramp', fr: 'Rampe');
  String get assistance =>
      _t(ar: 'مساعدة', en: 'Assistance', fr: 'Assistance');
  String get guideDog =>
      _t(ar: 'كلب مرشد', en: 'Guide dog', fr: 'Chien Guide');
  String get minWait =>
      _t(ar: 'دقيقة انتظار', en: 'min wait', fr: "min d'attente");
  String get noDriverAvailable => _t(
    ar: 'لا يوجد سائق متاح حالياً.',
    en: 'No driver available at the moment.',
    fr: 'Aucun chauffeur disponible pour le moment.',
  );
  String get requestTransport =>
      _t(ar: 'طلب نقل', en: 'Request transport', fr: 'Demander un transport');
  String get requestTransportShort =>
      _t(ar: 'طلب', en: 'Request', fr: 'Demander');
  String get chooseTransportType =>
      _t(ar: 'نوع النقل', en: 'Transport type', fr: 'Type de transport');
  String get transportUrgency =>
      _t(ar: 'نقل عاجل', en: 'Emergency transport', fr: "Transport d'urgence");
  String get transportDaily =>
      _t(ar: 'نقل يومي', en: 'Daily transport', fr: 'Transport quotidien');
  String get departure =>
      _t(ar: 'مكان المغادرة', en: 'Departure place', fr: 'Lieu de départ');
  String get destination =>
      _t(ar: 'الوجهة', en: 'Destination', fr: 'Destination');
  String get creationRequestTitle =>
      _t(ar: 'إنشاء طلب', en: 'Create request', fr: 'Création de demande');
  String get typeOfAssistance =>
      _t(ar: 'نوع المساعدة', en: 'Type of assistance', fr: "Type d'assistance");
  String get selectAssistanceNeeded => _t(
    ar: 'اختر المساعدات اللازمة لرحلتك. يمكنك اختيار عدة خيارات.',
    en: 'Select the assistance you need for your trip. You can choose several.',
    fr: 'Sélectionnez les aides nécessaires pour votre trajet. Vous pouvez en choisir plusieurs.',
  );
  String get wheelchairAssistance =>
      _t(ar: 'كرسي متحرك', en: 'Wheelchair', fr: 'Fauteuil roulant');
  String get wheelchairSubtitle =>
      _t(ar: 'مركبة مكيفة TPMR', en: 'TPMR adapted vehicle', fr: 'Véhicule adapté TPMR');
  String get boardingHelp =>
      _t(ar: 'مساعدة الصعود', en: 'Boarding help', fr: "Aide à l'embarquement");
  String get boardingSubtitle =>
      _t(ar: 'دعم بدني أو إرشاد', en: 'Physical support or guidance', fr: 'Soutien physique ou guidage');
  String get visualImpairment =>
      _t(ar: 'ضعف البصر', en: 'Visual impairment', fr: 'Déficience visuelle');
  String get visualImpairmentSubtitle =>
      _t(ar: 'إعلانات صوتية وإرشاد', en: 'Voice announcements and guidance', fr: 'Annonces vocales et guidage');
  String get continueButton =>
      _t(ar: 'متابعة', en: 'Continue', fr: 'Continuer');
  String get scheduleDateAndTime =>
      _t(ar: 'التاريخ والوقت', en: 'Date & time', fr: 'Date et heure');
  String get requestNow =>
      _t(ar: 'الآن', en: 'Now', fr: 'Immédiat');
  String get scheduleLater =>
      _t(ar: 'الجدولة لاحقاً', en: 'Schedule', fr: 'Planifier');
  String get sendRequest =>
      _t(ar: 'إرسال الطلب', en: 'Send request', fr: 'Envoyer la demande');
  String get transportRequestSent => _t(
    ar: 'تم إرسال طلب النقل بنجاح.',
    en: 'Your transport request has been sent successfully.',
    fr: 'Votre demande de transport a bien été envoyée.',
  );
  String get urgencyBadge =>
      _t(ar: 'عاجل', en: 'Urgent', fr: 'Urgence');
  String get requestsTitle =>
      _t(ar: 'الطلبات', en: 'Requests', fr: 'Demandes');
  String get chooseVehicleForTrip =>
      _t(ar: 'اختر المركبة لهذه الرحلة', en: 'Choose vehicle for this trip', fr: 'Choisir le véhicule');
  String get selectTransportForRide => _t(
    ar: 'اختر وسيلة النقل لهذه الرحلة.',
    en: 'Select the transport means for this trip.',
    fr: 'Sélectionnez le moyen de transport pour cette course.',
  );
  String get noVehicleOption =>
      _t(ar: 'بدون مركبة', en: 'No vehicle', fr: 'Sans véhicule');
  String get pedestrianAccompagnement =>
      _t(ar: 'مرافقة سيراً على الأقدام', en: 'Pedestrian accompaniment', fr: 'Accompagnement piéton');
  String get confirmAcceptance =>
      _t(ar: 'تأكيد القبول', en: 'Confirm acceptance', fr: "Confirmer l'acceptation");
  String timeAgoMinutes(int minutes) =>
      _t(ar: 'منذ $minutes د', en: '${minutes}m ago', fr: 'Il y a $minutes min');
  String timeAgoHours(int hours) =>
      _t(ar: 'منذ $hours س', en: '${hours}h ago', fr: 'Il y a $hours h');
  String get endTrip =>
      _t(ar: 'إنهاء الرحلة', en: 'End trip', fr: 'Terminer le trajet');
  String etaArrivalInMinutes(int minutes) => _t(
    ar: 'الوصول المتوقع خلال $minutes د',
    en: 'Estimated arrival in $minutes min',
    fr: 'Arrivée estimée dans $minutes min',
  );
  String get liveTracking =>
      _t(ar: 'التتبع المباشر', en: 'Live tracking', fr: 'Suivi en direct');
  String get optionalDurationOrArrival => _t(
    ar: 'المدة أو وقت الوصول (اختياري)',
    en: 'Duration or arrival time (optional)',
    fr: "Durée ou heure d'arrivée (optionnel)",
  );
  String get tripEnded =>
      _t(ar: 'تم إنهاء الرحلة', en: 'Trip ended', fr: 'Trajet terminé');
  String tripDurationMinutes(int n) =>
      _t(ar: '$n دقيقة', en: '$n min', fr: '$n min');
  String orderNumberDisplay(String shortId) =>
      _t(ar: 'طلب #$shortId', en: 'Order #$shortId', fr: 'Commande #$shortId');
  String get estimatedArrivalLabel =>
      _t(ar: 'الوصول المتوقع', en: 'Estimated arrival', fr: 'Arrivée estimée');
  String get participantsSection =>
      _t(ar: 'المشاركون', en: 'Participants', fr: 'Participants');
  String get climatised =>
      _t(ar: 'مكيّف', en: 'Air-conditioned', fr: 'Climatisé');
  String get enRoute =>
      _t(ar: 'في الطريق', en: 'En route', fr: 'En route');
  String get arrivedAtPickupLabel => _t(
        ar: 'وصلت إلى نقطة الانطلاق',
        en: 'Arrived at pickup',
        fr: 'Arrivé au point de départ',
      );
  String get startRideToDestinationLabel => _t(
        ar: 'بدء التوجه إلى الوجهة',
        en: 'Start trip to destination',
        fr: 'Trajet en cours vers la destination',
      );
  String get cancelTripAction =>
      _t(ar: 'إلغاء الطلب', en: 'Cancel trip', fr: 'Annuler la course');
  String get cancelReasonOptionalHint => _t(
        ar: 'سبب الإلغاء (اختياري)',
        en: 'Cancellation reason (optional)',
        fr: "Motif d'annulation (optionnel)",
      );
  String estimatedPriceTnd(double v) => _t(
        ar: 'تقدير السعر: ${v.toStringAsFixed(2)} د.ت',
        en: 'Estimated fare: ${v.toStringAsFixed(2)} TND',
        fr: 'Prix estimé : ${v.toStringAsFixed(2)} TND',
      );
  String finalPriceTnd(double v) => _t(
        ar: 'السعر النهائي: ${v.toStringAsFixed(2)} د.ت',
        en: 'Final fare: ${v.toStringAsFixed(2)} TND',
        fr: 'Prix final : ${v.toStringAsFixed(2)} TND',
      );
  String get reviewAlreadyExistsError => _t(
        ar: 'تم تقييم هذا الطلب مسبقاً',
        en: 'This trip has already been reviewed',
        fr: 'Ce trajet a déjà été évalué',
      );

  // ─── Localisation ──────────────────────────────────────────────────────────
  String get currentLocation =>
      _t(ar: 'موقعي الحالي', en: 'My location', fr: 'Ma position');
  String get myCurrentLocation =>
      _t(ar: 'موقعي الحالي', en: 'My current location', fr: 'Ma position actuelle');
  String get enterDepartureAddress =>
      _t(ar: 'أدخل عنوان المغادرة...', en: 'Enter departure address...', fr: "Entrez l'adresse de départ...");
  String get calculatingRoute => _t(
    ar: 'جاري حساب المسار...',
    en: 'Calculating route...',
    fr: "Calcul de l'itinéraire...",
  );
  String get usedProfileLocationInsteadOfGps => _t(
    ar: 'تم استخدام موقع ملفك الشخصي (تونس) لأن موقع الجهاز خارج تونس.',
    en: 'Using your profile location (Tunisia) because device GPS is outside Tunisia.',
    fr: 'Position du profil (Tunisie) utilisée : le GPS indique un point hors Tunisie.',
  );
  String get usedSavedCoordinatesWhenGpsUnavailable => _t(
    ar: 'تم استخدام آخر موقع محفوظ في ملفك لأن GPS غير متاح.',
    en: 'Using your saved profile coordinates because GPS is unavailable.',
    fr: 'Coordonnées enregistrées sur votre profil utilisées (GPS indisponible ou trop lent).',
  );

  // ─── Historique ────────────────────────────────────────────────────────────
  String get tripHistory =>
      _t(ar: 'سجل التنقلات', en: 'Trip history', fr: 'Historique des déplacements');
  String get tripHistoryTitle =>
      _t(ar: 'سجل الرحلات', en: 'Trip history', fr: 'Historique des trajets');
  String get filterAll => _t(ar: 'الكل', en: 'All', fr: 'Tous');
  String get filterCompleted =>
      _t(ar: 'منتهية', en: 'Completed', fr: 'Terminés');
  String get filterCancelled =>
      _t(ar: 'ملغاة', en: 'Cancelled', fr: 'Annulés');
  String get sectionToday =>
      _t(ar: 'اليوم', en: 'TODAY', fr: "AUJOURD'HUI");
  String get sectionYesterday =>
      _t(ar: 'أمس', en: 'YESTERDAY', fr: 'HIER');
  String get detailsLink =>
      _t(ar: 'التفاصيل', en: 'Details', fr: 'Détails');
  String get detailsLinkWithArrow =>
      _t(ar: '< التفاصيل', en: '< Details', fr: '< Détails');
  String tripNumberDisplay(String shortId) =>
      _t(ar: 'رحلة #$shortId', en: 'Trip #$shortId', fr: 'N° Trajet: #$shortId');
  String get tripHistoryDescription =>
      _t(ar: 'رحلات مع مركبة وسائق', en: 'Trips made with vehicle and driver', fr: 'Trajets effectués avec véhicule et chauffeur');
  String get noTripHistory =>
      _t(ar: 'لا توجد تنقلات سابقة', en: 'No trips recorded', fr: 'Aucun déplacement enregistré');
  String get driver => _t(ar: 'السائق', en: 'Driver', fr: 'Chauffeur');
  String get vehicleLabel =>
      _t(ar: 'المركبة', en: 'Vehicle', fr: 'Véhicule');
  String get tripDetails =>
      _t(ar: 'تفاصيل الرحلة', en: 'Trip details', fr: 'Détails du trajet');
  String get shareTripTitle =>
      _t(ar: 'مشاركة التتبع', en: 'Share live tracking', fr: 'Partager le suivi');
  String get shareTripHint => _t(
        ar: 'أرسل الرمز للمقرب لفتح الخريطة بدون تسجيل الدخول.',
        en: 'Send this token so a relative can open the map without logging in.',
        fr: 'Envoyez ce token à un proche pour qu’il suive le trajet (sans connexion).',
      );
  String get copyToken =>
      _t(ar: 'نسخ الرمز', en: 'Copy token', fr: 'Copier le token');
  String get openGuestSuivi =>
      _t(ar: 'فتح المتابعة', en: 'Open tracking', fr: 'Ouvrir le suivi');
  String get copiedToClipboard =>
      _t(ar: 'تم النسخ', en: 'Copied', fr: 'Copié dans le presse-papiers');
  String get tripMotifLabel =>
      _t(ar: 'سبب التنقل', en: 'Trip purpose', fr: 'Motif du trajet');
  String get medicalPriorityLabel => _t(
        ar: 'أولوية طبية',
        en: 'Medical priority',
        fr: 'Priorité médicale',
      );
  String get motifMedical =>
      _t(ar: 'طبي', en: 'Medical', fr: 'Médical');
  String get motifAdministratif =>
      _t(ar: 'إداري', en: 'Administrative', fr: 'Administratif');
  String get motifQuotidienMotif =>
      _t(ar: 'يومي', en: 'Daily', fr: 'Quotidien');
  String get motifLoisir =>
      _t(ar: 'ترفيه', en: 'Leisure', fr: 'Loisir');
  String get motifNone =>
      _t(ar: 'بدون', en: 'None', fr: 'Non précisé');
  String get statusCompleted =>
      _t(ar: 'منتهي', en: 'Completed', fr: 'Terminé');
  String get statusCancelled =>
      _t(ar: 'ملغى', en: 'Cancelled', fr: 'Annulé');
  String get sectionRecent =>
      _t(ar: 'الأخير', en: 'RECENT', fr: 'RÉCENT');
  String get myRequestsTitle =>
      _t(ar: 'طلباتي', en: 'My Requests', fr: 'Mes Demandes');
  String get tabAll => _t(ar: 'الكل', en: 'All', fr: 'Tout');
  String get tabPending =>
      _t(ar: 'قيد الانتظار', en: 'Pending', fr: 'En attente');
  String get tabCompleted =>
      _t(ar: 'منتهية', en: 'Completed', fr: 'Terminées');
  String get requester =>
      _t(ar: 'طالب', en: 'Requester', fr: 'Demandeur');
  String get viewDetailsLink =>
      _t(ar: 'عرض التفاصيل >', en: 'View details >', fr: 'Voir détails >');
  String get departurePrefix =>
      _t(ar: 'انطلاق: ', en: 'Departure: ', fr: 'Départ: ');
  String durationLabel(int minutes) =>
      _t(ar: 'المدة: $minutes د', en: 'Duration: $minutes min', fr: 'Durée: $minutes min');
  String get labelDeparture =>
      _t(ar: 'انطلاق', en: 'DEPARTURE', fr: 'DÉPART');
  String get labelDestination =>
      _t(ar: 'الوجهة', en: 'DESTINATION', fr: 'DESTINATION');
  String get labelArrival =>
      _t(ar: 'وصول', en: 'ARRIVAL', fr: 'ARRIVÉE');

  // ─── Évaluation ────────────────────────────────────────────────────────────
  String get evaluateTrip =>
      _t(ar: 'تقييم الرحلة', en: 'Rate this trip', fr: 'Évaluer ce trajet');
  String get yourReview =>
      _t(ar: 'تقييمك', en: 'Your review', fr: 'Votre avis');
  String get rating => _t(ar: 'التقييم', en: 'Rating', fr: 'Note');
  String get optionalComment =>
      _t(ar: 'تعليق (اختياري)', en: 'Comment (optional)', fr: 'Commentaire (optionnel)');
  String get submitReview =>
      _t(ar: 'إرسال التقييم', en: 'Submit review', fr: "Envoyer l'évaluation");
  String get reviewSent => _t(
    ar: 'شكراً، تم إرسال تقييمك.',
    en: 'Thank you, your review has been recorded.',
    fr: 'Merci, votre évaluation a bien été enregistrée.',
  );
  String get alreadyReviewed =>
      _t(ar: 'تم التقييم', en: 'Already reviewed', fr: 'Déjà évalué');
  String get serviceEvaluationTitle =>
      _t(ar: 'تقييم الخدمة', en: 'Service evaluation', fr: 'Évaluation du service');
  String serviceEvaluationPrompt(String driverName) => _t(
    ar: 'كيف كانت رحلتك مع $driverName؟ رأيك يساعد في تحسين التنقل الشامل للجميع.',
    en: 'How was your trip with $driverName? Your feedback helps improve inclusive mobility for all.',
    fr: "Comment s'est passé votre trajet avec $driverName ? Votre avis aide à améliorer la mobilité inclusive pour tous.",
  );
  String get reviewSubmittedTag =>
      _t(ar: 'مُرسل', en: 'SUBMITTED', fr: 'SOUMIS');
  String get evaluationSubtitle =>
      _t(ar: 'رأيك يساعدنا على تحسين معاك', en: 'Your review helps us improve Ma3ak', fr: 'Votre avis nous aide à améliorer Ma3ak');
  String get commentPlaceholder =>
      _t(ar: 'شاركنا تجربتك...', en: 'Share your experience with us...', fr: 'Partagez votre expérience avec nous...');
  String get cancelLabel =>
      _t(ar: 'إلغاء', en: 'Cancel', fr: 'Annuler');
  String get mobilityInclusiveFooter =>
      _t(ar: 'تنقل شامل • معاك', en: 'INCLUSIVE MOBILITY • MA3AK', fr: 'MOBILITÉ INCLUSIVE • MA3AK');
  String ratingLabel(int note) {
    if (note < 1 || note > 5) return '';
    const fr = ['', 'Très insuffisant', 'Insuffisant', 'Correct', 'Très bien', 'Parfait'];
    const ar = ['', 'غير كافٍ جداً', 'غير كافٍ', 'مقبول', 'جيد جداً', 'ممتاز'];
    const en = ['', 'Very poor', 'Poor', 'Fair', 'Good', 'Excellent'];
    if (isAr) return ar[note];
    if (isEn) return en[note];
    return fr[note];
  }
  String get tripIdLabel =>
      _t(ar: 'رحلة', en: 'Trip', fr: 'Trajet');
  String get paidViaWallet =>
      _t(ar: 'مدفوع عبر المحفظة', en: 'Paid via Wallet', fr: 'Payé via Portefeuille');

  // ─── Inscription & formulaires ───────────────────────────────────────────
  String get obstacleDetection =>
      _t(ar: 'كشف العوائق', en: 'Obstacle detection', fr: "Détection d'obstacles");
  String get obstacleNavHubTitle => _t(
        ar: 'الكشف والملاحة',
        en: 'Detection & navigation',
        fr: 'Détection & navigation',
      );
  String get obstacleNavOptionSolo => _t(
        ar: 'كشف العوائق فقط',
        en: 'Obstacle detection only',
        fr: "Détection d'obstacles seule",
      );
  String get obstacleNavOptionSoloSubtitle => _t(
        ar: 'تنبيهات صوتية وتصوير متقدم (نموذج على الجهاز).',
        en: 'Voice alerts and on-device model (YOLO).',
        fr: 'Alertes vocales et modèle sur l’appareil (YOLO).',
      );
  String get obstacleNavOptionGuided => _t(
        ar: 'كشف العوائق + إرشاد ذكي',
        en: 'Obstacles + smart guidance',
        fr: 'Obstacles + guidage intelligent',
      );
  /// Libellé court pour grilles / actions rapides (évite le débordement).
  String get guidedObstacleNavShort => _t(
        ar: 'إرشاد + عوائق',
        en: 'Guidance + obstacles',
        fr: 'Guidage + obstacles',
      );
  /// Grille d’accueil « Lieux & milieux » (libellé court).
  String get airWritingHomeLabel => _t(
        ar: 'كتابة هوائية',
        en: 'Air writing',
        fr: 'Écriture aérienne',
      );
  String get obstacleNavOptionGuidedSubtitle => _t(
        ar: 'وجهة، مسار من الخادم، سهم على الكاميرا واكتشاف بالذكاء الاصطناعي.',
        en: 'Destination, server route, on-camera arrow and ML detection.',
        fr: 'Destination, itinéraire API, flèche sur la caméra et détection IA.',
      );
  String get guidedArTitle => _t(
        ar: 'ملاحة معززة بالواقع',
        en: 'Augmented guidance',
        fr: 'Navigation & guidage intelligent',
      );
  String get guidedArIntro => _t(
        ar: 'اختر وجهتك: يُحسب المسار من خادم معاك، ثم تظهر الكاميرا مع سهم الاتجاه وتنبيهات العوائق.',
        en: 'Pick a destination: Ma3ak server computes the route, then the camera shows a direction arrow and obstacle alerts.',
        fr: 'Choisissez une destination : l’itinéraire est calculé par l’API Ma3ak, puis la caméra affiche une flèche et la détection d’obstacles.',
      );
  String get guidedArDestinationLabel =>
      _t(ar: 'الوجهة', en: 'Destination', fr: 'Destination');
  String get guidedArDestinationHint => _t(
        ar: 'ابحث عن عنوان في تونس',
        en: 'Search for an address in Tunisia',
        fr: 'Rechercher une adresse en Tunisie',
      );
  String get guidedArSelectDestination => _t(
        ar: 'يرجى اختيار وجهة من القائمة.',
        en: 'Please select a destination from the list.',
        fr: 'Veuillez choisir une destination dans la liste.',
      );
  String get guidedArStartButton =>
      _t(ar: 'ابدأ الملاحة', en: 'Start guidance', fr: 'Démarrer le guidage');
  String get guidedArCalculatingRoute => _t(
        ar: 'جاري حساب المسار…',
        en: 'Calculating route…',
        fr: 'Calcul de l’itinéraire…',
      );
  String get guidedArEmptyRoute => _t(
        ar: 'مسار فارغ. جرّب وجهة أخرى.',
        en: 'Empty route. Try another destination.',
        fr: 'Itinéraire vide. Essayez une autre destination.',
      );
  String get guidedArGpsError => _t(
        ar: 'تعذر تحديد الموقع. فعّل GPS أو حدّث موقعك في الملف الشخصي.',
        en: 'Could not get location. Enable GPS or update your profile location.',
        fr: 'Impossible de vous localiser. Activez le GPS ou renseignez votre position dans le profil.',
      );
  String get guidedArNoCamera => _t(
        ar: 'لا توجد كاميرا.',
        en: 'No camera available.',
        fr: 'Aucune caméra disponible.',
      );
  String get guidedArCameraError => _t(
        ar: 'خطأ في الكاميرا',
        en: 'Camera error',
        fr: 'Erreur caméra',
      );
  String get guidedArModelMissing => _t(
        ar: 'النموذج غير موجود. أضف m3ak_yolov8.tflite في assets/models/ (راجع README).',
        en: 'Model missing. Add m3ak_yolov8.tflite under assets/models/ (see README).',
        fr: 'Modèle manquant. Ajoutez m3ak_yolov8.tflite dans assets/models/ (voir README).',
      );
  String get guidedArCompassHint => _t(
        ar: 'وجّه أعلى الهاتف نحو الشمال لقراءة أفضل للاتجاه.',
        en: 'Point the top of the phone toward north for a clearer direction.',
        fr: 'Orientez le haut du téléphone vers le nord pour une meilleure lecture de la direction.',
      );
  String guidedArRemainingDistance(String d) => _t(
        ar: 'متبقي حوالي $d',
        en: 'About $d remaining',
        fr: 'Environ $d restants',
      );
  String get lastName =>
      _t(ar: 'اسم العائلة', en: 'Last name', fr: 'Nom de famille');
  String get firstName =>
      _t(ar: 'الاسم الأول', en: 'First name', fr: 'Prénom');
  String get specificNeedsOptionalLabel => _t(
    ar: 'احتياجات خاصة (اختياري)',
    en: 'Specific needs (optional)',
    fr: 'Besoins spécifiques (optionnel)',
  );
  String get assistanceAnimal =>
      _t(ar: 'حيوان مساعد', en: 'Assistance animal', fr: "Animal d'assistance");
  String get passwordAndRoleTitle =>
      _t(ar: 'كلمة المرور والدور', en: 'Password & role', fr: 'Mot de passe et rôle');
  String get languageScreenTitle =>
      _t(ar: 'اللغة', en: 'Language', fr: 'Langue');
  String get preferredLanguageOptional =>
      _t(ar: 'اللغة المفضلة (اختياري)', en: 'Preferred language (optional)', fr: 'Langue préférée (optionnel)');
  String get englishLanguage => _t(ar: 'English', en: 'English', fr: 'English');
  String get companionTypeAndSpecialization => _t(
    ar: 'المرافق: النوع والتخصص',
    en: 'Companion: type & specialisation',
    fr: 'Accompagnant : type et spécialisation',
  );
  String get finalizeTitle =>
      _t(ar: 'إنهاء', en: 'Finalisation', fr: 'Finalisation');
  String get verifyThenSignUp => _t(
    ar: 'تحقق من معلوماتك ثم اضغط على التسجيل.',
    en: 'Check your information then tap Sign up.',
    fr: "Vérifiez vos informations puis cliquez sur S'inscrire.",
  );
  String get specializationOptional =>
      _t(ar: 'التخصص (اختياري)', en: 'Specialisation (optional)', fr: 'Spécialisation (optionnel)');
  String get hintLastNameExample =>
      _t(ar: 'مثال: بن علي', en: 'e.g. Smith', fr: 'Ex: Ben Ali');
  String get hintFirstNameExample =>
      _t(ar: 'مثال: أحمد', en: 'e.g. John', fr: 'Ex: Ahmed');
  String get hintSpecialisation =>
      _t(ar: 'مثال: طبي', en: 'e.g. Medical', fr: 'Ex: Médical');
  String get chooseDateAndTime =>
      _t(ar: 'الرجاء اختيار التاريخ والوقت.', en: 'Please choose a date and time.', fr: 'Veuillez choisir une date et une heure.');
  String get reverseGeocodeError => _t(
    ar: 'تعذر جلب العنوان لهذه النقطة.',
    en: 'Could not get the address for this point.',
    fr: "Impossible de récupérer l'adresse pour ce point.",
  );
  String get emailRequiredRegister =>
      _t(ar: 'البريد الإلكتروني إلزامي.', en: 'Email address is required.', fr: "L'adresse e-mail est obligatoire.");
  String get phoneRequiredRegister =>
      _t(ar: 'رقم الهاتف إلزامي.', en: 'Phone number is required.', fr: 'Le téléphone est obligatoire.');
  String get fieldRequiredShort =>
      _t(ar: 'إلزامي', en: 'Required', fr: 'Obligatoire');
  String get invalidEmailShort =>
      _t(ar: 'بريد غير صالح', en: 'Invalid email', fr: 'Email invalide');
  String get passwordMinChars =>
      _t(ar: '6 أحرف على الأقل', en: 'At least 6 characters', fr: 'Min. 6 caractères');
  String get passwordsDoNotMatch =>
      _t(ar: 'كلمتا المرور غير متطابقتين', en: 'Passwords do not match', fr: 'Les mots de passe ne correspondent pas');
  String get confirmPasswordHint =>
      _t(ar: 'أكد كلمة المرور', en: 'Confirm your password', fr: 'Confirmez votre mot de passe');
  String get emailAddressLabel =>
      _t(ar: 'البريد الإلكتروني *', en: 'Email address *', fr: 'Adresse e-mail *');
  String get phoneNumberLabel =>
      _t(ar: 'رقم الهاتف *', en: 'Phone number *', fr: 'Numéro de téléphone *');
  String get passwordLabel =>
      _t(ar: 'كلمة المرور *', en: 'Password *', fr: 'Mot de passe *');
  String get confirmPasswordLabel =>
      _t(ar: 'تأكيد كلمة المرور *', en: 'Confirm password *', fr: 'Confirmer le mot de passe *');
  String get noRequestsYet =>
      _t(ar: 'لا توجد طلبات', en: 'No requests', fr: 'Aucune demande');
  String get accessibilityOptions =>
      _t(ar: 'خيارات إمكانية الوصول', en: 'Accessibility options', fr: "Options d'accessibilité");
  String get voiceInput =>
      _t(ar: 'إدخال صوتي', en: 'Voice input', fr: 'Saisie vocale');
  String get placeholderSoon =>
      _t(ar: 'قريباً', en: 'Coming soon', fr: 'Bientôt disponible');


  // ─── Communauté (module intégré) ───────────────────────────────────────
  // Communauté & Lieux
  String get community => isAr ? 'المجتمع' : 'Communauté';
  String get communityAiEntryTooltip => _t(
    ar: 'مساعد ذكي للنشر والمساعدة',
    en: 'Smart assistant for posts and help',
    fr: 'Assistant pour publier ou demander de l’aide',
  );
  /// Titre court (AppBar / tuile accueil) — même écran que `/community-ai-entry`.
  String get communityAssistantEntryTitle => _t(
    ar: 'مساعد ذكي',
    en: 'Smart assistant',
    fr: 'Assistant intelligent',
  );
  /// Liste des conversations (`/messages`).
  String get messagerieInboxTitle => _t(
    ar: 'الرسائل',
    en: 'Messages',
    fr: 'Messagerie',
  );
  String get messagerieInboxEmpty => _t(
    ar: 'لا توجد محادثات بعد.',
    en: 'No conversations yet.',
    fr: 'Aucune conversation pour le moment.',
  );
  String get messagerieGoToPosts => _t(
    ar: 'المنشورات',
    en: 'Community posts',
    fr: 'Voir les publications',
  );
  /// Barre d’app du live (`/community-live`).
  String get liveCommunityAppBarTitle => _t(
    ar: 'بث مباشر',
    en: 'Community live',
    fr: 'Live communauté',
  );
  String get liveWriteMessageHint => _t(
    ar: 'اكتب رسالة للبث…',
    en: 'Write a live message…',
    fr: 'Écrire un message live…',
  );
  String get chatDiscussionTitle => _t(
    ar: 'محادثة',
    en: 'Discussion',
    fr: 'Discussion',
  );
  String get chatReadConversation => _t(
    ar: 'قراءة المحادثة',
    en: 'Read conversation',
    fr: 'Lire la conversation',
  );
  String get chatSpeakToReply => _t(
    ar: 'تحدث للرد',
    en: 'Speak to reply',
    fr: 'Parler pour répondre',
  );
  String get chatAddPhoto => _t(
    ar: 'إضافة صورة',
    en: 'Add photo',
    fr: 'Ajouter photo',
  );
  String get chatSendLocation => _t(
    ar: 'إرسال الموقع',
    en: 'Send location',
    fr: 'Envoyer localisation',
  );
  String get chatWriteMessageHint => _t(
    ar: 'اكتب رسالة…',
    en: 'Write a message…',
    fr: 'Écrire un message…',
  );
  String get cancel => _t(ar: 'إلغاء', en: 'Cancel', fr: 'Annuler');
  /// Accueil → même écran que la carte accessibilité (onglets lieux, posts, aide).
  String get communityHubHomeCardSubtitle => isAr
      ? 'منشورات، طلبات المساعدة، أماكن مهيأة'
      : 'Publications, demandes d’aide et lieux accessibles.';
  String get communityPlaces => isAr ? 'الأماكن' : 'Lieux accessibles';
  String get submitNewPlace => isAr ? 'إضافة مكان جديد' : 'Soumettre un lieu';
  String get allCategories => isAr ? 'الكل' : 'Toutes';
  String get noPlacesFound => isAr ? 'لم يتم العثور على أماكن' : 'Aucun lieu trouvé';
  String get tryDifferentFilters =>
      isAr ? 'جرب فلاتر مختلفة' : 'Essayez des filtres différents';
  String get errorLoadingPlaces =>
      isAr ? 'خطأ في تحميل الأماكن' : 'Erreur lors du chargement des lieux';
  String get retry => isAr ? 'إعادة المحاولة' : 'Réessayer';
  String get approved => isAr ? 'موافق عليه' : 'Approuvé';
  String get description => isAr ? 'الوصف' : 'Description';
  String get openingHours => isAr ? 'ساعات العمل' : 'Horaires';
  String get amenities => isAr ? 'المرافق' : 'Équipements';
  String get submittedBy => isAr ? 'تم الإرسال بواسطة' : 'Soumis par';
  String get errorLoadingPlace =>
      isAr ? 'خطأ في تحميل المكان' : 'Erreur lors du chargement du lieu';
  String get getDirections =>
      isAr ? 'الاتجاهات' : 'Itinéraire';
  String get reportIssue =>
      isAr ? 'الإبلاغ عن مشكلة' : 'Signaler un problème';
  String get sharePlace =>
      isAr ? 'مشاركة المكان' : 'Partager ce lieu';
  String get accessibilityScoreShort =>
      isAr ? 'الوصول' : 'Accès';
  String get noDescriptionForPlace =>
      isAr ? 'لا يوجد وصف لهذا المكان.' : 'Aucune description disponible pour ce lieu.';
  String get couldNotOpenMaps =>
      isAr ? 'تعذر فتح الخرائط' : 'Impossible d’ouvrir l’application cartes.';
  String get coordinatesUnavailable =>
      isAr ? 'إحداثيات غير متاحة لهذا المكان' : 'Coordonnées indisponibles pour ce lieu.';
  String get linkCopied =>
      isAr ? 'تم النسخ' : 'Copié dans le presse-papiers';
  String get reportDraftAssistPrefix =>
      isAr ? '[مساعدة الإدخال] ' : '[Saisie assistée] ';
  String reportLocationDraftTitle(String nom, String adresse) => isAr
      ? 'مشكلة وصول — $nom\n$adresse\n'
      : 'Signalement accessibilité — $nom\n$adresse\n';
  String get goBack => isAr ? 'رجوع' : 'Retour';
  String get placeName => isAr ? 'اسم المكان' : 'Nom du lieu';
  String get placeNameHint => isAr ? 'مثال: Pharmacie de l\'Espoir' : 'ex. Pharmacie de l\'Espoir';
  String get category => isAr ? 'الفئة' : 'Catégorie';
  String get address => isAr ? 'العنوان' : 'Adresse';
  String get addressHint => isAr ? 'العنوان الكامل' : 'Adresse complète';
  String get city => isAr ? 'المدينة' : 'Ville';
  String get cityHint => isAr ? 'مثال: Tunis' : 'ex. Tunis';
  String get optional => isAr ? 'اختياري' : 'Optionnel';
  String get descriptionHint =>
      isAr ? 'وصف تفصيلي للمكان' : 'Description détaillée du lieu';
  String get images => isAr ? 'الصور' : 'Images';
  String get addImages => isAr ? 'إضافة صور' : 'Ajouter des images';
  String get fromGallery => isAr ? 'من المعرض' : 'Depuis la galerie';
  String get fromCamera => isAr ? 'من الكاميرا' : 'Depuis l\'appareil photo';
  String get submit => isAr ? 'إرسال' : 'Soumettre';
  String get submitLocationDescription =>
      isAr
          ? 'Partagez un lieu accessible pour aider la communauté'
          : 'Partagez un lieu accessible pour aider la communauté';
  String get submitLocationNote =>
      isAr
          ? 'Votre soumission sera examinée par un modérateur avant publication.'
          : 'Votre soumission sera examinée par un modérateur avant publication.';
  String get locationSubmittedSuccess =>
      isAr
          ? 'Lieu soumis avec succès ! Il sera examiné par un modérateur.'
          : 'Lieu soumis avec succès ! Il sera examiné par un modérateur.';
  String get fieldRequired => isAr ? 'Ce champ est requis' : 'Ce champ est requis';
  String get anonymousUser => isAr ? 'Utilisateur anonyme' : 'Utilisateur anonyme';
  String get submittedOn => isAr ? 'Soumis le' : 'Soumis le';
  String get phoneNumberHint => isAr ? 'ex. +216 12 345 678' : 'ex. +216 12 345 678';
  String get openingHoursHint => isAr ? 'ex. Lun-Ven: 9h-18h' : 'ex. Lun-Ven: 9h-18h';
  String get invalidEmailOrPhone => isAr ? 'Email ou téléphone invalide' : 'Email ou téléphone invalide';
  String get invalidPassword => isAr ? 'Mot de passe invalide' : 'Mot de passe invalide';
  String get serverError => isAr ? 'Erreur serveur' : 'Erreur serveur';
  String get invalidData => isAr ? 'Données invalides' : 'Données invalides';
  String get emailAlreadyExists => isAr ? 'Cet email existe déjà' : 'Cet email existe déjà';
  String get phoneAlreadyExists => isAr ? 'Ce numéro existe déjà' : 'Ce numéro existe déjà';
  String get invalidCredentials => isAr ? 'Identifiants invalides' : 'Identifiants invalides';
  String get connectionError => isAr ? 'Erreur de connexion' : 'Erreur de connexion';

  // Posts & Community
  String get communityPosts => isAr ? 'منشورات المجتمع' : 'Publications de la communauté';
  /// Module communauté — où trouver FALC + analyse photo dans les posts.
  String get communityPostsAccessibilityTitle => isAr
      ? ''
      : '';
  String get communityPostsAccessibilityBody => isAr
      ? ''
      : '';
  String get createPost => isAr ? 'إنشاء منشور' : 'Créer un post';
  /// Intro : tous les profils peuvent publier (tactile, voix, tête, vibrations).
  String get postAccessibilityForAllTitle => isAr
      ? 'النشر متاح للجميع'
      : 'Publier : tous les handicaps';
  String get postAccessibilityForAllBody => isAr
      ? 'نموذج كبير وصور. الاهتزازات الثابتة من تبويب طلبات المساعدة.'
      : 'Grand formulaire et photos ci‑dessous. Tête & yeux et voix + vibrations : carte dédiée sur cet écran. Vibrations fixes (menu codé) : onglet Demandes d’aide. Le bouton + peut suivre un raccourci (Profil).';
  String get postAccessibilityModesTitle => isAr
      ? 'طرق بدون لوحة المفاتيح'
      : 'Modes sans tout saisir au clavier';
  String get postAccessibilityModesBody => isAr
      ? 'الرأس والصوت هنا؛ الاهتزازات الثابتة في طلبات المساعدة.'
      : 'Tête & yeux et voix + vibrations ici. Les vibrations fixes (sourd-aveugle) sont dans l’onglet Demandes d’aide.';
  /// Web : les boutons ne sont pas affichés (caméra / micro / vibrateur requis).
  String get postAccessibilityModesWebOnly => isAr
      ? 'الرأس والصوت والاهتزاز: متوفرة في تطبيق الهاتف فقط، وليس في المتصفح.'
      : 'Tête & yeux et voix + vibrations : disponibles dans l’app mobile (Android / iOS), pas dans le navigateur.';
  /// Carte en tête de l’onglet Demandes d’aide : vibrations codées uniquement.
  String get helpAccessibilityPublicationTitle => isAr
      ? 'اهتزازات ثابتة (من تبويب المساعدة)'
      : 'Vibrations fixes (Aides)';
  String get helpAccessibilityPublicationSubtitle => isAr
      ? 'قائمة باهتزازات قصيرة ثم تأكيد — نفس منشور المجتمع.'
      : 'Menu par impulsions puis confirmation (tap dos) — même publication communautaire.';
  /// Écran vibrations codées : rappel que ce n’est pas le seul mode « ajouter un post ».
  String get vibrationPostExplainerTitle => isAr
      ? 'ليس هذا كل خيارات النشر'
      : 'Pas seulement cet écran';
  String get vibrationPostExplainerBody => isAr
      ? 'هنا: طلب مساعدة بالموقع (٣ خيارات). للمنشور الكامل أو الكاميرا أو الصوت + اهتزاز:'
      : 'Ici : demande d’aide géolocalisée (3 choix par vibrations). Pour un post communautaire (texte, photos, type), ou tête & yeux / voix + vibrations, utilisez les boutons ci‑dessous.';
  String get vibrationPostOpenFullForm => isAr
      ? 'منشور كامل (نص + صور)'
      : 'Post complet (texte + photos)';

  // Création de post — flux inclusif (sections)
  String get postCreateSectionPublisher =>
      isAr ? 'من ينشر؟' : 'Qui publie ?';
  String get postCreateForSelf =>
      isAr ? 'لنفسي' : 'Pour moi-même';
  String get postCreateForSomeoneElse =>
      isAr ? 'لشخص آخر' : 'Pour une autre personne';
  String get postCreateSectionInputMode =>
      isAr ? 'طريقة الإدخال' : 'Mode de saisie';
  String get postCreateInputKeyboard => isAr ? 'لوحة المفاتيح' : 'Clavier';
  String get postCreateInputVoice => isAr ? 'صوت' : 'Voix';
  String get postCreateInputHeadEyes => isAr ? 'رأس وعينان' : 'Tête et yeux';
  String get postCreateInputVibration => isAr ? 'اهتزازات' : 'Vibrations';
  String get postCreateInputDeafBlind => isAr ? 'صمم-أعمى' : 'Sourd-aveugle';
  String get postCreateInputCaregiver => isAr ? 'مرافق' : 'Accompagnant';
  String get postCreateShortcutsHint => isAr
      ? 'مسارات مخصصة: تفتح شاشة ثم تعود هنا.'
      : 'Parcours dédiés : ouvre un écran puis revient ici.';
  String get postCreateSectionNature =>
      isAr ? 'طبيعة المنشور' : 'Nature du post';
  String get postCreateNatureSignalement =>
      isAr ? 'إبلاغ' : 'Signalement';
  String get postCreateNatureConseil =>
      isAr ? 'نصيحة' : 'Conseil';
  String get postCreateNatureTemoignage =>
      isAr ? 'شهادة' : 'Témoignage';
  String get postCreateNatureInformation =>
      isAr ? 'معلومات' : 'Information';
  String get postCreateNatureAlerte =>
      isAr ? 'تنبيه' : 'Alerte';
  String get postCreateSectionAudience =>
      isAr ? 'الجمهور المستهدف' : 'Public concerné';
  String get postCreateAudienceAll =>
      isAr ? 'الجميع' : 'Tous';
  String get postCreateAudienceMotor =>
      isAr ? 'إعاقة حركية' : 'Handicap moteur';
  String get postCreateAudienceVisual =>
      isAr ? 'إعاقة بصرية' : 'Handicap visuel';
  String get postCreateAudienceHearing =>
      isAr ? 'إعاقة سمعية' : 'Handicap auditif';
  String get postCreateAudienceCognitive =>
      isAr ? 'إعاقة معرفية' : 'Handicap cognitif';
  String get postCreateAudienceCaregiver =>
      isAr ? 'مرافق' : 'Accompagnant';
  String get postCreateSectionNeeds =>
      isAr ? 'احتياجات إمكانية الوصول' : 'Besoins d’accessibilité';
  String get postCreateSectionContent =>
      isAr ? 'المحتوى' : 'Contenu';
  String get postCreatePresetSuggestions =>
      isAr ? 'اقتراحات جاهزة' : 'Suggestions';
  String get postCreateSectionImages =>
      isAr ? 'صور' : 'Images';
  String get postCreateSectionLocation =>
      isAr ? 'مشاركة الموقع' : 'Partage de position';
  String get postCreateLocationNone =>
      isAr ? 'بدون' : 'Aucune';
  String get postCreateLocationApproximate =>
      isAr ? 'تقريبي' : 'Approximatif';
  String get postCreateLocationPrecise =>
      isAr ? 'دقيق' : 'Précis';
  String get postCreateSectionPreview =>
      isAr ? 'معاينة' : 'Aperçu avant publication';
  String get postCreatePresetThanks =>
      isAr ? 'شكراً للمجتمع على المساعدة.' : 'Merci à la communauté pour l’aide.';
  String get postCreatePresetObstacle =>
      isAr ? 'أبلغ عن عقبة في هذا المكان.' : 'Je signale un obstacle à cet endroit.';
  String get postCreatePresetInfo =>
      isAr ? 'معلومة قد تفيد الآخرين.' : 'Une information utile pour les autres.';
  String get postCreatePresetNeedHelp =>
      isAr ? 'أحتاج نصيحة للتنقل هنا.' : 'J’ai besoin d’un conseil pour me déplacer ici.';

  /// Interrupteur — libellés explicites (même charge utile API : isForAnotherPerson, inputMode).
  String get postCreateSwitchForSelf =>
      isAr ? 'أنشر عن نفسي' : 'Je publie pour moi';
  String get postCreateSwitchForOther =>
      isAr ? 'أنشر عن شخص آخر' : 'Je publie pour quelqu’un d’autre';
  String get postCreatePublisherSwitchTitle =>
      isAr ? 'لمن هذا المنشور؟' : 'Pour qui publiez-vous ?';
  String get postCreatePublisherSubtitleSelf =>
      isAr
          ? 'أنت تنشر تجربتك أو طلبك باسمك.'
          : 'Vous publiez votre expérience ou votre demande en votre nom.';
  String get postCreatePublisherSubtitleOther =>
      isAr
          ? 'تنشر نيابة عن شخص آخر؛ اكتب بوضوح ليفهم المجتمع السياق.'
          : 'Vous publiez pour une autre personne : rédigez clairement pour que la communauté comprenne.';
  String get postCreateCaregiverPostIntro =>
      isAr
          ? 'أنشر نيابة عن شخص آخر (بموافقته عند الإمكان).'
          : 'Je publie pour une autre personne (avec son accord si possible).';
  /// Aide sous le champ texte en mode accompagnant — reste lisible pour tout le monde.
  String get postCreateContentHintCaregiver =>
      isAr
          ? 'صف الوضع والمكان وما تحتاجه الشخص من المجتمع بوضوح.'
          : 'Décrivez la situation, le lieu et ce que la personne attend de la communauté.';
  String get postCreateSemanticSwitchHint =>
      isAr
          ? 'التبديل بين النشر لنفسك أو لشخص آخر.'
          : 'Basculer entre publier pour vous-même ou pour une autre personne.';
  /// Ligne ajoutée à l’aperçu quand le message est relayé.
  String get postCreatePreviewCaregiverNote =>
      isAr
          ? 'هذا المنشور يُنشر من طرف مرافق أو قريب باسم الشخص المعني.'
          : 'Ce message est publié par un accompagnant ou un proche au nom de la personne concernée.';

  String get postCreateSectionNeedsHint =>
      isAr
          ? 'اختر ما يساعد المجتمع على مساعدتك أو تكييف الردود.'
          : 'Indiquez ce qui aide la communauté à vous répondre ou adapter les réponses.';
  String get postCreateNeedAudioHint =>
      isAr
          ? 'مثال: إرشادات صوتية أو وصف شفهي للمسار.'
          : 'Ex. consignes vocales, description orale du chemin.';
  String get postCreateNeedVisualHint =>
      isAr
          ? 'مثال: لافتات واضحة أو تباين ألوان أو إشارات بصرية.'
          : 'Ex. signalétique lisible, contraste, repères visuels.';
  String get postCreateNeedPhysicalHint =>
      isAr
          ? 'مثال: مساعدة للمشي أو رفع أو تجاوز عقبة.'
          : 'Ex. aide pour marcher, franchir un obstacle, se déplacer.';
  String get postCreateNeedSimpleLangHint =>
      isAr
          ? 'مثال: جمل قصيرة وكلمات سهلة.'
          : 'Ex. phrases courtes et mots simples.';

  String get postCreatePresetAppliedSnack =>
      isAr ? 'تم تطبيق النموذج.' : 'Suggestion appliquée.';
  String get postCreatePresetTapHint =>
      isAr
          ? 'اضغط على اقتراح لملء النص وتعديل نوع المنشور والجمهور والاحتياجات.'
          : 'Appuyez sur une suggestion pour remplir le texte et ajuster le type, le public et les besoins.';

  // Libellés courts — puces de suggestion (création de post)
  String get postCreatePresetChipBlocked =>
      isAr ? 'أنا محبوس' : 'Je suis bloqué';
  String get postCreatePresetChipDifficultAccess =>
      isAr ? 'وصول صعب' : 'Accès difficile';
  String get postCreatePresetChipInaccessibleEntrance =>
      isAr ? 'مدخل غير متاح' : 'Entrée inaccessible';
  String get postCreatePresetChipMissingRamp =>
      isAr ? 'بدون منحدر' : 'Rampe absente';
  String get postCreatePresetChipStairsNoHelp =>
      isAr ? 'درج بلا مساعدة' : 'Escaliers sans aide';
  String get postCreatePresetChipNeedOrientation =>
      isAr ? 'أحتاج توجيهاً' : 'J’ai besoin d’orientation';
  String get postCreatePresetChipUsefulAdvice =>
      isAr ? 'نصيحة مفيدة' : 'Conseil utile';
  String get postCreatePresetChipPersonalTestimony =>
      isAr ? 'شهادة شخصية' : 'Témoignage personnel';

  /// Textes générés pour le champ contenu (public communautaire).
  String get postCreatePresetBodyBlocked =>
      isAr
          ? 'أنا محبوس في هذا المكان وأحتاج مساعدة للتحرك أو للخروج. إن أمكن، أشيروا إلى مسار يمكن الوصول إليه.'
          : 'Je suis bloqué·e dans ce lieu et j’ai besoin d’aide pour me déplacer ou sortir. Si vous pouvez, indiquez un itinéraire accessible.';
  String get postCreatePresetBodyDifficultAccess =>
      isAr
          ? 'الوصول إلى هذا المكان صعب بالنسبة لي (منحدرات، عقبات، بُعد). أبلغ عن ذلك لإعلام الآخرين.'
          : 'L’accès à ce lieu est difficile pour moi (pentes, obstacles, distance). Je le signale pour informer les autres personnes.';
  String get postCreatePresetBodyInaccessibleEntrance =>
      isAr
          ? 'المدخل غير متاح: درج، باب ضيق، أو عائق آخر. أبلغ لتحسين الوصول.'
          : 'L’entrée n’est pas accessible : marches, porte étroite ou autre obstacle. Je le signale pour améliorer l’accès.';
  String get postCreatePresetBodyMissingRamp =>
      isAr
          ? 'لا يوجد منحدر أو ميل يمكن الوصول إليه هنا. يصعب ذلك الوصول بالكرسي أو العربة.'
          : 'Il manque une rampe ou une pente accessible ici. Cela complique l’accès en fauteuil ou avec une poussette.';
  String get postCreatePresetBodyStairsNoHelp =>
      isAr
          ? 'لا يوجد مصعد أو بديل للدرج، أو لا أستطيع استخدام الدرج دون مساعدة.'
          : 'Il n’y a pas d’ascenseur ou d’alternative aux escaliers, ou je ne peux pas les utiliser sans aide.';
  String get postCreatePresetBodyNeedOrientation =>
      isAr
          ? 'أحتاج توجيهاً للوصول إلى المدخل أو لمتابعة المسار بشكل يمكن الوصول إليه.'
          : 'J’ai besoin d’orientation pour rejoindre l’entrée ou poursuivre mon trajet de façon accessible.';
  String get postCreatePresetBodyUsefulAdvice =>
      isAr
          ? 'أشارك نصيحة مفيدة من تجربتي لتسهيل الوصول أو الاستقلالية للمعنيين.'
          : 'Je partage un conseil utile tiré de mon expérience pour faciliter l’accès ou l’autonomie des personnes concernées.';
  String get postCreatePresetBodyPersonalTestimony =>
      isAr
          ? 'أشهد عن تجربتي في هذا المكان لإعلام المجتمع (إيجابيات أو نقاط يجب الانتباه لها).'
          : 'Je témoigne de mon expérience à cet endroit pour informer la communauté (points positifs ou points de vigilance).';

  /// Hub Milieux (POST / AIDE / LIEU) — style prototype React.
  String get hubTitle => isAr ? 'مركز المجتمع' : 'Hub Milieux';
  String get hubZonePosts => isAr ? 'منشورات' : 'Posts';
  String get hubZoneAide => isAr ? 'مساعدة' : 'Aide';
  String get hubZoneLieux => isAr ? 'أماكن' : 'Lieux';
  String get communityProches => isAr ? 'أقارب' : 'Proches';
  /// Onglet « lieux à proximité » (pas les contacts).
  String get communityPlacesNearbyTab =>
      isAr ? 'بالجوار' : 'À proximité';
  String get nearbyPlacesTitle =>
      isAr ? 'أماكن قريبة' : 'Lieux à proximité';
  String get readScreen => isAr ? 'قراءة الشاشة' : 'Lire cet écran';
  String get stopReading => isAr ? 'إيقاف القراءة' : 'Arrêter la lecture';
  String get nearbyPlacesHint => isAr
      ? 'ضمن ٤ كم من موقعك، مرتبة حسب الخطر ثم البعد.'
      : 'Dans un rayon de 4 km, tri par niveau de risque puis distance.';
  String nearbyPlacesNoneInRadiusKm(int km) => isAr
      ? 'لا توجد أماكن في نطاق ‎$km‎ كم من موقعك.'
      : 'Aucun lieu dans un rayon de $km km autour de vous.';
  String get nearbyPlacesNeedLocation => isAr
      ? 'فعّل خدمات الموقع وامنح الإذن لعرض الأماكن القريبة.'
      : 'Activez la localisation et autorisez l’app pour voir les lieux proches.';
  String get nearbyPlacesWebUnavailable => isAr
      ? 'الأماكن القريبة متاحة في تطبيق الهاتف فقط.'
      : 'Les lieux à proximité sont disponibles dans l’app mobile.';
  String nearbyPlacesKmOneDecimal(double km) => isAr
      ? '${km.toStringAsFixed(1)} كم'
      : '${km.toStringAsFixed(1)} km';
  String nearbyPlacesMeters(int m) =>
      isAr ? '$m م' : '$m m';
  String get riskDanger => isAr ? 'خطر' : 'Danger';
  String get riskCaution => isAr ? 'يتطلب تحقق' : 'A vérifier';
  String get riskSafe => isAr ? 'معلومات' : 'Info';
  String nearbyPlacesAudioIntro(int count) => isAr
      ? 'تم العثور على $count أماكن قريبة.'
      : '$count lieux à proximité trouvés.';
  String nearbyPlaceAudioItem(String name, String category, String distance) => isAr
      ? '$name. $category. المسافة $distance.'
      : '$name. $category. Distance $distance.';
  String locationDetailsAudio(
    String name,
    String address,
    String category,
    String? description,
  ) => isAr
      ? 'تفاصيل المكان: $name. الفئة: $category. العنوان: $address. ${description ?? ''}'
      : 'Détails du lieu : $name. Catégorie : $category. Adresse : $address. ${description ?? ''}';
  String get communityCircleOfTrust => isAr ? 'دائرة الثقة' : 'Cercle de confiance';
  String get communitySearchCloseOne =>
      isAr ? 'ابحث عن قريب…' : 'Rechercher un proche…';
  String get communityNoCloseOne =>
      isAr ? 'لا يوجد أقارب بعد.' : 'Aucun proche pour le moment.';
  String get communityAddCloseOne => isAr ? 'إضافة قريب' : 'Ajouter un proche';
  String get communityDistanceUnknown => isAr ? '— km' : '— km';
  String get communitySurveillanceTitle =>
      isAr ? 'وضع المراقبة' : 'Mode Surveillance';
  String get communitySurveillanceBody => isAr
      ? 'سيستلم أقاربك موقعك إذا لم تؤكد وصولك.'
      : 'Vos proches reçoivent votre position si vous ne confirmez pas votre arrivée.';
  String get communityShareTrip =>
      isAr ? 'مشاركة مساري' : 'Partager mon trajet';
  String get communitySurveillanceSoon =>
      isAr ? 'قريباً' : 'Bientôt disponible';
  String get call => isAr ? 'اتصال' : 'Appeler';
  String get message => isAr ? 'رسالة' : 'Message';
  String get hubMute => isAr ? 'كتم' : 'Muet';
  String get hubUnmute => isAr ? 'تشغيل الصوت' : 'Activer';
  String get hubPostsSubtitle => isAr
      ? 'الذكاء الجماعي لسلامتك.'
      : 'L’intelligence collective pour votre sécurité.';
  String get hubOpenCommunityPosts => isAr ? 'فتح المنشورات' : 'Ouvrir les posts';
  String get hubDangerAlert => isAr ? 'خطر' : 'Alerte danger';
  String get hubSeeOnMap => isAr ? 'الخريطة' : 'Voir sur carte';
  String get hubVigilance => isAr ? 'انتباه' : 'Vigilance';
  String get hubLieuBody => isAr
      ? 'ملاحظة: تم الإبلاغ عن عائق قريبًا. استخدم الدليل الصوتي.'
      : 'Note : un obstacle a été signalé récemment à proximité. Le guide vocal aide au contournement.';
  String get hubOpenPlaces => isAr ? 'فتح الأماكن' : 'Ouvrir les lieux';
  String get hubAideTitle => isAr ? 'SOS لمسي' : 'SOS tactile';
  String get hubAideSubtitle => isAr
      ? 'اضغط في أي مكان'
      : 'Appui n’importe où';
  String get hubNetworkTitle => isAr ? 'شبكة M3AK' : 'Réseau M3AK';
  String get hubNetworkBody => isAr
      ? 'مشاركة الموقع مع المتطوعين القريبين.'
      : 'Position partagée avec des bénévoles proches.';
  String get hubOpenHelpRequests =>
      isAr ? 'فتح طلبات المساعدة' : 'Ouvrir demandes d’aide';
  String get hubNoRecentPost => isAr ? 'لا منشور حديث.' : 'Aucun signalement récent.';
  String get hubNoPlace => isAr ? 'لا مكان قريب.' : 'Aucun lieu proche.';

  // Voice guide phrases
  String get hubVoiceAideIdle => isAr
      ? 'منطقة المساعدة. اضغط ثلاث مرات للإغاثة الفورية.'
      : 'Zone d’assistance. Tapez trois fois n’importe où pour un secours immédiat.';
  String hubVoiceAideTap(int n) => isAr ? 'تم استقبال $n.' : '$n tape reçue.';
  String hubVoicePost(String danger) => isAr
      ? 'منطقة المجتمع. الإشارة الحالية: $danger.'
      : 'Zone Communauté. Signalement actuel : $danger.';
  String hubVoiceLieu(String place) => isAr
      ? 'منطقة الأماكن. أنت قريب من: $place.'
      : 'Zone Lieux. Vous êtes près de : $place.';

  // Hub v2 (aligné prototype Gemini)
  String get hubAudioMuted => isAr ? 'الصوت مكتوم' : 'Audio muet';
  String hubAudioActive(String zoneLabel) => isAr
      ? 'الدليل الصوتي نشط — $zoneLabel'
      : 'Guide vocal actif — $zoneLabel';
  String get hubAlternativeRoute => isAr
      ? 'مسار بديل: شارع جانبي (مناسب).'
      : 'Passage par la rue latérale (Accessible).';
  String hubPostsHintSafe(String safeLocation) => isAr
      ? 'ملجأ قريب: $safeLocation.'
      : 'Refuge proche : $safeLocation.';
  String get hubVolunteersLoading => isAr ? 'بحث عن متطوعين قريبين…' : 'Recherche de bénévoles proches…';
  String hubVolunteersCount(int? n) {
    if (n == null) {
      return isAr ? 'شبكة الطوارئ جاهزة.' : 'Réseau d’urgence prêt.';
    }
    return isAr ? '$n متطوع قريب.' : '$n Anges Gardiens autour de vous.';
  }
  String get postShortcutSectionTitle =>
      isAr ? 'زر + في المجتمع' : 'Bouton + (communauté)';
  String get postShortcutFormTitle =>
      isAr ? 'النموذج العادي' : 'Formulaire classique';
  String get postShortcutFormSubtitle => isAr
      ? 'فتح شاشة الإنشاء المعتادة.'
      : 'Ouvre l’écran de création habituel (tactile ou vocal).';
  String get postShortcutHeadTitle =>
      isAr ? 'الرأس والعيون' : 'Caméra tête & yeux';
  String get postShortcutHeadSubtitle => isAr
      ? 'للشلل الشديد: الكاميرا الأمامية مباشرة.'
      : 'Handicap moteur lourd : caméra frontale tout de suite.';
  String get postShortcutVibrationTitle =>
      isAr ? 'الاهتزازات' : 'Vibrations codées';
  String get postShortcutVibrationSubtitle => isAr
      ? 'قائمة بالاهتزازات (مثلاً صمم-بكم).'
      : 'Menu par impulsions (ex. sourd-aveugle) — raccourci depuis l’onglet Aides.';
  String get postShortcutVoiceVibTitle =>
      isAr ? 'صوت + اهتزازات' : 'Voix + vibrations';
  String get postShortcutSourdAveugleTitle => isAr
      ? 'صمم‑بكم'
      : 'Sourd‑aveugle';
  String get postShortcutVoiceVibSubtitle => isAr
      ? 'إملاء ثم اهتزاز لكل كلمة.'
      : 'Dictée puis une vibration par mot — depuis l’onglet Aides.';
  String get createPostDescription => isAr ? 'Partagez vos pensées avec la communauté' : 'Partagez vos pensées avec la communauté';
  String get postType => isAr ? 'نوع المنشور' : 'Type de post';
  String get allTypes => isAr ? 'الكل' : 'Tous';
  String get content => isAr ? 'المحتوى' : 'Contenu';
  String get postContentHint => isAr ? 'Écrivez votre message...' : 'Écrivez votre message...';
  String get shareYourThoughts => isAr ? 'Partagez vos pensées avec la communauté' : 'Partagez vos pensées avec la communauté';
  String get publish => isAr ? 'نشر' : 'Publier';
  String get postNote => isAr ? 'Votre post sera visible par tous les membres de la communauté.' : 'Votre post sera visible par tous les membres de la communauté.';
  String get postCreatedSuccess => isAr ? 'Post créé avec succès !' : 'Post créé avec succès !';
  String get noPosts => isAr ? 'Aucun post trouvé' : 'Aucun post trouvé';
  String get beFirstToPost => isAr ? 'Soyez le premier à publier !' : 'Soyez le premier à publier !';
  String get errorLoadingPosts => isAr ? 'Erreur lors du chargement des posts' : 'Erreur lors du chargement des posts';
  String get postDetails => isAr ? 'Détails du post' : 'Détails du post';
  String get comments => isAr ? 'التعليقات' : 'Commentaires';
  String get writeComment => isAr ? 'Écrivez un commentaire...' : 'Écrivez un commentaire...';
  String get noComments => isAr ? 'Aucun commentaire pour le moment' : 'Aucun commentaire pour le moment';
  String get errorLoadingComments => isAr ? 'Erreur lors du chargement des commentaires' : 'Erreur lors du chargement des commentaires';
  String get errorLoadingPost => isAr ? 'Erreur lors du chargement du post' : 'Erreur lors du chargement du post';
  String get page => isAr ? 'صفحة' : 'Page';
  String minimumCharacters(int n) => isAr ? 'Minimum $n caractères requis' : 'Minimum $n caractères requis';

  // Help Requests
  String get helpRequests => isAr ? 'طلبات المساعدة' : 'Demandes d\'aide';
  String get createHelpRequest => isAr ? 'إنشاء طلب مساعدة' : 'Créer une demande d\'aide';
  String get createHelpRequestDescription => isAr ? 'Demandez de l\'aide à la communauté' : 'Demandez de l\'aide à la communauté';
  String get helpRequestDescriptionHint => isAr ? 'Décrivez votre besoin...' : 'Décrivez votre besoin...';
  String get describeYourNeed => isAr ? 'Décrivez clairement votre besoin' : 'Décrivez clairement votre besoin';
  String get location => isAr ? 'الموقع' : 'Localisation';
  String get useCurrentLocation => isAr ? 'استخدام الموقع الحالي' : 'Utiliser ma position';
  String get locationHelpMessage => isAr ? 'Votre position sera partagée pour permettre aux bénévoles de vous trouver.' : 'Votre position sera partagée pour permettre aux bénévoles de vous trouver.';
  String get shareLocationWithPost => isAr
      ? 'مشاركة موقعي مع المنشور'
      : 'Partager ma localisation avec ce post';
  String get shareLocationPostHint => isAr
      ? 'سيساعد ذلك المجتمع على فهم المكان بدقة.'
      : 'Cela aide la communauté à comprendre le lieu exact du signalement.';
  String get locationAttached => isAr
      ? 'تم إرفاق الموقع بالمنشور.'
      : 'Position attachée au post.';
  String get locationUpdated =>
      isAr ? 'تم تحديث الموقع.' : 'Position mise à jour.';
  String get locationUnavailable => isAr
      ? 'تعذر الحصول على الموقع.'
      : 'Position indisponible. Activez la localisation et autorisez l’app.';
  /// Raccourci volume+ sur l’onglet Demandes d’aide (Android).
  String get helpVolumeShortcutHint => isAr
      ? 'Android: في تبويب طلبات المساعدة، اضغط رفع الصوت لإرسال طلب مع موقعك.'
      : 'Android : sur cet onglet, appuyez sur volume+ pour envoyer une demande d’aide avec votre position actuelle.';
  String get helpRequestNote => isAr ? 'Les membres de la communauté pourront voir votre demande et vous aider.' : 'Les membres de la communauté pourront voir votre demande et vous aider.';
  String get helpRequestCreatedSuccess => isAr ? 'Demande d\'aide créée avec succès !' : 'Demande d\'aide créée avec succès !';
  String get noHelpRequests => isAr ? 'Aucune demande d\'aide trouvée' : 'Aucune demande d\'aide trouvée';
  String get beFirstToHelp => isAr ? 'Soyez le premier à demander de l\'aide !' : 'Soyez le premier à demander de l\'aide !';
  String get errorLoadingHelpRequests => isAr ? 'Erreur lors du chargement des demandes' : 'Erreur lors du chargement des demandes';

  // Création demande d’aide — flux inclusif
  String get helpCreateSectionHowTitle =>
      isAr ? 'كيف تريد طلب المساعدة؟' : 'Comment voulez-vous demander de l’aide ?';
  String get helpCreateSectionWhatTitle =>
      isAr ? 'أي نوع من المساعدة؟' : 'Quel type d’aide ?';
  String get helpCreateSectionNeedsTitle =>
      isAr ? 'احتياجات إمكانية الوصول' : 'Besoins d’accessibilité';
  String get helpCreateSectionPreviewTitle =>
      isAr ? 'معاينة قبل الإرسال' : 'Aperçu avant envoi';
  String get helpCreateModeText =>
      isAr ? 'كتابة' : 'Texte';
  String get helpCreateModeVoice =>
      isAr ? 'صوت' : 'Voix';
  String get helpCreateModeTap =>
      isAr ? 'نقر سريع' : 'Préréglages rapides';
  String get helpCreateModeHaptic =>
      isAr ? 'لمسي' : 'Haptique';
  String get helpCreateModeCaregiver =>
      isAr ? 'مرافق' : 'Accompagnant';
  String get helpCreateScenarioBlocked =>
      isAr ? 'محبوس' : 'Je suis bloqué';
  String get helpCreateScenarioLost =>
      isAr ? 'تائه' : 'Je suis perdu';
  String get helpCreateScenarioCannotEnter =>
      isAr ? 'لا أستطيع الدخول' : 'Je ne peux pas entrer';
  String get helpCreateScenarioEscort =>
      isAr ? 'مرافقة' : 'J’ai besoin d’accompagnement';
  String get helpCreateScenarioCommunicate =>
      isAr ? 'التواصل' : 'J’ai besoin d’aide pour communiquer';
  String get helpCreateScenarioDanger =>
      isAr ? 'وضع خطير' : 'Situation dangereuse';
  String get helpCreateNeedAudio =>
      isAr ? 'إرشادات صوتية' : 'Guidance audio';
  String get helpCreateNeedVisual =>
      isAr ? 'دعم بصري' : 'Support visuel';
  String get helpCreateNeedPhysical =>
      isAr ? 'مساعدة جسدية' : 'Assistance physique';
  String get helpCreateNeedSimpleLang =>
      isAr ? 'لغة بسيطة' : 'Langage simple';
  String get helpCreateSelectScenario =>
      isAr ? 'اختر نوع المساعدة' : 'Choisissez un type d’aide';
  String get helpCreateVoiceHint =>
      isAr ? 'استخدم لوحة المفاتيح أو الإملاء' : 'Utilisez le clavier ou la dictée du système';

  /// Dictée — états (écran demande d’aide)
  String get helpVoiceStateUninitialized =>
      isAr ? 'جاري تجهيز الميكروفون…' : 'Préparation du microphone…';
  String get helpVoiceStateReady =>
      isAr ? 'جاهز. اضغط على الميكروفون للتحدث.' : 'Prêt. Appuyez sur le microphone pour parler.';
  String get helpVoiceStateListening =>
      isAr ? 'يستمع… تحدث بوضوء.' : 'Écoute en cours… Parlez distinctement.';
  String get helpVoiceStateRecognized =>
      isAr ? 'تم التعرف على النص. يمكنك تعديله أو الإرسال مع اختيار سريع.'
          : 'Texte reconnu. Vous pouvez le corriger ou envoyer avec un préréglage.';
  String get helpVoiceMicSemanticsStart =>
      isAr ? 'بدء التحدث بالصوت' : 'Démarrer la dictée vocale';
  String get helpVoiceMicSemanticsStop =>
      isAr ? 'إيقاف الاستماع' : 'Arrêter l’écoute et valider le texte reconnu';
  String get helpVoiceRetry =>
      isAr ? 'إعادة المحاولة' : 'Réessayer';
  String get helpVoiceWebHint =>
      isAr
          ? 'على الويب قد يطلب المتصفح إذن الميكروفون.'
          : 'Sur le web, le navigateur peut demander l’accès au microphone.';
  String get helpVoiceShortOkHint =>
      isAr
          ? 'يمكنك الإرسال حتى مع نص قصير إذا اخترت نوع المساعدة أعلاه.'
          : 'Vous pouvez envoyer même avec un texte court si vous avez choisi un type d’aide ci-dessus.';

  String helpVoiceErrorMessage(String? code) {
    switch (code) {
      case 'microphone_denied':
        return isAr
            ? 'تم رفض الميكروفون. اسمح بالوصول من الإعدادات.'
            : 'Microphone refusé. Autorisez l’accès dans les paramètres.';
      case 'init_failed':
        return isAr
            ? 'تعذر تشغيل التعرف على الكلام على هذا الجهاز.'
            : 'Reconnaissance vocale indisponible sur cet appareil.';
      default:
        if (code == null || code.isEmpty) {
          return isAr ? 'حدث خطأ.' : 'Une erreur s’est produite.';
        }
        return isAr
            ? 'خطأ في التعرف على الصوت: $code'
            : 'Erreur de reconnaissance vocale : $code';
    }
  }
  String get helpCreatePreviewNote =>
      isAr ? 'النص النهائي قد يُكمَل على الخادم' : 'Le texte final peut être complété côté serveur';

  // Préréglages rapides — libellés (FR / AR)
  String get helpCreateQuickBlocked =>
      isAr ? 'أنا محبوس' : 'Je suis bloqué';
  String get helpCreateQuickLost =>
      isAr ? 'أنا تائه' : 'Je suis perdu';
  String get helpCreateQuickCannotFindEntrance =>
      isAr ? 'لا أجد المدخل' : 'Je ne trouve pas l’entrée';
  String get helpCreateQuickMobilityHelp =>
      isAr ? 'أحتاج مساعدة للتنقل' : 'J’ai besoin d’aide pour me déplacer';
  String get helpCreateQuickOrientationHelp =>
      isAr ? 'أحتاج مساعدة للتوجه' : 'J’ai besoin d’aide pour m’orienter';
  String get helpCreateQuickCommunicationHelp =>
      isAr ? 'أحتاج مساعدة للتواصل' : 'J’ai besoin d’aide pour communiquer';
  String get helpCreateQuickForAnotherPerson =>
      isAr ? 'أطلب المساعدة لشخص آخر' : 'Je demande de l’aide pour une autre personne';
  String get helpCreateQuickDanger =>
      isAr ? 'وضع خطير' : 'Situation dangereuse';

  /// Phrase d’aperçu (alignée sur le message serveur quand un préréglage est utilisé).
  String get helpCreateQuickPreviewBlocked => isAr
      ? 'أحتاج مساعدة في المكان: يبدو الوصول صعبًا.'
      : 'Je suis bloqué. L’accès semble difficile ou inaccessible. J’ai besoin d’aide sur place.';
  String get helpCreateQuickPreviewLost => isAr
      ? 'أنا تائه وأحتاج مساعدة للتوجه.'
      : 'Je suis perdu et j’ai besoin d’aide pour m’orienter.';
  String get helpCreateQuickPreviewCannotFindEntrance => isAr
      ? 'لا أستطيع الوصول أو إيجاد المدخل. أحتاج مساعدة.'
      : 'Je n’arrive pas à accéder ou à trouver l’entrée. J’ai besoin d’aide.';
  String get helpCreateQuickPreviewMobilityHelp => isAr
      ? 'أحتاج مساعدة للتنقل أو مرافقة.'
      : 'J’ai besoin d’être accompagné·e pour me déplacer ou pour communiquer.';
  String get helpCreateQuickPreviewOrientationHelp => isAr
      ? 'أحتاج مساعدة للتوجه وإيجاد الطريق.'
      : 'Je suis perdu·e et j’ai besoin d’aide pour m’orienter.';
  String get helpCreateQuickPreviewCommunicationHelp => isAr
      ? 'أحتاج مساعدة للتواصل أو لأن يفهمني الآخرون.'
      : 'J’ai besoin d’aide pour communiquer ou me faire comprendre.';
  String get helpCreateQuickPreviewForAnotherPerson => isAr
      ? 'أطلب مساعدة لشخص آخر.'
      : 'Je demande de l’aide pour une personne.';
  String get helpCreateQuickPreviewDanger => isAr
      ? 'أحتاج مساعدة عاجلة متعلقة بالصحة أو الراحة.'
      : 'J’ai besoin d’aide liée à un problème de santé ou de confort immédiat.';

  /// Titre court au-dessus de la phrase d’aperçu principale.
  String get helpCreatePreviewMainMessageTitle =>
      isAr ? 'الرسالة (معاينة)' : 'Message principal (aperçu)';

  /// Libellé accessibilité (lecteur d’écran) : « Priorité : … ».
  String get helpRequestPrioritySemanticLabel =>
      isAr ? 'الأولوية' : 'Priorité';

  String get helpRequestDetailTitle =>
      isAr ? 'تفاصيل طلب المساعدة' : 'Détail de la demande d’aide';

  String get helpRequestPriorityReasonHeading =>
      isAr ? 'تفسير الأولوية' : 'Justification de la priorité';

  String get helpRequestDescriptionHeading =>
      isAr ? 'الرسالة' : 'Message';
  String get helpRequestAccessibilityHeading =>
      isAr ? 'احتياجات إمكانية الوصول' : 'Besoins d’accessibilité';
  String get helpRequestInputModeHeading =>
      isAr ? 'طريقة الإدخال' : 'Mode de saisie';
  String get helpRequestHelpTypeHeading =>
      isAr ? 'نوع الطلب' : 'Type de besoin';
  String get helpRequestCaregiverBadge =>
      isAr ? 'لشخص آخر / مرافق' : 'Pour une autre personne (accompagnant)';
  String get helpRequestCaregiverSemantic =>
      isAr ? 'طلب لصالح شخص آخر أو من مرافق' : 'Demande pour une autre personne ou par un accompagnant';
  String get helpRequestSummaryFallback =>
      isAr ? '(لا يوجد نص؛ تم إنشاء الرسالة تلقائياً)' : '(Aucun texte libre ; message généré automatiquement)';
  String get helpRequestDeveloperSignalsTitle =>
      isAr ? 'إشارات الأولوية (مطور)' : 'Signaux de priorité (développeur)';
  String get helpRequestDeveloperSignalsSubtitle =>
      isAr ? 'للتصحيح فقط' : 'À des fins de débogage uniquement';

  String get helpRequestAcceptLabel =>
      isAr ? 'قبول' : 'Accepter';
  String get helpRequestAcceptThisLabel =>
      isAr ? 'قبول هذا الطلب' : 'Accepter cette demande';
  String get helpRequestAcceptingLabel =>
      isAr ? 'جاري…' : 'Patientez…';

  String helpRequestHelpTypeLabel(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'mobility':
        return isAr ? 'تنقل' : 'Mobilité';
      case 'orientation':
        return isAr ? 'توجيه' : 'Orientation';
      case 'communication':
        return isAr ? 'تواصل' : 'Communication';
      case 'medical':
        return isAr ? 'صحة / طوارئ' : 'Santé / urgence';
      case 'escort':
        return isAr ? 'مرافقة' : 'Accompagnement';
      case 'unsafe_access':
        return isAr ? 'وصول / خطر' : 'Accès / sécurité';
      case 'other':
        return isAr ? 'آخر' : 'Autre';
      default:
        if (raw != null && raw.trim().isNotEmpty) return raw.trim();
        return isAr ? 'غير محدد' : 'Non précisé';
    }
  }

  String helpRequestInputModeLabel(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'text':
        return isAr ? 'كتابة' : 'Texte';
      case 'voice':
        return isAr ? 'صوت' : 'Voix';
      case 'tap':
        return isAr ? 'نقر' : 'Préréglages';
      case 'haptic':
        return isAr ? 'لمسي' : 'Haptique';
      case 'volume_shortcut':
        return isAr ? 'زر الصوت' : 'Raccourci volume';
      case 'caregiver':
        return isAr ? 'مرافق' : 'Accompagnant';
      default:
        if (raw != null && raw.trim().isNotEmpty) return raw.trim();
        return isAr ? 'غير محدد' : 'Non précisé';
    }
  }

  /// Résumé des cases à cocher inclusives (pour affichage).
  String helpRequestNeedsSummary({
    required bool? audio,
    required bool? visual,
    required bool? physical,
    required bool? simpleLang,
  }) {
    final parts = <String>[];
    if (audio == true) parts.add(helpCreateNeedAudio);
    if (visual == true) parts.add(helpCreateNeedVisual);
    if (physical == true) parts.add(helpCreateNeedPhysical);
    if (simpleLang == true) parts.add(helpCreateNeedSimpleLang);
    if (parts.isEmpty) {
      return isAr ? 'لم يُذكر' : 'Non précisé';
    }
    return parts.join(isAr ? '، ' : ', ');
  }

  /// Étiquette affichée sur le badge (texte explicite, pas seulement la couleur).
  String helpRequestPriorityLabel(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'critical':
        return isAr ? 'حرج' : 'CRITIQUE';
      case 'high':
        return isAr ? 'عاجل' : 'URGENT';
      case 'medium':
        return isAr ? 'متوسط' : 'MOYEN';
      case 'low':
        return isAr ? 'منخفض' : 'FAIBLE';
      default:
        return '';
    }
  }

  /// Module aide tactile (3 taps → SOS).
  String get hapticHelpTitle =>
      isAr ? 'مساعدة لمسية' : 'Aide tactile — SOS';
  String get hapticHelpSubtitle => isAr
      ? 'مساعدة حرجة — نقرات مشفرة'
      : 'Assistance critique — tapotements codés';
  String get hapticHelpCardSubtitle => isAr
      ? 'ثلاث نقرات على المنطقة لإرسال تنبيه طوارئ مع موقعك.'
      : 'Trois taps sur la zone pour envoyer une alerte SOS avec votre position.';
  String get hapticHelpTapIntro => isAr
      ? 'اضغط في أي مكان للمساعدة'
      : 'Appuyez n’importe où sur la zone pour demander de l’aide';
  String hapticHelpTapCount(int n) => isAr
      ? 'تم اكتشاف $n نقرة…'
      : '$n tap${n > 1 ? 's' : ''} détecté${n > 1 ? 's' : ''}…';
  String get hapticHelpSosSentBanner =>
      isAr ? '🚨 تم إرسال تنبيه الطوارئ' : '🚨 SOS ENVOYÉ';
  String get hapticHelpTtsEntry => isAr
      ? 'وضع المساعدة اللمسية مفعّل. انقر ثلاث مرات للإغاثة الفورية.'
      : 'Mode aide tactile activé. Tapez trois fois pour un secours immédiat.';
  String get hapticHelpTtsAfterSos => isAr
      ? 'تم إرسال التنبيه. يمكن إبلاغ مرافق بموقعك.'
      : 'Alerte envoyée. Un accompagnant peut être prévenu de votre position.';
  String get hapticHelpCallContact =>
      isAr ? 'الاتصال بقريب' : 'Appeler un proche';
  String get hapticHelpVocalGuide =>
      isAr ? 'دليل صوتي' : 'Guide vocal';
  String get hapticHelpSosApiOk =>
      isAr ? 'تم تسجيل تنبيه الطوارئ.' : 'Alerte SOS enregistrée.';
  String get hapticHelpWebNotice => isAr
      ? 'الاهتزاز والوصول الكامل للموقع على التطبيق فقط.'
      : 'Vibrations et SOS géolocalisé : utilisez l’app sur téléphone.';

  /// Hub M3AK Secours (SOS + réseau + simulation bénévole).
  String get helpHubTitle =>
      isAr ? 'مساعدة M3AK' : 'M3AK Secours';
  String get helpHubPanelNetwork =>
      isAr ? 'شبكة قريبة' : 'Voir le réseau';
  String get helpHubPanelBackSos =>
      isAr ? 'رجوع SOS' : 'Retour SOS';
  String get helpHubDemoBadge => isAr
      ? 'عرض توضيحي'
      : 'Démo (démo web uniquement)';
  String get helpHubWaitingResponder => isAr
      ? 'في انتظار أن يضغط متطوع «أنا قادم» في قائمة التنبيهات القريبة.'
      : 'En attente qu’un aidant appuie sur « M’y rendre » dans les alertes à proximité.';
  String get helpHubPollTimeout => isAr
      ? 'لا رد بعد عدة دقائق. اتصل بقريب أو أعد المحاولة.'
      : 'Aucun secours confirmé pour l’instant. Contactez un proche ou réessayez.';
  String helpHubResponderOnWay(String name) {
    final n = name.trim().isEmpty ? 'Un accompagnant' : name;
    return isAr
        ? 'خبر سار: $n في الطريق لمساعدتك.'
        : 'Bonne nouvelle : $n est en route pour vous aider.';
  }

  String helpHubConfirmedResponder(String name) {
    final n = name.trim().isEmpty ? 'Un accompagnant' : name;
    return isAr ? '$n في الطريق.' : '$n est en route pour vous aider.';
  }

  String get sosMyWayButton =>
      isAr ? 'أنا قادم' : 'M’y rendre';
  String get sosMyWayOk => isAr ? 'تم التسجيل.' : 'Vous avez pris en charge cette alerte.';
  String get helpHubTtsSearchVoluntary => isAr
      ? 'تم إرسال التنبيه. البحث عن متطوع قريب.'
      : 'Alerte envoyée. Recherche d’un accompagnant ou bénévole à proximité.';
  String get helpHubTtsDemoArrival => isAr
      ? 'خبر جيد: يوجد مساعد في الطريق إليك.'
      : 'Bonne nouvelle : un accompagnant a pris en charge votre alerte. Restez sur place si possible.';
  String get helpHubStatusReady =>
      isAr ? 'جاهز' : 'Prêt';
  String get helpHubStatusWaiting =>
      isAr ? 'في الانتظار' : 'En attente';
  String get helpHubStatusConfirmed =>
      isAr ? 'مساعدة في الطريق' : 'Secours en route';
  String get helpHubNetworkOk =>
      isAr ? 'الشبكة نشطة' : 'Réseau proximité OK';
  String get helpHubNearbyTitle =>
      isAr ? 'تنبيهات قريبة' : 'Alertes à proximité';
  String get helpHubNearbySubtitle => isAr
      ? 'من API findNearby — نفس منطقة الخطر يمكن أن تُنشأ من منشور حرج.'
      : 'API findNearby — un post « danger critique » avec position crée aussi une alerte ici.';
  String get helpHubNearbyEmpty => isAr
      ? 'لا تنبيهات في هذه المنطقة.'
      : 'Aucune alerte SOS dans ce périmètre pour l’instant.';
  String get helpHubNearbyLoadError =>
      isAr ? 'تعذر تحميل القائمة.' : 'Impossible de charger les alertes.';
  String get helpHubFooter =>
      isAr ? 'Ma3ak Security Engine v2.5' : 'Ma3ak Security Engine v2.5';
  String get helpHubResetSos =>
      isAr ? 'تنبيه جديد' : 'Nouvelle alerte';
  String get helpHubConfirmedLine1 => isAr
      ? 'تم قبول طلبك.'
      : 'Votre alerte est prise en charge.';
  String get helpHubConfirmedLine2 => isAr
      ? 'ابقَ في مكانك إن أمكن.'
      : 'Restez sur place si vous le pouvez.';
  String get helpHubSosLabel =>
      isAr ? 'SOS' : 'SOS';
  String get helpHubSosSending =>
      isAr ? 'جاري الإرسال…' : 'Envoi…';
  String get helpHubSosOk =>
      isAr ? 'OK' : 'OK';
  String helpHubTapProgress(int n, int max) => isAr
      ? '$n / $max'
      : '$n / $max';
  String get helpHubCardStatLabel =>
      isAr ? 'الحالة' : 'Statut';
  String get helpHubCardNetworkLabel =>
      isAr ? 'الشبكة' : 'Réseau';

  // ─── Dates ─────────────────────────────────────────────────────────────────
  static const List<String> _monthNamesFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  static const List<String> _monthNamesAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const List<String> _monthNamesEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _monthShortFr = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
  ];
  static const List<String> _monthShortEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String monthYearLabel(int month, int year) {
    if (isAr) return '${_monthNamesAr[month - 1]} $year';
    if (isEn) return '${_monthNamesEn[month - 1]} $year';
    return '${_monthNamesFr[month - 1]} $year';
  }

  String formatTripDate(int day, int month, int year) {
    if (isAr) return '$day ${_monthNamesAr[month - 1]} $year';
    if (isEn) return '$day ${_monthNamesEn[month - 1]} $year';
    return '$day ${_monthNamesFr[month - 1]} $year';
  }

  String formatTripDateShort(int day, int month) {
    if (isAr) return '$day ${_monthNamesAr[month - 1]}';
    if (isEn) return '${_monthShortEn[month - 1]} $day';
    return 'Le $day ${_monthShortFr[month - 1]}';
  }

  String formatRequestListDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return _t(ar: 'اليوم، $time', en: 'Today, $time', fr: 'Auj, $time');
    if (d == yesterday) return _t(ar: 'أمس، $time', en: 'Yesterday, $time', fr: 'Hier, $time');
    if (isAr) return '${d.day} ${_monthNamesAr[d.month - 1]}, $time';
    if (isEn) return '${_monthShortEn[d.month - 1]} ${d.day}, $time';
    return '${d.day} ${_monthShortFr[d.month - 1]}, $time';
  }
}
