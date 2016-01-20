//
//  AppDelegate.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/15/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <HealthKit/HealthKit.h>

#import "AppDelegate.h"
#import "SessionsConfiguration.h"
#import "SSKeychain.h"
#import "AllChallengesViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // save launch options
    _launchOpts = launchOptions;

    // if signed in, install push and health listenerss
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *userId = [defs objectForKey:@"userId"];
    if (userId) {
        
        // if we've asked for healthkit and we have access, then register
        NSNumber *healthAsked = [defs objectForKey:@"healthPerm"];
        if (healthAsked && [healthAsked integerValue] == 1) {
            [self installHealthListener];
        }
        
    }
    
    return YES;
}

// called by root view controller
- (BOOL)refreshchallenges {
    
    // if signed in, install push and health listenerss
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *userId = [defs objectForKey:@"userId"];
    
    if (userId) {

        // sign in and refresh the user list
        return [self signIn:userId];
        
    } else {
     
        // perform signup or sign in
        return [self signUp];
        
    }
    
}

- (BOOL)signUp {
    
    // create a password
    NSString *password = CFBridgingRelease(SecCreateSharedWebCredentialPassword());
    if (!password) {
        return NO;
    }

    // serialize password
    NSDictionary *params = @{ @"password": password };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"error encoding user data");
        return NO;
    }
    
    // post user with password
    NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me2", [SessionsConfiguration sessionsApiEndpoint]];
    NSLog(@"signin endpoint = %@", signinEndpoint);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod: @"POST"];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable urlResponse, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)urlResponse;
        if (error || [httpResonse statusCode] != 201) {
            return NSLog(@"error registering user");
        }
        
        // save userid and password for later launches
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *userId = [response objectForKey:@"id"];
        NSString *service = [SessionsConfiguration sessionsApiEndpoint];
        BOOL status = [SSKeychain setPassword:password forService:service account:userId];
        if (status) {
            NSLog(@"signing up %@", userId);
            NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
            [defs setObject:userId forKey:@"userId"];
            if ([defs objectForKey:@"askedNotifications"]) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
            if ([defs objectForKey:@"healthPerm"]) {
                [self installHealthListener];
            }
            [defs synchronize];
        }
        
        NSLog(@"user signed up");
        NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"responseBody: %@", responseBody);
        AllChallengesViewController *ctrl = (AllChallengesViewController*)_window.rootViewController;
        [ctrl refreshChallenges];
        
    }];
    [task resume];
    
    return YES;
    
}

- (BOOL)signIn:(NSString*)userId {
    
    // get the username and password
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSString *endpoint = [SessionsConfiguration sessionsApiEndpoint];
    NSString *password = [SSKeychain passwordForService:endpoint account:userId];
    if (!password) {
        [defs removeObjectForKey:@"userId"];
        [defs synchronize];
        return NO;
    }

    // encode sign in infomration
    NSDictionary *params = @{ @"username": userId, @"password": password };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NO;
    }

    // perform sign in
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/native2", [SessionsConfiguration sessionsApiEndpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
        if (error || [httpResonse statusCode] != 200) {
            
            NSLog(@"status code = %ld", [httpResonse statusCode]);
            NSLog(@"error signing in");
            
            if ([httpResonse statusCode] == 404) {
                
                [defs removeObjectForKey:@"userId"];
                [self signUp];
                
            } else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Service Error"
                                                                                   message:@"We are having trouble signing in. Please try again later."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        
                        
                    }];
                    
                    [alert addAction:defaultAction];
                    [_window.rootViewController presentViewController:alert animated:YES completion:nil];
                    
                });
                
            }
            
        } else {
            
            // if we've asked for notifiations and we have access, then register
            if ([defs objectForKey:@"askedNotifications"]) {
                NSLog(@"registering");
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            }
            
            NSLog(@"user signed in %@", userId);
            NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"responseBody: %@", responseBody);
            AllChallengesViewController *ctrl = (AllChallengesViewController*)_window.rootViewController;
            [ctrl refreshChallenges];
            
        }
        
    }];
    [task resume];
    return YES;

}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:@(1) forKey:@"askedNotifications"];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
}

