//
//  SavedChallengeTableViewController.h
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SavedChallengeTableViewController : UITableViewController

@property IBOutlet UITableViewCell *challengeNameLabel;
@property IBOutlet UILabel *challengeDescLabel;

@property NSString *challengeId;
@property NSString *challengeName;
@property NSString *challengeDesc;

-(IBAction)removeChallege:(id)sender;
-(IBAction)acceptChallenge:(id)sender;

@end
