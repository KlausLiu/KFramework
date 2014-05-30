//
//  KDatabase.m
//  Pods
//
//  Created by corptest on 14-4-30.
//
//

#import "KDatabase.h"
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabaseQueue.h>
#import "FMDatabase+KDBAdditions.h"
#import "KDefine.h"
#import "KCategories.h"
#import "KClassUtils.h"

@interface KDatabase () {
    dispatch_queue_t _lockQueue;
}

@property (nonatomic, K_Strong) FMDatabaseQueue * dbQueue;

@end

@implementation KDatabase

static NSMutableArray *_checkedTableNameArray = nil;
+ (void) initialize
{
    _checkedTableNameArray = [[NSMutableArray alloc] init];
}

+ (instancetype) databaseWithFilePath:(NSString *)filePath
{
    return K_Auto_Release([[self alloc] initWithFilePath:filePath]);
}

- (instancetype) initWithFilePath:(NSString *)filePath
{
    if (self = [super init]) {
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:filePath];
        _lockQueue = dispatch_queue_create([[NSString stringWithFormat:@"kdb.%@", [self description]] UTF8String], NULL);
    }
    return self;
}

- (void) dealloc
{
    K_Release(self.dbQueue);
    K_Dispatch_Queue_Release(_lockQueue);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark - operation

- (void) run:(void (^)(FMDatabase *db))block
{
    [self.dbQueue inDatabase:block];
    [self.dbQueue close];
}

#pragma mark insert

- (BOOL) insert:(id)obj
{
    __block BOOL success = YES;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = [self tableNameWithObject:obj
                                                     db:db];
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ %@",
                         tableName,
                         [self objectToInsertString:obj]];
        NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
        for (NSDictionary *dic in propertiesInClass) {
            NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
            KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
            if (classType == KClassType_NSArray) {
                // array
                if (![self __saveArrayWithPropertyName:propertyName
                                              inObject:obj
                                              database:db]) {
                    *rollback = YES;
                    success = NO;
                    return ;
                }
            } else if (classType == KClassType_NSDictionary) {
                // dictionary
                if (![self __saveDictionaryWithPropertyName:propertyName
                                                   inObject:obj
                                                   database:db]) {
                    *rollback = YES;
                    success = NO;
                    return ;
                }
            } else if (classType == KClassType_Object) {
                // object
                if (![self __saveObjectWithPropertyName:propertyName
                                               inObject:obj
                                               database:db]) {
                    *rollback = YES;
                    success = NO;
                    return ;
                }
            }
        }
        if (![db executeUpdate:sql]) {
            *rollback = YES;
            success = NO;
            return ;
        }
    }];
    [self.dbQueue close];
    return success;
}

#pragma mark update

- (BOOL) update:(id)obj
{
    [self update:obj
      ignoreNull:NO];
}

- (BOOL) update:(id)obj
     ignoreNull:(BOOL)ignoreNull
{
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    if (!pk) {
        KDB_Log_Warning(@"primary key may not exists for class %@. note:define KDB_Primary_Key(__pkname) in your class:%@", [obj class], [obj class]);
        return NO;
    }
    __block BOOL success = NO;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = [self tableNameWithObject:obj
                                                     db:db];
        KClassType classType = [KClassUtils typeWithPropertyName:pk
                                                         inClass:[obj class]];
        if (classType == KClassType_Unknow) {
            success = NO;
            return ;
        }
        BOOL isString = classType == KClassType_NSString;
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=%@%@%@",
                         tableName,
                         [self objectToWhereString:obj
                                        ignoreNull:ignoreNull],
                         [[self class] columnNameWithClass:[obj class]
                                              propertyName:pk],
                         (isString ? @"\"" : @""),
                         [[obj valueForKey:pk] description],
                         (isString ? @"\"" : @"")];
        [self __checkTableWithObject:obj
                                  db:db];
        NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
        for (NSDictionary *dic in propertiesInClass) {
            NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
            KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
            if (classType == KClassType_NSArray) {
                // array
                if (![self __updateArrayWithPropertyName:propertyName
                                                inObject:obj
                                                database:db]) {
                    *rollback = YES;
                    return ;
                }
            } else if (classType == KClassType_NSDictionary) {
                // dictionary
                if (![self __updateDictionaryWithPropertyName:propertyName
                                                     inObject:obj
                                                     database:db]) {
                    *rollback = YES;
                    return ;
                }
            } else if (classType == KClassType_Object) {
                // object
                if (![self __updateObjectWithPropertyName:propertyName
                                                 inObject:obj
                                                 database:db]) {
                    *rollback = YES;
                    return ;
                }
            }
        }
        if (![db executeUpdate:sql]) {
            *rollback = YES;
            return ;
        }
    }];
    [self.dbQueue close];
    return success;
}

#pragma mark query

- (NSArray *) queryWithClass:(Class)class
                   condition:(KDatabaseCondition *)cdn
{
    return [self queryWithClass:class
                      condition:cdn
                          pager:nil];
}

