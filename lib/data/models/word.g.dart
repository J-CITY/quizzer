// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWordCollection on Isar {
  IsarCollection<Word> get words => this.collection();
}

const WordSchema = CollectionSchema(
  name: r'Word',
  id: 2997905348638732671,
  properties: {
    r'isLearned': PropertySchema(
      id: 0,
      name: r'isLearned',
      type: IsarType.bool,
    ),
    r'japanese': PropertySchema(
      id: 1,
      name: r'japanese',
      type: IsarType.string,
    ),
    r'lastTrained': PropertySchema(
      id: 2,
      name: r'lastTrained',
      type: IsarType.dateTime,
    ),
    r'progress': PropertySchema(
      id: 3,
      name: r'progress',
      type: IsarType.long,
    ),
    r'reading': PropertySchema(
      id: 4,
      name: r'reading',
      type: IsarType.string,
    ),
    r'sheetId': PropertySchema(
      id: 5,
      name: r'sheetId',
      type: IsarType.long,
    ),
    r'translation': PropertySchema(
      id: 6,
      name: r'translation',
      type: IsarType.string,
    )
  },
  estimateSize: _wordEstimateSize,
  serialize: _wordSerialize,
  deserialize: _wordDeserialize,
  deserializeProp: _wordDeserializeProp,
  idName: r'id',
  indexes: {
    r'sheetId': IndexSchema(
      id: -2362520892615582298,
      name: r'sheetId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'sheetId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _wordGetId,
  getLinks: _wordGetLinks,
  attach: _wordAttach,
  version: '3.1.0+1',
);

int _wordEstimateSize(
  Word object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.japanese.length * 3;
  {
    final value = object.reading;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.translation.length * 3;
  return bytesCount;
}

void _wordSerialize(
  Word object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isLearned);
  writer.writeString(offsets[1], object.japanese);
  writer.writeDateTime(offsets[2], object.lastTrained);
  writer.writeLong(offsets[3], object.progress);
  writer.writeString(offsets[4], object.reading);
  writer.writeLong(offsets[5], object.sheetId);
  writer.writeString(offsets[6], object.translation);
}

Word _wordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Word();
  object.id = id;
  object.japanese = reader.readString(offsets[1]);
  object.lastTrained = reader.readDateTimeOrNull(offsets[2]);
  object.progress = reader.readLong(offsets[3]);
  object.reading = reader.readStringOrNull(offsets[4]);
  object.sheetId = reader.readLong(offsets[5]);
  object.translation = reader.readString(offsets[6]);
  return object;
}

P _wordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _wordGetId(Word object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _wordGetLinks(Word object) {
  return [];
}

void _wordAttach(IsarCollection<dynamic> col, Id id, Word object) {
  object.id = id;
}

extension WordByIndex on IsarCollection<Word> {
  Future<Word?> getBySheetId(int sheetId) {
    return getByIndex(r'sheetId', [sheetId]);
  }

  Word? getBySheetIdSync(int sheetId) {
    return getByIndexSync(r'sheetId', [sheetId]);
  }

  Future<bool> deleteBySheetId(int sheetId) {
    return deleteByIndex(r'sheetId', [sheetId]);
  }

  bool deleteBySheetIdSync(int sheetId) {
    return deleteByIndexSync(r'sheetId', [sheetId]);
  }

  Future<List<Word?>> getAllBySheetId(List<int> sheetIdValues) {
    final values = sheetIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'sheetId', values);
  }

  List<Word?> getAllBySheetIdSync(List<int> sheetIdValues) {
    final values = sheetIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sheetId', values);
  }

  Future<int> deleteAllBySheetId(List<int> sheetIdValues) {
    final values = sheetIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sheetId', values);
  }

  int deleteAllBySheetIdSync(List<int> sheetIdValues) {
    final values = sheetIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sheetId', values);
  }

  Future<Id> putBySheetId(Word object) {
    return putByIndex(r'sheetId', object);
  }

  Id putBySheetIdSync(Word object, {bool saveLinks = true}) {
    return putByIndexSync(r'sheetId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySheetId(List<Word> objects) {
    return putAllByIndex(r'sheetId', objects);
  }

  List<Id> putAllBySheetIdSync(List<Word> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'sheetId', objects, saveLinks: saveLinks);
  }
}

extension WordQueryWhereSort on QueryBuilder<Word, Word, QWhere> {
  QueryBuilder<Word, Word, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Word, Word, QAfterWhere> anySheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sheetId'),
      );
    });
  }
}

