//
//  KDatabaseCondition.m
//  Pods
//
//  Created by corptest on 14-5-4.
//
//

#import "KDatabaseCondition.h"
#import "KDefine.h"
#import "KDatabase.h"

typedef NS_ENUM(NSInteger, KDatabaseLogic) {
    KDatabaseLogic_And = 0,
    KDatabaseLogic_Or
};

@interface KDatabaseWhereInfo : NSObject

@property (nonatomic, K_Strong) NSString *        name;
@property (nonatomic, assign) KDatabaseOperate  op;
@property (nonatomic, K_Strong) id                arg;
@property (nonatomic, assign) KDatabaseLogic    logic;

+ (instancetype) whereInfoWithName:(NSString *)name
                                op:(KDatabaseOperate)op
                               arg:(id)arg
                             logic:(KDatabaseLogic)logic;

@end

@interface KDatabaseOrderByInfo : NSObject

@property (nonatomic, K_Strong) NSString *            name;
@property (nonatomic, assign) KDatabaseOrderBySort  sort;

+ (instancetype) orderByInfoWithName:(NSString *)name
                                sort:(KDatabaseOrderBySort)sort;

@end

@interface KDatabaseCondition ()

@property (nonatomic, K_Strong) NSMutableArray *whereInfos;

@property (nonatomic, K_Strong) NSMutableArray *orderByInfos;

@property (nonatomic, assign) Class cdnOfClass;

@end

@implementation KDatabaseCondition

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.whereInfos = [[NSMutableArray alloc] init];
        self.orderByInfos = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    K_Release(self.whereInfos);
    K_Release(self.orderByInfos);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

+ (KDataBaseWhereBlock) where
{
    KDataBaseWhereBlock block = ^ KDatabaseCondition *(NSString *name, KDatabaseOperate op, id value) {
        KDatabaseCondition *cdn = K_Auto_Release([[KDatabaseCondition alloc] init]);
        [cdn __expWithName:name
                        op:op
                     value:value
                     logic:KDatabaseLogic_And];
        return cdn;
    };
    return K_Auto_Release([block copy]);
}

- (KDataBaseWhereBlock) and
{
    KDataBaseWhereBlock block = ^ KDatabaseCondition *(NSString *name, KDatabaseOperate op, id value) {
        [self __expWithName:name
                        op:op
                     value:value
                     logic:KDatabaseLogic_And];
        return self;
    };
    return K_Auto_Release([block copy]);
}

- (KDataBaseWhereBlock) or
{
    KDataBaseWhereBlock block = ^ KDatabaseCondition *(NSString *name, KDatabaseOperate op, id value) {
        [self __expWithName:name
                         op:op
                      value:value
                      logic:KDatabaseLogic_Or];
        return self;
    };
    return K_Auto_Release([block copy]);
}

- (instancetype) orderByName:(NSString *)name
{
    return [self orderByName:name
                 sort:KDatabaseOrderBySort_asc];
}

- (instancetype) orderByName:(NSString *)name
                        sort:(KDatabaseOrderBySort)sort
{
    [self.orderByInfos addObject:[KDatabaseOrderByInfo orderByInfoWithName:name
                                                                      sort:sort]];
    return self;
}

- (KDataBaseWhereBlockC) setClass
{
    KDataBaseWhereBlockC block = ^KDatabaseCondition *(Class class){
        self.cdnOfClass = class;
        return self;
    };
    return K_Auto_Release([block copy]);
}

- (NSString *) toSql
{
    return [self toSqlWithClass:self.cdnOfClass];
}

