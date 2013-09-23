//
//  ALAppDelegate.m
//  Car Online Desktop
//
//  Created by Alex Lebedev on 26/8/13.
//
//

#import "ALAppDelegate.h"
#import "ALMainViewController.h"

@interface ALAppDelegate ()

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSPopover *popover;

@end

@implementation ALAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.title = @"Car";
    self.statusItem.highlightMode = YES;
    self.statusItem.target = self;
    self.statusItem.action = @selector(statusItemClicked:);
}

- (void)statusItemClicked:(id)sender {
    if (self.popover.shown) {
        [self.popover performClose:sender];
        self.popover = nil;
        
    } else {
        ALMainViewController *main = [[ALMainViewController alloc] init];
        
        self.popover = [[NSPopover alloc] init];
        self.popover.contentViewController = main;
        [self.popover showRelativeToRect:NSZeroRect ofView:sender preferredEdge:NSMaxYEdge];
    }
}

@end
