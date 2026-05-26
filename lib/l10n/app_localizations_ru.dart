// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get errorNoSheetId => 'Укажите ID Google Таблицы в настройках';

  @override
  String get errorNetwork =>
      'Не удалось обновить слова. Проверьте подключение к сети.';

  @override
  String wordReading(String reading) {
    return 'Чтение: $reading';
  }

  @override
  String wordTranslation(String translation) {
    return 'Перевод: $translation';
  }

  @override
  String wordProgress(String progress) {
    return 'Прогресс: $progress / 5';
  }

  @override
  String wordLastTrained(String date) {
    return 'Посл. тренировка: $date';
  }

  @override
  String get never => 'Никогда';

  @override
  String get close => 'Закрыть';

  @override
  String get searchHint => 'Поиск (ru/jp)...';

  @override
  String get syncTooltip => 'Синхронизировать';

  @override
  String get noWordsFound => 'Нет слов для отображения';

  @override
  String get noWordsForTraining => 'Нет слов для тренировки';

  @override
  String get trainingResultsTitle => 'Результаты тренировки';

  @override
  String get trainingResultsPerfect => 'Отлично! Ни одной ошибки! 🎉';

  @override
  String trainingResultsMistakes(String count) {
    return 'Слова, где были ошибки ($count):';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsQuestionsCount => 'Количество вопросов в тренировке';

  @override
  String get settingsSheetId => 'ID Google Таблицы';

  @override
  String get settingsSheetIdHint =>
      'Например: 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsDesc =>
      'Напоминать о словах, которые пора повторить';

  @override
  String get settingsAutoTts => 'Авто-озвучка вопросов';

  @override
  String get settingsAutoTtsDesc => 'Озвучивает японские слова';

  @override
  String get errorLoadingSettings => 'Ошибка загрузки настроек';

  @override
  String get tabAllWords => 'Все слова';

  @override
  String get tabCustomLists => 'Списки';

  @override
  String get errorEmptyListName => 'Введите название списка';

  @override
  String get newListTitle => 'Новый список';

  @override
  String get editListTitle => 'Настройки списка';

  @override
  String get listNameLabel => 'Название списка';

  @override
  String get selectWordsLabel => 'Выберите слова:';

  @override
  String get listEmpty => 'В этом списке пока нет слов';

  @override
  String get noCustomLists => 'У вас пока нет кастомных списков';

  @override
  String wordsCount(String count) {
    return 'Слов: $count';
  }

  @override
  String errorLoadingLists(String error) {
    return 'Ошибка загрузки списков: $error';
  }

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get syncOnStartup => 'Загружать при старте приложения';

  @override
  String get deleteList => 'Удалить список';

  @override
  String get editList => 'Редактировать';

  @override
  String get addToAnotherList => 'Добавить в другой список';

  @override
  String get notificationFrequency => 'Частота уведомлений (в минутах)';

  @override
  String get notificationTimeWindow => 'Время уведомлений';

  @override
  String timeStart(String time) {
    return 'С: $time';
  }

  @override
  String timeEnd(String time) {
    return 'До: $time';
  }

  @override
  String get settingsSoundEffects => 'Звуковые эффекты';

  @override
  String get settingsSoundEffectsDesc =>
      'Звуки при правильном и неправильном ответе';

  @override
  String get questionTypes => 'Типы вопросов';

  @override
  String get questionWordToTranslate => 'Японский -> Русский';

  @override
  String get questionTranslateToWord => 'Русский -> Японский';

  @override
  String get questionReading => 'Чтение';

  @override
  String get freq30m => '30 мин';

  @override
  String get freq1h => '1 час';

  @override
  String get freq1_5h => '1,5 часа';

  @override
  String get freq2h => '2 часа';

  @override
  String get freq3h => '3 часа';

  @override
  String get freq6h => '6 часов';

  @override
  String get freq1d => '1 раз в день';
}
