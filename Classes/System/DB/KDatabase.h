//
//  KDatabase.h
//  Pods
//
//  Created by corptest on 14-4-30.
//
//

#import <Foundation/Foundation.h>
#import "KDatabaseCondition.h"
#import "KDatabasePager.h"
#import <FMDB/FMDatabase.h>

#undef KDB_Log
#define KDB_Log(...) \
NSLog(@"==KDB== %@", [NSString stringWithFormat:__VA_ARGS__])

#undef KDB_Log_Warning
#define KDB_Log_Warning(...) \
    NSLog(@"==KDB== Warning!: %@", [NSString stringWithFormat:__VA_ARGS__])

/*
  声明表名
 */
#undef KDB_Table_Name
#define KDB_Table_Name(__name) \
    + (NSString *) kdb_table_name \
    { \
        return [NSString stringWithUTF8String:#__name]; \
    }

/*
  标明此类中的成员与表中的列保持同步，删除多余的列
 */
#undef KDB_Auto_Sync_Property_Column
#define KDB_Auto_Sync_Property_Column \
    + (BOOL) kdb_auto_sync_property_column \
    { \
        return YES; \
    }
/*
  声明表的主键
 */
#undef KDB_Primary_Key
#define KDB_Primary_Key(__pname, __cname) \
    + (NSString *) kdb_pk \
    { \
        return [NSString stringWithUTF8String:#__pname]; \
    } \
    + (NSString *) kdb_cname_4_##__pname \
    { \
        return [NSString stringWithUTF8String:#__cname]; \
    } \
    + (NSString *) kdb_pname_4_##__cname \
    { \
        return [NSString stringWithUTF8String:#__pname]; \
    }

/*
  为成员名声明列名
 */
#undef KDB_Column_Name
#define KDB_Column_Name(__pname, __cname) \
    + (NSString *) kdb_cname_4_##__pname \
    { \
       return [NSString stringWithUTF8String:#__cname]; \
    } \
    + (NSString *) kdb_pname_4_##__cname \
    { \
        return [NSString stringWithUTF8String:#__pname]; \
    }

/*
  为array/dictionary成员声明表名
  目前array中仅支持基础类型(string、(长)整形、单/双精度型)
  目前dictionary中的key必须为string、number，value必须为string、number
 */
#undef KDB_Array_Dictionary_Table_Name
#define KDB_Array_Dictionary_Table_Name(__pname, __tname) \
    + (NSString *) kdb_tname_4_##__pname \
    { \
        return [NSString stringWithUTF8String:#__tname]; \
    } \
    + (NSString *) kdb_pname_4_##__tname \
    { \
        return [NSString stringWithUTF8String:#__pname]; \
    }

/*
  1对1关系中，在对方表中存放id的column name
 */
#undef KDB_One_2_One_Id_Column_Name
#define KDB_One_2_One_Id_Column_Name(__pname, __cname) \
    + (NSString *) kdb_one_2_one_id_column_name_4_##__pname \
    { \
        return [NSString stringWithUTF8String:#__cname]; \
    }

@interface KDatabase : NSObject

+ (instancetype) databaseWithFilePath:(NSString *)filePath;

- (instancetype) initWithFilePath:(NSString *)filePath;

#pragma mark - operation

- (void) run:(void (^)(FMDatabase *db))block;

#pragma mark insert

- (BOOL) insert:(id)obj;

#pragma mark update

- (BOOL) update:(id)obj;

- (BOOL) update:(id)obj
     ignoreNull:(BOOL)ignoreNull;

#pragma mark query

- (NSArray *) queryWithClass:(Class)class
                   condition:(KDatabaseCondition *)cdn;

- (NSArray *) queryWithClass:(Class)class
                   condition:(KDatabaseCondition *)cdn
                       pager:(KDatabasePager *)pager;

- (NSArray *) queryWithTableName:(NSString *)tableName
                       condition:(KDatabaseCondition *)cdn
                           pager:(KDatabasePager *)pager;

- (id) fetchWithClass:(Class)class
                   id:(id)id;

- (id) fetchWithClass:(Class)class
            condition:(KDatabaseCondition *)cdn;

#pragma mark delete

- (BOOL) delete:(id)obj;

- (BOOL) deleteWithClass:(Class)class
                      id:(id)id;

#pragma mark utils

+ (NSString *) columnNameWithClass:(Class)class
                      propertyName:(NSString *)propertyName;

@end
