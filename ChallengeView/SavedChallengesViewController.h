//
//  SavedChallengesViewController.h
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SavedChallengesViewController : UITableViewController

@property NSArray *challenges;

-(void)reloadChallenges;
-(IBAction)doAdd:(id)sender;

@end
