//
//  ALMainViewController.m
//  Car Online
//
//  Created by Alex Lebedev on 6/9/13.
//
//

#import "ALMainViewController.h"

@interface ALMainViewController ()

@end

@implementation ALMainViewController

- (void)dealloc {
    NSLog(@"cnt dealloc");
}

- (id)init {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
    }
    return self;
}

@end
