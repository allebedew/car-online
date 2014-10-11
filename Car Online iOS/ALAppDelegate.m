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

@end
