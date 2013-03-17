//
//  ALSMSList.m
//  Car Online
//
//  Created by Alex Lebedev on 28-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALSMSListCOntroller.h"
#import <MessageUI/MessageUI.h>

@interface ALSMSListController () <MFMessageComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *smsList;

@end

@implementation ALSMSListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.smsList = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMSList" ofType:@"plist"]] objectForKey:@"sms-list"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.smsList.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.smsList objectAtIndex:section] objectForKey:@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.smsList objectAtIndex:section] objectForKey:@"items"] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11.];
    }

    NSDictionary *info = [[[self.smsList objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
    cell.textLabel.text = [info objectForKey:@"text"];
    cell.detailTextLabel.text = [info objectForKey:@"description"];
    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![MFMessageComposeViewController canSendText]) {
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    NSDictionary *info = [[[self.smsList objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.body = [info objectForKey:@"text"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"phone-number"]) {
        messageController.recipients = [NSArray arrayWithObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"phone-number"]];
    }
    messageController.messageComposeDelegate = self;
    [self presentViewController:messageController animated:YES completion:nil];
}

#pragma mark Message Framework Delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    NSLog(@"composer finished res=%d", result);
    if (controller.recipients.count) {
        [[NSUserDefaults standardUserDefaults] setObject:[controller.recipients objectAtIndex:0] forKey:@"phone-number"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
