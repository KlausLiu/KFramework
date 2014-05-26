//
//  KNSObjectTests.m
//  Demo
//
//  Created by corptest on 14-5-19.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+KExtension.h"
#import "KAPI.h"

@interface KNSObjectTests : XCTestCase

@end

@implementation KNSObjectTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testObjectToNSDictionary
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
    
    
}

@end
