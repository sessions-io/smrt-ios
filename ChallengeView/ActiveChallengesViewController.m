//
//  ActiveChallengesViewController.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import "ActiveChallengesViewController.h"
#import "SessionsConfiguration.h"
#import "SavedChallengeTableViewController.h"
#import "AppDelegate.h"
#import "ActiveChallengeTableViewController.h"

@interface ActiveChallengesViewController ()

@end

@implementation ActiveChallengesViewController

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

-(void)reloadChallenges {
    
    // fetch this challenge from the URL into dictionary
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *serverEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/active", [SessionsConfiguration sessionsApiEndpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"GET"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
        if (error || [httpResonse statusCode] != 200) {
            
            NSLog(@"status code = %ld", (long)[httpResonse statusCode]);
            NSLog(@"error loading challenge");
            
        } else {
            
            // parse the challenge JSON object
            NSError *error;
            _challenges = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"error decoding challenges array");
            }
            
            dispatch_async(dispatch_get_main_queue(), ^() {
                
                // refresh the utiableviewlist
                [[self tableView] reloadData];
                
                // if we are showing a detail view, reload it as well
                UINavigationController *ctrl = [self navigationController];
                UIViewController *top = [ctrl topViewController];
                if (top != self && [top isKindOfClass:UITableViewController.class]) {
                    
                    [ctrl popToRootViewControllerAnimated:YES];
                    
                }

            });
            
        }
        
    }];
    [task resume];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_challenges) {
        return 0;
    }
    return [_challenges count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CHALLENGE" forIndexPath:indexPath];
    
    NSDictionary *challenge = [_challenges objectAtIndex:indexPath.row];
    [cell.textLabel setText:[challenge objectForKey:@"name"]];
    return cell;
    
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // If row is deleted, remove it from the list.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"Drop Challenge" message:@"Would you like to re-save or remove this challenge completely?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *resaveButton = [UIAlertAction actionWithTitle:@"Re-save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *challengeId = [[_challenges objectAtIndex:indexPath.row] objectForKey:@"id"];
            NSLog(@"re-saving %@", challengeId);
            NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/active/%@", [SessionsConfiguration sessionsApiEndpoint], challengeId];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setHTTPMethod: @"PUT"];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                
                NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
                if (connectionError) {
                    
                    NSLog(@"error adding challenge");
                    
                } else {
                    
                    if ([httpResonse statusCode] == 200) {
                        
                        NSMutableArray *updated = [[NSMutableArray alloc] initWithArray:_challenges];
                        [updated removeObjectAtIndex:indexPath.row];
                        _challenges = [[NSArray alloc] initWithArray:updated];
                        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                        AppDelegate *app = [UIApplication sharedApplication].delegate;
                        [app refreshchallenges];
                        
                    } else {
                        NSLog(@"delete error");
                    }
                }
                
            }];
            
        }];
        
        UIAlertAction *removeButton = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
           
            NSString *challengeId = [[_challenges objectAtIndex:indexPath.row] objectForKey:@"id"];
            NSLog(@"deleting %@", challengeId);
            NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/active/%@", [SessionsConfiguration sessionsApiEndpoint], challengeId];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setHTTPMethod: @"DELETE"];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                
                NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
                if (connectionError) {
                    
                    NSLog(@"error adding challenge");
                    
                } else {
                    
                    if ([httpResonse statusCode] == 200) {
                        
                        NSMutableArray *updated = [[NSMutableArray alloc] initWithArray:_challenges];
                        [updated removeObjectAtIndex:indexPath.row];
                        _challenges = [[NSArray alloc] initWithArray:updated];
                        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                        
                    } else {
                        NSLog(@"delete error");
                    }
                }
                
            }];
            
        }];
        
        [ctrl addAction:resaveButton];
        [ctrl addAction:removeButton];
        
        [self presentViewController:ctrl animated:YES completion:^{
            
            
        }];
        
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Drop";
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].

    if ([[segue identifier] isEqualToString:@"CHALLENGE_DETAIL"]) {
        
        ActiveChallengeTableViewController *ctrl = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSDictionary *challenge = [_challenges objectAtIndex:indexPath.row];
        
        NSLog(@"challenge = %@", challenge);
        ctrl.challengeName = [challenge objectForKey:@"name"];
        ctrl.challengeId = [challenge objectForKey:@"id"];
        ctrl.challengeProgress = [challenge objectForKey:@"progress"];
        ctrl.sessions = [challenge objectForKey: @"sessions"];
        
    }
    
}

@end
