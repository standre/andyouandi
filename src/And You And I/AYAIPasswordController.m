//
//  AYAIPasswordController.m
//  And You And I
//
//  Created by sga on 25.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAI.h"
#import "AYAIPasswordController.h"
#import "AYAIPasswordManager.h"
#import "AYAICrypto.h"
#import "AYAIIdentity.h"
#import "AYAIUserData.h"

@implementation AYAIPasswordController

@synthesize navigationTitle, labelPassword, viewPassword, textPassword, textConfirmation, passwordMode;

- (IBAction)cancelPassword:(id)sender
{
    if (self.passwordMode == PASSWORD_PKCS12)
    {
        [AYAIAppDelegate sharedAppDelegate].migrationCancelled = YES;
    }
    if (self.passwordMode == PASSWORD_AES_CHANGE)
    {
        [self performSegueWithIdentifier:@"PasswordToSettings" sender:sender];
    }
    else
    {
        [self performSegueWithIdentifier:@"PasswordToSettings" sender:sender];
    }
}

- (IBAction)textChanged:(id)sender
{
    if ([self.textPassword.text length] < 16)
    {
        [self.viewPassword setBackgroundColor:[UIColor colorWithRed:255.0/255 green:222.0/255 blue:222.0/255 alpha:1.0]];
    }
    else if ((passwordMode == PASSWORD_AES_NEW  || passwordMode == PASSWORD_AES_CHANGE) && [self.textPassword.text isEqualToString:self.textConfirmation.text])
    {
        [self.viewPassword setBackgroundColor:[UIColor colorWithRed:180.0/255 green:255.0/255 blue:180.0/255 alpha:1.0]];
    }
    else
    {
        [self.viewPassword setBackgroundColor:[UIColor colorWithRed:222.0/255 green:255.0/255 blue:222.0/255 alpha:1.0]];
    }
}

- (IBAction)donePassword:(id)sender
{
    switch (self.passwordMode)
    {
        case PASSWORD_AES:
        {
            [KeychainUserPass save:@"AESPassword" data:[self.textPassword text]];
            [self performSegueWithIdentifier:@"PasswordToMain" sender:sender];
            break;
        }
        case PASSWORD_AES_NEW:
        case PASSWORD_AES_CHANGE:
        {
            if (! [self.textPassword.text isEqualToString:self.textConfirmation.text])
            {
                [self.labelPassword setTextColor:[UIColor redColor]];
                [self.labelPassword setText:LS("PasswordBadConfirmation")];
            }
            else if ([self.textPassword.text length] < 16)
            {
                [self.labelPassword setTextColor:[UIColor redColor]];
                [self.labelPassword setText:LS("PasswordBadLength")];
            }
            else if ([[self.textPassword text] cStringUsingEncoding:NSISOLatin1StringEncoding] == NULL)
            {
                [self.labelPassword setTextColor:[UIColor redColor]];
                [self.labelPassword setText:LS("PasswordBadCharacters")];
            }
            else
            {
                [KeychainUserPass save:@"AESNewPassword" data:[self.textPassword text]];
                [[[AYAIAppDelegate sharedAppDelegate] getUserData] changePassword];
                GREENTOASTER("ToastAllRecrypted");
                if (self.passwordMode == PASSWORD_AES_CHANGE)
                {
                    [self performSegueWithIdentifier:@"PasswordToSettings" sender:sender];
                }
                else
                {
                    [self performSegueWithIdentifier:@"PasswordToMain" sender:sender];
                }
            }
            break;
        }
        case PASSWORD_PKCS12:
        {
            AYAIPKCS12 *pkcs12 = [[AYAIPKCS12 alloc] initWithData:self.pkcs12Data];
            if (pkcs12 == nil)
            {
                [self.labelPassword setTextColor:[UIColor redColor]];
                [self.labelPassword setText:LS("PFXBadFormat")];
                break;
            }
            if ([pkcs12 decryptWithPassword:[self.textPassword text]] == NO)
            {
                [self.labelPassword setTextColor:[UIColor redColor]];
                [self.labelPassword setText:LS("PFXBadPassword")];
                break;
            }
            AYAIIdentity *identity = [[AYAIIdentity alloc] init];
            identity.isArchive = NO;
            identity.subjectPKCS12 = self.pkcs12Data;
            identity.password = [self.textPassword text];
            identity.subjectX509 = [pkcs12 subjectCertData];
            identity.issuerX509 = [pkcs12 issuerCertData];
            [identity completeWithKey:[pkcs12 subjectKey]];
            if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:identity] == YES)
            {
                [AYAISyncManager addIdentity:identity];
                [AYAISyncManager deleteAllLocalFiles:DELETE_LOCAL_VERSION1:self.pkcs12ID];
            }
            [KeychainUserPass save:@"PKCS12Password" data:[self.textPassword text]];
            [self performSegueWithIdentifier:@"PasswordToMain" sender:self];
            break;
        }
        default:
            break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    switch (self.passwordMode)
    {
        case PASSWORD_AES:
        {
            if (theTextField == self.textPassword)
            {
                [self donePassword:self];
            }
            break;
        }
        case PASSWORD_AES_NEW:
        case PASSWORD_AES_CHANGE:
        {
            if (theTextField == self.textPassword)
            {
                [self.textConfirmation becomeFirstResponder];
            }
            else if (theTextField == self.textConfirmation)
            {
                [self donePassword:self];
            }
            break;
        }
        case PASSWORD_PKCS12:
        {
            if (theTextField == self.textPassword)
            {
                [self donePassword:self];
            }
            break;
        }
        default:
            break;
    }

    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    switch (self.passwordMode)
    {
        case PASSWORD_AES:
        {
            [self.navigationTitle setTitle:LS("PasswordTitleID")];
            [self.labelPassword setText:LS("PasswordID")];
            [self.textConfirmation setHidden:YES];
            break;
        }
        case PASSWORD_AES_NEW:
        {
            [self.navigationTitle setTitle:LS("PasswordTitleNewID")];
            [self.labelPassword setText:LS("PasswordNewID")];
            [self.textConfirmation setHidden:NO];
            break;
        }
        case PASSWORD_AES_CHANGE:
        {
            [self.navigationTitle setTitle:LS("PasswordTitleChangeID")];
            [self.labelPassword setText:LS("PasswordChangeID")];
            [self.textConfirmation setHidden:NO];
            break;
        }
        case PASSWORD_PKCS12:
        {
            [self.navigationTitle setTitle:self.pkcs12ID];
            [self.labelPassword setText:LS("PasswordPFX")];
            [self.textConfirmation setHidden:YES];
            break;
        }
        default:
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    self.textPassword.delegate = self;
    self.textConfirmation.delegate = self;
    [textPassword becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
