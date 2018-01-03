//
//  AYAIViewController.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "TargetConditionals.h"
#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SWTableViewCell.h"
#import "UMTableViewCell.h"
#import "iCloud.h"
#import "AYAI.h"
#import "AYAIIdentity.h"
#import "AYAIAttachment.h"
#import "AYAIUserData.h"
#import "AYAICrypto.h"

#define IDENTITY_CELL_HEIGHT_NORMAL     50
#define IDENTITY_CELL_HEIGHT_MEDIUM     70
#define IDENTITY_CELL_HEIGHT_THUMBNAIL  80
#define IDENTITY_CELL_HEIGHT_EXTENDED   154

/*
 
 Object structure:
 
 ViewController :: UI                   all you can see except mail and contact views
                   UserData             app settings and identities array
                   Identity             single identity, a table row
 Identity ::       MobileConfig         all files generated for this identity
                   SyncManager          file I/O in local device (iTunes) and iCloud
                   MailManager          mail generation
                   Crypto               key and certiticates generation
                   PasswordManager      password generator
 
 */

@interface AYAIViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, ABPeoplePickerNavigationControllerDelegate, UIAccelerometerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, SWTableViewCellDelegate, iCloudDelegate>

@property (strong, nonatomic) IBOutlet UIView *progressView;
@property (strong, nonatomic) IBOutlet UITableView *identityTableView;
@property (strong, nonatomic) IBOutlet UIToolbar *identityToolbar;
@property (strong, nonatomic) IBOutlet UINavigationBar *identityNavigationBar;
@property (strong, nonatomic) IBOutlet CMMotionManager *motionManager;
@property (strong, nonatomic) IBOutlet UIProgressView *iCloudProgressView;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong, nonatomic) IBOutlet UILabel *progressLabel;
@property (nonatomic) NSInteger randomBits;
@property (strong, nonatomic) NSString *randomSeed;
@property (nonatomic) BOOL randomSeedInitialized;
@property (atomic) BOOL opensslLock;
@property (atomic) BOOL mustHandleSharedAttachment;
@property (strong, nonatomic) IBOutlet UIImageView *logo;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *logoGesture;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonCloud;
@property (strong, retain) NSOperationQueue *mainQueue;
@property (nonatomic) float angle;
@property (strong, nonatomic) UIDocumentInteractionController *documentController;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSInteger filterIdentityView;
// cell which has action menu opened
@property (strong, nonatomic) NSIndexPath *actionCellIndexPath;
@property (strong, nonatomic) AYAIIdentity *actionIdentity;
@property (strong, nonatomic) AYAIAttachment *actionAttachment;
// objects during migration for hand-over to PasswordController
@property (strong, nonatomic) NSString *pkcs12ID;
@property (strong, nonatomic) NSData *pkcs12Data;

- (IBAction)refreshICloud:(id)sender;
- (IBAction)toggleDetails:(id)sender;
- (IBAction)tapDetected:(UITapGestureRecognizer *)sender;
- (IBAction)addPerson:(id)sender;
- (void)addPersonOpenUI:(bool)granted;
- (IBAction)openSettings:(id)sender;
- (IBAction)showStatistics:(id)sender;
- (void)refreshIdentityTableView;
- (void)migrateLocalFilesVersion1x;

- (void)handleOpenURL;
- (void)handleSharedAttachment;

- (void)beginProgressViewForICloudLoading:(float)percent;
- (void)endProgressViewForICloudLoading;
- (void)beginProgressViewForRandomGeneration;
- (void)endProgressViewForRandomGeneration;
- (void)beginGenerateNewKeys;
- (void)endGenerateNewKeys;
- (void)fadeInProgessView;
- (void)fadeOutProgessView;

@end
