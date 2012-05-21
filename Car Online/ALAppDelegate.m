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
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithWhite:.7 alpha:1.]];
    
    return YES;
}

@end
