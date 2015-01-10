//
//  ALAppDelegate.h
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFURLSessionManager;

@interface ALAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readonly) AFURLSessionManager *sessionManager;

+ (instancetype)appDelegate;

@end