- (NSArray *) queryWithClass:(Class)class
                   condition:(KDatabaseCondition *)cdn
                       pager:(KDatabasePager *)pager
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@%@%@",
                     [self __tableNameWithClass:class],
                     cdn?[cdn toSqlWithClass:class]:@"",
                     pager?[pager toSql]:@""];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            id obj = [class objectFromDictionary:
                      [self convertToBeanDictionaryWithTableDictionary:[rs resultDictionary]
                                                                 class:class]];
            NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
            for (NSDictionary *dic in propertiesInClass) {
                NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
                KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
                if (classType == KClassType_NSArray) {
                    // array
                    NSArray *array = [self __queryArrayWithPropertyName:propertyName
                                                               inObject:obj
                                                               database:db];
                    if (array) {
                        [obj setValue:array
                               forKey:propertyName];
                    }
                } else if (classType == KClassType_NSDictionary) {
                    // dictionary
                    NSDictionary *dic = [self __queryDictionaryWithPropertyName:propertyName
                                                                       inObject:obj
                                                                       database:db];
                    if (dic) {
                        [obj setValue:dic
                               forKey:propertyName];
                    }
                } else if (classType == KClassType_Object) {
                    // object
                    id *object = [self __queryObjectWithPropertyName:propertyName
                                                            inObject:obj
                                                            database:db];
                    if (dic) {
                        [obj setValue:object
                               forKey:propertyName];
                    }
                }
            }
            [result addObject:obj];
        }
        [rs close];
    }];
    [self.dbQueue close];
    return result;
}

- (NSArray *) queryWithTableName:(NSString *)tableName
                       condition:(KDatabaseCondition *)cdn
                           pager:(KDatabasePager *)pager
{
    NSMutableArray *result = [NSMutableArray array];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@%@%@",
                     tableName,
                     cdn?[cdn toSql]:@"",
                     pager?[pager toSql]:@""];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            [result addObject:[rs resultDictionary]];
        }
        [rs close];
    }];
    [self.dbQueue close];
    return result;
}

- (id) fetchWithClass:(Class)class
                   id:(id)_id
{
    NSString *pk = [[self class] primaryKeyForClass:class];
    __block BOOL success = NO;
    NSString *tableName = [self __tableNameWithClass:class];
    __block id result = nil;
    if (pk) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            KClassType classType = [KClassUtils typeWithPropertyName:pk
                                                             inClass:class];
            if (classType == KClassType_Unknow) {
                success = NO;
                return ;
            }
            BOOL isString = classType == KClassType_NSString;
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=%@%@%@ LIMIT 1",
                             tableName,
                             [[self class] columnNameWithClass:class
                                                  propertyName:pk],
                             (isString ? @"\"" : @""),
                             [_id description],
                             (isString ? @"\"" : @"")];
            FMResultSet *rs = [db executeQuery:sql];
            if ([rs next]) {
                NSDictionary *dic = [self convertToBeanDictionaryWithTableDictionary:[rs resultDictionary]
                                                                            class:class];
                result = [class objectFromDictionary:dic];
                NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[result class]];
                for (NSDictionary *dic in propertiesInClass) {
                    NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
                    KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
                    if (classType == KClassType_NSArray) {
                        // array
                        NSArray *array = [self __queryArrayWithPropertyName:propertyName
                                                                   inObject:result
                                                                   database:db];
                        if (array) {
                            [result setValue:array
                                      forKey:propertyName];
                        }
                    } else if (classType == KClassType_NSDictionary) {
                        // dictionary
                        NSDictionary *dic = [self __queryDictionaryWithPropertyName:propertyName
                                                                           inObject:result
                                                                           database:db];
                        if (dic) {
                            [result setValue:dic
                                      forKey:propertyName];
                        }
                    } else if (classType == KClassType_Object) {
                        // object
                        id *object = [self __queryObjectWithPropertyName:propertyName
                                                                inObject:result
                                                                database:db];
                        if (dic) {
                            [result setValue:object
                                   forKey:propertyName];
                        }
                    }
                }
            }
            [rs close];
        }];
        [self.dbQueue close];
    } else {
        KDB_Log_Warning(@"primary key may not exists in table %@ for class %@. note:define KDB_Primary_Key(__pkname) in your class:%@", tableName, class, class);
    }
    return result;
}

- (id) fetchWithClass:(Class)class
            condition:(KDatabaseCondition *)cdn
{
    NSArray *array = [self queryWithClass:class
                                condition:cdn
                                    pager:nil];
    return array.count > 0 ? array[0] : nil;
}

#pragma mark delete

- (BOOL) delete:(id)obj
{
    __block BOOL success = NO;
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *pk = [[self class] primaryKeyForClass:[obj class]];
        if (pk) {
            NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
            for (NSDictionary *dic in propertiesInClass) {
                NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
                KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
                id r_id = [obj valueForKey:[[self class] primaryKeyForClass:[obj class]]];
                if (classType == KClassType_NSArray) {
                    // array
                    if (![self __deleteArrayWithPropertyName:propertyName
                                                     inClass:[obj class]
                                                    database:db
                                                        r_id:r_id]) {
                        *rollback = YES;
                        success = NO;
                        return ;
                    }
                } else if (classType == KClassType_NSDictionary) {
                    // dictionary
                    if (![self __deleteDictionaryWithPropertyName:propertyName
                                                          inClass:[obj class]
                                                         database:db
                                                             r_id:r_id]) {
                        *rollback = YES;
                        success = NO;
                        return ;
                    }
                } else if (classType == KClassType_Object) {
                    // object
                    if (![self __deleteObjectWithPropertyName:propertyName
                                                        class:[[obj valueForKey:propertyName] class]
                                                      inClass:[obj class]
                                                     database:db
                                                         r_id:r_id]) {
                        *rollback = YES;
                        success = NO;
                        return ;
                    }
                }
            }
        }
        success = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@",
                                     [self tableNameWithObject:obj db:db],
                                     [self objectToWhereString:obj
                                                    ignoreNull:YES]]];
    }];
    [self.dbQueue close];
    return success;
}

