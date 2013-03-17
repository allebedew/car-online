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

- (void)validateDoneButton;

- (IBAction)donePressed:(id)sender;
- (IBAction)textFieldChanged:(id)sender;

@end

@implementation ALSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.apiKeyField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"];
    self.apiKeyField.rightView = self.activityIndicator;
    self.apiKeyField.rightViewMode = UITextFieldViewModeAlways;
    [self validateDoneButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.apiKeyField becomeFirstResponder];
}

#pragma mark - Private

- (void)validateDoneButton {
    self.doneButton.enabled = self.apiKeyField.text.length > 0;
}

#pragma mark - User Actions

- (IBAction)textFieldChanged:(id)sender {
    [self validateDoneButton];
}

- (IBAction)donePressed:(id)sender {
    if (self.apiKeyField.text.length == 0)
        return;
    NSString *oldValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"api-key"];
    [[NSUserDefaults standardUserDefaults] setObject:self.apiKeyField.text forKey:@"api-key"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.activityIndicator startAnimating];
    self.doneButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *data = [ALRequest runRequest:@"telemetry"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.doneButton.enabled = YES;
            if (!data) {
                if (oldValue) {
                    [[NSUserDefaults standardUserDefaults] setObject:oldValue forKey:@"api-key"];
                } else {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"api-key"];
                }
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            [self performSegueWithIdentifier:@"mainscreen" sender:self];
        });
    });
}

@end
