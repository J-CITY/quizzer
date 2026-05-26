import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @errorNoSheetId.
  ///
  /// In ru, this message translates to:
  /// **'Укажите ID Google Таблицы в настройках'**
  String get errorNoSheetId;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить слова. Проверьте подключение к сети.'**
  String get errorNetwork;

  /// No description provided for @wordReading.
  ///
  /// In ru, this message translates to:
  /// **'Чтение: {reading}'**
  String wordReading(String reading);

  /// No description provided for @wordTranslation.
  ///
  /// In ru, this message translates to:
  /// **'Перевод: {translation}'**
  String wordTranslation(String translation);

  /// No description provided for @wordProgress.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс: {progress} / 5'**
  String wordProgress(String progress);

  /// No description provided for @wordLastTrained.
  ///
  /// In ru, this message translates to:
  /// **'Посл. тренировка: {date}'**
  String wordLastTrained(String date);

  /// No description provided for @never.
  ///
  /// In ru, this message translates to:
  /// **'Никогда'**
  String get never;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск (ru/jp)...'**
  String get searchHint;

  /// No description provided for @syncTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизировать'**
  String get syncTooltip;

  /// No description provided for @noWordsFound.
  ///
  /// In ru, this message translates to:
  /// **'Нет слов для отображения'**
  String get noWordsFound;

  /// No description provided for @noWordsForTraining.
  ///
  /// In ru, this message translates to:
  /// **'Нет слов для тренировки'**
  String get noWordsForTraining;

  /// No description provided for @trainingResultsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Результаты тренировки'**
  String get trainingResultsTitle;

  /// No description provided for @trainingResultsPerfect.
  ///
  /// In ru, this message translates to:
  /// **'Отлично! Ни одной ошибки! 🎉'**
  String get trainingResultsPerfect;

  /// No description provided for @trainingResultsMistakes.
  ///
  /// In ru, this message translates to:
  /// **'Слова, где были ошибки ({count}):'**
  String trainingResultsMistakes(String count);

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsQuestionsCount.
  ///
  /// In ru, this message translates to:
  /// **'Количество вопросов в тренировке'**
  String get settingsQuestionsCount;

  /// No description provided for @settingsSheetId.
  ///
  /// In ru, this message translates to:
  /// **'ID Google Таблицы'**
  String get settingsSheetId;

  /// No description provided for @settingsSheetIdHint.
  ///
  /// In ru, this message translates to:
  /// **'Например: 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms'**
  String get settingsSheetIdHint;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In ru, this message translates to:
  /// **'Напоминать о словах, которые пора повторить'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsAutoTts.
  ///
  /// In ru, this message translates to:
  /// **'Авто-озвучка вопросов'**
  String get settingsAutoTts;

  /// No description provided for @settingsAutoTtsDesc.
  ///
  /// In ru, this message translates to:
  /// **'Озвучивает японские слова'**
  String get settingsAutoTtsDesc;

  /// No description provided for @errorLoadingSettings.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки настроек'**
  String get errorLoadingSettings;

  /// No description provided for @tabAllWords.
  ///
  /// In ru, this message translates to:
  /// **'Все слова'**
  String get tabAllWords;

  /// No description provided for @tabCustomLists.
  ///
  /// In ru, this message translates to:
  /// **'Списки'**
  String get tabCustomLists;

  /// No description provided for @errorEmptyListName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название списка'**
  String get errorEmptyListName;

  /// No description provided for @newListTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый список'**
  String get newListTitle;

  /// No description provided for @editListTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки списка'**
  String get editListTitle;

  /// No description provided for @listNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название списка'**
  String get listNameLabel;

  /// No description provided for @selectWordsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Выберите слова:'**
  String get selectWordsLabel;

  /// No description provided for @listEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В этом списке пока нет слов'**
  String get listEmpty;

  /// No description provided for @noCustomLists.
  ///
  /// In ru, this message translates to:
  /// **'У вас пока нет кастомных списков'**
  String get noCustomLists;

  /// No description provided for @wordsCount.
  ///
  /// In ru, this message translates to:
  /// **'Слов: {count}'**
  String wordsCount(String count);

  /// No description provided for @errorLoadingLists.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки списков: {error}'**
  String errorLoadingLists(String error);

  /// No description provided for @copiedToClipboard.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано в буфер обмена'**
  String get copiedToClipboard;

  /// No description provided for @syncOnStartup.
  ///
  /// In ru, this message translates to:
  /// **'Загружать при старте приложения'**
  String get syncOnStartup;

  /// No description provided for @deleteList.
  ///
  /// In ru, this message translates to:
  /// **'Удалить список'**
  String get deleteList;

  /// No description provided for @editList.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get editList;

  /// No description provided for @addToAnotherList.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в другой список'**
  String get addToAnotherList;

  /// No description provided for @notificationFrequency.
  ///
  /// In ru, this message translates to:
  /// **'Частота уведомлений (в минутах)'**
  String get notificationFrequency;

  /// No description provided for @notificationTimeWindow.
  ///
  /// In ru, this message translates to:
  /// **'Время уведомлений'**
  String get notificationTimeWindow;

  /// No description provided for @timeStart.
  ///
  /// In ru, this message translates to:
  /// **'С: {time}'**
  String timeStart(String time);

  /// No description provided for @timeEnd.
  ///
  /// In ru, this message translates to:
  /// **'До: {time}'**
  String timeEnd(String time);

  /// No description provided for @settingsSoundEffects.
  ///
  /// In ru, this message translates to:
  /// **'Звуковые эффекты'**
  String get settingsSoundEffects;

  /// No description provided for @settingsSoundEffectsDesc.
  ///
  /// In ru, this message translates to:
  /// **'Звуки при правильном и неправильном ответе'**
  String get settingsSoundEffectsDesc;

  /// No description provided for @questionTypes.
  ///
  /// In ru, this message translates to:
  /// **'Типы вопросов'**
  String get questionTypes;

  /// No description provided for @questionWordToTranslate.
  ///
  /// In ru, this message translates to:
  /// **'Японский -> Русский'**
  String get questionWordToTranslate;

  /// No description provided for @questionTranslateToWord.
  ///
  /// In ru, this message translates to:
  /// **'Русский -> Японский'**
  String get questionTranslateToWord;

  /// No description provided for @questionReading.
  ///
  /// In ru, this message translates to:
  /// **'Чтение'**
  String get questionReading;

  /// No description provided for @freq30m.
  ///
  /// In ru, this message translates to:
  /// **'30 мин'**
  String get freq30m;

  /// No description provided for @freq1h.
  ///
  /// In ru, this message translates to:
  /// **'1 час'**
  String get freq1h;

  /// No description provided for @freq1_5h.
  ///
  /// In ru, this message translates to:
  /// **'1,5 часа'**
  String get freq1_5h;

  /// No description provided for @freq2h.
  ///
  /// In ru, this message translates to:
  /// **'2 часа'**
  String get freq2h;

  /// No description provided for @freq3h.
  ///
  /// In ru, this message translates to:
  /// **'3 часа'**
  String get freq3h;

  /// No description provided for @freq6h.
  ///
  /// In ru, this message translates to:
  /// **'6 часов'**
  String get freq6h;

  /// No description provided for @freq1d.
  ///
  /// In ru, this message translates to:
  /// **'1 раз в день'**
  String get freq1d;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
