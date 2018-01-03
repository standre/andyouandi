//
//  AYAISettingsController.m
//  And You And I
//
//  Created by sga on 27.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAISettingsController.h"
#import "AYAIPasswordController.h"
#import "AYAIUserData.h"
#import "AYAISyncManager.h"

@implementation AYAISettingsController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SettingsNewPasswordToNewPassword"])
    {
        AYAIPasswordController *passwordController = segue.destinationViewController;
        passwordController.passwordMode = PASSWORD_AES_CHANGE;
    }
    else if ([segue.identifier isEqualToString:@"SettingsToLogBook"])
    {
        // nothing to do
    }
}

- (IBAction)setNewPassword:(id)sender
{
    [self performSegueWithIdentifier:@"SettingsNewPasswordToNewPassword" sender:sender];
}

- (IBAction)doneSettings:(id)sender
{
    [self performSegueWithIdentifier:@"SettingsToMain" sender:sender];
}

- (IBAction)showLogBook:(id)sender
{
    [self performSegueWithIdentifier:@"SettingsToLogBook" sender:sender];
}

- (IBAction)helpHomePage:(id)sender
{
    [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:LS("AYAIURL")]];
}

- (IBAction)helpOnApp:(id)sender
{
    [self performSegueWithIdentifier:@"SettingsToTutorialPages" sender:sender];
}

- (IBAction)valueChanged:(id)sender
{
    if (sender == self.switchAppLock)
    {
        [AYAISettings save:@"prefAppLock" data:[NSNumber numberWithBool:(BOOL)[(UISwitch *)sender isOn]]];
        [self.buttonAppLock setEnabled:[self.switchAppLock isOn]];
    }
    else if (sender == self.stepperIterations)
    {
        int value = (int)[(UIStepper *)sender value];
        [AYAISettings save:@"prefIterations" data:[NSNumber numberWithInt:value]];
        [self.labelStepperIterations setText:[NSString stringWithFormat:LS("FormatIterations"), [[NSNumber numberWithInteger:value] descriptionWithLocale:[NSLocale currentLocale]]]];
        [self performSegueWithIdentifier:@"SettingsNewPasswordToNewPassword" sender:sender];
    }
    else if (sender == self.stepperKeySize)
    {
        int value = (int)[(UIStepper *)sender value];
        [AYAISettings save:@"prefKeySize" data:[NSNumber numberWithInt:value]];
        [self.labelStepperKeySize setText:[NSString stringWithFormat:LS("FormatKeySize"), [[NSNumber numberWithInteger:value] descriptionWithLocale:[NSLocale currentLocale]]]];
    }
    else if (sender == self.switchUseICloud)
    {
        [AYAISettings save:@"prefUseICloud" data:[NSNumber numberWithBool:(BOOL)[(UISwitch *)sender isOn]]];
        if ([self.switchUseICloud isOn] == NO)
        {
            [[[AYAIAppDelegate sharedAppDelegate] getUserData] persistAllDocuments];
        }
        else
        {
            [[[AYAIAppDelegate sharedAppDelegate] getUserData] moveAllDocuments];
        }
    }
    else if (sender == self.switchDeleteICloud)
    {
        [self.buttonDeleteICloud setEnabled:[self.switchDeleteICloud isOn]];
    }
    else if (sender == self.switchDeleteLocal)
    {
        [self.buttonDeleteLocal setEnabled:[self.switchDeleteLocal isOn]];
    }
    else if (sender == self.switchShowArchives)
    {
        [AYAISettings save:@"prefShowArchives" data:[NSNumber numberWithBool:(BOOL)[(UISwitch *)sender isOn]]];
    }
    else if (sender == self.switchLogDetails)
    {
        [AYAISettings save:@"prefLogDetails" data:[NSNumber numberWithBool:(BOOL)[(UISwitch *)sender isOn]]];
    }
    else if (sender == self.switchTraceIntoFiles)
    {
        [AYAISettings save:@"prefTraceIntoFiles" data:[NSNumber numberWithBool:(BOOL)[(UISwitch *)sender isOn]]];
        if ([(UISwitch *)sender isOn])
        {
            [[AYAIAppDelegate sharedAppDelegate] redirectConsoleLog];
        }
        else
        {
            [[AYAIAppDelegate sharedAppDelegate] restoreConsoleLog];
        }
    }
}

- (IBAction)restoreArchives:(id)sender
{

}

- (IBAction)deleteICloudFiles:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:LS("MenuDeleteICloudTitle")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  LS("MenuDeleteAllURL"),
                                  LS("Delete"),
                                  nil];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:LS("Cancel")];
    actionSheet.tag = 10;
    [actionSheet showInView:sender];
    [self.switchDeleteICloud setOn:NO];
    [self.buttonDeleteICloud setEnabled:NO];
}

- (IBAction)deleteLocalFiles:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:LS("MenuDeleteLocalTitle")
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:
                                  LS("MenuKeepArchives"),
                                  LS("MenuCleanTraces"),
                                  LS("Delete"),
                                  nil];
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:LS("Cancel")];
    actionSheet.tag = 20;
    [actionSheet showInView:sender];
    [self.switchDeleteLocal setOn:NO];
    [self.buttonDeleteLocal setEnabled:NO];
}

