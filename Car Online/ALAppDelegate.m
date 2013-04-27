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
    
    // appearence
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithWhite:.60 alpha:1.]];
    
    /*
    self.window = [[UIWindow alloc] init];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"] != nil) {
        self.window.rootViewController = [storyboard instantiateInitialViewController];
    } else {
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"api-key"];
    }
    [self.window makeKeyAndVisible];
    */
    
    [[NSUserDefaults standardUserDefaults] setObject:@"1e23019c8FdbffB2bec223311e1682" forKey:@"api-key"];
    
    return YES;
}

@end
