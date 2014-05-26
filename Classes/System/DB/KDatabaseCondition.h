//
//  KDatabaseCondition.h
//  Pods
//
//  Created by corptest on 14-5-4.
//
//

#import <Foundation/Foundation.h>

@class KDatabaseCondition;

typedef NS_ENUM(NSInteger, KDatabaseOperate) {
    KDatabaseOperate_eq = 0,
    KDatabaseOperate_ne,
    KDatabaseOperate_gt,
    KDatabaseOperate_lt,
    KDatabaseOperate_ge,
    KDatabaseOperate_le,
    KDatabaseOperate_like,
    KDatabaseOperate_not_like,
    KDatabaseOperate_between,
//    KDatabaseOperate_not_between,
    KDatabaseOperate_in,
    KDatabaseOperate_not_in,
    KDatabaseOperate_is_null,
    KDatabaseOperate_is_not_null,
};

typedef NS_ENUM(NSInteger, KDatabaseOrderBySort) {
    KDatabaseOrderBySort_asc = 0,
    KDatabaseOrderBySort_desc
};

typedef KDatabaseCondition *(^KDataBaseWhereBlock)(NSString *name, KDatabaseOperate op, id value);

typedef KDatabaseCondition *(^KDataBaseWhereBlockC)(Class class);

@interface KDatabaseCondition : NSObject

+ (KDataBaseWhereBlock) where;

- (KDataBaseWhereBlock) and;

- (KDataBaseWhereBlock) or;

- (instancetype) orderByName:(NSString *)name;

- (instancetype) orderByName:(NSString *)name
                        sort:(KDatabaseOrderBySort)sort;

- (KDataBaseWhereBlockC) setClass;

- (NSString *) toSql;

- (NSString *) toSqlWithClass:(Class)class;

@end
