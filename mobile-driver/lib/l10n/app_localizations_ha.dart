// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get driverBrandingLine => 'Tuƙi tare da Along';

  @override
  String get phoneEntryTitle => 'Tuƙi tare da Along';

  @override
  String get phoneEntrySubtitle =>
      'Za mu tura lamba zuwa wannan lambar don ranarka ta zama naka.';

  @override
  String get continueButton => 'Ci gaba';

  @override
  String get legalPrefix => 'Idan ka ci gaba, ka amince da ';

  @override
  String get termsLink => 'Sharuɗɗa';

  @override
  String get legalMiddle => ' da ';

  @override
  String get privacyLink => 'Manufar Sirri';

  @override
  String otpTitle(String phone) {
    return 'Shigar da lambar lamba 6 da aka tura zuwa $phone';
  }

  @override
  String get wrongNumber => 'Lambar ba daidai ba?';

  @override
  String get resendCode => 'Sake tura lamba';

  @override
  String resendCountdown(int seconds) {
    return 'Sake tura cikin ${seconds}s';
  }

  @override
  String get errorInvalidPhone => 'Shigar da lambar Najeriya mai inganci';

  @override
  String get errorWrongOtp => 'Lambar ba daidai ba — sake gwadawa';

  @override
  String get errorExpiredOtp => 'Lambar ta ƙare — nemi sabuwa';

  @override
  String errorRateLimited(int seconds) {
    return 'Ƙoƙari ya yi yawa. Sake gwadawa cikin ${seconds}s';
  }

  @override
  String get errorGeneric => 'Wani abu ya faru. Da fatan a sake gwadawa.';

  @override
  String get errorAuthNotConfigured =>
      'Wannan ginin ba a haɗa shi da Along ba. Sake gina staging APK da env/staging.json.';

  @override
  String get errorValidation => 'Da fatan a duba filayen ka sake gwadawa.';

  @override
  String get errorPlateConflict => 'An riga an yi rajistar wannan lambar mota.';

  @override
  String get profileTitle => 'Bayanan kanka';

  @override
  String get profileSubtitle => 'Faɗa mana kaɗan game da kanka';

  @override
  String get nameLabel => 'Cikakken suna';

  @override
  String get nameHint => 'Sunanka';

  @override
  String get cityLabel => 'Birni';

  @override
  String get genderLabel => 'Jinsi (na zaɓi)';

  @override
  String get genderFemale => 'Mace';

  @override
  String get genderMale => 'Namiji';

  @override
  String get genderOther => 'Ban so in faɗa ba';

  @override
  String get photoOptional => 'Ƙara hoto (na zaɓi)';

  @override
  String get vehicleTitle => 'Motarka';

  @override
  String get vehicleSubtitle => 'Ta yaya za ka tuƙa a Along?';

  @override
  String get plateLabel => 'Lambar mota';

  @override
  String get plateHint => 'misali ABC-123-XY';

  @override
  String get seatsLabel => 'Kujeru';

  @override
  String get colorLabel => 'Launi';

  @override
  String get makeModelLabel => 'Kamfani da samfuri';

  @override
  String get ownerQuestion => 'Wannan motarka ce?';

  @override
  String get ownerYes => 'Eh, tawa ce';

  @override
  String get ownerNo => 'A\'a, ta wani ce';

  @override
  String get ownerNameLabel => 'Sunan mai mota';

  @override
  String get ownerPhoneLabel => 'Wayar mai mota';

  @override
  String get documentsTitle => 'Tabbatar da takardunka';

  @override
  String get documentsSubtitle => 'Ɗora kowace takarda don fara tuƙi';

  @override
  String get docStatusNotStarted => 'Ba a fara ba';

  @override
  String get docStatusPending => 'Ana jira';

  @override
  String get docStatusApproved => 'An amince';

  @override
  String get docStatusRejected => 'An ƙi';

  @override
  String get saveAndContinueLater => 'Adana ka ci gaba daga baya';

  @override
  String captureTitle(String document) {
    return 'Ɗauki $document';
  }

  @override
  String get captureGuide => 'Sanya takardar cikin firam';

  @override
  String get takePhoto => 'Ɗauki hoto';

  @override
  String get retakePhoto => 'Sake ɗauka';

  @override
  String get submitDocument => 'Aika takarda';

  @override
  String get ocrReviewTitle => 'Duba bayanan da aka ciro';

  @override
  String get ocrReviewSubtitle => 'Tabbatar da kowane fili kafin aikawa';

  @override
  String ocrSuggestedValue(String value) {
    return 'Shawara: $value';
  }

  @override
  String get ocrConfirmField => 'Yi amfani da wannan';

  @override
  String get ocrFieldConfirmed => 'An tabbatar';

  @override
  String get ocrNoAutoFillNote =>
      'Ba a cika lambobin shaida kai tsaye — danna tabbatar ga kowane fili.';

  @override
  String get pendingTitle => 'Ana tabbatarwa';

  @override
  String get pendingHero => 'Muna duba takardunka';

  @override
  String get pendingExpectedGeneric => 'Yawanci yana ɗaukar kwanakin aiki 1–3';

  @override
  String pendingExpectedHours(int hours) {
    return 'Ana sa ran cikin sa\'o\'i $hours';
  }

  @override
  String get pendingWhatNext =>
      'Za mu sanar da kai idan an amince. Za ka iya tsara hanyarka yayin da kake jira.';

  @override
  String get setupRouteCta => 'Tsara hanyarka yayin da kake jira';

  @override
  String get routesListTitle => 'Hanyoyinka';

  @override
  String get routesAddRoute => 'Ƙara hanya';

  @override
  String get routesEmptyTitle => 'Tsara hanyarka cikin \'yan dannawa';

  @override
  String get routesEmptyBody =>
      'Wallafa tashoshinka da farashi don fasinjoji su same ka a hanyarka ta yau da kullum.';

  @override
  String get routeSuggestedCardTitle => 'Hanyar da aka ba da shawara';

  @override
  String routeSuggestedCardBody(String mode, int stopCount) {
    return 'Mun gano hanyar $mode ta yau da kullum mai tasha $stopCount.';
  }

  @override
  String get routeSuggestedCardCta => 'Danna don dubawa da wallafawa';

  @override
  String routeUnnamedProfile(String mode) {
    return 'Hanyar $mode';
  }

  @override
  String routeStopsCount(int count) {
    return 'Tasha $count';
  }

  @override
  String routeLoadSurchargeLabel(String amount) {
    return 'Ƙarin kuɗin kaya: $amount';
  }

  @override
  String get routeLoadSurchargeOptional => 'Ƙarin kuɗin kaya (na zaɓi)';

  @override
  String get routeLoadSurchargeHint => 'misali 50';

  @override
  String get routeFastSetupTitle => 'Tsara hanya';

  @override
  String get routeFastSetupQuestion => 'Wannan hanyarka ce?';

  @override
  String routeFastSetupSubtitle(int count) {
    return 'An gano tasha $count daga hanyarka ta yau da kullum';
  }

  @override
  String get routeYesPublish => 'Eh, wallafa';

  @override
  String get routeEditPrices => 'Gyara farashi';

  @override
  String get routeDrawManually => 'A\'a, zana da hannu';

  @override
  String get routeDrawTitle => 'Zana hanyarka';

  @override
  String get routeDrawHint => 'Danna taswira don ƙara tashoshi';

  @override
  String get routeDrawEmptyStops => 'Ƙara aƙalla tasha biyu a taswira';

  @override
  String get routePublish => 'Wallafa';

  @override
  String routePriceToEnd(String amount) {
    return 'Zuwa ƙarshe: $amount';
  }

  @override
  String routeSnapMatched(String name) {
    return 'An daidaita: $name ✓';
  }

  @override
  String get routeSnapNewStopHint => 'Sabuwar tasha — suna?';

  @override
  String get routeSnapPending => 'Ana daidaitawa…';

  @override
  String get routePriceKeypadTitle => 'Saita farashi zuwa ƙarshe';

  @override
  String get routePriceKeypadSet => 'Saita';

  @override
  String get routePriceErrorNonMonotone =>
      'Kada farashi ya ƙaru yayin zuwa inda za a je.';

  @override
  String get routePriceErrorLastNotZero => 'Tasha ta ƙarshe dole ta zama ₦0.';

  @override
  String get routePriceErrorEmpty => 'Ƙara aƙalla tasha ɗaya mai farashi.';

  @override
  String get routeLoadError => 'Ba a iya lodi hanyoyi ba.';

  @override
  String get routePublishError => 'Ba a iya wallafa hanya ba. Sake gwadawa.';

  @override
  String get back => 'Koma';

  @override
  String get navHome => 'Gida';

  @override
  String get navRoutes => 'Hanyoyi';

  @override
  String get navEarnings => 'Kuɗi';

  @override
  String get navAccount => 'Asusu';

  @override
  String get homeUnverifiedBanner => 'Kammala tabbatarwa don shiga aiki.';

  @override
  String get homeBatteryGuardBanner =>
      'Batir ya yi ƙasa — an rage sabunta wuri don ajiye wuta.';

  @override
  String get homeLedgerBlockedBanner =>
      'An dakatar da haɗawa — biya bashinka don shiga aiki.';

  @override
  String get homeSelectPark => 'A: zaɓi tasha ▾';

  @override
  String homeAtPark(String parkName) {
    return 'A: $parkName ▾';
  }

  @override
  String get homeDirectionOnRoute => 'Hanya: a kan hanyata ▾';

  @override
  String get homeDirectionNone => 'Hanya: babu ▾';

  @override
  String get homeErrorSelectPark => 'Zaɓi tasha kafin ka shiga aiki a tasha.';

  @override
  String get homeErrorLocation => 'Kunna wuri don shiga aiki.';

  @override
  String get homeParkPickerTitle => 'Tashoshi kusa';

  @override
  String get homeParkPickerEmpty => 'Babu tasha a kusa.';

  @override
  String homeParkDistance(int meters) {
    return 'Nisan $meters m';
  }

  @override
  String get homeParkSomewhereElse => 'Ina wani wuri';

  @override
  String get incomingRequestTitle => 'Sabuwar buƙata';

  @override
  String incomingRequestCountdown(int seconds) {
    return '${seconds}s';
  }

  @override
  String incomingRequestRiderLine(String name, String rating, int trips) {
    return '$name · $rating · tafiya $trips';
  }

  @override
  String get incomingRequestPickup => 'Ɗauka';

  @override
  String get incomingRequestRoamingPickup => 'Wurin fasinja';

  @override
  String get incomingRequestRoamingPickupMeta =>
      'Tsayar da mota — haɗu a alamar';

  @override
  String incomingRequestCascade(int attempt, int max) {
    return 'Sake gwadawa $attempt cikin $max';
  }

  @override
  String get incomingRequestDropoff => 'Wurin sauka';

  @override
  String incomingRequestPickupMeta(int distance, int eta) {
    return '$distance m · $eta min';
  }

  @override
  String incomingRequestFareLine(String amount, String tierLabel) {
    return 'Fasinja zai biya $amount · $tierLabel';
  }

  @override
  String incomingRequestAlongFee(String amount, String percent) {
    return 'Kuɗin Along $amount · $percent%';
  }

  @override
  String get incomingRequestLoadDefault => 'Fasinja yana da kaya';

  @override
  String incomingRequestLoadDetail(String size, String note) {
    return 'Kaya $size — $note';
  }

  @override
  String get incomingRequestWomenOnly => 'Haɗin mata kawai';

  @override
  String get incomingRequestApproachBandUnder2 => 'ƙasa da min 2';

  @override
  String get incomingRequestApproachBandM2_5 => 'min 2–5';

  @override
  String get incomingRequestApproachBandOver5 => 'min 5+';

  @override
  String get incomingRequestAccept => 'Karɓa';

  @override
  String get incomingRequestDecline => 'Ƙi';

  @override
  String get declineReasonTitle => 'Me ya sa kake ƙi?';

  @override
  String get declineReasonNoRoomForLoad => 'Babu wurin kaya';

  @override
  String get declineReasonTooFar => 'Ya yi nisa';

  @override
  String get declineReasonEndingShift => 'Ina gama aiki';

  @override
  String get declineReasonOther => 'Wani';

  @override
  String get fareTierStandard => 'Kuɗin da aka saba';

  @override
  String get fareTierCommunity => 'Kuɗin jama\'a';

  @override
  String get fareTierProfile => 'Farashin direba';

  @override
  String get fareTierEstimate => 'Kimanin — yarda da farashi';

  @override
  String pricingRiderOffer(String amount) {
    return 'Fasinja ya ba da $amount';
  }

  @override
  String get pricingLapsed =>
      'Babu yarjejeniya — fasinja na iya zaɓar wata mota';

  @override
  String get pricingOutOfRange => 'Motar ta wuce — an rufe ciniki';

  @override
  String get pricingDeclined => 'Ka ƙi wannan kuɗi';

  @override
  String get pricingDismiss => 'Koma taswira';

  @override
  String get manifestTitle => 'Tafiye-tafiye masu aiki';

  @override
  String get manifestEmpty => 'Babu fasinjojin da aka karɓa tukuna';

  @override
  String manifestBoarding(String stage) {
    return 'Hawa: $stage';
  }

  @override
  String manifestStatus(String status) {
    return 'Matsayi: $status';
  }

  @override
  String get manifestMarkBoarded => 'Ya hau';

  @override
  String manifestOpen(int count) {
    return 'Tafiye-tafiye masu aiki ($count)';
  }

  @override
  String get activeTripStart => 'Fara tafiya';

  @override
  String get activeTripComplete => 'Kammala tafiya';

  @override
  String activeTripBoardAlight(String board, String alight) {
    return '$board → $alight';
  }

  @override
  String activeTripWalkEta(int minutes) {
    return 'Tafiyar ƙafa min $minutes';
  }

  @override
  String get activeTripStalledCaption => 'ba ya ƙara kusantowa';

  @override
  String get activeTripRelease => 'Saki';

  @override
  String get activeTripReport => 'Kai rahoto';

  @override
  String get sosTeamAlerted => 'A shirye don kiran 112';

  @override
  String get sosSharingDetails => 'Raba wurinka kai tsaye da abokan hulɗarka';

  @override
  String sosCallEmergency(String number) {
    return 'Kira $number';
  }

  @override
  String get sosHoldToCancel => 'Riƙe don soke';

  @override
  String get sosRaising => 'Ana buɗe kiran 112…';

  @override
  String get sosRaiseFailed => 'Ba a iya buɗe kiran 112 ba';

  @override
  String get sosRetry => 'Sake gwadawa';

  @override
  String get reportIncidentTitle => 'Kai rahoton abin da ya faru';

  @override
  String get reportIncidentCategoryHeading => 'Me ya faru?';

  @override
  String get reportIncidentDescriptionHeading => 'Ƙara mana bayani';

  @override
  String get reportIncidentDescriptionHint =>
      'Bayyana abin da ya faru (cikakken bayani yana taimakawa)';

  @override
  String get reportIncidentSubmit => 'Aika rahoto';

  @override
  String get reportIncidentPickCategory => 'Zaɓi rukuni';

  @override
  String get reportIncidentDescriptionRequired => 'Ƙara taƙaitaccen bayani';

  @override
  String get reportIncidentSubmitted => 'An adana rahoto a wannan wayar';

  @override
  String get incidentCategorySafety => 'Damuwar tsaro';

  @override
  String get incidentCategoryFareDispute => 'Saɓani kan kuɗi';

  @override
  String get incidentCategoryVehicleQuality => 'Yanayin mota';

  @override
  String get incidentCategoryDriverBehavior => 'Halin direba';

  @override
  String get incidentCategoryLostItem => 'Abin da ya ɓace';

  @override
  String get incidentCategoryOther => 'Wani';

  @override
  String get accountProfileHeading => 'BAYANAN KAI';

  @override
  String get accountProfileUnknown => 'Direba';

  @override
  String get accountVerified => 'An tabbatar';

  @override
  String get accountUnverified => 'Ba a tabbatar ba';

  @override
  String get accountVehicleHeading => 'MOTA';

  @override
  String get accountVehicleActiveHint => 'Mota mai aiki';

  @override
  String get accountVehicleEmpty => 'Ƙara motarka';

  @override
  String get accountVehicleSwitchHint => 'Tuntuɓi tallafi don canza mota';

  @override
  String get accountDocumentsHeading => 'TAKARDU';

  @override
  String get accountDocumentsAllApproved => 'An amince da duk takardu';

  @override
  String get accountDocumentsPending => 'Takardu suna jiran dubawa';

  @override
  String get accountDocumentsNeedsAttention =>
      'Wasu takardu suna buƙatar kulawa';

  @override
  String get accountDocumentsIncomplete => 'Takardu ba su cika ba';

  @override
  String get accountDocumentsUnknown => 'Ba a san matsayin takarda ba';

  @override
  String get accountPayoutHeading => 'BIYA';

  @override
  String get accountPayoutBank => 'Bankin karɓa';

  @override
  String accountPayoutConfigured(String last4) {
    return 'Banki mai ƙarewa da $last4';
  }

  @override
  String get accountPayoutNotConfigured => 'Saita bankin karɓa';

  @override
  String get accountPreferencesHeading => 'ZAƁUƁUKA';

  @override
  String get accountCityLabel => 'Birnin aiki';

  @override
  String get accountCityHint =>
      'Taswira, wuraren pack da buƙatu suna amfani da wannan birni';

  @override
  String get accountLanguage => 'Harshe';

  @override
  String get accountLanguageValue => 'Hausa';

  @override
  String get accountSafetyHeading => 'TSARO';

  @override
  String get accountSafetyHowSos => 'Yadda SOS ke aiki';

  @override
  String get accountSafetyHowSosBody =>
      'Riƙe SOS don kiran 112 da raba wurinka da abokan hulɗa';

  @override
  String get accountHelp => 'Taimako';

  @override
  String get accountLegal => 'Doka';

  @override
  String get accountSignOut => 'Fita';

  @override
  String get homeLedgerBlockedTitle => 'An dakatar da haɗawa';

  @override
  String homeLedgerBlockedBalance(String amount) {
    return 'Ma\'auni $amount';
  }

  @override
  String homeLedgerBlockedThreshold(String amount) {
    return 'Iyakar toshewa $amount';
  }

  @override
  String get settleCta => 'Biya';

  @override
  String get settleTitle => 'Biya bashi';

  @override
  String settleCurrentBalance(String amount) {
    return 'Ma\'auni na yanzu: $amount';
  }

  @override
  String get settleAmountLabel => 'Kuɗin da za a biya';

  @override
  String get settleChannelBank => 'Turawar banki';

  @override
  String get settleChannelUssd => 'USSD';

  @override
  String get settleChannelCard => 'Kati';

  @override
  String get settleChannelAgent => 'Biya wakili';

  @override
  String get settleAgentCodeTitle => 'Lambar wakilinka';

  @override
  String settleAgentExpires(String time) {
    return 'Zai ƙare $time';
  }

  @override
  String get settleNearbyAgentsTitle => 'Wakilai kusa';

  @override
  String settleNearbyAgentDistance(int distance) {
    return 'Nisan $distance m';
  }

  @override
  String get settleDone => 'An gama';

  @override
  String get earningsLedgerSection => 'Ayyukan ma\'auni';

  @override
  String get earningsTripsSection => 'TAFIYE-TAFIYE';

  @override
  String get earningsLedgerEmpty => 'Babu shigarwar littafi tukuna';

  @override
  String get earningsTripsCaption =>
      'Tsabar kuɗin da ka karɓa kai tsaye — ba ya cikin ma\'aunin Along';

  @override
  String get earningsTripsEmpty =>
      'Babu tafiyar tsabar kuɗi da aka kammala yau';

  @override
  String earningsTripsTodaySummary(int count, String amount) {
    return 'Tafiya $count yau · an karɓi $amount';
  }

  @override
  String get standingLink => 'Matsayi';

  @override
  String get standingTitle => 'Matsayinka';

  @override
  String standingBalanceAt(String amount) {
    return 'Ma\'auni a lokacin sauyi: $amount';
  }

  @override
  String standingBlockThreshold(String amount) {
    return 'Daidaitawa na tsayawa idan bashin ya wuce $amount';
  }

  @override
  String standingGraceDeadline(String date) {
    return 'Wa\'adin jinkiri: $date';
  }

  @override
  String get standingRestoreHint =>
      'Biya sama da iyakar gargaɗi don dawo da kyakkyawan matsayi';

  @override
  String get standingHistoryTitle => 'TARIHI';

  @override
  String get standingHistoryEmpty => 'Babu canjin matsayi tukuna';

  @override
  String get guarantorLink => 'Ƙara mai lamuni';

  @override
  String get guarantorTitle => 'Mai lamuni';

  @override
  String get guarantorExplainer =>
      'Ana sanar da mai lamuninka idan bashinka bai biya ba bayan lokacin jinkiri. Ba a taɓa cire komai daga gare shi ba.';

  @override
  String get guarantorTypeDriver => 'Abokin direba';

  @override
  String get guarantorTypeOwner => 'Mai mota';

  @override
  String get guarantorNameLabel => 'Cikakken suna';

  @override
  String get guarantorPhoneLabel => 'Lambar waya';

  @override
  String get guarantorSubmit => 'Ƙara mai lamuni';

  @override
  String get guarantorSuccess =>
      'An ƙara mai lamuni — zai karɓi hanyar tabbatarwa';

  @override
  String get extendTripTitle => 'Tsawaita tafiya';

  @override
  String get extendTripSearchHint => 'Ina yanzu?';

  @override
  String extendTripDestination(String destination) {
    return 'Ana ci gaba zuwa $destination';
  }

  @override
  String get extendTripPropose => 'Ba fasinja shawara';

  @override
  String get incomingExtensionTitle => 'Buƙatar tsawaitawa';

  @override
  String get incomingExtensionDecline => 'Ƙi';

  @override
  String get incomingExtensionAccept => 'Karɓa';

  @override
  String incomingRiderExtensionBody(String destination, String delta) {
    return 'Fasinja yana so a ci gaba zuwa $destination kan +$delta';
  }

  @override
  String get tripCompleteTitle => 'An kammala tafiya';

  @override
  String tripCompleteFareLine(String amount) {
    return 'Kuɗi $amount — fasinja zai biya ka tsabar kuɗi';
  }

  @override
  String tripCompleteAlongFeeLine(String amount) {
    return 'Kuɗin Along $amount — an saka a ma\'auninka';
  }

  @override
  String tripCompleteNewBalance(String amount) {
    return 'Sabon ma\'auni $amount';
  }

  @override
  String get tripCompleteCashQuestion => 'Ka tabbatar ka karɓi tsabar kuɗi?';

  @override
  String get tripCompleteYes => 'Eh';

  @override
  String get tripCompleteDifferent => 'Wani adadi daban';

  @override
  String get tripCompleteDifferentPrompt => 'Nawa ka karɓa?';

  @override
  String get tripCompleteRateTitle => 'Yi wa fasinjanka ƙima';

  @override
  String get tripCompleteDone => 'An gama';

  @override
  String get requestPayment => 'Nemi biya';

  @override
  String tripCompleteDigitalLine(String amount) {
    return 'An biya ta yanar gizo · $amount an tura bankinka';
  }

  @override
  String tripCompleteDigitalFeeLine(String amount) {
    return 'An riga an cire kuɗin Along $amount';
  }

  @override
  String get myQrTitle => 'Lambar QR ta';

  @override
  String get myQrAccountSubtitle =>
      'Raba lambarka don biyan kuɗi ta yanar gizo';

  @override
  String get myQrDigitalDisabledBanner =>
      'Biyan kuɗi ta yanar gizo bai fara aiki ba — QR ɗinka don saiti da gwaji ne kawai.';

  @override
  String get myQrPayoutPrompt => 'Saita bankin karɓa';

  @override
  String get myQrPayoutHint =>
      'Ƙara asusun bankinka don fasinjoji su biya ka ta yanar gizo. Along ba ya riƙe kuɗinka.';

  @override
  String get myQrSetupPayout => 'Saita bankin karɓa';

  @override
  String get myQrPayoutComingSoon =>
      'Saitin karɓar kuɗi zai buɗe daga Asusu idan biyan kuɗi ta yanar gizo ya fara.';

  @override
  String get myQrShare => 'Raba a matsayin hoto';

  @override
  String get myQrOrderSticker => 'Yi odar sitika';

  @override
  String myQrStickerStatus(String status) {
    return 'Buƙatar sitika: $status';
  }

  @override
  String get myQrVerifySticker => 'Tabbatar da sitikata';

  @override
  String get myQrVerifyMatch => 'Sitika ta dace da lambarka da lambar mota';

  @override
  String get myQrVerifyMismatch => 'Wannan sitika ba ta dace da asusunka ba';

  @override
  String get myQrVerifyInvalid => 'Ba lambar QR ta Along ba ce';

  @override
  String get myQrVerifyTimeout => 'Lokacin duba ya ƙare — sake gwadawa';

  @override
  String get myQrPauseDigital => 'Dakatar da biya ta yanar gizo';

  @override
  String get myQrPauseDigitalHint =>
      'Fasinjoji za su ga tsabar kuɗi kawai lokacin dakatarwa';

  @override
  String get myQrPausedBanner =>
      'An dakatar da biya ta yanar gizo — fasinjoji suna ganin tsabar kuɗi kawai';

  @override
  String get myQrRotate => 'Canza lamba';

  @override
  String get myQrRotateConfirmTitle => 'Canza lambar QR?';

  @override
  String get myQrRotateConfirmBody =>
      'Sitikunka na yanzu za su daina aiki. Ma\'aikata za su buga sababbi.';

  @override
  String get myQrRotateCancel => 'Soke';

  @override
  String get myQrRotateConfirm => 'Canza';

  @override
  String get paymentRequestTitle => 'Buƙatar biya';

  @override
  String paymentRequestForRider(String riderName) {
    return 'Ga $riderName';
  }

  @override
  String paymentRequestCountdown(int seconds) {
    return 'Zai ƙare cikin ${seconds}s';
  }

  @override
  String get paymentRequestWaiting => 'Ana jiran biya…';

  @override
  String paymentRequestPaidLine(String amount) {
    return 'An biya $amount ✓';
  }

  @override
  String paymentRequestBankLine(String amount) {
    return '$amount zuwa bankinka';
  }

  @override
  String get paymentRequestDone => 'An gama';

  @override
  String get paymentRequestExpired => 'Wannan QR ta ƙare — ƙirƙiri sabuwa';

  @override
  String get paymentRequestDigitalDisabled =>
      'Biya ta yanar gizo bai fara ba tukuna';

  @override
  String get paymentRequestTokenError =>
      'Ba a iya tabbatar da QR na biya ba — sake gwadawa';

  @override
  String get earningsDigitalSection => 'Biyan dijital';

  @override
  String get earningsDigitalCaption =>
      'An biya kai tsaye zuwa bankinka — ba ya cikin ma\'aunin Along';

  @override
  String get earningsDigitalEmpty => 'Babu biya ta yanar gizo tukuna';

  @override
  String earningsDigitalRow(String source) {
    return 'Yanar gizo · $source';
  }

  @override
  String get sosQueued =>
      'An adana a wannan wayar. Kira 112 idan ka dawo kan layi.';

  @override
  String get sosLiveLink => 'Kwafi hanyar wuri kai tsaye';

  @override
  String get sosLiveLinkCopied => 'An kwafi hanyar wuri kai tsaye';

  @override
  String get sosContactsHeading => 'Faɗa wa wanda ka amince da shi';

  @override
  String sosContactWhatsapp(String name) {
    return 'WhatsApp $name';
  }

  @override
  String sosContactSms(String name) {
    return 'Tura saƙo ga $name';
  }

  @override
  String get emergencyContactsHeading => 'ABOKAN HULƊA NA GAGGAWA';

  @override
  String get emergencyContactsHint =>
      'Muna sanar da waɗannan mutane idan ka danna SOS. Har zuwa 5. WhatsApp ko saƙo zai buɗe a wayarka.';

  @override
  String get emergencyContactsEmpty => 'Babu abokan hulɗa na gaggawa tukuna';

  @override
  String get emergencyContactName => 'Suna';

  @override
  String get emergencyContactPhone => 'Waya';

  @override
  String get emergencyContactAdd => 'Ƙara lamba';

  @override
  String emergencyContactRemove(String name) {
    return 'Cire $name';
  }

  @override
  String get emergencyContactInvalidPhone =>
      'Yi amfani da lamba kamar +2348012345678';

  @override
  String get emergencyContactLimit => 'Za ka iya adana har abokan hulɗa 5';

  @override
  String get emergencyContactSaveFailed =>
      'Ba a iya adana wannan abokin hulɗa ba';

  @override
  String get buildMyDayTitle => 'Gina ranata';

  @override
  String get buildMyDayStart => 'Adana ka yi amfani da wannan rana';

  @override
  String get buildMyDayCorridor => 'Hanya';

  @override
  String get saveLayout => 'Adana tsari';

  @override
  String get layoutName => 'Sunan tsari';

  @override
  String get addRow => 'Ƙara layi';

  @override
  String get addSeat => 'Ƙara kujera';

  @override
  String get removeRow => 'Cire layi';

  @override
  String get overCapacityNote =>
      'Wannan ya wuce adadin kujeru na yau da kullum. An adana shi kuma an yi masa alama don dubawa.';

  @override
  String get seatMapTitle => 'Taswirar kujeru';

  @override
  String get seatFull => 'Ya cika';

  @override
  String get seatEmpty => 'Fanko';

  @override
  String get seatFree => 'fanko';

  @override
  String get seatOccupied => 'an zauna';

  @override
  String get seatHeld => 'an riƙe';

  @override
  String get seatBlocked => 'an toshe';

  @override
  String get seatDriver => 'direba';

  @override
  String get rideRulesHeading => 'Dokokin tafiya';

  @override
  String get customRuleHint => 'Taken doka';

  @override
  String get customRuleBody => 'Abin da fasinjoji ya kamata su sani';

  @override
  String get customRuleSave => 'Ƙara dokata';

  @override
  String get holdMinutes => 'Mintunan riƙewa';

  @override
  String get capMax => 'Iyakar kujeru';

  @override
  String get deleteRule => 'Cire doka';

  @override
  String get dayNeedsCorridor => 'Zaɓi hanya';

  @override
  String get seatStale => 'Taswirar kujeru ta wuce minti ɗaya';

  @override
  String get shiftStart => 'Aiki zai fara';

  @override
  String get shiftEnd => 'Aiki zai ƙare';

  @override
  String get homeLabel => 'Tashar komawa gida';

  @override
  String get walkExtension =>
      'Ƙarin mintunan riƙewa ga fasinja mai tafiya da ƙafa';

  @override
  String get seatLuggage => 'kaya';

  @override
  String get voiceCommandHint =>
      'Faɗi karɓa, cike, ko kujerar baya ta hagu fanko';

  @override
  String get conductorOpen => 'Lambar kwandasta';

  @override
  String get conductorTitle => 'Kwandasta';

  @override
  String get conductorCode => 'Lamba daga direba';

  @override
  String get conductorJoin => 'Buɗe taswirar kujeru';

  @override
  String get ghostSeatTitle => 'Har yanzu an zauna bayan sauka?';

  @override
  String get ghostSeatFree => 'Sake shi';

  @override
  String freeSeatCount(int count) {
    return '$count babu kowa';
  }

  @override
  String get restTitle => 'Hutu';

  @override
  String get restDriveMinutes => 'Mintunan tuƙi kafin hutu';

  @override
  String get restMinutes => 'Mintunan hutu';

  @override
  String get restSave => 'Adana';

  @override
  String get restStart => 'Fara hutu';

  @override
  String get restFinish => 'Gama hutu';

  @override
  String get restPriority =>
      'Fifiko wajen tura aiki har lokacin hutunka ya ƙare';

  @override
  String get marketplaceTitle => 'Yau';

  @override
  String get marketplaceGoal => 'Burin yau';

  @override
  String get marketplaceEarned => 'An riga an samu';

  @override
  String get marketplaceTypical => 'Kuɗin kujera na yau da kullum';

  @override
  String marketplaceSeats(int count) {
    return 'Saura kujeru $count';
  }

  @override
  String get marketplaceGoalMet => 'An cimma buri';

  @override
  String get marketplaceSave => 'Adana';

  @override
  String get marketplaceCorridor => 'Hanyar da kake kallo';

  @override
  String get marketplaceRequests => 'Buƙatu';

  @override
  String get marketplaceAddCorridor => 'Ƙara';

  @override
  String marketplaceTip(String corridor) {
    return 'Shiga layi zuwa $corridor';
  }

  @override
  String get marketplaceFuel => 'Farashin lita';

  @override
  String get marketplaceFuelLabel => 'Famfo';

  @override
  String get marketplaceFuelSave => 'Adana farashi';

  @override
  String get marketplaceEventName => 'Sunan taro';

  @override
  String get marketplaceEventHours => 'Sa\'o\'in da wurin zai kasance a buɗe';

  @override
  String get marketplaceEventSave => 'Buɗe wurin';

  @override
  String activeTripMessageRider(String name) {
    return 'Aika wa $name saƙo';
  }

  @override
  String get activeTripMessageRiderUnknown => 'Aika wa fasinja saƙo';

  @override
  String get tripEtaCalculating => 'Ana lissafi…';

  @override
  String tripEtaPickup(String label) {
    return 'Dauka $label';
  }

  @override
  String get drivePhasePickup => 'Ɗauka';

  @override
  String get drivePhaseBoard => 'Shiga';

  @override
  String get drivePhaseDrop => 'Sauke';

  @override
  String activeTripPickUpTitle(String name) {
    return 'Ɗauki $name';
  }

  @override
  String activeTripOnBoardTitle(String name) {
    return '$name ya shiga';
  }

  @override
  String activeTripDropTitle(String name) {
    return 'Sauke $name';
  }

  @override
  String get activeTripRiderFallback => 'fasinjanka';

  @override
  String get activeTripBoardNaMe => 'Shiga da Na Me';

  @override
  String get activeTripEnterPin => 'Saka PIN na ɗauka';

  @override
  String get activeTripPinShort => 'PIN';

  @override
  String get activeTripMessageShort => 'Saƙo';

  @override
  String get activeTripSeatsShort => 'Kujeru';

  @override
  String get activeTripExtendShort => 'Tsawaita';

  @override
  String get activeTripReportShort => 'Rahoto';

  @override
  String get activeTripFareLabel => 'Fasinja zai biya';

  @override
  String activeTripFeeCaption(String amount, String percent) {
    return 'Kuɗin Along $amount ($percent%)';
  }

  @override
  String incomingAcceptFare(String amount) {
    return 'Karɓa · $amount';
  }

  @override
  String incomingFareCaption(String tierLabel) {
    return 'Fasinja zai biya · $tierLabel';
  }

  @override
  String get homeOfflineTitle => 'Ba ka kan layi';

  @override
  String get homeOnlineTitle => 'Kana kan layi';

  @override
  String get homeOfflineHint => 'Shiga layi don samun buƙatu kusa da kai.';

  @override
  String get homeOnlineHint =>
      'Buƙatu za su bayyana nan. Karɓa da taɓawa ɗaya.';

  @override
  String get homeGoOnline => 'MU JE';

  @override
  String get homeGoOffline => 'Fita daga layi';

  @override
  String get homeModeAtPark => 'A tasha';

  @override
  String get homeModeRoaming => 'Yawo';

  @override
  String get homeModeFull => 'Ya cika';

  @override
  String homeTodayEarned(String amount) {
    return 'Yau · $amount';
  }

  @override
  String homeTodayTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tafiya $count',
      one: 'Tafiya 1',
      zero: 'Babu tafiya tukuna',
    );
    return '$_temp0';
  }

  @override
  String get homeShortcutsTitle => 'Ranarka';

  @override
  String get homeDirectionShortOnRoute => 'Kan hanyata';

  @override
  String get homeDirectionShortNone => 'Kowace hanya';

  @override
  String get homeTileDemand => 'Buƙata';

  @override
  String get tripCompleteCashHero => 'Karɓi kuɗi a hannu';

  @override
  String get tripCompleteRowFare => 'Kuɗin mota';

  @override
  String get tripCompleteRowFee => 'Kuɗin Along (zuwa ma\'auni)';

  @override
  String get tripCompleteRowBalance => 'Sabon ma\'auni';

  @override
  String tripCompleteYesAmount(String amount) {
    return 'Eh, na karɓi $amount';
  }

  @override
  String get settleSubtitle => 'Asusun ka na Along';

  @override
  String get settleOwedLabel => 'Bashin Along a kanka';

  @override
  String get settleCreditLabel => 'Ma\'aunin ka';

  @override
  String settleThreshold(String amount) {
    return 'Daidaitawa na tsayawa idan bashin ya wuce $amount';
  }

  @override
  String get settleMethodTitle => 'Biya da';

  @override
  String settleSubmit(String amount) {
    return 'Biya $amount';
  }

  @override
  String get settleChannelBankDetail => 'Tura zuwa asusun Along';

  @override
  String get settleChannelUssdDetail => 'Danna lamba, ba data';

  @override
  String get settleChannelCardDetail => 'Katin banki';

  @override
  String get settleChannelAgentDetail => 'Biya kuɗi a wurin wakilin Along';

  @override
  String earningsBalanceAfter(String amount) {
    return 'Ma\'auni $amount';
  }

  @override
  String get ratingTagSafeDriving => 'Tuki lafiya';

  @override
  String get ratingTagFairFare => 'Kuɗi daidai';

  @override
  String get ratingTagCleanVehicle => 'Mota mai tsabta';

  @override
  String get ratingTagPolite => 'Mai ladabi';

  @override
  String get ratingTagOnTime => 'A kan lokaci';

  @override
  String get ratingTagReady => 'A shirye a wurin ɗauka';

  @override
  String get ratingTagPaidPromptly => 'Ya biya da wuri';

  @override
  String get guarantorWhoTitle => 'Wanda zai tsaya maka';

  @override
  String get guarantorDetailsTitle => 'Bayanansu';

  @override
  String get seatToolsTitle => 'Kayan aiki';

  @override
  String get seatBoardEmptyBody =>
      'Tsara ranarka don saita kujerun motarka. Sannan za ka iya nuna wanda ke ciki a nan.';

  @override
  String get mpGoalSection => 'Burin yau';

  @override
  String get mpDemandSection => 'Inda fasinjoji suke';

  @override
  String get mpFuelSection => 'Farashin mai';

  @override
  String get mpEventSection => 'Taruka na kusa';

  @override
  String seatBoardSubtitle(int count) {
    return '$count babu kowa · taɓa kujera don sauya ta';
  }

  @override
  String get mpSubtitle =>
      'Saita buri, ga inda fasinjoji suke, ka raba bayanai.';

  @override
  String get mpGoalEmpty => 'Saita buri don ganin kujeru nawa suka rage';

  @override
  String get mpMoreSection => 'Raba wa direbobi';

  @override
  String get mpFuelDetail => 'Farashin mai na yau a kusa';

  @override
  String get mpEventDetail => 'Buɗe wurin ɗauka don taro';

  @override
  String get restSubtitle =>
      'Ka huta sosai bayan dogon tuƙi. Cikakken hutu yana ɗaga ka a layi.';

  @override
  String get restStatusDriving => 'A kan hanya';

  @override
  String restStatusResting(String time) {
    return 'Hutu tun $time';
  }

  @override
  String restPlan(int rest, int drive) {
    return 'Hutun minti $rest kowane minti $drive';
  }

  @override
  String get restPlanEmpty => 'Saita tsawon tuƙi kafin hutu';

  @override
  String get restRhythmSection => 'Tsarinka';

  @override
  String get conductorSubtitle => 'Taimaka wa direba ya sabunta kujeru.';

  @override
  String get conductorHowTo =>
      'Direba zai buɗe Taswirar kujeru → Lambar kondakta ya karanta maka lamba mai haruffa 8.';

  @override
  String get restDriveShort => 'Tuƙi (minti)';

  @override
  String get restBreakShort => 'Hutu (minti)';

  @override
  String get mpTargetShort => 'Buri';

  @override
  String get mpEarnedShort => 'An samu';

  @override
  String get daySubtitle =>
      'Zaɓi inda za ka yi aiki, saita kujeru da dokokin da fasinjoji za su gani.';

  @override
  String daySeatsCount(int count) {
    return 'Kujeru $count';
  }

  @override
  String get dayRouteOptional => 'Hanya (zaɓi)';

  @override
  String get dayHoursSection => 'Lokutanka';

  @override
  String get daySeatsSection => 'Kujeru';

  @override
  String get dayRemove => 'Cire';

  @override
  String get dayAddRule => 'Ƙara doka';

  @override
  String get dayRuleRow => 'Ya shafi';

  @override
  String dayRowN(int n) {
    return 'Layi $n';
  }

  @override
  String get dayRuleDetails => 'Bayanin doka';

  @override
  String get dayRuleDetailsBody =>
      'Lokacin jira, ƙarin tafiya, iyakar kujeru, kalmomi';

  @override
  String get dayCustomRule => 'Rubuta dokarka';

  @override
  String get dayCustomRuleBody => 'Ana nuna wa fasinjoji kafin su yi rajista';

  @override
  String get howItWorks => 'Yadda yake aiki';

  @override
  String get conductorStep1 => 'Karɓi lambar';

  @override
  String get conductorStep1Body => 'Direba yana raba ta daga taswirar kujeru';

  @override
  String get conductorStep2 => 'Shiga motar';

  @override
  String get conductorStep2Body => 'Kana ganin kujeru ɗaya kai tsaye';

  @override
  String get conductorStep3 => 'Sabunta kujeru';

  @override
  String get conductorStep3Body =>
      'Taɓa kujera idan fasinja ya hau ko ya sauka';

  @override
  String get seatEmptyStep1 => 'Zaɓi motarka';

  @override
  String get seatEmptyStep1Body => 'Za mu zana kujerunta';

  @override
  String get seatEmptyStep2 => 'Zaɓi hanya';

  @override
  String get seatEmptyStep2Body => 'Fasinjoji a kanta suna ganin kujerunka';

  @override
  String get seatEmptyStep3 => 'Cika kujeru yayin tafiya';

  @override
  String get seatEmptyStep3Body => 'Taɓa kujera don alamta ta';

  @override
  String get connOffline => 'Babu intanet · za ka iya ci gaba';

  @override
  String connOfflineQueued(int count) {
    return 'Babu intanet · $count an ajiye don aikawa';
  }

  @override
  String get connReconnecting => 'Ana sake haɗawa';

  @override
  String connSending(int count) {
    return 'Ana sake haɗawa · ana aika $count';
  }

  @override
  String get connRestored => 'An dawo kan layi';

  @override
  String connRestoredSent(int count) {
    return 'An dawo kan layi · an aika $count';
  }

  @override
  String get connRetry => 'Sake gwadawa';

  @override
  String connNeedsConnection(int count) {
    return 'Babu intanet · $count a sake yi da intanet';
  }

  @override
  String connOfflineMixed(int queued, int needs) {
    return 'Babu intanet · $queued za a aika · $needs a sake';
  }

  @override
  String get homeOnlineNoSignal => 'A kan layi · babu sigina';

  @override
  String get authYourNumber => 'Lambar wayarka';

  @override
  String get authSendCode => 'Tura min lambar sirri';

  @override
  String get otpCheckTitle => 'Duba saƙonninka';

  @override
  String get otpChecking => 'Ana duba lambar…';

  @override
  String get otpAutofillHint => 'Lambar za ta cika da kanta idan saƙon ya iso.';

  @override
  String get authOffline => 'Ba ka da intanet. Haɗa don samun lambarka.';

  @override
  String get permSubtitle =>
      'Along zai tambaya sau ɗaya. Za ka iya canza wannan a Saituna.';

  @override
  String get permLocationTitle => 'Wuri';

  @override
  String get permNotifTitle => 'Sanarwa';

  @override
  String get permCameraTitle => 'Kyamara';

  @override
  String get permAllow => 'Ba da izini';

  @override
  String get permLater => 'Ba yanzu ba';

  @override
  String get authStory1H => 'Tuƙa tare da Along.';

  @override
  String get authStory1B => 'Fasinjoji suna samunka a tasha da kan hanya.';

  @override
  String get authStory2H => 'Farashinka, hanyarka.';

  @override
  String get authStory2B => 'Saita kuɗi bisa tasha kuma a biya ka nan take.';

  @override
  String get authStory3H => 'Lafiya a kowace tafiya.';

  @override
  String get authStory3B => 'Fasinjoji da aka tabbatar da SOS a riƙo ɗaya.';

  @override
  String get permTitle => 'Shirye don tuƙi';

  @override
  String get permLocationBody =>
      'Nuna wa fasinjoji inda kake yayin da kake kan layi.';

  @override
  String get permNotifBody => 'Ji labarin sabbin buƙatu da biyan kuɗi.';

  @override
  String get permCameraBody => 'Ɗauki hoton takardunka kuma duba lambobin QR.';

  @override
  String get otpDidntGet => 'Ba ka samu ba?';
}
