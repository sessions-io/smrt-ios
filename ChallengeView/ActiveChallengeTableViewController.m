//
//  ActiveChallengeTableViewController.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/19/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import "ActiveChallengeTableViewController.h"
#import "ProgressTableViewCell.h"

@interface ActiveChallengeTableViewController ()

@end

@implementation ActiveChallengeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0 || section == 1) {
        return 1;
    } else {
        if (!_sessions) {
            return 0;
        } else {
            return [_sessions count];
        }
    }
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = @"Name";
            break;
        case 1:
            sectionName = @"Progress";
            break;
        default:
            sectionName = @"Sessions";
            break;
    }
    return sectionName;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // the title of the challenge
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TITLE" forIndexPath:indexPath];
        [cell.textLabel setText:_challengeName];
        NSLog(@"setting name = %@", _challengeName);
        return cell;
    }
    
    // the progress of the challenge
    if (indexPath.section == 1) {
        ProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PROGRESS" forIndexPath:indexPath];
        [cell.progress setProgress:[_challengeProgress floatValue] animated:YES];
        return cell;
    }
    
    // the sessions that contribute to challenge
    if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACTIVITY" forIndexPath:indexPath];
        NSDictionary *session = [_sessions objectAtIndex:indexPath.row];
        NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
        [fmt setPositiveFormat:@"0.##"];
        NSString *interval = [fmt stringFromNumber:[session objectForKey:@"interval"]];
        NSString *distance = [fmt stringFromNumber:[session objectForKey:@"distance"]];
        NSString *activity = [session objectForKey:@"activity"];
        NSString *printedWalk;
        if ([activity isEqualToString:@"walk"]) {
            printedWalk = @"Walked";
        } else {
            if ([activity isEqualToString:@"run"]) {
                printedWalk = @"Ran";
            } else {
                printedWalk = @"Cycled";
            }
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%@ for %@ miles in %@ seconds", printedWalk, distance, interval];
        return cell;
        return cell;
    }
    
    return nil;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

@end
