//
//  ALRequest.h
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALCarInfo.h"

extern NSString* const ALRequestErrorDomain;

@class ALRequest;

@protocol ALRequestDelegate <NSObject>

- (void)requestDidUpdateProgress:(ALRequest*)request;

@end

typedef void(^ALRequestCallback)(ALCarInfo *carInfo);

@interface ALRequest : NSObject

+ (void)setAPIKey:(NSString*)key;

+ (ALRequest*)requestCarLocationWithCallback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate;
+ (ALRequest*)requestCarTelemetryWithCallback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate;
+ (ALRequest*)requestCarEventsWithCallback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate;

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) float progress;

@end

@interface ALCarLocationRequest : ALRequest

@end