#pragma mark Menus

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    [actionSheet.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop)
     {
         if ([subview isKindOfClass:[UIButton class]])
         {
             UIButton *button = (UIButton *)subview;
             NSString *buttonText = button.titleLabel.text;
             if ([buttonText isEqualToString:LS("Delete")])
             {
                 button.titleLabel.textColor = [UIColor redColor];
             }
         }
     }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag)
    {
        case 10:    // Delete iCloud files
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    [AYAISyncManager deleteAllICLoudPublicURLs];
                    break;
                }
                case 1:
                {
                    [AYAISyncManager deleteAllICLoudFiles];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 20:    // Delete local files
        {
            switch (buttonIndex)
            {
                case 0:     // Keep key archives
                {
                    [AYAISyncManager deleteAllLocalFiles:DELETE_LOCAL_KEEPARCHIVES];
                    [[[AYAIAppDelegate sharedAppDelegate] getUserData] releaseTableArrays];
                    break;
                }
                case 1:     // Clean traces
                {
                    [AYAISyncManager deleteAllLocalFiles:DELETE_LOCAL_TRACES];
                    break;
                }
                case 2:     // Delete (all)
                {
                    [AYAISyncManager deleteAllLocalFiles:DELETE_LOCAL_ALL];
                    [[[AYAIAppDelegate sharedAppDelegate] getUserData] releaseTableArrays];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
    {
        screenRect.origin.y = 45;
        screenRect.size.height -= 65;
    }
    else
    {
        screenRect.origin.y = 65;
        screenRect.size.height -= 65;
    }
    [self.mainView setFrame:screenRect];
    [self.scrollView setContentSize:CGSizeMake(320,1100)];
    
    self.switchAppLock.layer.zPosition = MAXFLOAT;
    self.buttonAppLock.layer.zPosition = MAXFLOAT;
    self.buttonNewPassword.layer.zPosition = MAXFLOAT;
    self.stepperKeySize.layer.zPosition = MAXFLOAT;
    self.stepperIterations.layer.zPosition = MAXFLOAT;
    self.switchUseICloud.layer.zPosition = MAXFLOAT;
    self.switchDeleteICloud.layer.zPosition = MAXFLOAT;
    self.buttonDeleteICloud.layer.zPosition = MAXFLOAT;
    self.switchDeleteLocal.layer.zPosition = MAXFLOAT;
    self.buttonDeleteLocal.layer.zPosition = MAXFLOAT;
    self.switchShowArchives.layer.zPosition = MAXFLOAT;
    self.buttonLogbook.layer.zPosition = MAXFLOAT;
    self.switchLogDetails.layer.zPosition = MAXFLOAT;
    self.switchTraceIntoFiles.layer.zPosition = MAXFLOAT;
    self.buttonHelpApp.layer.zPosition = MAXFLOAT;
    self.buttonHelpHomepage.layer.zPosition = MAXFLOAT;

    [self.switchAppLock setOn:(BOOL)[[AYAISettings load:@"prefAppLock"] boolValue]];
    [self.buttonAppLock setEnabled:[self.switchAppLock isOn]];
    [self.stepperKeySize setValue:(double)[[AYAISettings load:@"prefKeySize"] doubleValue]];
    [self.labelStepperKeySize setText:[NSString stringWithFormat:LS("FormatKeySize"), [[NSNumber numberWithInteger:[[AYAISettings load:@"prefKeySize"] intValue]] descriptionWithLocale:[NSLocale currentLocale]]]];
    
    [self.stepperIterations setValue:(double)[[AYAISettings load:@"prefIterations"] doubleValue]];
    [self.labelStepperIterations setText:[NSString stringWithFormat:LS("FormatIterations"), [[NSNumber numberWithInteger:[[AYAISettings load:@"prefIterations"] intValue]] descriptionWithLocale:[NSLocale currentLocale]]]];
    [self.switchUseICloud setEnabled:[[iCloud sharedCloud] checkCloudAvailability]];
    [self.switchUseICloud setOn:(BOOL)([[AYAISettings load:@"prefUseICloud"] boolValue] && [[iCloud sharedCloud] checkCloudAvailability])];
    [self.switchDeleteICloud setEnabled:[[iCloud sharedCloud] checkCloudAvailability]];
    [self.buttonDeleteICloud setEnabled:NO];
    [self.switchDeleteICloud setOn:NO];
    [self.buttonDeleteLocal setEnabled:NO];
    [self.switchDeleteLocal setOn:NO];
    [self.switchShowArchives setOn:(BOOL)[[AYAISettings load:@"prefShowArchives"] boolValue]];
    [self.switchLogDetails setOn:(BOOL)[[AYAISettings load:@"prefLogDetails"] boolValue]];
    [self.switchTraceIntoFiles setOn:(BOOL)[[AYAISettings load:@"prefTraceIntoFiles"] boolValue]];
    
    [self.switchDeleteICloud setOnTintColor:[UIColor redColor]];
    [self.switchDeleteLocal setOnTintColor:[UIColor redColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