// install background healthkit listener
- (BOOL)installHealthListener {
    
    NSLog(@"installing health listener");
 
    // check for healthkit support
    if (![HKHealthStore isHealthDataAvailable]) {
        return NO;
    }
    
    // install the real-time background listener
    HKHealthStore *healthInstance = [[HKHealthStore alloc] init];
    HKSampleType *sampleType = [HKObjectType workoutType];
    [healthInstance enableBackgroundDeliveryForType:sampleType frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {
        if (error) {
            return NSLog(@"error enabling background delivery: %@", error);
        }
    }];
    
    // set the background handler
    HKObserverQuery *query = [[HKObserverQuery alloc]
                              initWithSampleType:sampleType
                              predicate:nil
                              updateHandler:^(HKObserverQuery * _Nonnull query, HKObserverQueryCompletionHandler  _Nonnull completionHandler, NSError * _Nullable error) {
                                  
                                  if (error) {
                                      NSLog(@"Observer query error: %@", error);
                                      return completionHandler();
                                  }
                                  
                                  // if user is not signed in, then ignore this
                                  NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
                                  if (!userId) {
                                      NSLog(@"no user id, so dont do anything with data");
                                      return completionHandler();
                                  }
                                  
                                  // marker to continue stream query
                                  NSUInteger anchor = HKAnchoredObjectQueryNoAnchor;
                                  NSNumber *savedAnchor = [[NSUserDefaults standardUserDefaults] objectForKey:@"anchor"];
                                  if (savedAnchor) {
                                      anchor = [savedAnchor unsignedIntegerValue];
                                  }
                                  
                                  // execute an anchored query
                                  HKAnchoredObjectQuery *anchorQuery = [[HKAnchoredObjectQuery alloc]
                                                                        initWithType:sampleType
                                                                        predicate:nil
                                                                        anchor:anchor
                                                                        limit:HKObjectQueryNoLimit
                                                                        completionHandler:^(HKAnchoredObjectQuery *query,
                                                                                            NSArray *results,
                                                                                            NSUInteger newAnchor,
                                                                                            NSError *error) {

                                                                            // error reading workouts
                                                                            if (error) {
                                                                                NSLog(@"%@", error.localizedDescription);
                                                                                return completionHandler();
                                                                            }
                                                                            
                                                                            // we should eat old previous workouts
                                                                            if (anchor == HKAnchoredObjectQueryNoAnchor) {
                                                                                [[NSUserDefaults standardUserDefaults] setObject:[[NSNumber alloc] initWithUnsignedInteger:newAnchor] forKey:@"anchor"];
                                                                                return completionHandler();
                                                                            }
                                                                            
                                                                            // filter incoming workouts
                                                                            NSMutableArray *newWorkouts = [[NSMutableArray alloc] init];

                                                                            for (HKWorkout *sample in results) {
                                                                                
                                                                                // skip manual records
                                                                                /*
                                                                                NSDictionary *meta = sample.metadata;
                                                                                if ([meta objectForKey:@"HKWasUserEntered"]) {
                                                                                    continue;
                                                                                }
                                                                                */
                                                                                
                                                                                // skip unsupported activitiess
                                                                                NSString *activityString;
                                                                                HKWorkoutActivityType wt = sample.workoutActivityType;
                                                                                if (wt == HKWorkoutActivityTypeRunning || wt == HKWorkoutActivityTypeWalking || wt == HKWorkoutActivityTypeCycling) {
                                                                                    if (wt == HKWorkoutActivityTypeWalking) {
                                                                                        activityString = @"walk";
                                                                                    } else {
                                                                                        if (wt == HKWorkoutActivityTypeCycling ) {
                                                                                            activityString = @"cycle";
                                                                                        } else {
                                                                                            activityString = @"run";
                                                                                        }
                                                                                    }
                                                                                } else {
                                                                                    continue;
                                                                                }
                                                                                
                                                                                // convert date, time, units
                                                                                HKQuantity *distance = sample.totalDistance;
                                                                                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                                                                                [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
                                                                                NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                                                                                [dateFormatter setTimeZone:timeZone];
                                                                                NSString *startDate = [dateFormatter stringFromDate:sample.startDate];
                                                                                NSString *endDate = [dateFormatter stringFromDate:sample.endDate];
                                                                                
                                                                                NSTimeInterval interval = sample.duration;
                                                                                NSDictionary *workout = @{
                                                                                                          @"start": startDate,
                                                                                                          @"end": endDate,
                                                                                                          @"activity": activityString,
                                                                                                          @"distance": [[NSNumber alloc] initWithDouble:[distance doubleValueForUnit:[HKUnit mileUnit]]],
                                                                                                          @"interval": [[NSNumber alloc] initWithDouble:interval]
                                                                                                          };
                                                                                
                                                                                [newWorkouts addObject:workout];
                                                                                
                                                                            }
                                                                            
                                                                            // if we have nothing, then done
                                                                            if (![newWorkouts count]) {
                                                                                [[NSUserDefaults standardUserDefaults] setObject:[[NSNumber alloc] initWithUnsignedInteger:newAnchor] forKey:@"anchor"];
                                                                                return completionHandler();
                                                                            }

                                                                            // serialize activity for transmission
                                                                            NSError *err;
                                                                            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:newWorkouts options:NSJSONWritingPrettyPrinted error:&err];
                                                                            if (err) {
                                                                                return completionHandler();
                                                                            }
                                                                        
                                                                            // push new activiites
                                                                            NSString *endpoint = [NSString stringWithFormat:@"%@/v1/users/me/addsessions2", [SessionsConfiguration sessionsApiEndpoint]];
                                                                            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
                                                                            [request setHTTPMethod: @"POST"];
                                                                            [request setHTTPBody:jsonData];
                                                                            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                                                                            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                                                                            [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
                                                                            if (error) {
                                                                                return NSLog(@"error encoding json: %@", error);
                                                                            }
                                                                            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                                                                            sessionConfig.allowsCellularAccess = YES;
                                                                            NSURLSession *sendSessions = [NSURLSession sessionWithConfiguration:sessionConfig];
                                                                            NSURLSessionDataTask *task = [sendSessions uploadTaskWithRequest:request fromData:jsonData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                                
                                                                                if (error) {
                                                                                    NSLog(@"error connecting to server to send activity");
                                                                                    return completionHandler();
                                                                                }
                                                                                
                                                                                NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
                                                                                if ([resp statusCode] != 201) {
                                                                                    NSLog(@"did not successful send new activities");
                                                                                    return completionHandler();
                                                                                }
                                                                                
                                                                                NSLog(@"successfully transferred new activities");
                                                                                [[NSUserDefaults standardUserDefaults] setObject:[[NSNumber alloc] initWithUnsignedInteger:newAnchor] forKey:@"anchor"];
                                                                                
                                                                                completionHandler();
                                                                                
                                                                            }];
                                                                            [task resume];
                                                                            
                                                                        }];
                                  
                                  // execute this new query
                                  [healthInstance executeQuery:anchorQuery];
                                  
                              }];
    
    // start the observer query
    [healthInstance executeQuery:query];
    return YES;
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    
    // skip other user
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    NSString *messageUserId = [userInfo objectForKey:@"userId"];
    if (!userId || ![userId isEqualToString:messageUserId]) {
        return completionHandler(UIBackgroundFetchResultNoData);
    }
    
    // handle challenge completed
    if ([[userInfo objectForKey:@"type"] isEqualToString:@"challenge_completed"]) {
        
        // refresh challenges
        [self refreshchallenges];
        return completionHandler(UIBackgroundFetchResultNewData);
        
    }
    
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    
    // save the token
    NSString *devTokes = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    devTokes = [devTokes stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // return user id
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    if (!userId) {
        return;
    }
    
    // post this device token to the user settings
    NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/devices", [SessionsConfiguration sessionsApiEndpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    
    NSError *error;
    NSData *jsonData;
    NSDictionary *params = @{ @"token": devTokes };
    jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&error];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
    if (error) {
        return NSLog(@"error encoding json: %@", error);
    }
    
    [request setHTTPMethod: @"POST"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
        if (connectionError) {
            NSLog(@"error updating device token");
        } else {
            if ([httpResonse statusCode] == 200) {
                NSLog(@"token exists");
            } else {
                if ([httpResonse statusCode] == 201) {
                    NSLog(@"token added");
                } else {
                    NSLog(@"unknown token response: %ld", [httpResonse statusCode]);
                }
            }
        }
    }];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
