//
//  FMDatabase+KDBAdditions.h
//  Pods
//
//  Created by klaus on 14-5-2.
//
//

#import "FMDatabase.h"

@interface FMDatabase (KDBAdditions)

/*
 拿到不在表中存在的列名
 */
- (NSArray *) unExistsAndDeletedColumnNamesWithAllColumnNames:(NSArray *)columnNames
                                              inTableWithName:(NSString *)tableName;

@end
