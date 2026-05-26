// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSettingsCollection on Isar {
  IsarCollection<Settings> get settings => this.collection();
}

const SettingsSchema = CollectionSchema(
  name: r'Settings',
  id: -8656046621518759136,
  properties: {
    r'autoPlayVoice': PropertySchema(
      id: 0,
      name: r'autoPlayVoice',
      type: IsarType.bool,
    ),
    r'isMigratedV2': PropertySchema(
      id: 1,
      name: r'isMigratedV2',
      type: IsarType.bool,
    ),
    r'notificationIntervalMinutes': PropertySchema(
      id: 2,
      name: r'notificationIntervalMinutes',
      type: IsarType.long,
    ),
    r'notificationTimeEnd': PropertySchema(
      id: 3,
      name: r'notificationTimeEnd',
      type: IsarType.string,
    ),
    r'notificationTimeStart': PropertySchema(
      id: 4,
      name: r'notificationTimeStart',
      type: IsarType.string,
    ),
    r'notificationsEnabled': PropertySchema(
      id: 5,
      name: r'notificationsEnabled',
      type: IsarType.bool,
    ),
    r'playSoundEffects': PropertySchema(
      id: 6,
      name: r'playSoundEffects',
      type: IsarType.bool,
    ),
    r'questionReading': PropertySchema(
      id: 7,
      name: r'questionReading',
      type: IsarType.bool,
    ),
    r'questionTranslateToWord': PropertySchema(
      id: 8,
      name: r'questionTranslateToWord',
      type: IsarType.bool,
    ),
    r'questionWordToTranslate': PropertySchema(
      id: 9,
      name: r'questionWordToTranslate',
      type: IsarType.bool,
    ),
    r'questionsCount': PropertySchema(
      id: 10,
      name: r'questionsCount',
      type: IsarType.long,
    )
  },
  estimateSize: _settingsEstimateSize,
  serialize: _settingsSerialize,
  deserialize: _settingsDeserialize,
  deserializeProp: _settingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _settingsGetId,
  getLinks: _settingsGetLinks,
  attach: _settingsAttach,
  version: '3.1.0+1',
);

int _settingsEstimateSize(
  Settings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.notificationTimeEnd.length * 3;
  bytesCount += 3 + object.notificationTimeStart.length * 3;
  return bytesCount;
}

void _settingsSerialize(
  Settings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoPlayVoice);
  writer.writeBool(offsets[1], object.isMigratedV2);
  writer.writeLong(offsets[2], object.notificationIntervalMinutes);
  writer.writeString(offsets[3], object.notificationTimeEnd);
  writer.writeString(offsets[4], object.notificationTimeStart);
  writer.writeBool(offsets[5], object.notificationsEnabled);
  writer.writeBool(offsets[6], object.playSoundEffects);
  writer.writeBool(offsets[7], object.questionReading);
  writer.writeBool(offsets[8], object.questionTranslateToWord);
  writer.writeBool(offsets[9], object.questionWordToTranslate);
  writer.writeLong(offsets[10], object.questionsCount);
}

Settings _settingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Settings();
  object.autoPlayVoice = reader.readBool(offsets[0]);
  object.id = id;
  object.isMigratedV2 = reader.readBool(offsets[1]);
  object.notificationIntervalMinutes = reader.readLong(offsets[2]);
  object.notificationTimeEnd = reader.readString(offsets[3]);
  object.notificationTimeStart = reader.readString(offsets[4]);
  object.notificationsEnabled = reader.readBool(offsets[5]);
  object.playSoundEffects = reader.readBool(offsets[6]);
  object.questionReading = reader.readBool(offsets[7]);
  object.questionTranslateToWord = reader.readBool(offsets[8]);
  object.questionWordToTranslate = reader.readBool(offsets[9]);
  object.questionsCount = reader.readLong(offsets[10]);
  return object;
}

