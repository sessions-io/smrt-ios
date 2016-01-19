//
//  AllChallengesViewController.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import "AllChallengesViewController.h"
#import "SavedChallengesViewController.h"
#import "ActiveChallengesViewController.h"
#import "CompletedChallengesViewController.h"
#import "AppDelegate.h"

@interface AllChallengesViewController ()

@end

@implementation AllChallengesViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // load saved, active, completed challenges
    AppDelegate *app = [UIApplication sharedApplication].delegate;
    [app refreshchallenges];

}

-(void)refreshChallenges {
    
    
    UINavigationController *nav = [self.viewControllers objectAtIndex:0];
    SavedChallengesViewController *saved = (SavedChallengesViewController*)[[nav viewControllers] objectAtIndex:0];
    nav = [self.viewControllers objectAtIndex:1];
    ActiveChallengesViewController *active = (ActiveChallengesViewController*)[[nav viewControllers] objectAtIndex:0];
    nav = [self.viewControllers objectAtIndex:2];
    CompletedChallengesViewController *completed = (CompletedChallengesViewController*)[[nav viewControllers] objectAtIndex:0];
    
    [saved reloadChallenges];
    [active reloadChallenges];
    [completed reloadChallenges];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