- (BOOL) deleteWithClass:(Class)class
                      id:(id)_id
{
    NSString *pk = [[self class] primaryKeyForClass:class];
    __block BOOL success = NO;
    NSString *tableName = [self __tableNameWithClass:class];
    if (pk) {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            KClassType classType = [KClassUtils typeWithPropertyName:pk
                                                             inClass:class];
            if (![db tableExists:tableName]) {
                success = NO;
                return ;
            }
            NSArray *propertiesInClass  = [KClassUtils propertiesInClass:class];
            for (NSDictionary *dic in propertiesInClass) {
                NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
                KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
                if (classType == KClassType_NSArray) {
                    // array
                    if (![self __deleteArrayWithPropertyName:propertyName
                                                     inClass:class
                                                    database:db
                                                        r_id:_id]) {
                        *rollback = YES;
                        success = NO;
                        return ;
                    }
                } else if (classType == KClassType_NSDictionary) {
                    // dictionary
                    if (![self __deleteDictionaryWithPropertyName:propertyName
                                                          inClass:class
                                                         database:db
                                                             r_id:_id]) {
                        *rollback = YES;
                        success = NO;
                        return ;
                    }
                } else if (classType == KClassType_Object) {
                    // object
                    if (![self __deleteObjectWithPropertyName:propertyName
                                                        class:[KClassUtils classWithPropertyName:propertyName
                                                                                         inClass:class]
                                                      inClass:class
                                                     database:db
                                                         r_id:_id]) {
                        *rollback = YES;
                        success = NO;
                        return ;
                    }
                }
            }
            BOOL isString = classType == KClassType_NSString;
            success = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=%@%@%@",
                                         tableName,
                                         [[self class] columnNameWithClass:class
                                                              propertyName:pk],
                                         (isString ? @"\"" : @""),
                                         [_id description],
                                         (isString ? @"\"" : @"")]];
        }];
        [self.dbQueue close];
    }
    if (!success) {
        KDB_Log_Warning(@"primary key may not exists in table %@ for class %@. note:define KDB_Primary_Key(__pkname) in your class:%@", tableName, class, class);
//        [NSException raise:NSInvalidArgumentException format:@"def KDB_Primary_Key(__pkname) in your class:%@", class];
    }
    return success;
}

#pragma mark utils

+ (NSString *) columnNameWithClass:(Class)class
                      propertyName:(NSString *)propertyName
{
    if (propertyName == nil || class == nil) {
        return nil;
    }
    NSString *columnName = [propertyName lowercaseString];
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"kdb_cname_4_%@", propertyName]);
    if ([class respondsToSelector:sel]) {
        IMP m = [class methodForSelector:sel];
        columnName = m(class, sel);
    }
    return columnName;
}

+ (NSString *) primaryKeyForClass:(Class)class
{
    SEL sel = @selector(kdb_pk);
    if ([class respondsToSelector:sel]) {
        IMP m = [class methodForSelector:sel];
        return m(class, sel);
    }
    return nil;
}

+ (NSString *) one2oneIdColumnNameForPropertyName:(NSString *)propertyName
                                          inClass:(Class)class
{
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"kdb_one_2_one_id_column_name_4_%@", propertyName]);
    if ([class respondsToSelector:sel]) {
        IMP m = [class methodForSelector:sel];
        return m(class, sel);
    }
    return [[NSString stringWithFormat:@"%@_id", [class description]] lowercaseString];
}

#pragma mark - private

/**
 *  验证primary key是否合法
 *  只有在primary key必须时，才需调用此方法验证
 *
 *  @param class
 *
 *  @return 是否通过验证
 */
- (BOOL) __validatePrimaryKeyWithClass:(Class)class
{
    NSString *pk = [[self class] primaryKeyForClass:class];
    if (pk == nil) {
        KDB_Log_Warning(@"Id must be specified by KDB_Primary_Key(__pname, __cname) in class <%@>", class);
        return NO;
    }
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:class];
    if (idType == KClassType_NSArray || idType == KClassType_NSDictionary || idType == KClassType_Object || idType == KClassType_Unknow) {
        KDB_Log_Warning(@"PRIMARY KEY must be digital or string in class <%@>.", class);
        return NO;
    }
    return YES;
}

#pragma mark array

/**
 *  查询object中的array类型的数据
 *
 *  @param propertyName array类型的成员名称
 *  @param obj          对象
 *  @param db           db
 *
 *  @return 查询到的数据
 */
- (NSArray *) __queryArrayWithPropertyName:(NSString *)propertyName
                                  inObject:(id)obj
                                  database:(FMDatabase *)db
{
    if (![self __validatePrimaryKeyWithClass:[obj class]]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:[obj class]];
    id idValue = [obj valueForKey:pk];
    NSString *tName = [self tableName4ArrayPropertyWithName:propertyName
                                                    inClass:[obj class]
                                                         db:db];
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT r_value FROM %@ WHERE r_id=%@",
                                        tName,
                                        (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [idValue description]] : [idValue description])]];
    NSMutableArray *ret = [NSMutableArray array];
    while ([rs next]) {
        [ret addObject:[rs objectForColumnName:@"r_value"]];
    }
    [rs close];
    return ret;
}

