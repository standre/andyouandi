//
//  AYAISettingsController.h
//  And You And I
//
//  Created by sga on 27.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface AYAISettingsController : UIViewController <UIActionSheetDelegate>
- (IBAction)showLogBook:(id)sender;
- (IBAction)valueChanged:(id)sender;
- (IBAction)doneSettings:(id)sender;
- (IBAction)deleteLocalFiles:(id)sender;
- (IBAction)helpHomePage:(id)sender;
- (IBAction)helpOnApp:(id)sender;
- (IBAction)deleteICloudFiles:(id)sender;
- (IBAction)setNewPassword:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UISwitch *switchAppLock;
@property (strong, nonatomic) IBOutlet UIButton *buttonAppLock;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIButton *buttonNewPassword;
@property (strong, nonatomic) IBOutlet UIStepper *stepperKeySize;
@property (strong, nonatomic) IBOutlet UIStepper *stepperIterations;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogbook;
@property (strong, nonatomic) IBOutlet UISwitch *switchUseICloud;
@property (strong, nonatomic) IBOutlet UISwitch *switchDeleteICloud;
@property (strong, nonatomic) IBOutlet UISwitch *switchDeleteLocal;
@property (strong, nonatomic) IBOutlet UISwitch *switchShowArchives;
@property (strong, nonatomic) IBOutlet UILabel *labelStepperKeySize;
@property (strong, nonatomic) IBOutlet UILabel *labelStepperIterations;
@property (strong, nonatomic) IBOutlet UIButton *buttonDeleteICloud;
@property (strong, nonatomic) IBOutlet UIButton *buttonDeleteLocal;
@property (strong, nonatomic) IBOutlet UIButton *buttonHelpApp;
@property (strong, nonatomic) IBOutlet UIButton *buttonHelpHomepage;
@property (strong, nonatomic) IBOutlet UISwitch *switchLogDetails;
@property (strong, nonatomic) IBOutlet UISwitch *switchTraceIntoFiles;
@end
