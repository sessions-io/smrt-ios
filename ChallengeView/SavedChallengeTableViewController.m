//
//  SavedChallengeTableViewController.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <HealthKit/HealthKit.h>

#import "SavedChallengeTableViewController.h"
#import "SessionsConfiguration.h"
#import "AppDelegate.h"

@interface SavedChallengeTableViewController ()

@end

@implementation SavedChallengeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self loadUIData];
    
}

-(void)loadUIData {
    
    [_challengeDescLabel setText:_challengeDesc];
    [_challengeNameLabel.textLabel setText:_challengeName];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)removeChallege:(id)sender {
    
    // delete challenge from server and pop to root
    NSLog(@"deleting %@", _challengeId);
    NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/saved/%@", [SessionsConfiguration sessionsApiEndpoint], _challengeId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod: @"DELETE"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
        if (connectionError) {
            
            NSLog(@"error adding challenge");
            
        } else {
            
            if ([httpResonse statusCode] == 200) {
             
                [[self navigationController] popToRootViewControllerAnimated:YES];
                AppDelegate *app = [UIApplication sharedApplication].delegate;
                [app refreshchallenges];
                
            } else {
                NSLog(@"delete error");
            }
        }
        
    }];
    
}

-(IBAction)acceptChallenge:(id)sender {
    

    // before we load, check if user has enabled push notifications and healthkit
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    NSNumber *healthEnabled = [defs objectForKey:@"healthPerm"];
    if (!healthEnabled || [healthEnabled integerValue] != 1) {
        
        HKHealthStore *healthInstance = [[HKHealthStore alloc] init];
        AppDelegate *app = [UIApplication sharedApplication].delegate;
        
        // if we haven't asked before, then ask here
        NSSet *types = [[NSSet alloc] initWithObjects:[HKObjectType workoutType], nil];
        
        // just ask for read permission only, we aren't writing workouts
        [healthInstance requestAuthorizationToShareTypes:nil readTypes:types completion:^(BOOL success, NSError * _Nullable error) {
            
            if (error) {
                NSLog(@"ERROR HANDLING HEALTHKIT AUTH: %@", error);
                return;
            }
            
            if (success) {
                [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"healthPerm"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [app installHealthListener];
            } else {
                NSLog(@"Healthkit permission failed");
            }
            
            NSNumber *pushEnabled = [defs objectForKey:@"askedNotifications"];
            if (!pushEnabled) {
                
                UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                
            }
            
            // add challenge
            NSLog(@"accepting %@", _challengeId);
            NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/%@", [SessionsConfiguration sessionsApiEndpoint], _challengeId];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setHTTPMethod: @"PUT"];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                
                NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
                if (connectionError) {
                    
                    NSLog(@"error adding challenge");
                    
                } else {
                    
                    if ([httpResonse statusCode] == 200) {
                        
                        [[self navigationController] popToRootViewControllerAnimated:YES];
                        AppDelegate *app = [UIApplication sharedApplication].delegate;
                        [app refreshchallenges];
                        
                    } else {
                        NSLog(@"delete error");
                    }
                }
                
            }];
            
        }];
        
    } else {
        
        NSNumber *pushEnabled = [defs objectForKey:@"askedNotifications"];
        if (!pushEnabled) {
            
            UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
            
        }
        
        // add challenge
        NSLog(@"accepting %@", _challengeId);
        NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/%@", [SessionsConfiguration sessionsApiEndpoint], _challengeId];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setHTTPMethod: @"PUT"];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
            if (connectionError) {
                
                NSLog(@"error adding challenge");
                
            } else {
                
                if ([httpResonse statusCode] == 200) {
                    
                    [[self navigationController] popToRootViewControllerAnimated:YES];
                    AppDelegate *app = [UIApplication sharedApplication].delegate;
                    [app refreshchallenges];
                    
                } else {
                    NSLog(@"delete error");
                }
            }
            
        }];
    }
    
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
