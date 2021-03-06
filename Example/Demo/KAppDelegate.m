//
//  KAppDelegate.m
//  KFrameworkDemo
//
//  Created by corptest on 14-3-6.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KAppDelegate.h"
#import "KCategories.h"
#import "KAPI.h"
#import <KFramework/KNumberUtils.h>

typedef void(^KBasicBlock)(void);

@implementation KAppDelegate

- (void) foo
{
    __block int i1 = 0;
    int i2 = 10;
    
    KBasicBlock block1 = ^{
        i1 += i2;
    };
    i2 = 20;
    block1();
    
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSArray *set = [KNumberUtils randomIntsWithFrom:0 to:20 count:5];
    NSLog(@"%@", set);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
