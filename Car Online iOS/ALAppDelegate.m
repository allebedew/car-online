//
//  ALAppDelegate.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALAppDelegate.h"

#import "AFNetworking.h"

@import CoreLocation;

@interface ALAppDelegate ()

@property (nonatomic, strong, readwrite) AFURLSessionManager *sessionManager;

@end

@implementation ALAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setObject:@"1e23019c8FdbffB2bec223311e1682" forKey:@"api-key"];
  
    // Loading UI
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"] == nil) {
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"settings"];
    } else {
        self.window.rootViewController = [storyboard instantiateInitialViewController];
    }
    [self.window makeKeyAndVisible];
  
    return YES;
}

+ (instancetype)appDelegate {
    return [UIApplication sharedApplication].delegate;
}

- (AFURLSessionManager*)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:nil];
    }
    return _sessionManager;
}

@end
