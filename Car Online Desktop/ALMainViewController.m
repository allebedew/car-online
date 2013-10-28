//
//  ALMainViewController.m
//  Car Online
//
//  Created by Alex Lebedev on 6/9/13.
//
//

#import "ALMainViewController.h"
#import "ALRequest.h"

@interface ALMainViewController () <NSAlertDelegate>

@property (nonatomic, strong) IBOutlet NSTextField *textLabel;

- (IBAction)loadData:(id)sender;

@end

@implementation ALMainViewController

- (id)init {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
    }
    return self;
}

- (IBAction)loadData:(id)sender {
    [ALRequest requestWithType:ALRequestTypeGetTelemetry callback:^(BOOL success, id data) {
        NSDictionary *telemetry = [data lastObject];
        [self.textLabel setStringValue:[NSString stringWithFormat:@"%ld stands, %ld km, %ld max",
                                        (long)[telemetry[@"standsCount"] integerValue], [telemetry[@"mileage"] integerValue], [telemetry[@"maxSpeed"] integerValue]]];
    }];
}

@end
