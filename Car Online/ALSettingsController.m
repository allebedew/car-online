//
//  ALSettingsController.m
//  Car Online
//
//  Created by Alex Lebedev on 28-03-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ALSettingsController.h"
#import "ALRequest.h"

@interface ALSettingsController ()

@property (nonatomic, strong) IBOutlet UITextField *apiKeyField;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)donePressed:(id)sender;
- (IBAction)textFieldChanged:(id)sender;
- (void)updateDoneButton;

@end

@implementation ALSettingsController

@synthesize apiKeyField, doneButton, delegate, activityIndicator;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.apiKeyField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"];
    self.apiKeyField.rightView = self.activityIndicator;
    self.apiKeyField.rightViewMode = UITextFieldViewModeAlways;
    [self updateDoneButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.apiKeyField becomeFirstResponder];
}

- (void)updateDoneButton {
    self.doneButton.enabled = self.apiKeyField.text.length > 0;
}

- (IBAction)donePressed:(id)sender {
    if (self.apiKeyField.text.length == 0)
        return;
    [[NSUserDefaults standardUserDefaults] setObject:self.apiKeyField.text forKey:@"api-key"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.activityIndicator startAnimating];
    self.doneButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *data = [ALRequest runRequest:@"telemetry"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.doneButton.enabled = YES;
            if (data) {
                [self.delegate settingsControllerDidSaveChanges:self];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"api-key"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        });
    });
}

- (IBAction)textFieldChanged:(id)sender {
    [self updateDoneButton];
}

@end