/**
 *  更新对象中的array成员
 *  先delete，再insert
 *
 *  @param propertyName array成员名称
 *  @param obj          对象
 *  @param db           db实例
 *
 *  @return 成功与否
 */
- (BOOL) __updateArrayWithPropertyName:(NSString *)propertyName
                              inObject:(id)obj
                        database:(FMDatabase *)db

{
    if (![self __deleteArrayWithPropertyName:propertyName
                                     inClass:[obj class]
                                    database:db
                                 r_id:[obj valueForKey:[[self class] primaryKeyForClass:[obj class]]]]) {
        return NO;
    }
    return [self __saveArrayWithPropertyName:propertyName
                                    inObject:obj
                                    database:db];
}

/**
 *  删除对象中的array成员
 *  先delete，再insert
 *
 *  @param propertyName array成员名称
 *  @param class        对象
 *  @param db           db实例
 *  @param value        array成员的值
 *
 *  @return 成功与否
 */
- (BOOL) __deleteArrayWithPropertyName:(NSString *)propertyName
                               inClass:(Class)class
                              database:(FMDatabase *)db
                                  r_id:(id)_id
{
    if (![self __validatePrimaryKeyWithClass:class]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:class];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:class];
    NSString *tName = [self tableName4ArrayPropertyWithName:propertyName
                                                    inClass:class
                                                         db:db];
    return [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE r_id=%@",
                              tName,
                              (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [_id description]] : [_id description])]];
}

/**
 *  保存对象中的array成员
 *
 *  @param propertyName array成员名称
 *  @param obj          对象
 *  @param db           db实例
 *
 *  @return 成功与否
 */
- (BOOL) __saveArrayWithPropertyName:(NSString *)propertyName
                            inObject:(id)obj
                            database:(FMDatabase *)db
{
    NSArray* value = (NSArray *)[obj valueForKey:propertyName];
    if (![value isKindOfClass:[NSArray class]]) {
        return NO;
    }
    if (![self __validatePrimaryKeyWithClass:[obj class]]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:[obj class]];
    id idValue = [obj valueForKey:pk];
    NSString *tName = [self tableName4ArrayPropertyWithName:propertyName
                                                    inClass:[obj class]
                                                         db:db];
    if ([db tableExists:tName]) {
        Class type = nil;
        for (id sub in value) {
            type == nil ? type = [sub class] : nil;
            if (type != [sub class]) {
                KDB_Log_Warning(@"Type must be unique in array property %@ of class %@", propertyName, [obj class]);
                return NO;
            }
            type = [sub class];
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (r_id, r_value) VALUES (%@, %@)",
                             tName,
                             (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [idValue description]] : [idValue description]),
                             ([type isSubclassOfClass:[NSString class]] ? [NSString stringWithFormat:@"\"%@\"", [sub description]] : [sub description])];
            if (![db executeUpdate:sql]) {
                return NO;
            }
        }
    } else {
        KDB_Log_Warning(@"Table is not exist for array property %@ in class %@", propertyName, [obj class]);
        return NO;
    }
    return YES;
}

/**
 *  为array成员创建表
 *
 *  @param propertyName NSArray类型的成员名称
 *  @param class        类名
 *
 *  @return 表名
 */
- (NSString *) tableName4ArrayPropertyWithName:(NSString *)propertyName
                                       inClass:(Class)class
                                            db:(FMDatabase *)db
{
    NSString *tableName = nil;
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"kdb_tname_4_%@", propertyName]);
    if ([class respondsToSelector:sel]) {
        IMP m = [class methodForSelector:sel];
        tableName = m(class, sel);
    } else {
        tableName = [[NSString stringWithFormat:@"t_%@_%@", [class description], propertyName] lowercaseString];
    }
    if (![_checkedTableNameArray containsObject:tableName]) {
        [_checkedTableNameArray addObject:tableName];
        if (![db tableExists:tableName]) {
            // array 只有两个column 一个是array所在的对象的id，一个是对应的值
            NSString *a = [self __columnDataTypeWithClassType:[KClassUtils typeWithPropertyName:[[self class] primaryKeyForClass:class]
                                                                                        inClass:class]];
            [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE %@ (r_id %@, r_value %@);",
                               tableName,
                               [self __columnDataTypeWithClassType:[KClassUtils typeWithPropertyName:[[self class] primaryKeyForClass:class]
                                                                                             inClass:class]],
                               [self __columnDataTypeWithClassType:[KClassUtils typeWithPropertyName:propertyName
                                                                                             inClass:class]]]];
        }
    }
    return tableName;
}

#pragma mark dictionary

/**
 *  查询object中的dictionary类型的数据
 *
 *  @param propertyName dictionary类型的成员名称
 *  @param obj          对象
 *  @param db           db
 *
 *  @return 查询到的数据
 */
