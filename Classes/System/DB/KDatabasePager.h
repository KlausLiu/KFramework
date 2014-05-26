//
//  KDatabasePager.h
//  Pods
//
//  Created by corptest on 14-5-5.
//
//

#import <Foundation/Foundation.h>

@interface KDatabasePager : NSObject

+ (instancetype) pager;

+ (instancetype) pagerWithPageNumber:(NSUInteger)pageNumber
                            pageSize:(NSUInteger)pageSize;

+ (instancetype) pagerWithPageNumber:(NSUInteger)pageNumber
                            pageSize:(NSUInteger)pageSize
                         recordCount:(NSUInteger)recordCount;

- (instancetype) resetPageCount;

- (instancetype) setPageNumber:(NSUInteger)pageNumber;
- (instancetype) setPageSize:(NSUInteger)pageSize;
- (instancetype) setRecordCount:(NSUInteger)recordCount;

- (NSUInteger) pageNumber;
- (NSUInteger) pageSize;
- (NSInteger) pageCount;
- (NSUInteger) recordCount;

- (NSString *) toSql;

@end
