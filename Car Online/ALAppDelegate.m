//
//  ALAppDelegate.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALAppDelegate.h"

@implementation ALAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] setObject:@"1e23019c8FdbffB2bec223311e1682" forKey:@"api-key"];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithWhite:.3 alpha:1.]];
    [[UITabBar appearance] setTintColor:[UIColor colorWithWhite:.2 alpha:1.]];
    
    // Loading UI
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"] == nil) {
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"api-key"];
    } else {
        self.window.rootViewController = [storyboard instantiateInitialViewController];
    }
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
