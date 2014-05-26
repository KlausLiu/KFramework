//
//  KDBTests.m
//  Demo
//
//  Created by corptest on 14-5-19.
//  Copyright (c) 2014年 corp. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "KDatabase.h"
#import "KSystemAppInfo.h"
#import "KAPI.h"

@interface KDBTests : XCTestCase

@property (nonatomic, strong) KDatabase *db;

@end

@implementation KDBTests

- (void) setUp
{
    [super setUp];
    
    self.db = [KDatabase databaseWithFilePath:[KSystemAppInfo somethingInDocumentsDirectoryWithSomeThing:@"kdb.db"]];
}

- (void) tearDown
{
    [super tearDown];
}

- (void) testInsert
{
    TEST_USER *zhangsan = [[TEST_USER alloc] init];
    zhangsan.u_id = 111;
    zhangsan.name = @"张三";
    zhangsan.age = 25;
    zhangsan.oldNames = @[@"张3", @"张san"];
    zhangsan.order_num = @{
                           @"o1" : @5,
                           @"o2" : @"o2v"
                           };
    TEST_ABC *abc = [[TEST_ABC alloc] init];
    abc.a = 123;
    abc.b = @"bbb";
    zhangsan.abc = abc;
    [self.db insert:zhangsan];
}

@end
