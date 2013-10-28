//
//  ALRequest.h
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

extern NSString* const ALRequestErrorDomain;

// Reques types
extern NSString* const ALRequestTypeGetPoints;
extern NSString* const ALRequestTypeGetTelemetry;
extern NSString* const ALRequestTypeGetEvents;

typedef NSString* ALRequestType;
typedef void(^ALRequestCallback)(BOOL success, id data);

@interface ALRequest : NSObject

+ (void)setAPIKey:(NSString*)key;
+ (ALRequest*)requestWithType:(ALRequestType)type callback:(ALRequestCallback)callback;

@end
