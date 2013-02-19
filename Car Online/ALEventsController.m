//
//  ALEventsController.m
//  Car Online
//
//  Created by Alex Lebedev on 19-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALEventsController.h"
#import "ALRequest.h"
#import "Convertions.h"

@interface ALEventsController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *events;
@property (strong, nonatomic) NSDictionary *eventTypes;

- (IBAction)close:(id)sender;

- (void)loadData;

@end

@implementation ALEventsController

@synthesize tableView, events, eventTypes;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    self.eventTypes = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"EventTypes" ofType:@"plist"]];
    [super viewDidLoad];
    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *loadedEvents = [ALRequest runRequest:@"events"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!loadedEvents)
                return;
            NSLog(@"%d events loaded", loadedEvents.count);
            self.events = loadedEvents;
            [self.tableView reloadData];
        });
    });
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11.];
    }
    NSDictionary *event = [self.events objectAtIndex:indexPath.row];
    NSDictionary *eventInfo = [self.eventTypes objectForKey:[[event objectForKey:@"type"] stringValue]];
    cell.textLabel.text = [eventInfo objectForKey:@"title"];
    if ([eventInfo objectForKey:@"icon"])
        cell.imageView.image = [UIImage imageNamed:[[eventInfo objectForKey:@"icon"] stringByAppendingPathExtension:@"gif"]];
    else
        cell.imageView.image = nil;
    cell.detailTextLabel.text = [[event objectForKey:@"datetime"] formattedString];
    if ([event objectForKey:@"groupSize"])
        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (%d %@)", [[event objectForKey:@"groupSize"] integerValue], NSLocalizedString(@"events", @"5 events")];
    return cell;
}

#pragma Shake Detection

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        NSLog(@"shake detected");
        [self loadData];
    }
}

@end
