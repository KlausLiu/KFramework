//
//  KKDBViewController.m
//  Demo
//
//  Created by corptest on 14-5-7.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KKDBViewController.h"
#import "KAPI.h"
#import "KDatabase.h"

@interface KKDBViewController ()

@property (nonatomic, strong) KDatabase *kdb;

@end

@implementation KKDBViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"test.db"];
    NSLog(@"db path:%@", dbPath);
    self.kdb = [KDatabase databaseWithFilePath:dbPath];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) save:(id)sender
{
    TEST_USER *zhangsan = [[TEST_USER alloc] init];
    zhangsan.u_id = 112;
    zhangsan.name = @"张三";
    zhangsan.age = 25;
    zhangsan.oldNames = @[@"张31", @"张san1", @"张33"];
    zhangsan.order_num = @{
                           @"o1" : @5,
                           @"o2" : @"o2v",
                           @"o3" : @"ov33"
                           };
    TEST_ABC *abc = [[TEST_ABC alloc] init];
    abc.a = 123;
    abc.b = @"bbb";
    zhangsan.abc = abc;
    [self.kdb insert:zhangsan];
}

- (IBAction) query:(id)sender
{
    TEST_USER *u = [self.kdb fetchWithClass:[TEST_USER class]
                                         id:@111];
    NSLog(@"%@", [u asNSDictionary]);
    
    NSArray *us = [self.kdb queryWithClass:[TEST_USER class]
                                 condition:[KDatabaseCondition.where(@"name", KDatabaseOperate_eq, @"张三") orderByName:@"name"
                                                                                                                 sort:KDatabaseOrderBySort_desc]
                                     pager:[KDatabasePager pagerWithPageNumber:1 pageSize:20]];
    NSLog(@"%@", [us asNSDictionary]);
}

- (IBAction) update:(id)sender
{
    TEST_USER *u = [self.kdb fetchWithClass:[TEST_USER class]
                                         id:@111];
    NSLog(@"修改前：%@", [u asNSDictionary]);
    
    u.name = @"张三1";
    u.age = 251;
    u.oldNames = @[@"张31", @"张san1", @"张33"];
    u.order_num = @{
                    @"o1" : @51,
                    @"o2" : @"o2v1",
                    @"o3" : @"ov33"
                    };
    TEST_ABC *abc = [[TEST_ABC alloc] init];
    abc.a = 1231;
    abc.b = @"bbb1";
    abc.c = @"cccc";
    u.abc = abc;
    [self.kdb update:u];
    
    u = [self.kdb fetchWithClass:[TEST_USER class]
                              id:@111];
    NSLog(@"修改后：%@", [u asNSDictionary]);
}

- (IBAction) delete:(id)sender
{
    [self.kdb deleteWithClass:[TEST_USER class] id:@111];
    
    NSArray *us = [self.kdb queryWithClass:[TEST_USER class]
                                 condition:[KDatabaseCondition.where(@"name", KDatabaseOperate_eq, @"张三") orderByName:@"name"
                                                                                                                 sort:KDatabaseOrderBySort_desc]
                                     pager:[KDatabasePager pagerWithPageNumber:1 pageSize:20]];
    NSLog(@"%@", [us asNSDictionary]);
}

@end
