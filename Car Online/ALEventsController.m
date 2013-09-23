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

@interface ALEventsController ()

@property (nonatomic, weak) IBOutlet UILabel *updatedLabel;
@property (nonatomic, weak) NSTimer *updateTimer;
@property (nonatomic, strong) NSDate *updatedDate;
@property (nonatomic, strong) NSArray *events;
@property (nonatomic, strong) NSDictionary *eventTypes;

- (IBAction)loadData:(id)sender;

@end

@implementation ALEventsController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.refreshControl addTarget:self action:@selector(loadData:) forControlEvents:UIControlEventValueChanged];    
    self.eventTypes = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"EventTypes" ofType:@"plist"]];
    [self loadData:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUpdatedLabel];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(updateUpdatedLabel) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.updateTimer invalidate];
}

- (void)updateUpdatedLabel {
    self.updatedLabel.text = [NSString stringWithFormat:@"Updated %@", self.updatedDate ? [self.updatedDate agoFromNow] : @"never"];
}

#pragma mark - Actions

- (IBAction)loadData:(id)sender {
    [self.refreshControl beginRefreshing];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [ALRequest requestWithType:ALRequestCommandEvents callback:^(BOOL success, id data) {
        NSArray *loadedEvents = data;

        [self.refreshControl endRefreshing];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        if (!loadedEvents) {
            return;
        }
        NSLog(@"%d events loaded", loadedEvents.count);
        self.updatedDate = [NSDate date];
        [self updateUpdatedLabel];
        self.events = loadedEvents;
        [self.tableView reloadData];

    }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *event = [self.events objectAtIndex:indexPath.row];
    NSDictionary *eventInfo = [self.eventTypes objectForKey:[[event objectForKey:@"type"] stringValue]];
    cell.textLabel.text = [eventInfo objectForKey:@"title"];
    if ([eventInfo objectForKey:@"icon"]) {
        cell.imageView.image = [UIImage imageNamed:[[eventInfo objectForKey:@"icon"] stringByAppendingPathExtension:@"gif"]];
    } else {
        cell.imageView.image = nil;
    }
    cell.detailTextLabel.text = [[event objectForKey:@"datetime"] formattedString];
    if ([event objectForKey:@"groupSize"]) {
        cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@" (%d %@)", [[event objectForKey:@"groupSize"] integerValue], NSLocalizedString(@"events", @"5 events")];
    }
    return cell;
}

@end
