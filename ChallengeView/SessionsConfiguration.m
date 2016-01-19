//
//  SessionsConfiguration.m
//  ChallengeView
//
//  Created by Jeff Kingyens on 1/18/16.
//  Copyright © 2016 Sessions-io. All rights reserved.
//

#import "SessionsConfiguration.h"

@interface SessionsConfiguration ()

@property (copy, nonatomic) NSString *configuration;
@property (nonatomic, strong) NSDictionary *variables;

@end

@implementation SessionsConfiguration

#pragma mark -
#pragma mark Shared Configuration
+ (SessionsConfiguration *)sharedConfiguration {
    static SessionsConfiguration *_sharedConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConfiguration = [[self alloc] init];
    });
    
    return _sharedConfiguration;
}

#pragma mark -
#pragma mark Private Initialization
- (id)init {
    self = [super init];
    
    if (self) {
        
        // Fetch Current Configuration
        NSBundle *mainBundle = [NSBundle mainBundle];
        _configuration = [[mainBundle infoDictionary] objectForKey:@"Configuration"];
        
        // Load Configurations
        NSString *path = [mainBundle pathForResource:_configuration ofType:@"plist"];
        _variables = [NSDictionary dictionaryWithContentsOfFile:path];
        
    }
    
    return self;
}

#pragma mark -
+ (NSString *)configuration {
    return [[SessionsConfiguration sharedConfiguration] configuration];
}

#pragma mark -
+ (NSString *)sessionsApiEndpoint {
    SessionsConfiguration *sharedConfiguration = [SessionsConfiguration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:@"ServerEndpoint"];
    }
    
    return nil;
}

@end
