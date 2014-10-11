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

@property (nonatomic, weak) ALRequest *request;
@property (nonatomic, strong) ALCarEvents *carEvents;

- (IBAction)loadData:(id)sender;

@end

@implementation ALEventsController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.refreshControl addTarget:self action:@selector(loadData:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.carEvents && !self.request.running) {
        [self loadData:self];
    }
}

#pragma mark - Actions

- (IBAction)loadData:(id)sender {
    [self.refreshControl beginRefreshing];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    self.request = [ALRequest requestCarEventsWithCallback:^(ALCarInfo *carInfo) {
//        NSLog(@"%@", carInfo);
        [self.refreshControl endRefreshing];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
        if (!carInfo) {
            return;
        }
        
        self.carEvents = (ALCarEvents*)carInfo;
        [self reloadData];
    } delegate:nil];
}

- (void)reloadData {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.carEvents.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ALCarEventGroup *eventGroup = self.carEvents.events[indexPath.row];
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = eventGroup.title;
    if (eventGroup.iconAvailable) {
        cell.imageView.image = eventGroup.icon;
    } else {
        cell.imageView.image = nil;
    }
    NSString *timeString = [eventGroup.lastEventTime formattedString];
    if (eventGroup.count > 1) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", timeString,
             [NSString stringWithFormat:NSLocalizedString(@"%d events", @"Events count"), eventGroup.count]];
    } else {
        cell.detailTextLabel.text = timeString;
    }
    return cell;
}

@end
