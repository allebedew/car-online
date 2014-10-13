//
//  ALRequest.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALRequest.h"
#import "Convertions.h"

#define LOG YES

NSString* const ALRequestAPIKey = @"api-key";
NSString* const ALRequestErrorDomain = @"com.alexlebedev.alrequest";

float const responseProgressWeight = 0.3f;

@interface ALRequest () <NSURLConnectionDelegate>

@property (nonatomic, copy) NSString *command;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) ALRequestCallback callback;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, weak) id <ALRequestDelegate> delegate;

@end

@implementation ALRequest

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ [command = %@, progress = %f]", [super description], self.command, self.progress];
}

+ (void)setAPIKey:(NSString*)key {
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:ALRequestAPIKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (ALRequest*)requestCarLocationWithCallback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate {
    return [self requestWithCommand:@"gpslist" callback:callback delegate:delegate];
}

+ (ALRequest*)requestCarTelemetryWithCallback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate {
    return [self requestWithCommand:@"telemetry" callback:callback delegate:delegate];
}

+ (ALRequest*)requestCarEventsWithCallback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate {
    return [self requestWithCommand:@"events" callback:callback delegate:delegate];
}

+ (ALRequest*)requestWithCommand:(NSString*)command callback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate {
    ALRequest *request = [[ALRequest alloc] initWithRequestCommand:command callback:callback delegate:delegate];
    [request configureRequest];
    [request run];
    return request;
}

- (id)initWithRequestCommand:(NSString*)command callback:(ALRequestCallback)callback delegate:(id <ALRequestDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _command = [command copy];
        _callback = [callback copy];
    }
    return self;
}

- (void)notify_requestProgressUpdate:(float)progress running:(BOOL)running {
    self.running = running;
    self.progress = progress;
    [self.delegate requestDidUpdateProgress:self];
}

+ (NSURL*)urlWithKey:(NSString*)key comand:(NSString*)comand beginDate:(NSDate*)beginDate endDate:(NSDate*)endDate {
  NSParameterAssert(key != nil && comand != nil);
  
  if (!beginDate) {
      
      beginDate = [NSDate startOfTheDayDate];
//      beginDate = [NSDate dateWithTimeIntervalSince1970:[beginDate timeIntervalSince1970] - 86400];
  }
  NSLog(@"%@ %@", [NSDate date], [NSDate startOfTheDayDate]);
  NSString *beginDateString = [NSString stringWithFormat:@"%.0f000", [beginDate timeIntervalSince1970]];
  
  NSMutableArray *queryItems = [@[
    [NSURLQueryItem queryItemWithName:@"skey" value:key],
    [NSURLQueryItem queryItemWithName:@"get" value:comand],
    [NSURLQueryItem queryItemWithName:@"begin" value:beginDateString] ] mutableCopy];
  
  if (endDate) {
    NSString *endDateString = [NSString stringWithFormat:@"%.0f000", [endDate timeIntervalSince1970]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"end" value:endDateString]];
  }

  NSURLComponents *urlComp = [[NSURLComponents alloc] init];
  urlComp.scheme = @"http";
  urlComp.host = @"api.car-online.ru";
  urlComp.path = @"/v2";
  urlComp.queryItems = queryItems;
  
  return urlComp.URL;
}

- (void)configureRequest {
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:ALRequestAPIKey];
    if (!apiKey) {
        NSLog(@"%@: no api key", self.class);
        
        NSError *error = [NSError errorWithDomain:ALRequestErrorDomain code:-2 userInfo:nil];
        [self finalizeRequestWithResult:nil error:error];
        return;
    }
  
    self.url = [[self class] urlWithKey:apiKey comand:self.command beginDate:nil endDate:nil];
}

- (void)run {
    [self notify_requestProgressUpdate:0.0f running:YES];
    
    NSLog(@"%@ loading url %@", [self class], self.url);
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [self.connection start];
#if !DESKTOP
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
}

- (ALCarInfo*)generateResultObject {
    ALCarInfo *carInfo = nil;
    if ([self.command isEqualToString:@"gpslist"]) {
        carInfo = [[ALCarLocation alloc] initWithServerData:self.receivedData];
    } else if ([self.command isEqualToString:@"telemetry"]) {
        carInfo = [[ALCarTelemetry alloc] initWithServerData:self.receivedData];
    } else if ([self.command isEqualToString:@"events"]) {
        carInfo = [[ALCarEvents alloc] initWithServerData:self.receivedData];
    } else {
        NSAssert(NO, @"Wrong request type");
    }
    return carInfo;
}

- (void)finalizeRequestWithResult:(ALCarInfo*)result error:(NSError *)error {
    [self notify_requestProgressUpdate:1.0f running:NO];
    
    if (result.error) {
        error = result.error;
    }
    
    if (error) {
#if !DESKTOP
        [[[UIAlertView alloc] initWithTitle:@"Server Request Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
        result = nil;
    }
    
    if (self.callback) {
        self.callback(result);
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#if !DESKTOP
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    [self finalizeRequestWithResult:nil error:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self notify_requestProgressUpdate:responseProgressWeight running:YES];
    self.response = (NSHTTPURLResponse*)response;
    self.receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    float dataProgress;
    if (self.response.expectedContentLength == -1) {
        dataProgress = 0.5f;
    } else {
        dataProgress = MAX((double)self.response.expectedContentLength / (double)data.length, 1.0f);
    }
    float overallProgress = responseProgressWeight + (dataProgress * (1.0f - responseProgressWeight));
    [self notify_requestProgressUpdate:overallProgress running:YES];
    [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
#if !DESKTOP
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    ALCarInfo *result = [self generateResultObject];
    [self finalizeRequestWithResult:result error:nil];
}

@end
