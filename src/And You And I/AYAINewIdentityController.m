//
//  AYAINewIdentityController.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAINewIdentityController.h"
#import "AYAIAppDelegate.h"
#import "AYAIIdentity.h"
#import "AYAIUserData.h"
#import "AYAISyncManager.h"

#pragma mark New Identity View Controller

@implementation AYAINewIdentityController : UIViewController

@synthesize textMail, textFirstName, textLastName, textCity;

- (IBAction)done:(id)sender
{
    AYAIIdentity *identity = [[AYAIIdentity alloc] init];
    identity.isArchive = NO;
    identity.personEmail = textMail.text;
    identity.personFirstName = textFirstName.text;
    identity.personLastName = textLastName.text;
    identity.personAddressCity = textCity.text;
    if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:identity] == YES)
    {
        [AYAISyncManager addIdentity:identity];
    }
    [self performSegueWithIdentifier:@"NewIdentityToMain" sender:sender];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if (theTextField == self.textCity)
    {
        [self done:self];
    }
    else if (theTextField == self.textMail)
    {
        [self.textFirstName becomeFirstResponder];
    }
    else if (theTextField == self.textFirstName)
    {
        [self.textLastName becomeFirstResponder];
    }
    else if (theTextField == self.textLastName)
    {
        [self.textCity becomeFirstResponder];
    }
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.textMail.delegate = self;
    self.textFirstName.delegate = self;
    self.textLastName.delegate = self;
    self.textCity.delegate = self;
    [textMail becomeFirstResponder];
}

@end

