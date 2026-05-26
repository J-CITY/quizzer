// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomListCollection on Isar {
  IsarCollection<CustomList> get customLists => this.collection();
}

const CustomListSchema = CollectionSchema(
  name: r'CustomList',
  id: -8525547938508663416,
  properties: {
    r'googleSheetId': PropertySchema(
      id: 0,
      name: r'googleSheetId',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'syncOnStartup': PropertySchema(
      id: 2,
      name: r'syncOnStartup',
      type: IsarType.bool,
    )
  },
  estimateSize: _customListEstimateSize,
  serialize: _customListSerialize,
  deserialize: _customListDeserialize,
  deserializeProp: _customListDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'words': LinkSchema(
      id: 8515103240983292619,
      name: r'words',
      target: r'Word',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _customListGetId,
  getLinks: _customListGetLinks,
  attach: _customListAttach,
  version: '3.1.0+1',
);

int _customListEstimateSize(
  CustomList object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.googleSheetId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _customListSerialize(
  CustomList object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.googleSheetId);
  writer.writeString(offsets[1], object.name);
  writer.writeBool(offsets[2], object.syncOnStartup);
}

CustomList _customListDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomList();
  object.googleSheetId = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  object.syncOnStartup = reader.readBool(offsets[2]);
  return object;
}

P _customListDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customListGetId(CustomList object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customListGetLinks(CustomList object) {
  return [object.words];
}

void _customListAttach(IsarCollection<dynamic> col, Id id, CustomList object) {
  object.id = id;
  object.words.attach(col, col.isar.collection<Word>(), r'words', id);
}

extension CustomListQueryWhereSort
    on QueryBuilder<CustomList, CustomList, QWhere> {
  QueryBuilder<CustomList, CustomList, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomListQueryWhere
    on QueryBuilder<CustomList, CustomList, QWhereClause> {
  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterWhereClause> idBetween(
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

extension CustomListQueryFilter
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {
  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'googleSheetId',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'googleSheetId',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'googleSheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'googleSheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'googleSheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'googleSheetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'googleSheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'googleSheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'googleSheetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'googleSheetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'googleSheetId',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      googleSheetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'googleSheetId',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      syncOnStartupEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncOnStartup',
        value: value,
      ));
    });
  }
}

extension CustomListQueryObject
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {}

extension CustomListQueryLinks
    on QueryBuilder<CustomList, CustomList, QFilterCondition> {
  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> words(
      FilterQuery<Word> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'words');
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      wordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'words', length, true, length, true);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition> wordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'words', 0, true, 0, true);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      wordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'words', 0, false, 999999, true);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      wordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'words', 0, true, length, include);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      wordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'words', length, include, 999999, true);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterFilterCondition>
      wordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'words', lower, includeLower, upper, includeUpper);
    });
  }
}

extension CustomListQuerySortBy
    on QueryBuilder<CustomList, CustomList, QSortBy> {
  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByGoogleSheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleSheetId', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByGoogleSheetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleSheetId', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortBySyncOnStartup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnStartup', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> sortBySyncOnStartupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnStartup', Sort.desc);
    });
  }
}

extension CustomListQuerySortThenBy
    on QueryBuilder<CustomList, CustomList, QSortThenBy> {
  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByGoogleSheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleSheetId', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByGoogleSheetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'googleSheetId', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenBySyncOnStartup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnStartup', Sort.asc);
    });
  }

  QueryBuilder<CustomList, CustomList, QAfterSortBy> thenBySyncOnStartupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnStartup', Sort.desc);
    });
  }
}

extension CustomListQueryWhereDistinct
    on QueryBuilder<CustomList, CustomList, QDistinct> {
  QueryBuilder<CustomList, CustomList, QDistinct> distinctByGoogleSheetId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'googleSheetId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomList, CustomList, QDistinct> distinctBySyncOnStartup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncOnStartup');
    });
  }
}

extension CustomListQueryProperty
    on QueryBuilder<CustomList, CustomList, QQueryProperty> {
  QueryBuilder<CustomList, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomList, String?, QQueryOperations> googleSheetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'googleSheetId');
    });
  }

  QueryBuilder<CustomList, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CustomList, bool, QQueryOperations> syncOnStartupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncOnStartup');
    });
  }
}
