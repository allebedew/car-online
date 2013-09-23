//
//  ALRequest.h
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const ALRequestErrorDomain;

typedef NS_ENUM(NSInteger, ALRequestCommand) {
    ALRequestCommandPoints,
    ALRequestCommandTelemetry,
    ALRequestCommandEvents
};

typedef void(^ALRequestCallback)(BOOL success, id data);

@interface ALRequest : NSObject

+ (ALRequest*)requestWithType:(ALRequestCommand)command callback:(ALRequestCallback)callback;

@end
