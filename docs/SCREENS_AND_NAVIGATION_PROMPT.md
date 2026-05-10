# Prompt : Liste des écrans et relations de navigation (Ma3ak)

Copie le bloc ci-dessous pour donner le contexte à un assistant (ou pour la doc).

---

## Contexte à fournir

```
Application Flutter "Ma3ak" (appm3ak). Voici la liste des écrans et leurs relations de navigation (GoRouter).

### ROUTES ET ÉCRANS

Auth:
- / → SplashScreen (redirige vers /home si connecté, sinon /login)
- /login → LoginScreen (→ /home si OK, → /register pour inscription)
- /register → RegisterScreen (→ /login après inscription)

Shell principal (après login):
- /home → MainShell avec 5 onglets: 0=Accueil, 1=Santé, 2=Transport, 3=Milieux, 4=Profil
- /profile → MainShell(initialIndex: 4)

Profil et édition:
- /profile-edit → ProfileScreen

Accompagnement / relations:
- /accompagnants → EmergencyContactsScreen
- /relations/accompagnants → MyAccompagnantsRelationsScreen
- /relations/handicapes → MyHandicapesRelationsScreen
- /beneficiaires → TransportRequestsScreen (demandes transport pour accompagnant)

Santé / médical:
- /medical-record → MedicalRecordScreen
- /medical-emergency-card → MedicalEmergencyCardScreen
- /sos-alerts → SosAlertsScreen
- /emergency-settings → EmergencySettingsScreen
- /medication-reminders → MedicationRemindersListScreen
- /medication-reminders/new → MedicationReminderFormScreen (création)
- /medication-reminders/:id/edit → MedicationReminderFormScreen (édition)
- /risk-alerts → RiskAlertsListScreen

Notifications:
- /notifications → NotificationsListScreen

Véhicules:
- /vehicles → MyVehiclesScreen
- /vehicles/new → VehicleFormScreen (création)
- /vehicles/:id → VehicleDetailScreen
- /vehicles/:id/edit → VehicleFormScreen (édition)

Réservations véhicules:
- /vehicle-reservations → VehicleReservationListScreen
- /vehicle-reservations/new → VehicleReservationFormScreen (?vehicleId optionnel)
- /vehicle-reservations/:id → VehicleReservationDetailScreen

Transport:
- /transport/hub → TransportHubScreen (Centre Transport)
- /transport/obstacle-detection → ObstacleDetectionScreen (détection d'obstacles)
- /transport/dynamic → TransportDynamicScreen (carte)
- /transport/map → TransportMapScreen
- /transport/vehicles → AdaptedVehiclesScreen
- /transport/request → TransportRequestScreen
- /transport/history → TransportHistoryScreen
- /transport/my-requests → TransportMyRequestsScreen
- /transport/:id → TransportDetailScreen
- /transport/:id/suivi → TransportSuiviScreen

Navigation AR:
- /navigation-ar → ArNavigationScreen

### RELATIONS PRINCIPALES (qui mène où)

Splash → /home ou /login. Login → /home ou /register. Register → /login.

Depuis MainShell (onglets): Accueil (HomeTab/HomeCompanionTab), Santé (HealthTab), Transport (tab 2), Milieux, Profil (ProfileTab). ProfileTab → profile-edit, accompagnants, relations/*, medical-record, medical-emergency-card, emergency-settings, medication-reminders, risk-alerts, notifications, vehicle-reservations, vehicles, logout→/login. HealthTab → sos-alerts, medical-record, medical-emergency-card, accompagnants, emergency-settings, medication-reminders, risk-alerts, notifications. HomeTab → notifications, profile, home?tab=2, relations/accompagnants|handicapes, navigation-ar, transport/obstacle-detection, transport/dynamic, sos-alerts.

Transport hub → transport/request, transport/my-requests, transport/obstacle-detection, beneficiaires, transport/dynamic, transport/history. Transport dynamic → home?tab=0, transport/my-requests, transport/history, transport/obstacle-detection, transport/request, vehicle-reservations/new. Transport my-requests → transport/:id. Transport detail → transport/:id/suivi. Transport requests (beneficiaires) → transport/:id. Transport history → transport/request, vehicle-reservations/:id.

Véhicules: vehicles → vehicles/:id, vehicles/new. vehicles/:id → vehicles/:id/edit. vehicle-reservations (list) → vehicle-reservations/:id, transport/history, home?tab=2. vehicle-reservations/new (form) → vehicle-reservations/:id après création. vehicle-reservations/:id → vehicle-reservations (retour).

AdaptedVehiclesScreen → transport/map, vehicle-reservations/new?vehicleId=, vehicles/:id. MedicationRemindersList → medication-reminders/new, medication-reminders/:id/edit.
```

---

*Généré pour le projet appm3ak. Mettre à jour ce fichier si de nouvelles routes ou navigations sont ajoutées.*