- (NSDictionary *) __queryDictionaryWithPropertyName:(NSString *)propertyName
                                            inObject:(id)obj
                                            database:(FMDatabase *)db
{
    if (![self __validatePrimaryKeyWithClass:[obj class]]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:[obj class]];
    id idValue = [obj valueForKey:pk];
    NSString *tName = [self __tableName4DictionaryPropertyWithName:propertyName
                                                           inClass:[obj class]];
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE r_id=%@",
                                        tName,
                                        (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [idValue description]] : [idValue description])]];
    id ret = nil;
    if ([rs next]) {
        ret = [NSMutableDictionary dictionaryWithDictionary:[rs resultDictionary]];
        [ret removeObjectForKey:@"r_id"];
    }
    [rs close];
    return ret;
}

/**
 *  更新对象中的dictionary成员
 *
 *  @param propertyName dictionary成员名称
 *  @param obj          对象
 *  @param db           db实例
 *
 *  @return 成功与否
 */
- (BOOL) __updateDictionaryWithPropertyName:(NSString *)propertyName
                                     inObject:(id)obj
                             database:(FMDatabase *)db
{
    if (![self __deleteDictionaryWithPropertyName:propertyName
                                          inClass:[obj class]
                                         database:db
                                             r_id:[obj valueForKey:[[self class] primaryKeyForClass:[obj class]]]]) {
        return NO;
    }
    
    return [self __saveDictionaryWithPropertyName:propertyName
                                         inObject:obj
                                         database:db];
}

/**
 *  删除对象中的dictionary成员
 *  先delete，再insert
 *
 *  @param propertyName dictionary成员名称
 *  @param class        对象
 *  @param db           db实例
 *  @param r_id         class的id值
 *
 *  @return 成功与否
 */
- (BOOL) __deleteDictionaryWithPropertyName:(NSString *)propertyName
                                    inClass:(Class)class
                                   database:(FMDatabase *)db
                                       r_id:(id)_id
{
    if (![self __validatePrimaryKeyWithClass:class]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:class];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:class];
    NSString *tName = [self __tableName4DictionaryPropertyWithName:propertyName
                                                           inClass:class];
    return [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE r_id=%@",
                              tName,
                              (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [_id description]] : [_id description])]];
}

/**
 *  保存对象中的dictionary成员
 *
 *  @param propertyName dictionary成员名称
 *  @param obj          对象
 *  @param db           db实例
 *
 *  @return 成功与否
 */
- (BOOL) __saveDictionaryWithPropertyName:(NSString *)propertyName
                                 inObject:(id)obj
                           database:(FMDatabase *)db
{
    NSDictionary* value = (NSDictionary *)[obj valueForKey:propertyName];
    if (![value isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    if (![self __validatePrimaryKeyWithClass:[obj class]]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:[obj class]];
    id idValue = [obj valueForKey:pk];
    NSString *tName = [self tableName4DictionaryPropertyWithName:propertyName
                                                        inObject:obj
                                                              db:db];
    if (tName && [db tableExists:tName]) {
        NSArray *allKeys = [value allKeys];
        NSMutableString *columns = [NSMutableString stringWithFormat:@"r_id,"];
        NSMutableString *values = [NSMutableString stringWithFormat:@"%@,",
                                   (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [idValue description]] : [idValue description])];
        for (id key in allKeys) {
            [columns appendFormat:@"%@,", key];
            id v = [value objectForKey:key];
            KClassType vType = [KClassUtils typeWithObject:v];
            [values appendFormat:@"%@,",
             (vType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [v description]] : [v description])];
        }
        if (![db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", tName,
                                [columns substringToIndex:columns.length - 1],
                                [values substringToIndex:values.length - 1]]]) {
            return NO;
        }
    } else {
        KDB_Log_Warning(@"Table is not exist for array property %@ in class %@", propertyName, [obj class]);
        return NO;
    }
    return YES;
}

/**
 *  dictionary成员对应的表名
 *
 *  @param propertyName NSDictionary类型的成员名称
 *  @param obj          类名
 *
 *  @return 表名
 */
- (NSString *) __tableName4DictionaryPropertyWithName:(NSString *)propertyName
                                              inClass:(Class)class
{
    __block NSString *tableName = nil;
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"kdb_tname_4_%@", propertyName]);
    if ([class respondsToSelector:sel]) {
        IMP m = [class methodForSelector:sel];
        tableName = m(class, sel);
    } else {
        tableName = [[NSString stringWithFormat:@"t_%@_%@", [class description], propertyName] lowercaseString];
    }
    return tableName;
}

/**
 *  为dictionary成员创建表
 *
 *  @param propertyName NSDictionary类型的成员名称
 *  @param obj          类名
 *
 *  @return 表名
 */