P _settingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _settingsGetId(Settings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _settingsGetLinks(Settings object) {
  return [];
}

void _settingsAttach(IsarCollection<dynamic> col, Id id, Settings object) {
  object.id = id;
}

extension SettingsQueryWhereSort on QueryBuilder<Settings, Settings, QWhere> {
  QueryBuilder<Settings, Settings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SettingsQueryWhere on QueryBuilder<Settings, Settings, QWhereClause> {
  QueryBuilder<Settings, Settings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Settings, Settings, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SettingsQueryFilter
    on QueryBuilder<Settings, Settings, QFilterCondition> {
  QueryBuilder<Settings, Settings, QAfterFilterCondition> autoPlayVoiceEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoPlayVoice',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> isMigratedV2EqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMigratedV2',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationIntervalMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationIntervalMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationIntervalMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationIntervalMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationTimeEnd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationTimeEnd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationTimeEnd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationTimeEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notificationTimeEnd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notificationTimeEnd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notificationTimeEnd',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notificationTimeEnd',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationTimeEnd',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeEndIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notificationTimeEnd',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationTimeStart',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationTimeStart',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationTimeStart',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationTimeStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notificationTimeStart',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notificationTimeStart',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notificationTimeStart',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notificationTimeStart',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationTimeStart',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationTimeStartIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notificationTimeStart',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationsEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationsEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      playSoundEffectsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'playSoundEffects',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      questionReadingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionReading',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      questionTranslateToWordEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionTranslateToWord',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      questionWordToTranslateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionWordToTranslate',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> questionsCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      questionsCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'questionsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      questionsCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'questionsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> questionsCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'questionsCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SettingsQueryObject
    on QueryBuilder<Settings, Settings, QFilterCondition> {}

extension SettingsQueryLinks
    on QueryBuilder<Settings, Settings, QFilterCondition> {}

extension SettingsQuerySortBy on QueryBuilder<Settings, Settings, QSortBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy> sortByAutoPlayVoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoPlayVoice', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByAutoPlayVoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoPlayVoice', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByIsMigratedV2() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMigratedV2', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByIsMigratedV2Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMigratedV2', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationIntervalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationIntervalMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByNotificationTimeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeEnd', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationTimeEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeEnd', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByNotificationTimeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeStart', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationTimeStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeStart', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByPlaySoundEffects() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playSoundEffects', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByPlaySoundEffectsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playSoundEffects', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByQuestionReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionReading', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByQuestionReadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionReading', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByQuestionTranslateToWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionTranslateToWord', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByQuestionTranslateToWordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionTranslateToWord', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByQuestionWordToTranslate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionWordToTranslate', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByQuestionWordToTranslateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionWordToTranslate', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByQuestionsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionsCount', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortByQuestionsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionsCount', Sort.desc);
    });
  }
}

extension SettingsQuerySortThenBy
    on QueryBuilder<Settings, Settings, QSortThenBy> {
  QueryBuilder<Settings, Settings, QAfterSortBy> thenByAutoPlayVoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoPlayVoice', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByAutoPlayVoiceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoPlayVoice', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIsMigratedV2() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMigratedV2', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByIsMigratedV2Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMigratedV2', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationIntervalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalMinutes', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationIntervalMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalMinutes', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByNotificationTimeEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeEnd', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationTimeEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeEnd', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByNotificationTimeStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeStart', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationTimeStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationTimeStart', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationsEnabled', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByPlaySoundEffects() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playSoundEffects', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByPlaySoundEffectsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playSoundEffects', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByQuestionReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionReading', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByQuestionReadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionReading', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByQuestionTranslateToWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionTranslateToWord', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByQuestionTranslateToWordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionTranslateToWord', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByQuestionWordToTranslate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionWordToTranslate', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByQuestionWordToTranslateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionWordToTranslate', Sort.desc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByQuestionsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionsCount', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenByQuestionsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionsCount', Sort.desc);
    });
  }
}

extension SettingsQueryWhereDistinct
    on QueryBuilder<Settings, Settings, QDistinct> {
  QueryBuilder<Settings, Settings, QDistinct> distinctByAutoPlayVoice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoPlayVoice');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByIsMigratedV2() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMigratedV2');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
      distinctByNotificationIntervalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationIntervalMinutes');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByNotificationTimeEnd(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationTimeEnd',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByNotificationTimeStart(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationTimeStart',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationsEnabled');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByPlaySoundEffects() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playSoundEffects');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByQuestionReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionReading');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
      distinctByQuestionTranslateToWord() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionTranslateToWord');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct>
      distinctByQuestionWordToTranslate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionWordToTranslate');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByQuestionsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionsCount');
    });
  }
}

extension SettingsQueryProperty
    on QueryBuilder<Settings, Settings, QQueryProperty> {
  QueryBuilder<Settings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> autoPlayVoiceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoPlayVoice');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> isMigratedV2Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMigratedV2');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations>
      notificationIntervalMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationIntervalMinutes');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations>
      notificationTimeEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationTimeEnd');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations>
      notificationTimeStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationTimeStart');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations>
      notificationsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationsEnabled');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> playSoundEffectsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playSoundEffects');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations> questionReadingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionReading');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations>
      questionTranslateToWordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionTranslateToWord');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations>
      questionWordToTranslateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionWordToTranslate');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> questionsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionsCount');
    });
  }
}
