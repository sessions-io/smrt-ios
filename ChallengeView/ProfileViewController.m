//
//  ProfileViewController.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/19/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import <SafariServices/SafariServices.h>

#import "ProfileViewController.h"
#import "SessionsConfiguration.h"
#import "SSKeychain.h"
#import "AppDelegate.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doDeleteAccount:(id)sender {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                   message:@"By deleting your account you will lose the completion status of all active and completed challenges. Are you sure you want to do this?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        
    }];
    
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        
        // login with native and return
        NSURLSession *session = [NSURLSession sharedSession];
        NSString *signinEndpoint = [NSString stringWithFormat:@"%@/v1/users/me", [SessionsConfiguration sessionsApiEndpoint]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signinEndpoint] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
        
        [self performSegueWithIdentifier:@"DO_DELETE" sender:self];
        
        [request setHTTPMethod:@"DELETE"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
            if (error || [httpResonse statusCode] != 200) {
                
                NSLog(@"status code = %ld", [httpResonse statusCode]);
                NSLog(@"error deleting user");
                
                [self dismissViewControllerAnimated:YES completion:^{
                    
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                   message:@"Error deleting account"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                        
                    }];
                    
                    [alert addAction:cancelAction];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                }];
                
            } else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
                    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
                    NSString *userId = [defs objectForKey:@"userId"];
                    NSString *endpoint = [SessionsConfiguration sessionsApiEndpoint];
                    [SSKeychain deletePasswordForService:endpoint account:userId];
                    [defs removeObjectForKey:@"userId"];
                    [defs removeObjectForKey:@"anchor"];
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                        
                        AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
                        UINavigationController *ctrl = [self navigationController];
                        [ctrl popToRootViewControllerAnimated:YES];
                        [app signUp];
                        
                    }];
                    
                    
                });
                
            }
            
        }];
        
        [task resume];
        
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(IBAction)doPrivacy:(id)sender {
    
    
    // pass the token along with the URL
    NSURL *privacyURL = [NSURL URLWithString:@"https://blog.sessions.io/privacy"];
    SFSafariViewController *ctrl = [[SFSafariViewController alloc] initWithURL:privacyURL];
    if (ctrl) {
        [self presentViewController:ctrl animated:YES completion:^{
            
        }];
    } else {
        [[UIApplication sharedApplication] openURL:privacyURL];
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
