//
//  ALSMSList.m
//  Car Online
//
//  Created by Alex Lebedev on 28-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALSMSListCOntroller.h"
#import <MessageUI/MessageUI.h>

@interface ALSMSListController () <MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *smsList;

@end

@implementation ALSMSListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.smsList = [[[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SMSList" ofType:@"plist"]] objectForKey:@"sms-list"];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.smsList.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.smsList[section][@"title"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.smsList[section][@"items"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *info = self.smsList[indexPath.section][@"items"][indexPath.row];
    cell.textLabel.text = info[@"text"];
    cell.detailTextLabel.text = info[@"description"];
    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![MFMessageComposeViewController canSendText]) {
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    NSDictionary *info = self.smsList[indexPath.section][@"items"][indexPath.row];
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.body = info[@"text"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"phone-number"]) {
        messageController.recipients = @[[[NSUserDefaults standardUserDefaults] objectForKey:@"phone-number"]];
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
