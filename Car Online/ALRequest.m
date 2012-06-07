//
//  ALRequest.m
//  Car Online
//
//  Created by Alex Lebedev on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALRequest.h"
#import "GDataXMLNode.h"

@implementation ALRequest

#define LOG NO
#define SERVER_TIME_ZONE 4

+ (void)processErrorString:(NSString*)errorString {
    NSLog(@"Request error: %@", errorString);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
    });
}

+ (NSArray*)runRequest:(NSString*)type {
    NSAssert(type != nil, @"No request type", type);
    NSDictionary *requestInfo = [[[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:NSStringFromClass([self class]) ofType:@"plist"]] objectForKey:@"request-types"] objectForKey:type];
    NSAssert(requestInfo != nil, @"Unknown request type (%@)", type);
    NSAssert([[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"] != nil, @"No API Key");
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"http://api.car-online.ru/do?skey=%@&data=%@&content=xml", [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"], [requestInfo objectForKey:@"data-param-value"]];
    NSLog(@"Requesting %@", urlString);
    NSError *err = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString] options:0 error:&err];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (err) {
        [self processErrorString:err.localizedDescription];
        return nil;
    }
    
    if (LOG)
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    GDataXMLDocument *xml = [[[GDataXMLDocument alloc] initWithData:data options:0 error:&err] autorelease];
    
    if (err || [xml.rootElement.name isEqual:@"error"]) {
        [self processErrorString:err ? err.localizedDescription : xml.rootElement.stringValue];
        return nil;
    }

    // Parsing
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"ddMMyyyy_HHmmss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:60*60*SERVER_TIME_ZONE]];
    
    NSMutableArray *result = [NSMutableArray array];
    for (GDataXMLElement *element in xml.rootElement.children) {
        if (![element isKindOfClass:[GDataXMLElement class]])
            continue;
        NSMutableDictionary *resultItem = [NSMutableDictionary dictionary];
        
        for (GDataXMLNode *attribute in element.attributes) {
            if ([[requestInfo objectForKey:@"ignore-attributes"] containsObject:attribute.name]) {
                continue;
            } else if ([[requestInfo objectForKey:@"date-attributes"] containsObject:attribute.name]) {
                [resultItem setObject:[formatter dateFromString:attribute.stringValue] forKey:attribute.name];
            } else if ([[requestInfo objectForKey:@"double-attributes"] containsObject:attribute.name]) {
                [resultItem setObject:[NSNumber numberWithDouble:attribute.stringValue.doubleValue] forKey:attribute.name];
            } else if ([[requestInfo objectForKey:@"integer-attributes"] containsObject:attribute.name]) {
                [resultItem setObject:[NSNumber numberWithInteger:attribute.stringValue.integerValue] forKey:attribute.name];
            } else {
                [resultItem setObject:attribute.stringValue forKey:attribute.name];
            }
        }
        
        // filtering
        for (NSString *filterKey in [requestInfo objectForKey:@"filter"]) {
            if ([[resultItem objectForKey:filterKey] isEqual:[[requestInfo objectForKey:@"filter"] objectForKey:filterKey]]) {
                resultItem = nil;
                break;
            }
        }
        
        // grouping
        if (resultItem && [requestInfo objectForKey:@"group-by"]) {
            BOOL isEqualToLast = YES;
            for (NSString *groupKey in [requestInfo objectForKey:@"group-by"]) {
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
        NSLog(@"%@", result);
    
    return result;
}

@end