- (NSString *) tableName4DictionaryPropertyWithName:(NSString *)propertyName
                                           inObject:(id)obj
                                                 db:(FMDatabase *)db
{
    NSDictionary *value = [obj valueForKey:propertyName];
    if (![value isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    Class class = [obj class];
    __block NSString *tableName = [self __tableName4DictionaryPropertyWithName:propertyName
                                                                       inClass:[obj class]];
    BOOL tableExists = [db tableExists:tableName];
    // dictionary中key为column的名称，增加一列为r_id对应dictionary所在object的id
    NSArray *allKeys = [value allKeys];
    NSMutableString *create = [NSMutableString string];
    for (id key in allKeys) {
        if (![key isKindOfClass:[NSString class]]) {
            KDB_Log_Warning(@"Keys in NSDictionary type property name <%@> of class <%@> must be NSString.", propertyName, class);
            return nil;
        }
        KClassType vType = [KClassUtils typeWithObject:[value objectForKey:key]];
        if (vType == KClassType_NSArray ||
            vType == KClassType_NSDictionary ||
            vType == KClassType_Unknow ||
            vType == KClassType_Object) {
            KDB_Log_Warning(@"value in NSDictionary type property name <%@> of class <%@> must be digital or string.", propertyName, class);
            return nil;
        }
        if (tableExists && ![db columnExists:key inTableWithName:tableName]) {
            if (![db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@",
                                    tableName,
                                    key,
                                    [self __columnDataTypeWithClassType:vType]]]) {
                return nil;
            }
        } else if (!tableExists) {
            [create appendFormat:@"%@ %@,", key, [self __columnDataTypeWithClassType:vType]];
        }
    }
    if (!tableExists) {
        if (![db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE %@ (r_id %@, %@);",
                                tableName,
                                [self __columnDataTypeWithClassType:[KClassUtils typeWithPropertyName:[[self class] primaryKeyForClass:class]
                                                                                              inClass:class]],
                                [create substringToIndex:create.length - 1]]]) {
            return nil;
        }
    }
    return tableName;
}

#pragma mark object

- (id) __queryObjectWithPropertyName:(NSString *)propertyName
                                        inObject:(id)inObject
                                        database:(FMDatabase *)db
{
    if (![self __validatePrimaryKeyWithClass:[inObject class]]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:[inObject class]];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:[inObject class]];
    id idValue = [inObject valueForKey:pk];
    Class objectClass = [KClassUtils classWithPropertyName:propertyName inClass:[inObject class]];
    NSString *tName = K_Auto_Release(K_Retain([self __tableNameWithClass:objectClass]));
    NSString *one2oneColumnName = [[self class] one2oneIdColumnNameForPropertyName:propertyName
                                                                           inClass:[inObject class]];
    FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=%@",
                                        tName,
                                        one2oneColumnName,
                                        (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [idValue description]] : [idValue description])]];
    id ret = nil;
    if ([rs next]) {
        ret = [objectClass objectFromDictionary:[rs resultDictionary]];
    }
    [rs close];
    return ret;
}

- (BOOL) __updateObjectWithPropertyName:(NSString *)propertyName
                               inObject:(id)obj
                               database:(FMDatabase *)db

{
    if (![self __deleteObjectWithPropertyName:propertyName
                                        class:[[obj valueForKey:propertyName] class]
                                      inClass:[obj class]
                                     database:db
                                         r_id:[obj valueForKey:[[self class] primaryKeyForClass:[obj class]]]]) {
        return NO;
    }
    
    return [self __saveObjectWithPropertyName:propertyName
                                     inObject:obj
                                     database:db];
}

- (BOOL) __deleteObjectWithPropertyName:(NSString *)propertyName
                                  class:(Class)class
                                inClass:(Class)inClass
                               database:(FMDatabase *)db
                                   r_id:(id)r_id
{
    if (![self __validatePrimaryKeyWithClass:inClass]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:inClass];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:inClass];
    NSString *tName = K_Auto_Release(K_Retain([self __tableNameWithClass:class]));
    NSString *one2oneColumnName = [[self class] one2oneIdColumnNameForPropertyName:propertyName
                                                                           inClass:inClass];
    return [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=%@",
                              tName,
                              one2oneColumnName,
                              (idType == KClassType_NSString ? [NSString stringWithFormat:@"\"%@\"", [r_id description]] : [r_id description])]];
}

/**
 *  保存对象中的object成员
 *
 *  @param propertyName object成员名称
 *  @param obj          对象
 *  @param db           db实例
 *
 *  @return 成功与否
 */
- (BOOL) __saveObjectWithPropertyName:(NSString *)propertyName
                             inObject:(id)obj
                             database:(FMDatabase *)db

