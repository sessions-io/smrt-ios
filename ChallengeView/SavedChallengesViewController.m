//
//  SavedChallengesViewController.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import "SavedChallengesViewController.h"
#import "SessionsConfiguration.h"
#import "AppDelegate.h"

@interface SavedChallengesViewController ()

@end

@implementation SavedChallengesViewController

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
    NSString *serverEndpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges/saved", [SessionsConfiguration sessionsApiEndpoint]];
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
                
            });
    
        }
        
    }];
    [task resume];

}

// add a challenge to the saved list
-(IBAction)doAdd:(id)sender {
    
    UIAlertController *ctrl = [UIAlertController alertControllerWithTitle:@"Add Challenge" message:@"Enter URL" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *loadbutton = [UIAlertAction actionWithTitle:@"Load" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        NSString *url = [ctrl.textFields objectAtIndex:0].text;
        
        // fetch this challenge from the URL into dictionary
        NSURLSession *session = [NSURLSession sharedSession];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
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
                NSDictionary *dictResp = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error) {
                    return;
                }
                
                // verify signature from the JSON data
                NSString *signature = [dictResp objectForKey:@"sessions"];
                if (!signature || ![signature isEqualToString:@"0.1.0"]) {
                    return;
                }
                
                // now we can push this challenge into the users list
                NSString *endpoint = [NSString stringWithFormat:@"%@/v1/users/me/challenges2", [SessionsConfiguration sessionsApiEndpoint]];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
                [request setHTTPMethod: @"POST"];
                [request setHTTPBody:data];
                [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
                if (error) {
                    return NSLog(@"error encoding json: %@", error);
                }
                NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                NSURLSession *sendChallenge = [NSURLSession sessionWithConfiguration:sessionConfig];
                NSURLSessionDataTask *task = [sendChallenge uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                
                    if (error) {
                        return NSLog(@"error saving challenge to server");
                    }
                    
                    NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
                    if ([resp statusCode] != 201) {
                        return NSLog(@"error saving challenge on server: %ld", [resp statusCode]);
                    }
                
                    NSLog(@"Challenge saved");
                    
                    AppDelegate *app = [UIApplication sharedApplication].delegate;
                    [app refreshchallenges];
                    
                }];
                [task resume];
                
            }
            
        }];
        
        [task resume];

    }];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    
        
    }];
    
    [ctrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        [textField setKeyboardType:UIKeyboardTypeURL];
        
    }];
    
    [ctrl addAction:loadbutton];
    [ctrl addAction:cancelButton];
    
    [self presentViewController:ctrl animated:YES completion:^{
        
        
        
    }];
    
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
    return NO;
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
