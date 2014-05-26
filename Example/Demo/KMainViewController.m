//
//  KMainViewController.m
//  Demo
//
//  Created by klaus on 14-3-15.
//  Copyright (c) 2014年 corp. All rights reserved.
//

#import "KMainViewController.h"


@interface KMainViewController ()

@property (nonatomic, strong) NSMutableArray * data;

@end

@implementation KMainViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.data = [NSMutableArray arrayWithObjects:
                 @"WVJB",
                 @"network/object to json/json to object",
                 @"kdb",
                 nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [self.data objectAtIndex:indexPath.row];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = nil;
    switch (indexPath.row) {
        case 0:
            identifier = @"wvjb";
            break;
        case 1:
            identifier = @"network";
            break;
            break;
        case 2:
            identifier = @"kdb";
            break;
    }
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    if (viewController) {
        [self.navigationController pushViewController:viewController
                                             animated:YES];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:@"没有对应的view controller"
                                   delegate:nil
                          cancelButtonTitle:@"确定"
                          otherButtonTitles:nil] show];
    }
}

@end