{
    NSObject* value = (NSObject *)[obj valueForKey:propertyName];
    if (![value isKindOfClass:[NSObject class]]) {
        return NO;
    }
    if (![self __validatePrimaryKeyWithClass:[obj class]]) {
        return NO;
    }
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    KClassType idType = [KClassUtils typeWithPropertyName:pk
                                                  inClass:[obj class]];
    id idValue = [obj valueForKey:pk];
    NSString *tName = [self __tableNameWithObject:value
                                  forPropertyName:propertyName
                                         inObject:obj
                                               db:db];
    if (tName && [db tableExists:tName]) {
        NSString *one2oneColumnName = [[self class] one2oneIdColumnNameForPropertyName:propertyName inClass:[obj class]];
        NSString *sql = [self objectToInsertString:[obj valueForKey:propertyName]
                                          addition:@{
                                                     one2oneColumnName : idValue
                                                     }];
        if (![db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ %@", tName, sql]]) {
            return NO;
        }
    } else {
        KDB_Log_Warning(@"Table is not exist for array property %@ in class %@", propertyName, [obj class]);
        return NO;
    }
    return YES;
}

- (NSString *) __tableNameWithObject:(id)obj
                     forPropertyName:(NSString *)propertyName
                            inObject:(id)inObject
                                  db:(FMDatabase *)db
{
    NSString *tableName = K_Retain([self __tableNameWithClass:[obj class]]);
    if (![_checkedTableNameArray containsObject:tableName]) {
        [_checkedTableNameArray addObject:tableName];
        [self __checkTableWithObject:obj
                     forPropertyName:propertyName
                            inObject:inObject
                                  db:db];
    }
    return K_Auto_Release(tableName);
}

#pragma mark other

- (void) executeLocked:(void (^)(void))aBlock
{
    dispatch_sync(_lockQueue, aBlock);
}

- (NSString *) objectToInsertString:(id)obj
{
    return [self objectToInsertString:obj
                      addition:nil];
}

- (NSString *) objectToInsertString:(id)obj
                           addition:(NSDictionary *)addition
{
    NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
    NSMutableString *columns = [NSMutableString stringWithString:@""];
    NSMutableString *values = [NSMutableString stringWithString:@""];
    for (NSDictionary *dic in propertiesInClass) {
        NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
        KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
        NSString *columnName = [[self class] columnNameWithClass:[obj class]
                                                    propertyName:propertyName];
        if (classType == KClassType_Unknow) {
            KDB_Log_Warning(@"unknow type for property %@ in class %@", columnName, [obj class]);
            return nil;
        }
        if (classType == KClassType_NSDictionary || classType == KClassType_NSArray || classType == KClassType_Object) {
            continue;
        }
        id value = [obj valueForKey:propertyName];
        [columns appendFormat:@"%@,", columnName];
        if (KClassType_NSString == classType) {
            [values appendFormat:@"\"%@\",", value ? [value description] : @""];
        } else {
            [values appendFormat:@"%@,", [value description]];
        }
    }
    if (addition) {
        for (NSString *key in addition.allKeys) {
            id value = [addition objectForKey:key];
            KClassType vType = [KClassUtils typeWithObject:value];
            if (vType == KClassType_NSDictionary || vType == KClassType_NSArray || vType == KClassType_Object || vType == KClassType_Unknow) {
                continue;
            }
            [columns appendFormat:@"%@,", key];
            if (KClassType_NSString == vType) {
                [values appendFormat:@"\"%@\",", [value description]];
            } else {
                [values appendFormat:@"%@,", [value description]];
            }
        }
    }
    
    return [NSString stringWithFormat:@"(%@) VALUES (%@)", [columns substringToIndex:(columns.length - 1)], [values substringToIndex:(values.length - 1)]];
}

- (NSString *) objectToWhereString:(id)obj
                        ignoreNull:(BOOL)ignoreNull
{
    NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
    NSDictionary *dic = [obj asNSDictionary];
    NSMutableString *ret = [NSMutableString stringWithString:@""];
    for (NSDictionary *dic in propertiesInClass) {
        NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
        KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
        if (classType == KClassType_NSDictionary || classType == KClassType_NSArray || classType == KClassType_Object || classType == KClassType_Unknow) {
            continue;
        }
        id value = [obj valueForKey:propertyName];
        if (ignoreNull && value == nil) {
            continue;
        }
        NSString *columnName = [[self class] columnNameWithClass:[obj class]
                                                    propertyName:propertyName];
        if (KClassType_NSString == classType) {
            [ret appendFormat:@"%@=\"%@\",", columnName, value ? [value description] : @""];
        } else {
            [ret appendFormat:@"%@=%@,", columnName, [value description]];
        }
    }
    
    return [ret substringToIndex:(ret.length - 1)];
}

- (NSString *) tableNameWithObject:(id)obj
                                db:(FMDatabase *)db
{
    NSString *tableName = K_Retain([self __tableNameWithClass:[obj class]]);
    if (![_checkedTableNameArray containsObject:tableName]) {
        [_checkedTableNameArray addObject:tableName];
        [self __checkTableWithObject:obj
                                  db:db];
    }
    return K_Auto_Release(tableName);
}

/**
 *  将表中的一行数据转化为bean中的dictionary，主要工作是将key从column名称转化为成员名称
 *
 *  @param tableDictionary
 *  @param class
 *
 *  @return
 */
- (NSDictionary *) convertToBeanDictionaryWithTableDictionary:(NSDictionary *)tableDictionary
                                                        class:(Class)class
{
    NSMutableDictionary *beanDictionary = [NSMutableDictionary dictionaryWithCapacity:tableDictionary.count];
    for (NSString *key in tableDictionary.allKeys) {
        SEL sel = NSSelectorFromString([NSString stringWithFormat:@"kdb_pname_4_%@", key]);
        NSString *propertyName = key;
        if ([class respondsToSelector:sel]) {
            IMP imp = [class methodForSelector:sel];
            propertyName = imp(class, sel);
        }
        [beanDictionary setObject:[tableDictionary objectForKey:key]
                           forKey:propertyName];
    }
    return beanDictionary;
}

- (NSString *) __tableNameWithClass:(Class)class
{
    NSString *tableName = nil;
    SEL sel = @selector(kdb_table_name);
    if ([class respondsToSelector:sel]) {
        IMP m = [class methodForSelector:sel];
        tableName = m(class, sel);
    } else {
        tableName = [NSString stringWithFormat:@"t_%@", [class description]];
    }
    tableName = [tableName lowercaseString];
    return tableName;
}

- (void) __checkTableWithObject:(id)obj
                             db:(FMDatabase *)db
{
    [self __checkTableWithObject:obj
                 forPropertyName:nil
                        inObject:nil
                              db:db];
}

- (void) __checkTableWithObject:(id)obj
                forPropertyName:(NSString *)propertyName
                       inObject:(id)inObject
                             db:(FMDatabase *)db
{
    NSArray *propertiesInClass  = [KClassUtils propertiesInClass:[obj class]];
    NSString *tableName = [self __tableNameWithClass:[obj class]];
    if (![db tableExists:tableName]) {
        NSString *sql = [self __createTableSqlWithObject:obj
                                       propertiesInClass:propertiesInClass];
        if (inObject) {
            NSString *one2oneColumnName = [[self class] one2oneIdColumnNameForPropertyName:propertyName inClass:[inObject class]];
            [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE %@ (%@,%@ %@)",
                               tableName,
                               sql,
                               one2oneColumnName,
                               [self __columnDataTypeWithClassType:[KClassUtils typeWithPropertyName:propertyName
                                                                                             inClass:[inObject class]]]]];
        } else {
            [db executeUpdate:[NSString stringWithFormat:@"CREATE TABLE %@ (%@)",
                               tableName,
                               sql]];
        }
    } else {
        NSArray *ptc = [propertiesInClass collectWithClosureBlock:^id(id _obj) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_obj];
            [dic setObject:[[self class] columnNameWithClass:[obj class]
                                                propertyName:[((NSDictionary *)_obj) objectForKey:KClassPropertyNameKey]] forKey:KClassPropertyColumnNameKey];
            return dic;
        }];
        NSArray *propertyNames = [ptc collectWithClosureBlock:^id(id _obj) {
            return [((NSDictionary *)_obj) objectForKey:KClassPropertyColumnNameKey];
        }];
        NSArray *cs = [db unExistsAndDeletedColumnNamesWithAllColumnNames:propertyNames
                                                          inTableWithName:tableName];
        NSMutableArray *_unExistsColumnNames = [[NSMutableArray alloc] initWithArray:cs[0]];
        for (NSString *columnName in _unExistsColumnNames) {
            NSDictionary *dic = [ptc filteredOneUsingPredicate:
                                 [NSPredicate predicateWithFormat:@"SELF.%@ == %@",
                                  KClassPropertyColumnNameKey, columnName]];
            KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
            if (classType == KClassType_NSDictionary || classType == KClassType_NSArray || classType == KClassType_Object) {
                continue;
            }
            [db executeUpdate:[self __addColumnSqlWithClass:[obj class]
                                               propertyInfo:dic]];
        }
        // TODO 通知出去
        
        K_Release(_unExistsColumnNames);
        if ([[obj class] respondsToSelector:@selector(kdb_auto_sync_property_column)]) {
            NSMutableArray *_deletedColumnNames = [[NSMutableArray alloc] initWithArray:cs[1]];
            for (NSString *columnName in _deletedColumnNames) {
                [db executeUpdate:[NSString stringWithFormat:@"ALTER TABLE %@ DROP COLUMN %@",
                                   tableName, columnName]];
            }
            // TODO 通知出去
            
            K_Release(_deletedColumnNames);
        }
    }
}

