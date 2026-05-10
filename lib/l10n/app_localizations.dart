import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ma3ak'**
  String get appTitle;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @welcomeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome :)'**
  String get welcomeHeroTitle;

  /// No description provided for @welcomeHeroHi.
  ///
  /// In en, this message translates to:
  /// **'Hi there!'**
  String get welcomeHeroHi;

  /// No description provided for @welcomeHeroLine2.
  ///
  /// In en, this message translates to:
  /// **'Ma3ak is here for more inclusive mobility in Tunisia.'**
  String get welcomeHeroLine2;

  /// No description provided for @welcomeHeroChoiceLead.
  ///
  /// In en, this message translates to:
  /// **'The choice is yours:'**
  String get welcomeHeroChoiceLead;

  /// No description provided for @welcomeHeroChoiceOr.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get welcomeHeroChoiceOr;

  /// No description provided for @welcomeHeroChoiceEnd.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get welcomeHeroChoiceEnd;

  /// No description provided for @nom.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nom;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @ville.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get ville;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get bio;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @handicapTypes.
  ///
  /// In en, this message translates to:
  /// **'Disability Types'**
  String get handicapTypes;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @companion.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get companion;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myAccompagnants.
  ///
  /// In en, this message translates to:
  /// **'My companions'**
  String get myAccompagnants;

  /// No description provided for @myBeneficiaires.
  ///
  /// In en, this message translates to:
  /// **'My beneficiaries'**
  String get myBeneficiaires;

  /// No description provided for @addAccompagnant.
  ///
  /// In en, this message translates to:
  /// **'Add a companion'**
  String get addAccompagnant;

  /// No description provided for @addHandicape.
  ///
  /// In en, this message translates to:
  /// **'Add a beneficiary'**
  String get addHandicape;

  /// No description provided for @removeAccompagnant.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAccompagnant;

  /// No description provided for @relationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get relationStatusPending;

  /// No description provided for @relationStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get relationStatusAccepted;

  /// No description provided for @acceptRelation.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get acceptRelation;

  /// No description provided for @deleteRelation.
  ///
  /// In en, this message translates to:
  /// **'Delete link'**
  String get deleteRelation;

  /// No description provided for @addAccompagnantById.
  ///
  /// In en, this message translates to:
  /// **'Add companion by ID'**
  String get addAccompagnantById;

  /// No description provided for @addHandicapeById.
  ///
  /// In en, this message translates to:
  /// **'Add beneficiary by ID'**
  String get addHandicapeById;

  /// No description provided for @idPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'User ID (MongoDB)'**
  String get idPlaceholder;

  /// No description provided for @relationAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This link already exists'**
  String get relationAlreadyExists;

  /// No description provided for @relationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Link not found'**
  String get relationNotFound;

  /// No description provided for @myHandicapes.
  ///
  /// In en, this message translates to:
  /// **'My beneficiaries'**
  String get myHandicapes;

  /// No description provided for @noAccompagnantsYet.
  ///
  /// In en, this message translates to:
  /// **'No companions yet'**
  String get noAccompagnantsYet;

  /// No description provided for @noHandicapesYet.
  ///
  /// In en, this message translates to:
  /// **'No beneficiaries yet'**
  String get noHandicapesYet;

  /// No description provided for @relationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People linked to you in the app'**
  String get relationsSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneric;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get errorInvalidCredentials;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Inclusive mobility for all'**
  String get tagline;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email / Phone'**
  String get emailOrPhone;

  /// No description provided for @hintEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone'**
  String get hintEmailOrPhone;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get hintPassword;

  /// No description provided for @connexion.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get connexion;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// No description provided for @registerPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerPageTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the Ma3ak community for inclusive mobility in Tunisia.'**
  String get registerSubtitle;

  /// No description provided for @dataSecurityMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure and used only to facilitate your transport.'**
  String get dataSecurityMessage;

  /// No description provided for @iAm.
  ///
  /// In en, this message translates to:
  /// **'I am...'**
  String get iAm;

  /// No description provided for @roleHandicap.
  ///
  /// In en, this message translates to:
  /// **'Person with disability'**
  String get roleHandicap;

  /// No description provided for @registerAlready.
  ///
  /// In en, this message translates to:
  /// **'Already registered?'**
  String get registerAlready;

  /// No description provided for @registerWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ma3ak. Please provide your information to help us personalise your accessibility experience in Tunisia.'**
  String get registerWelcome;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sami Mansour'**
  String get fullNameHint;

  /// No description provided for @handicapTypeOptional.
  ///
  /// In en, this message translates to:
  /// **'Disability type (Optional)'**
  String get handicapTypeOptional;

  /// No description provided for @typeHandicapHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the type'**
  String get typeHandicapHint;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get selectOption;

  /// No description provided for @handicapHelper.
  ///
  /// In en, this message translates to:
  /// **'This helps us suggest suitable routes and features.'**
  String get handicapHelper;

  /// No description provided for @emailOrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number *'**
  String get emailOrPhoneRequired;

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'email@example.com or +216...'**
  String get emailOrPhoneHint;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get personalInfo;

  /// No description provided for @securitySupport.
  ///
  /// In en, this message translates to:
  /// **'SECURITY & SUPPORT'**
  String get securitySupport;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get emergencyContacts;

  /// No description provided for @assistanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Assistance history'**
  String get assistanceHistory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @verifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified user'**
  String get verifiedUser;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @assistedTrips.
  ///
  /// In en, this message translates to:
  /// **'ASSISTED TRIPS'**
  String get assistedTrips;

  /// No description provided for @communityRating.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY RATING'**
  String get communityRating;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @transportHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport Hub'**
  String get transportHubTitle;

  /// No description provided for @transportHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access to all transport services'**
  String get transportHubSubtitle;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// No description provided for @activeTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active trips'**
  String get activeTripsTitle;

  /// No description provided for @availableRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available requests'**
  String get availableRequestsTitle;

  /// No description provided for @noActiveTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'No active trips at the moment'**
  String get noActiveTripsMessage;

  /// No description provided for @noAvailableRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'No available requests at the moment'**
  String get noAvailableRequestsMessage;

  /// No description provided for @urgentAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent alerts'**
  String get urgentAlertsTitle;

  /// No description provided for @myTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get myTripsLabel;

  /// No description provided for @liveMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get liveMapLabel;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @whereToGoToday.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to go today?'**
  String get whereToGoToday;

  /// No description provided for @searchAccessiblePlaces.
  ///
  /// In en, this message translates to:
  /// **'Search accessible places'**
  String get searchAccessiblePlaces;

  /// No description provided for @mainServices.
  ///
  /// In en, this message translates to:
  /// **'Main Services'**
  String get mainServices;

  /// No description provided for @mobilityTransport.
  ///
  /// In en, this message translates to:
  /// **'Mobility & Transport'**
  String get mobilityTransport;

  /// No description provided for @findAssistant.
  ///
  /// In en, this message translates to:
  /// **'Find an assistant'**
  String get findAssistant;

  /// No description provided for @accessibilityCard.
  ///
  /// In en, this message translates to:
  /// **'Accessibility card'**
  String get accessibilityCard;

  /// No description provided for @learningCenter.
  ///
  /// In en, this message translates to:
  /// **'Learning center'**
  String get learningCenter;

  /// No description provided for @nearbyAndActive.
  ///
  /// In en, this message translates to:
  /// **'Nearby & Active'**
  String get nearbyAndActive;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @exploreNearby.
  ///
  /// In en, this message translates to:
  /// **'Explore nearby'**
  String get exploreNearby;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get available;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// No description provided for @companionRole.
  ///
  /// In en, this message translates to:
  /// **'COMPANION'**
  String get companionRole;

  /// No description provided for @followedUsers.
  ///
  /// In en, this message translates to:
  /// **'Followed users'**
  String get followedUsers;

  /// No description provided for @atHome.
  ///
  /// In en, this message translates to:
  /// **'AT HOME'**
  String get atHome;

  /// No description provided for @calm.
  ///
  /// In en, this message translates to:
  /// **'CALM'**
  String get calm;

  /// No description provided for @atDistance.
  ///
  /// In en, this message translates to:
  /// **'AT 500M'**
  String get atDistance;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @assistanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Assistance requests'**
  String get assistanceRequests;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @urgentTransport.
  ///
  /// In en, this message translates to:
  /// **'URGENT TRANSPORT'**
  String get urgentTransport;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @mySchedule.
  ///
  /// In en, this message translates to:
  /// **'My schedule'**
  String get mySchedule;

  /// No description provided for @medicalAccompaniment.
  ///
  /// In en, this message translates to:
  /// **'Medical accompaniment'**
  String get medicalAccompaniment;

  /// No description provided for @groceryHelp.
  ///
  /// In en, this message translates to:
  /// **'Grocery help'**
  String get groceryHelp;

  /// No description provided for @resourcesAndGuide.
  ///
  /// In en, this message translates to:
  /// **'Resources & Guide'**
  String get resourcesAndGuide;

  /// No description provided for @goodPracticesGuide.
  ///
  /// In en, this message translates to:
  /// **'Good practices guide'**
  String get goodPracticesGuide;

  /// No description provided for @firstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get firstAid;

  /// No description provided for @typeAccompagnantRequired.
  ///
  /// In en, this message translates to:
  /// **'Companion type *'**
  String get typeAccompagnantRequired;

  /// No description provided for @typeAccompagnantHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your type'**
  String get typeAccompagnantHint;

  /// No description provided for @typeAccompagnantRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please choose a companion type'**
  String get typeAccompagnantRequiredError;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @myVehicles.
  ///
  /// In en, this message translates to:
  /// **'My vehicles'**
  String get myVehicles;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle'**
  String get addVehicle;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleDetails;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicle;

  /// No description provided for @deleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get deleteVehicle;

  /// No description provided for @marque.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get marque;

  /// No description provided for @modele.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modele;

  /// No description provided for @immatriculation.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get immatriculation;

  /// No description provided for @accessibilite.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilite;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @statut.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statut;

  /// No description provided for @coffreVaste.
  ///
  /// In en, this message translates to:
  /// **'Large trunk'**
  String get coffreVaste;

  /// No description provided for @rampeAcces.
  ///
  /// In en, this message translates to:
  /// **'Access ramp'**
  String get rampeAcces;

  /// No description provided for @siegePivotant.
  ///
  /// In en, this message translates to:
  /// **'Pivoting seat'**
  String get siegePivotant;

  /// No description provided for @climatisation.
  ///
  /// In en, this message translates to:
  /// **'Air conditioning'**
  String get climatisation;

  /// No description provided for @animalAccepte.
  ///
  /// In en, this message translates to:
  /// **'Animals accepted'**
  String get animalAccepte;

  /// No description provided for @vehicleCreated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle created successfully'**
  String get vehicleCreated;

  /// No description provided for @vehicleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated successfully'**
  String get vehicleUpdated;

  /// No description provided for @vehicleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted successfully'**
  String get vehicleDeleted;

  /// No description provided for @confirmDeleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this vehicle?'**
  String get confirmDeleteVehicle;

  /// No description provided for @noVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles'**
  String get noVehicles;

  /// No description provided for @vehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not found'**
  String get vehicleNotFound;

  /// No description provided for @immatriculationExists.
  ///
  /// In en, this message translates to:
  /// **'This license plate is already registered'**
  String get immatriculationExists;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @vehicleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleDetailsTitle;

  /// No description provided for @vehicleDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Please fill in your adapted vehicle information for inclusive mobility.'**
  String get vehicleDetailsDescription;

  /// No description provided for @vehiclePhoto.
  ///
  /// In en, this message translates to:
  /// **'Vehicle photo'**
  String get vehiclePhoto;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @photoFormats.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 10MB'**
  String get photoFormats;

  /// No description provided for @marqueAndModele.
  ///
  /// In en, this message translates to:
  /// **'Make & Model'**
  String get marqueAndModele;

  /// No description provided for @marqueModeleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Volkswagen Caddy'**
  String get marqueModeleHint;

  /// No description provided for @invalidImmatriculationFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid license plate format'**
  String get invalidImmatriculationFormat;

  /// No description provided for @specializedEquipment.
  ///
  /// In en, this message translates to:
  /// **'Specialised equipment'**
  String get specializedEquipment;

  /// No description provided for @rampeAccesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manual or automatic'**
  String get rampeAccesDescription;

  /// No description provided for @siegePivotantDescription.
  ///
  /// In en, this message translates to:
  /// **'Facilitates transfer'**
  String get siegePivotantDescription;

  /// No description provided for @espaceFauteuilRoulant.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair space'**
  String get espaceFauteuilRoulant;

  /// No description provided for @espaceFauteuilRoulantDescription.
  ///
  /// In en, this message translates to:
  /// **'Safety fixings included'**
  String get espaceFauteuilRoulantDescription;

  /// No description provided for @commandesVolant.
  ///
  /// In en, this message translates to:
  /// **'Steering wheel controls'**
  String get commandesVolant;

  /// No description provided for @commandesVolantDescription.
  ///
  /// In en, this message translates to:
  /// **'Manual accelerator and brake'**
  String get commandesVolantDescription;

  /// No description provided for @coffreVasteDescription.
  ///
  /// In en, this message translates to:
  /// **'Large storage space'**
  String get coffreVasteDescription;

  /// No description provided for @climatisationDescription.
  ///
  /// In en, this message translates to:
  /// **'Temperature control'**
  String get climatisationDescription;

  /// No description provided for @animalAccepteDescription.
  ///
  /// In en, this message translates to:
  /// **'Assistance animals allowed'**
  String get animalAccepteDescription;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favorites;

  /// No description provided for @inService.
  ///
  /// In en, this message translates to:
  /// **'In service'**
  String get inService;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'MAINTENANCE'**
  String get maintenance;

  /// No description provided for @lastMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Last maintenance'**
  String get lastMaintenance;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// No description provided for @plate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get plate;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'CAPACITY'**
  String get capacity;

  /// No description provided for @capacityPlaces.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get capacityPlaces;

  /// No description provided for @servicesIncluded.
  ///
  /// In en, this message translates to:
  /// **'services included'**
  String get servicesIncluded;

  /// No description provided for @checkAvailabilities.
  ///
  /// In en, this message translates to:
  /// **'Check availabilities'**
  String get checkAvailabilities;

  /// No description provided for @spacious.
  ///
  /// In en, this message translates to:
  /// **'Spacious'**
  String get spacious;

  /// No description provided for @pmrOptimized.
  ///
  /// In en, this message translates to:
  /// **'PRM optimised'**
  String get pmrOptimized;

  /// No description provided for @comfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get comfortable;

  /// No description provided for @dualZone.
  ///
  /// In en, this message translates to:
  /// **'Dual-zone'**
  String get dualZone;

  /// No description provided for @assistanceDogsWelcome.
  ///
  /// In en, this message translates to:
  /// **'Assistance dogs welcome'**
  String get assistanceDogsWelcome;

  /// No description provided for @adaptedVehicles.
  ///
  /// In en, this message translates to:
  /// **'Adapted Vehicles'**
  String get adaptedVehicles;

  /// No description provided for @searchVehicle.
  ///
  /// In en, this message translates to:
  /// **'Search a vehicle...'**
  String get searchVehicle;

  /// No description provided for @seeMoreVehicles.
  ///
  /// In en, this message translates to:
  /// **'See more vehicles'**
  String get seeMoreVehicles;

  /// No description provided for @soonAvailable.
  ///
  /// In en, this message translates to:
  /// **'SOON AVAILABLE'**
  String get soonAvailable;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'TND/day'**
  String get pricePerDay;

  /// No description provided for @tunis.
  ///
  /// In en, this message translates to:
  /// **'Tunis'**
  String get tunis;

  /// No description provided for @sousse.
  ///
  /// In en, this message translates to:
  /// **'Sousse'**
  String get sousse;

  /// No description provided for @wheelchairSpace.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair space'**
  String get wheelchairSpace;

  /// No description provided for @liftingPlatform.
  ///
  /// In en, this message translates to:
  /// **'Lifting platform'**
  String get liftingPlatform;

  /// No description provided for @wheelchairsAndPlaces.
  ///
  /// In en, this message translates to:
  /// **'2 Wheelchairs + 5 seats'**
  String get wheelchairsAndPlaces;

  /// No description provided for @myVehicleReservations.
  ///
  /// In en, this message translates to:
  /// **'My vehicle reservations'**
  String get myVehicleReservations;

  /// No description provided for @createReservation.
  ///
  /// In en, this message translates to:
  /// **'Create reservation'**
  String get createReservation;

  /// No description provided for @reservationDetails.
  ///
  /// In en, this message translates to:
  /// **'Reservation details'**
  String get reservationDetails;

  /// No description provided for @departurePlace.
  ///
  /// In en, this message translates to:
  /// **'Departure place'**
  String get departurePlace;

  /// No description provided for @destinationPlace.
  ///
  /// In en, this message translates to:
  /// **'Destination place'**
  String get destinationPlace;

  /// No description provided for @specificNeeds.
  ///
  /// In en, this message translates to:
  /// **'Specific needs'**
  String get specificNeeds;

  /// No description provided for @reservationCreated.
  ///
  /// In en, this message translates to:
  /// **'Reservation created successfully'**
  String get reservationCreated;

  /// No description provided for @reservationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled'**
  String get reservationCancelled;

  /// No description provided for @vehicleNotAvailableForDate.
  ///
  /// In en, this message translates to:
  /// **'This vehicle is not available at this date and time'**
  String get vehicleNotAvailableForDate;

  /// No description provided for @cancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation'**
  String get cancelReservation;

  /// No description provided for @confirmCancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this reservation?'**
  String get confirmCancelReservation;

  /// No description provided for @bookVehicle.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookVehicle;

  /// No description provided for @noReservations.
  ///
  /// In en, this message translates to:
  /// **'No reservations'**
  String get noReservations;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Date is required'**
  String get dateRequired;

  /// No description provided for @timeRequired.
  ///
  /// In en, this message translates to:
  /// **'Time is required'**
  String get timeRequired;

  /// No description provided for @timeFormatHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 14:30'**
  String get timeFormatHint;

  /// No description provided for @validateVehicle.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validateVehicle;

  /// No description provided for @rejectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectVehicle;

  /// No description provided for @vehicleStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle status updated successfully'**
  String get vehicleStatusUpdated;

  /// No description provided for @cannotModifyVehicle.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit this vehicle'**
  String get cannotModifyVehicle;

  /// No description provided for @cannotModifyVehicleStatus.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to edit this vehicle\'s status'**
  String get cannotModifyVehicleStatus;

  /// No description provided for @onlyStatusCanBeModified.
  ///
  /// In en, this message translates to:
  /// **'Only the status can be modified by a solidarity driver'**
  String get onlyStatusCanBeModified;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get changeStatus;

  /// No description provided for @vehicleStatus.
  ///
  /// In en, this message translates to:
  /// **'Vehicle status'**
  String get vehicleStatus;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search for an address...'**
  String get searchAddress;

  /// No description provided for @calculateRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculate route'**
  String get calculateRoute;

  /// No description provided for @fillAddressesFirst.
  ///
  /// In en, this message translates to:
  /// **'Fill in departure and arrival addresses'**
  String get fillAddressesFirst;

  /// No description provided for @routeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get routeDistance;

  /// No description provided for @routeDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get routeDuration;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// No description provided for @searchAccessiblePlace.
  ///
  /// In en, this message translates to:
  /// **'Search accessible place...'**
  String get searchAccessiblePlace;

  /// No description provided for @ramps.
  ///
  /// In en, this message translates to:
  /// **'Ramps'**
  String get ramps;

  /// No description provided for @toilets.
  ///
  /// In en, this message translates to:
  /// **'Toilets'**
  String get toilets;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @placeOfInterest.
  ///
  /// In en, this message translates to:
  /// **'Place of interest'**
  String get placeOfInterest;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @wheelchairAccess.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair access'**
  String get wheelchairAccess;

  /// No description provided for @brailleMenus.
  ///
  /// In en, this message translates to:
  /// **'Braille menus'**
  String get brailleMenus;

  /// No description provided for @bookAssistance.
  ///
  /// In en, this message translates to:
  /// **'Book assistance'**
  String get bookAssistance;

  /// No description provided for @reserveVehicle.
  ///
  /// In en, this message translates to:
  /// **'Reserve vehicle'**
  String get reserveVehicle;

  /// No description provided for @seeAdaptedVehicles.
  ///
  /// In en, this message translates to:
  /// **'See adapted vehicles'**
  String get seeAdaptedVehicles;

  /// No description provided for @whereAreYouGoing.
  ///
  /// In en, this message translates to:
  /// **'Where are you going?'**
  String get whereAreYouGoing;

  /// No description provided for @driversNearby.
  ///
  /// In en, this message translates to:
  /// **'Drivers nearby'**
  String get driversNearby;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @ramp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get ramp;

  /// No description provided for @assistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance'**
  String get assistance;

  /// No description provided for @guideDog.
  ///
  /// In en, this message translates to:
  /// **'Guide dog'**
  String get guideDog;

  /// No description provided for @minWait.
  ///
  /// In en, this message translates to:
  /// **'min wait'**
  String get minWait;

  /// No description provided for @noDriverAvailable.
  ///
  /// In en, this message translates to:
  /// **'No driver available at the moment.'**
  String get noDriverAvailable;

  /// No description provided for @requestTransport.
  ///
  /// In en, this message translates to:
  /// **'Request transport'**
  String get requestTransport;

  /// No description provided for @requestTransportShort.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestTransportShort;

  /// No description provided for @chooseTransportType.
  ///
  /// In en, this message translates to:
  /// **'Transport type'**
  String get chooseTransportType;

  /// No description provided for @transportUrgency.
  ///
  /// In en, this message translates to:
  /// **'Emergency transport'**
  String get transportUrgency;

  /// No description provided for @transportDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily transport'**
  String get transportDaily;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure place'**
  String get departure;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @creationRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Create request'**
  String get creationRequestTitle;

  /// No description provided for @typeOfAssistance.
  ///
  /// In en, this message translates to:
  /// **'Type of assistance'**
  String get typeOfAssistance;

  /// No description provided for @selectAssistanceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Select the assistance you need for your trip. You can choose several.'**
  String get selectAssistanceNeeded;

  /// No description provided for @wheelchairAssistance.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get wheelchairAssistance;

  /// No description provided for @wheelchairSubtitle.
  ///
  /// In en, this message translates to:
  /// **'TPMR adapted vehicle'**
  String get wheelchairSubtitle;

  /// No description provided for @boardingHelp.
  ///
  /// In en, this message translates to:
  /// **'Boarding help'**
  String get boardingHelp;

  /// No description provided for @boardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Physical support or guidance'**
  String get boardingSubtitle;

  /// No description provided for @visualImpairment.
  ///
  /// In en, this message translates to:
  /// **'Visual impairment'**
  String get visualImpairment;

  /// No description provided for @visualImpairmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice announcements and guidance'**
  String get visualImpairmentSubtitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @scheduleDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get scheduleDateAndTime;

  /// No description provided for @requestNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get requestNow;

  /// No description provided for @scheduleLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleLater;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @transportRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Your transport request has been sent successfully.'**
  String get transportRequestSent;

  /// No description provided for @urgencyBadge.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyBadge;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTitle;

  /// No description provided for @chooseVehicleForTrip.
  ///
  /// In en, this message translates to:
  /// **'Choose vehicle for this trip'**
  String get chooseVehicleForTrip;

  /// No description provided for @selectTransportForRide.
  ///
  /// In en, this message translates to:
  /// **'Select the transport means for this trip.'**
  String get selectTransportForRide;

  /// No description provided for @noVehicleOption.
  ///
  /// In en, this message translates to:
  /// **'No vehicle'**
  String get noVehicleOption;

  /// No description provided for @pedestrianAccompagnement.
  ///
  /// In en, this message translates to:
  /// **'Pedestrian accompaniment'**
  String get pedestrianAccompagnement;

  /// No description provided for @confirmAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Confirm acceptance'**
  String get confirmAcceptance;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get liveTracking;

  /// No description provided for @optionalDurationOrArrival.
  ///
  /// In en, this message translates to:
  /// **'Duration or arrival time (optional)'**
  String get optionalDurationOrArrival;

  /// No description provided for @tripEnded.
  ///
  /// In en, this message translates to:
  /// **'Trip ended'**
  String get tripEnded;

  /// No description provided for @estimatedArrivalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get estimatedArrivalLabel;

  /// No description provided for @participantsSection.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participantsSection;

  /// No description provided for @climatised.
  ///
  /// In en, this message translates to:
  /// **'Air-conditioned'**
  String get climatised;

  /// No description provided for @enRoute.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get enRoute;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get currentLocation;

  /// No description provided for @myCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'My current location'**
  String get myCurrentLocation;

  /// No description provided for @enterDepartureAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter departure address...'**
  String get enterDepartureAddress;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistory;

  /// No description provided for @tripHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistoryTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @sectionToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get sectionToday;

  /// No description provided for @sectionYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get sectionYesterday;

  /// No description provided for @detailsLink.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLink;

  /// No description provided for @tripHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Trips made with vehicle and driver'**
  String get tripHistoryDescription;

  /// No description provided for @noTripHistory.
  ///
  /// In en, this message translates to:
  /// **'No trips recorded'**
  String get noTripHistory;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @vehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleLabel;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetails;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @sectionRecent.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get sectionRecent;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequestsTitle;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tabPending;

  /// No description provided for @tabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tabCompleted;

  /// No description provided for @requester.
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get requester;

  /// No description provided for @viewDetailsLink.
  ///
  /// In en, this message translates to:
  /// **'View details >'**
  String get viewDetailsLink;

  /// No description provided for @departurePrefix.
  ///
  /// In en, this message translates to:
  /// **'Departure: '**
  String get departurePrefix;

  /// No description provided for @labelDeparture.
  ///
  /// In en, this message translates to:
  /// **'DEPARTURE'**
  String get labelDeparture;

  /// No description provided for @labelDestination.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION'**
  String get labelDestination;

  /// No description provided for @labelArrival.
  ///
  /// In en, this message translates to:
  /// **'ARRIVAL'**
  String get labelArrival;

  /// No description provided for @evaluateTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get evaluateTrip;

  /// No description provided for @yourReview.
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get yourReview;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @optionalComment.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get optionalComment;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @reviewSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you, your review has been recorded.'**
  String get reviewSent;

  /// No description provided for @alreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'Already reviewed'**
  String get alreadyReviewed;

  /// No description provided for @serviceEvaluationTitle.
  ///
  /// In en, this message translates to:
  /// **'Service evaluation'**
  String get serviceEvaluationTitle;

  /// No description provided for @reviewSubmittedTag.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get reviewSubmittedTag;

  /// No description provided for @evaluationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your review helps us improve Ma3ak'**
  String get evaluationSubtitle;

  /// No description provided for @commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with us...'**
  String get commentPlaceholder;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @mobilityInclusiveFooter.
  ///
  /// In en, this message translates to:
  /// **'INCLUSIVE MOBILITY • MA3AK'**
  String get mobilityInclusiveFooter;

  /// No description provided for @tripIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripIdLabel;

  /// No description provided for @paidViaWallet.
  ///
  /// In en, this message translates to:
  /// **'Paid via Wallet'**
  String get paidViaWallet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
