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
    r'notificationIntervalHours': PropertySchema(
      id: 1,
      name: r'notificationIntervalHours',
      type: IsarType.long,
    ),
    r'notificationsEnabled': PropertySchema(
      id: 2,
      name: r'notificationsEnabled',
      type: IsarType.bool,
    ),
    r'questionsCount': PropertySchema(
      id: 3,
      name: r'questionsCount',
      type: IsarType.long,
    ),
    r'sheetId': PropertySchema(
      id: 4,
      name: r'sheetId',
      type: IsarType.string,
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
  bytesCount += 3 + object.sheetId.length * 3;
  return bytesCount;
}

void _settingsSerialize(
  Settings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoPlayVoice);
  writer.writeLong(offsets[1], object.notificationIntervalHours);
  writer.writeBool(offsets[2], object.notificationsEnabled);
  writer.writeLong(offsets[3], object.questionsCount);
  writer.writeString(offsets[4], object.sheetId);
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
  object.notificationIntervalHours = reader.readLong(offsets[1]);
  object.notificationsEnabled = reader.readBool(offsets[2]);
  object.questionsCount = reader.readLong(offsets[3]);
  object.sheetId = reader.readString(offsets[4]);
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
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
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

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalHoursEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationIntervalHours',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalHoursGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationIntervalHours',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalHoursLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationIntervalHours',
        value: value,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition>
      notificationIntervalHoursBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationIntervalHours',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
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

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sheetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sheetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sheetId',
        value: '',
      ));
    });
  }

  QueryBuilder<Settings, Settings, QAfterFilterCondition> sheetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sheetId',
        value: '',
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

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationIntervalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalHours', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      sortByNotificationIntervalHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalHours', Sort.desc);
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

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> sortBySheetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.desc);
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

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationIntervalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalHours', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy>
      thenByNotificationIntervalHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationIntervalHours', Sort.desc);
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

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.asc);
    });
  }

  QueryBuilder<Settings, Settings, QAfterSortBy> thenBySheetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.desc);
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

  QueryBuilder<Settings, Settings, QDistinct>
      distinctByNotificationIntervalHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationIntervalHours');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByNotificationsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationsEnabled');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctByQuestionsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionsCount');
    });
  }

  QueryBuilder<Settings, Settings, QDistinct> distinctBySheetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sheetId', caseSensitive: caseSensitive);
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

  QueryBuilder<Settings, int, QQueryOperations>
      notificationIntervalHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationIntervalHours');
    });
  }

  QueryBuilder<Settings, bool, QQueryOperations>
      notificationsEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationsEnabled');
    });
  }

  QueryBuilder<Settings, int, QQueryOperations> questionsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionsCount');
    });
  }

  QueryBuilder<Settings, String, QQueryOperations> sheetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sheetId');
    });
  }
}
