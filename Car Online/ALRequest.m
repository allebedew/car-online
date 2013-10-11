//
//  ALRequest.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALRequest.h"
#import "GDataXMLNode.h"

#define LOG YES
#define SERVER_TIME_ZONE 4

NSString* const ALRequestErrorDomain = @"com.alexlebedev.alrequest";
NSString* const ALRequestTypeGetPoints = @"request-type-get-points";
NSString* const ALRequestTypeGetTelemetry = @"request-type-get-telemetry";
NSString* const ALRequestTypeGetEvents = @"request-type-get-events";

@interface ALRequest () <NSURLConnectionDelegate>

@property (nonatomic, strong) ALRequestType requestType;
@property (nonatomic, strong) ALRequestCallback callback;
@property (nonatomic, strong) NSDictionary *requestInfo;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation ALRequest

+ (ALRequest*)requestWithType:(ALRequestType)type callback:(ALRequestCallback)callback {
    ALRequest *request = [[ALRequest alloc] initWithType:type callback:callback];
    [request run];
    return request;
}

- (id)initWithType:(ALRequestType)type callback:(ALRequestCallback)callback {
    self = [super init];
    if (self) {
        self.requestType = type;
        self.callback = callback;
        
        static NSDictionary *config = nil;
        if (!config) {
            config = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:NSStringFromClass([self class]) ofType:@"plist"]] objectForKey:@"request-types"];
        }
        
        self.requestInfo = config[self.requestType];
        if (!self.requestInfo) {
            NSLog(@"%@: can't find config for command (%@)", [self class], self.requestInfo);
            callback(NO, nil);
            return nil;
        }
    }
    return self;
}

- (void)run {
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"];
    NSAssert(apiKey != nil, @"No API Key");
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"http://api.car-online.ru/do?skey=%@&data=%@&content=xml", apiKey, self.requestInfo[@"data-param-value"]];
    if (LOG)
        NSLog(@"%@ loading url %@", [self class], urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [self.connection start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)processReceivedData {
    NSError *error = nil;
    GDataXMLDocument *xml = [[GDataXMLDocument alloc] initWithData:self.receivedData options:0 error:&error];
    if (error) {
        [self processError:error];
        return;
    }
    if ([xml.rootElement.name isEqual:@"error"]) {
        NSError *error = [NSError errorWithDomain:ALRequestErrorDomain code:-1 userInfo:nil];
        [self processError:error];
        return;
    }

    // Parsing
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ddMMyyyy_HHmmss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:60*60*SERVER_TIME_ZONE]];

    NSMutableArray *result = [NSMutableArray array];
    for (GDataXMLElement *element in xml.rootElement.children) {
        if (![element isKindOfClass:[GDataXMLElement class]])
            continue;
        NSMutableDictionary *resultItem = [NSMutableDictionary dictionary];

        for (GDataXMLNode *attribute in element.attributes) {
            if ([[self.requestInfo objectForKey:@"ignore-attributes"] containsObject:attribute.name]) {
                continue;
            } else if ([[self.requestInfo objectForKey:@"date-attributes"] containsObject:attribute.name]) {
                [resultItem setObject:[formatter dateFromString:attribute.stringValue] forKey:attribute.name];
            } else if ([[self.requestInfo objectForKey:@"double-attributes"] containsObject:attribute.name]) {
                [resultItem setObject:[NSNumber numberWithDouble:attribute.stringValue.doubleValue] forKey:attribute.name];
            } else if ([[self.requestInfo objectForKey:@"integer-attributes"] containsObject:attribute.name]) {
                [resultItem setObject:[NSNumber numberWithInteger:attribute.stringValue.integerValue] forKey:attribute.name];
            } else {
                [resultItem setObject:attribute.stringValue forKey:attribute.name];
            }
        }

        // filtering
        for (NSString *filterKey in [self.requestInfo objectForKey:@"filter"]) {
            if ([[resultItem objectForKey:filterKey] isEqual:[[self.requestInfo objectForKey:@"filter"] objectForKey:filterKey]]) {
                resultItem = nil;
                break;
            }
        }

        // grouping
        if (resultItem && [self.requestInfo objectForKey:@"group-by"]) {
            BOOL isEqualToLast = YES;
            for (NSString *groupKey in [self.requestInfo objectForKey:@"group-by"]) {
                if (![[resultItem objectForKey:groupKey] isEqual:[[result lastObject] objectForKey:groupKey]]) {
                    isEqualToLast = NO;
                    break;
                }
            }
            if (isEqualToLast) {
                resultItem = nil;
                NSInteger groupSize = [[result lastObject] objectForKey:@"groupSize"] ? [[[result lastObject] objectForKey:@"groupSize"] integerValue] : 1;
                [[result lastObject] setObject:[NSNumber numberWithInteger:++groupSize] forKey:@"groupSize"];
            }
        }

        if (resultItem)
            [result addObject:resultItem];
    }

    if (LOG)
        NSLog(@"%@ got result %@", [self class], result);

    if (self.callback) {
        self.callback(YES, result);
    }
}

- (void)processError:(NSError*)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    if (self.callback) {
        self.callback(NO, nil);
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self processError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self processReceivedData];
}

@end
