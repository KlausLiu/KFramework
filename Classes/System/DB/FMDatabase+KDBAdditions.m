//
//  FMDatabase+KDBAdditions.m
//  Pods
//
//  Created by klaus on 14-5-2.
//
//

#import "FMDatabase+KDBAdditions.h"
#import "FMDatabaseAdditions.h"

@implementation FMDatabase (KDBAdditions)

- (NSArray *) unExistsAndDeletedColumnNamesWithAllColumnNames:(NSArray *)columnNames
                                              inTableWithName:(NSString *)tableName
{
    NSMutableArray *unExistsColumnNames = [NSMutableArray arrayWithArray:columnNames];
    NSMutableArray *deletedColumnNames = [NSMutableArray array];
    
    tableName  = [tableName lowercaseString];
    FMResultSet *rs = [self getTableSchema:tableName];
    //check if column is present in table schema
    while ([rs next]) {
        NSArray *filter = [unExistsColumnNames
                           filteredArrayUsingPredicate:
                           [NSPredicate predicateWithFormat:@"SELF ==[c] %@",
                            [rs stringForColumn:@"name"]]];
        if (filter.count == 0) {
            [deletedColumnNames addObject:[rs stringForColumn:@"name"]];
        } else {
            [unExistsColumnNames removeObjectsInArray:filter];
        }
    }
    //If this is not done FMDatabase instance stays out of pool
    [rs close];
    
    return @[unExistsColumnNames, deletedColumnNames];
}

@end