- (NSString *) toSqlWithClass:(Class)class
{
    if (self.cdnOfClass == nil) {
        self.cdnOfClass = class;
    }
    NSMutableString *sql = [NSMutableString string];
    for (NSInteger i = 0; i < self.whereInfos.count; i ++) {
        KDatabaseWhereInfo *info = [self.whereInfos objectAtIndex:i];
        if (i == 0) {
            [sql appendString:@" WHERE"];
        } else if (info.logic == KDatabaseLogic_And) {
            [sql appendString:@" AND"];
        } else if (info.logic == KDatabaseLogic_Or) {
            [sql appendString:@" OR"];
        }
        NSString *columnName = self.cdnOfClass == nil ? info.name : [KDatabase columnNameWithClass:self.cdnOfClass
                                                                                      propertyName:info.name];
        BOOL isString = [info.arg isKindOfClass:[NSString class]];
        if (!isString && [info.arg isKindOfClass:[NSArray class]] && ((NSArray *)info.arg).count > 0) {
            isString = [((NSArray *)info.arg)[0] isKindOfClass:[NSString class]];
        }
        NSString *op = nil;
        switch (info.op) {
            case KDatabaseOperate_eq:
            case KDatabaseOperate_ne: {
                if (info.arg == nil) {
                    op = info.op == KDatabaseOperate_eq ? @"IS NULL" : @"IS NOT NULL";
                    [sql appendFormat:@" %@ %@", columnName, op];
                    break;
                }
                op = info.op == KDatabaseOperate_eq ? @"=" : @"<>";
                if (isString) {
                    [sql appendFormat:@" %@%@'%@'", columnName, op, [info.arg description]];
                    break;
                }
                [sql appendFormat:@" %@%@%@", columnName, op, [info.arg description]];
                break;
            }
            case KDatabaseOperate_gt:
                op = @">";
            case KDatabaseOperate_lt:
                op = @"<";
            case KDatabaseOperate_ge:
                op = @">=";
            case KDatabaseOperate_le: {
                op == nil ? op = @"<=" : nil;
                if (isString) {
                    [sql appendFormat:@" %@%@'%@'", columnName, op, [info.arg description]];
                    break;
                }
                [sql appendFormat:@" %@%@%@", columnName, op, [info.arg description]];
                break;
            }
            case KDatabaseOperate_like:
                op = @" LIKE ";
            case KDatabaseOperate_not_like: {
                op == nil ? op = @" NOT LIKE " : nil;
                if (isString) {
                    [sql appendFormat:@" %@%@'%@'", columnName, op, [info.arg description]];
                    break;
                }
                [sql appendFormat:@" %@%@%@", columnName, op, [info.arg description]];
                break;
            }
            case KDatabaseOperate_between: {
                NSArray *array = (NSArray *)info.arg;
                if (![array isKindOfClass:[NSArray class]] && array.count == 2) {
                    KDB_Log_Warning(@"KDatabaseOperate_between arg must be array and count is 2.");
                    return nil;
                }
                if (isString) {
                    [sql appendFormat:@" %@ BETWEEN '%@' AND '%@'", columnName, [array[0] description], [array[1] description]];
                    break;
                }
                [sql appendFormat:@" %@ BETWEEN %@ AND %@", columnName, [array[0] description], [array[1] description]];
                break;
            }
            case KDatabaseOperate_in:
                op = @" IN ";
            case KDatabaseOperate_not_in: {
                op == nil ? op = @" NOT IN " : nil;
                NSArray *array = (NSArray *)info.arg;
                if (![array isKindOfClass:[NSArray class]] && array.count == 2) {
                    KDB_Log_Warning(@"KDatabaseOperate_not_in arg must be array.");
                    return nil;
                }
                [sql appendFormat:@" %@%@(%@)", columnName, op, [array componentsJoinedByString:@","]];
            }
            case KDatabaseOperate_is_null:
                op = @" IS NULL";
            case KDatabaseOperate_is_not_null: {
                op == nil ? op = @" IS NOT NULL" : nil;
                [sql appendFormat:@" %@%@", columnName, op];
            }
            default:
                break;
        }
    }
    for (NSInteger i = 0; i < self.orderByInfos.count; i ++) {
        KDatabaseOrderByInfo *info = self.orderByInfos[i];
        if (i == 0) {
            [sql appendString:@" ORDER BY"];
        } else {
            [sql appendString:@","];
        }
        NSString *columnName = self.cdnOfClass == nil ? info.name : [KDatabase columnNameWithClass:self.cdnOfClass
                                                                                      propertyName:info.name];
        [sql appendFormat:@" %@ %@", columnName, (info.sort == KDatabaseOrderBySort_asc ? @"ASC" : @"DESC")];
    }
    return sql;
}

- (void) __expWithName:(NSString *)name
                    op:(KDatabaseOperate)op
                 value:(id)value
                 logic:(KDatabaseLogic)logic
{
    [self.whereInfos addObject:[KDatabaseWhereInfo whereInfoWithName:name
                                                                  op:op
                                                                 arg:value
                                                               logic:logic]];
}

@end

@implementation KDatabaseWhereInfo

+ (instancetype) whereInfoWithName:(NSString *)name
                                op:(KDatabaseOperate)op
                               arg:(id)arg
                             logic:(KDatabaseLogic)logic
{
    KDatabaseWhereInfo *whereInfo = [[KDatabaseWhereInfo alloc] init];
    whereInfo.name = name;
    whereInfo.op = op;
    whereInfo.arg = arg;
    whereInfo.logic = logic;
    return K_Auto_Release(whereInfo);
}

- (void)dealloc
{
    K_Release(self.name);
    K_Release(self.arg);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

@end

@implementation KDatabaseOrderByInfo

+ (instancetype) orderByInfoWithName:(NSString *)name
                                sort:(KDatabaseOrderBySort)sort
{
    KDatabaseOrderByInfo *whereInfo = [[KDatabaseOrderByInfo alloc] init];
    whereInfo.name = name;
    whereInfo.sort = sort;
    return K_Auto_Release(whereInfo);
}

- (void)dealloc
{
    K_Release(self.name);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

@end