extension WordQueryWhere on QueryBuilder<Word, Word, QWhereClause> {
  QueryBuilder<Word, Word, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Word, Word, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> idBetween(
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

  QueryBuilder<Word, Word, QAfterWhereClause> sheetIdEqualTo(int sheetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sheetId',
        value: [sheetId],
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> sheetIdNotEqualTo(int sheetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sheetId',
              lower: [],
              upper: [sheetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sheetId',
              lower: [sheetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sheetId',
              lower: [sheetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sheetId',
              lower: [],
              upper: [sheetId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> sheetIdGreaterThan(
    int sheetId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sheetId',
        lower: [sheetId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> sheetIdLessThan(
    int sheetId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sheetId',
        lower: [],
        upper: [sheetId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterWhereClause> sheetIdBetween(
    int lowerSheetId,
    int upperSheetId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sheetId',
        lower: [lowerSheetId],
        includeLower: includeLower,
        upper: [upperSheetId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WordQueryFilter on QueryBuilder<Word, Word, QFilterCondition> {
  QueryBuilder<Word, Word, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Word, Word, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Word, Word, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Word, Word, QAfterFilterCondition> isLearnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLearned',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'japanese',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'japanese',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'japanese',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'japanese',
        value: '',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> japaneseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'japanese',
        value: '',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> lastTrainedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastTrained',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> lastTrainedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastTrained',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> lastTrainedEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTrained',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> lastTrainedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTrained',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> lastTrainedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTrained',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> lastTrainedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTrained',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> progressEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> progressGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> progressLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> progressBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reading',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reading',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reading',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reading',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reading',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reading',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reading',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reading',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reading',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reading',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reading',
        value: '',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> readingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reading',
        value: '',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> sheetIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sheetId',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> sheetIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sheetId',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> sheetIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sheetId',
        value: value,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> sheetIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sheetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'translation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'translation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translation',
        value: '',
      ));
    });
  }

  QueryBuilder<Word, Word, QAfterFilterCondition> translationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'translation',
        value: '',
      ));
    });
  }
}

extension WordQueryObject on QueryBuilder<Word, Word, QFilterCondition> {}

extension WordQueryLinks on QueryBuilder<Word, Word, QFilterCondition> {}

extension WordQuerySortBy on QueryBuilder<Word, Word, QSortBy> {
  QueryBuilder<Word, Word, QAfterSortBy> sortByIsLearned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLearned', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByIsLearnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLearned', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByJapanese() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByJapaneseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByLastTrained() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTrained', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByLastTrainedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTrained', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByReadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortBySheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortBySheetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByTranslation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> sortByTranslationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.desc);
    });
  }
}

extension WordQuerySortThenBy on QueryBuilder<Word, Word, QSortThenBy> {
  QueryBuilder<Word, Word, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByIsLearned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLearned', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByIsLearnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLearned', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByJapanese() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByJapaneseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'japanese', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByLastTrained() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTrained', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByLastTrainedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTrained', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByReading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByReadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reading', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenBySheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenBySheetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sheetId', Sort.desc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByTranslation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.asc);
    });
  }

  QueryBuilder<Word, Word, QAfterSortBy> thenByTranslationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.desc);
    });
  }
}

extension WordQueryWhereDistinct on QueryBuilder<Word, Word, QDistinct> {
  QueryBuilder<Word, Word, QDistinct> distinctByIsLearned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLearned');
    });
  }

  QueryBuilder<Word, Word, QDistinct> distinctByJapanese(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'japanese', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Word, Word, QDistinct> distinctByLastTrained() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTrained');
    });
  }

  QueryBuilder<Word, Word, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<Word, Word, QDistinct> distinctByReading(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reading', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Word, Word, QDistinct> distinctBySheetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sheetId');
    });
  }

  QueryBuilder<Word, Word, QDistinct> distinctByTranslation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'translation', caseSensitive: caseSensitive);
    });
  }
}

extension WordQueryProperty on QueryBuilder<Word, Word, QQueryProperty> {
  QueryBuilder<Word, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Word, bool, QQueryOperations> isLearnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLearned');
    });
  }

  QueryBuilder<Word, String, QQueryOperations> japaneseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'japanese');
    });
  }

  QueryBuilder<Word, DateTime?, QQueryOperations> lastTrainedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTrained');
    });
  }

  QueryBuilder<Word, int, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<Word, String?, QQueryOperations> readingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reading');
    });
  }

  QueryBuilder<Word, int, QQueryOperations> sheetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sheetId');
    });
  }

  QueryBuilder<Word, String, QQueryOperations> translationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translation');
    });
  }
}