- (NSString *) __addColumnSqlWithClass:(Class)class
                          propertyInfo:(NSDictionary *)propertyInfo
{
    return [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@",
            [self  __tableNameWithClass:class],
            [[self class] columnNameWithClass:class
                                 propertyName:[propertyInfo objectForKey:KClassPropertyNameKey]],
            [self __columnDataTypeWithClassType:[propertyInfo objectForKey:KClassPropertyTypeKey]]];
}

- (NSString *) __createTableSqlWithObject:(id)obj
                        propertiesInClass:(NSArray *)propertiesInClass
{
    NSString *pk = [[self class] primaryKeyForClass:[obj class]];
    if (pk && ![self __validatePrimaryKeyWithClass:[obj class]]) {
        return nil;
    }
    NSString *pkColumn = [[self class] columnNameWithClass:[obj class]
                                     propertyName:pk];
    NSMutableString *sql = [NSMutableString string];
    for (NSDictionary *dic in propertiesInClass) {
        NSString *propertyName = [dic objectForKey:KClassPropertyNameKey];
        KClassType classType = [[dic objectForKey:KClassPropertyTypeKey] integerValue];
        if (classType == KClassType_Unknow) {
            KDB_Log_Warning(@"Unknow type for property name <%@> in class <%@>.", propertyName, [obj class]);
            return nil;
        }
        if (classType == KClassType_NSDictionary
            || classType == KClassType_NSArray
            || classType == KClassType_Object) {
            continue;
        }
        [sql appendFormat:@"%@ %@%@,",
         [[self class] columnNameWithClass:[obj class]
                              propertyName:propertyName],
         [self __columnDataTypeWithClassType:classType],
         ((pkColumn && [pk isEqualToString:propertyName]) ? @" PRIMARY KEY" : @"")];
    }
    [sql deleteCharactersInRange:NSMakeRange(sql.length-1, 1)];
    return sql;
}

- (NSString *) __columnDataTypeWithClassType:(KClassType)classType
{
    switch (classType) {
        case KClassType_Int_NSInteger:
        case KClassType_Long:
        case KClassType_Long_Long:
            return @"INTEGER";
            break;
        case KClassType_Float_CGFloat:
        case KClassType_NSNumber:
        case KClassType_Double:
            return @"REAL";
            break;
        case KClassType_NSString:
            return @"TEXT";
            break;
    }
    return @"TEXT";
}

@end
