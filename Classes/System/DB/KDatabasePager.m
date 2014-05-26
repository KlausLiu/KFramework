//
//  KDatabasePager.m
//  Pods
//
//  Created by corptest on 14-5-5.
//
//

#import "KDatabasePager.h"
#import "KDefine.h"

#define KDB_Default_Page_Size   (20)

@interface KDatabasePager () {
    NSInteger _pageCount;
    NSUInteger _pageNumber, _pageSize, _recordCount;
}

@end

@implementation KDatabasePager

+ (instancetype) pager
{
    return [self pagerWithPageNumber:1
                            pageSize:KDB_Default_Page_Size];
}

+ (instancetype) pagerWithPageNumber:(NSUInteger)pageNumber
                            pageSize:(NSUInteger)pageSize
{
    return [self pagerWithPageNumber:pageNumber
                            pageSize:pageSize
                         recordCount:0];
}

+ (instancetype) pagerWithPageNumber:(NSUInteger)pageNumber
                            pageSize:(NSUInteger)pageSize
                         recordCount:(NSUInteger)recordCount
{
    KDatabasePager *pager = [[KDatabasePager alloc] init];
    pager.pageNumber = pageNumber;
    pager.pageSize = pageSize;
    pager.recordCount = recordCount;
    return KAutoRelease(pager);
}

- (instancetype) resetPageCount
{
    _pageCount = -1;
    return self;
}

- (instancetype) setPageNumber:(NSUInteger)pageNumber
{
    _pageNumber = pageNumber;
    return self;
}
- (instancetype) setPageSize:(NSUInteger)pageSize
{
    _pageSize = pageSize;
    return self;
}
- (instancetype) setRecordCount:(NSUInteger)recordCount
{
    _recordCount = recordCount;
    _pageCount = (int) ceil((double) recordCount / _pageSize);
    return self;
}

- (NSUInteger) pageNumber
{
    return _pageNumber;
}
- (NSUInteger) pageSize
{
    return _pageSize;
}
- (NSInteger) pageCount
{
    return _pageCount;
}
- (NSUInteger) recordCount
{
    return _recordCount;
}

- (NSString *) toSql
{
    return [NSString stringWithFormat:@" LIMIT %u,%u", (self.pageNumber - 1) * self.pageSize, self.pageSize];
}

@end
