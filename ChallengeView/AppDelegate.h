//
//  AppDelegate.h
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/15/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property NSDictionary *launchOpts;

- (BOOL)signUp;
- (BOOL)signIn:(NSString*)userId;

- (BOOL)installHealthListener;
- (BOOL)refreshchallenges;

@end

