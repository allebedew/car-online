//
//  ALRequestFactory.m
//  Car Online
//
//  Created by Lebedev Aleksey on 8/1/15.
//
//

#import "ALRequestFactory.h"
#import "Convertions.h"

NSString* const ALAPIKey = @"api-key";

@implementation ALRequestFactory

+ (NSURLRequest*)requestForTelemetry {
    return [self requestWithComand:@"telemetry" beginDate:nil endDate:nil];
}

+ (NSURLRequest*)requestForGPSList {
    return [self requestWithComand:@"gpslist" beginDate:nil endDate:nil];
}

+ (NSURLRequest*)requestWithComand:(NSString*)comand
                         beginDate:(NSDate*)beginDate
                           endDate:(NSDate*)endDate {

    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:ALAPIKey];

    if (!beginDate) {
        beginDate = [NSDate startOfTheDayDate];
        beginDate = [NSDate dateWithTimeIntervalSince1970:[beginDate timeIntervalSince1970] - 86400];
    }
    NSString *beginDateString = [NSString stringWithFormat:@"%.0f000", [beginDate timeIntervalSince1970]];

    NSMutableArray *queryItems = [NSMutableArray arrayWithArray:@[
        [NSURLQueryItem queryItemWithName:@"content" value:@"json"],
        [NSURLQueryItem queryItemWithName:@"skey" value:apiKey],
        [NSURLQueryItem queryItemWithName:@"get" value:comand],
        [NSURLQueryItem queryItemWithName:@"begin" value:beginDateString]
    ]];

    if (endDate) {
        NSString *endDateString = [NSString stringWithFormat:@"%.0f000", [endDate timeIntervalSince1970]];
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"end" value:endDateString]];
    }

    NSURLComponents *urlComp = [[NSURLComponents alloc] init];
    urlComp.scheme = @"http";
    urlComp.host = @"api.car-online.ru";
    urlComp.path = @"/v2";
    urlComp.queryItems = queryItems;

    return [NSURLRequest requestWithURL:urlComp.URL];
}

@end
