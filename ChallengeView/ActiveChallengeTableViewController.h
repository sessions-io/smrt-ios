//
//  ActiveChallengeTableViewController.h
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/19/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActiveChallengeTableViewController : UITableViewController

@property NSString *challengeId;
@property NSString *challengeName;
@property NSDecimalNumber *challengeProgress;
@property NSArray *sessions;

@end
