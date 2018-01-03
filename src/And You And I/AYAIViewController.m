//
//  ayai_ViewController.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAIViewController.h"
#import "AYAIPasswordController.h"
#import "AYAIPasswordManager.h"

@interface UILabel (FontAppearance)
@property (nonatomic, copy) UIFont * appearanceFont UI_APPEARANCE_SELECTOR;
@end
@implementation UILabel (FontAppearance)

-(void)setAppearanceFont:(UIFont *)font {
    if (font)
        [self setFont:font];
}
-(UIFont *)appearanceFont {
    return self.font;
}
@end


@implementation AYAIViewController

@synthesize identityTableView, identityToolbar, identityNavigationBar, logo, progressBar, buttonCloud, mainQueue, randomBits, angle, opensslLock, mustHandleSharedAttachment, documentController;

#pragma mark Buttons

- (IBAction)toggleDetails:(id)sender
{
    switch (self.filterIdentityView)
    {
        case 1:
            self.filterIdentityView = 0;
            self.identityTableView.rowHeight = IDENTITY_CELL_HEIGHT_NORMAL;
            break;
        default:
            self.filterIdentityView++;
            self.identityTableView.rowHeight = IDENTITY_CELL_HEIGHT_EXTENDED;
            break;
    }
    [[[AYAIAppDelegate sharedAppDelegate] getUserData] resetViewAllIdentities];
    [self refreshIdentityTableView];
}

- (IBAction)openSettings:(id)sender
{
    [self performSegueWithIdentifier:@"MainToSettings" sender:sender];
}

- (IBAction)openPattern:(id)sender
{
    [self performSegueWithIdentifier:@"MainToPattern" sender:sender];
}

- (IBAction)showStatistics:(id)sender
{
    NSString *statsMsg = [[NSString alloc] initWithFormat:LS("FormatStatistics"),
                          [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray count],
                          [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray count],
                          [AYAISyncManager countAttachmentsInICloud],
                          [AYAISyncManager countIdentitiesInICloud],
                          [AYAISyncManager countProfilesInICloud],
                          [AYAISyncManager countTotalFilesInICloud],
                          [AYAISyncManager countAttachmentsInITunes],
                          [AYAISyncManager countIdentitiesInITunes],
                          [AYAISyncManager countArchivesInITunes],
                          [AYAISyncManager countProfilesInITunes],
                          [AYAISyncManager countTotalFilesInITunes],
                          [AYAISyncManager countLogsInITunes]];
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:LS("TitleStatistics")
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:statsMsg];
    [attributed addAttribute:NSFontAttributeName
                       value:[UIFont systemFontOfSize:12]
                       range:NSMakeRange(0, [attributed length])];
    [alertController setValue:attributed forKey:@"attributedMessage"];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:LS("Close")
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                         }];
    [alertController addAction:ok];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)refreshICloud:(id)sender
{
    [[iCloud sharedCloud] updateFiles];
    [[[AYAIAppDelegate sharedAppDelegate] getUserData] releaseTableArrays];
    [self viewDidAppear:TRUE];
}

#pragma mark - Key Generation

- (void)beginGenerateNewKeys
{
    self.opensslLock = YES;
    self.progressBar.tag = 0;
    [self fadeInProgessView];
    [self.progressLabel setText:LS("ProgressLabelNewKeys")];
    self.angle = 0.0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1/30.0
                                                  target:self
                                                selector:@selector(doLogoAnimate)
                                                userInfo:nil
                                                 repeats:YES];
    self.mainQueue = [NSOperationQueue new];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self.actionIdentity
                                        selector:@selector(generateKeysAndCertificates)
                                        object:nil];
    [self.mainQueue addOperation:operation];
}

- (void)endGenerateNewKeys
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self fadeOutProgessView];
        [self refreshIdentityTableView];
    }];
    self.opensslLock = NO;
}

#pragma mark Progress View Fader

- (void)beginProgressViewForRandomGeneration
{
    [self fadeInProgessView];
}

- (void)endProgressViewForRandomGeneration
{
    [self fadeOutProgessView];
}

- (void)beginProgressViewForICloudLoading:(float)percent
{
    //FIXME: check if old progress was higher than percent to avoid backward progress
    self.iCloudProgressView.hidden = NO;
    [self.iCloudProgressView setProgress:percent/100 animated:YES];
}

- (void)endProgressViewForICloudLoading
{
    self.iCloudProgressView.hidden = YES;
    [self.iCloudProgressView setProgress:0 animated:NO];
}

- (void)fadeInProgessView
{
    self.progressView.hidden = NO;
    self.logo.hidden = NO;
    self.progressBar.hidden = NO;
    self.progressLabel.hidden = NO;
    [self.progressBar setProgress:0.0 animated:NO];
    [self.progressView.layer setBorderColor:[UIColor darkGrayColor].CGColor];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.progressView.bounds;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:245.0/255 green:245.0/255 blue:255.0/255 alpha:0.6] CGColor],
                       (id)[[UIColor colorWithRed:230.0/255 green:200.0/255 blue:200.0/255 alpha:0.6] CGColor],
                       nil];
    [self.progressView.layer insertSublayer:gradient atIndex:0];

    [self.progressView.layer setCornerRadius:10.0];
    [self.progressView.layer setMasksToBounds:YES];
    self.progressView.layer.zPosition = MAXFLOAT;
    [self.identityTableView setUserInteractionEnabled:NO];
    [self.identityNavigationBar setUserInteractionEnabled:NO];
    [self.identityToolbar setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.5 animations:^() {
        self.identityTableView.alpha = 0.3;
    }];
    [UIView animateWithDuration:0.5 animations:^() {
        self.progressView.alpha = 1.0;
    }];
}

- (void)fadeOutProgessView
{
    self.logo.hidden = YES;
    self.progressBar.hidden = YES;
    self.progressLabel.hidden = YES;
    [self.identityTableView setUserInteractionEnabled:YES];
    [self.identityNavigationBar setUserInteractionEnabled:YES];
    [self.identityToolbar setUserInteractionEnabled:YES];
    [UIView animateWithDuration:0.5 animations:^() {
        self.identityTableView.alpha = 1.0;
    }];
    [UIView animateWithDuration:0.5 animations:^() {
        self.progressView.alpha = 0.0;
    }];
    [self.timer invalidate];
}

#pragma mark Animate Logo

- (void)doLogoAnimate
{
    self.angle += 0.2;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, 0);
    CGAffineTransform rotate = CGAffineTransformMakeRotation(self.angle);
    [self.logo setTransform:CGAffineTransformConcat(rotate, translate)];
}

#pragma mark Logo tap gesture to stop key generation

- (IBAction)tapDetected:(UITapGestureRecognizer *)sender
{
    if (self.randomSeedInitialized == YES)
    {
        self.progressBar.tag = 1;
        BLUETOASTER("ToastKeyGenCancelled");
    }
}

#pragma mark Random Generator with Gyroscope

// this method is called in Simulator, but motionManager does not deliver data
- (void)doGyroUpdate
{
    CGPoint delta;
    float seed;
    
#if (TARGET_IPHONE_SIMULATOR)
    delta.y = 10.7;
    delta.x = 10.7;
#else
    delta.y = self.motionManager.gyroData.rotationRate.x * 1;
    delta.x = self.motionManager.gyroData.rotationRate.y * 1.5;
#endif
    if (fabs(delta.x) < 0.02 )
    {
        delta.x = 0;
    }
    if (fabs(delta.y) < 0.02 )
    {
        delta.y = 0;
    }
    self.angle += (fabs(delta.x)+fabs(delta.y))*0.1;
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, 0);
    CGAffineTransform rotate = CGAffineTransformMakeRotation(self.angle);
    [self.logo setTransform:CGAffineTransformConcat(rotate, translate)];
    
    if (self.opensslLock == NO && fabs(delta.x)+fabs(delta.y) > 0.2)
    {
        seed = fabs(delta.x)+fabs(delta.y);
        [self.progressBar setProgress:[self.progressBar progress]+seed/200 animated:YES];
        NSData *data = [NSData dataWithBytes:&seed length:sizeof(float)];
        RAND_add((void *)[data bytes], (int)[data length], 4);
        self.randomBits += 4 * 8;
        self.randomSeed = [self.randomSeed stringByAppendingString:[[[data description]
                                                                     componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]
                                                                    componentsJoinedByString:@""]];
    }
    if ([self.progressBar progress] == 1 && self.randomSeedInitialized == NO)
    {
        self.randomSeedInitialized = YES;
        [self.motionManager stopGyroUpdates];
        [self endProgressViewForRandomGeneration];
        NSString *msg = [[NSString alloc] initWithFormat:LS("FormatRandomGyroscope"), self.randomBits];
        BLUETOASTERNS(msg);
        [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[[NSString alloc] initWithFormat:LS("FormatRandomSeedGenerated"),
                                                            [@(self.randomBits) stringValue]]];
        [[AYAIAppDelegate sharedAppDelegate] appendLogBook:self.randomSeed];
    }
}

#pragma mark - Mail Composer

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
        case MFMailComposeResultSaved:
        case MFMailComposeResultFailed:
        case MFMailComposeResultSent:
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
            
        default:
            break;
    }
}
#pragma mark Segue for new identity view

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AYAIPasswordController *passwordController = segue.destinationViewController;
    
    if ([segue.identifier isEqualToString:@"MainToAESPassword"])
    {
        passwordController.passwordMode = PASSWORD_AES;
    }
    else if ([segue.identifier isEqualToString:@"MainToAESNewPassword"])
    {
        passwordController.passwordMode = PASSWORD_AES_NEW;
    }
    else if ([segue.identifier isEqualToString:@"MainToPKCS12Password"])
    {
        passwordController.pkcs12ID = self.pkcs12ID;
        passwordController.pkcs12Data = self.pkcs12Data;
        passwordController.passwordMode = PASSWORD_PKCS12;
    }
}

#pragma mark Migration support

- (void)migrateLocalFilesVersion1x
{
    NSMutableArray *pfxArray = [AYAISyncManager localVersion1PFXFiles];
    for (CFIndex idx = 0; idx < [pfxArray count]; idx++)
    {
        self.pkcs12ID = [[pfxArray objectAtIndex:idx] objectAtIndex:0];
        self.pkcs12Data = [[pfxArray objectAtIndex:idx] objectAtIndex:1];
        AYAIPKCS12 *pkcs12 = [[AYAIPKCS12 alloc] initWithData:self.pkcs12Data];
        if (pkcs12 == nil)
        {
            continue;
        }
        if ([pkcs12 decryptWithPassword:[KeychainUserPass load:@"PKCS12Password"]] == NO)
        {
            [self performSegueWithIdentifier:@"MainToPKCS12Password" sender:nil];
            
            return;
        }
        else
        {
            AYAIIdentity *identity = [[AYAIIdentity alloc] init];
            identity.isArchive = NO;
            identity.subjectPKCS12 = self.pkcs12Data;
            identity.password = [KeychainUserPass load:@"PKCS12Password"];
            identity.subjectX509 = [pkcs12 subjectCertData];
            identity.issuerX509 = [pkcs12 issuerCertData];
            [identity completeWithKey:[pkcs12 subjectKey]];
            if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:identity] == YES)
            {
                [AYAISyncManager addIdentity:identity];
                [AYAISyncManager deleteAllLocalFiles :DELETE_LOCAL_VERSION1:self.pkcs12ID];
            }
        }
    }
}

#pragma mark - People Picker

- (IBAction)addPerson:(id)sender
{
    ABAuthorizationStatus abAuthStatus = ABAddressBookGetAuthorizationStatus();
    if (abAuthStatus == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                 {
                                                     [self addPersonOpenUI:granted];
                                                 });
    }
    else [self addPersonOpenUI:(abAuthStatus == kABAuthorizationStatusAuthorized)];
}

- (void)addPersonOpenUI:(bool)granted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (granted)
        {
            ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
            picker.peoplePickerDelegate = self;
            [self presentViewController:picker animated:YES completion:nil];
        }
        else
        {
            GRAYTOASTER("ToastContactsDisabled");
            [self performSegueWithIdentifier:@"MainToNewIdentity" sender:self];
        }
    });
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [UIView commitAnimations];
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    [UIView commitAnimations];
    
    NSString *city;

    ABMultiValueRef multiAddresses = (__bridge ABMultiValueRef)((__bridge NSString *)ABRecordCopyValue(person, kABPersonAddressProperty));
    if (!multiAddresses)
    {
        REDTOASTER("MsgUserBadIdentity");
        return;
    }
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiAddresses); i++)
    {
        CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(multiAddresses, i);
        if (dict)
        {
            city = [(NSString *)CFDictionaryGetValue(dict, kABPersonAddressCityKey) copy];
            CFRelease(dict);
            break;
        }
    }
    CFRelease(multiAddresses);
    if (!city)
    {
        REDTOASTER("MsgUserBadIdentity");
        return;
    }
    ABMultiValueRef multiEmail = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (!ABMultiValueGetCount(multiEmail))
    {
        REDTOASTER("MsgUserBadIdentity");
        CFRelease(multiEmail);
        return;
    }
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiEmail); i++)
    {
        AYAIIdentity *identity = [[AYAIIdentity alloc] init];
        CFStringRef value;
        identity.isArchive = NO;
        value = ABMultiValueCopyValueAtIndex(multiEmail, i);
        identity.personEmail = (__bridge NSString *)(value);
        CFRelease(value);
        value = ABRecordCopyValue(person, kABPersonFirstNameProperty);
        identity.personFirstName = (__bridge NSString *)(value);
        CFRelease(value);
        value = ABRecordCopyValue(person, kABPersonLastNameProperty);
        identity.personLastName = (__bridge NSString *)(value);
        CFRelease(value);
        identity.personAddressCity = city;
        if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:identity] == YES)
        {
            [AYAISyncManager addIdentity:identity];
            [self refreshIdentityTableView];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    CFRelease(multiEmail);
    
    return;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

#pragma mark - Identity TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = LS("TableHeaderAttachments");
            break;
        case 1:
            sectionName = LS("TableHeaderIdentities");
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray count];
            break;
        case 1:
            return [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray count];
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(20, 8, 320, 20);
    myLabel.font = [UIFont italicSystemFontOfSize:14];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    myLabel.textColor = [UIColor blueColor];
    
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:myLabel];
    [headerView setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:1.0 alpha:0.85]];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            AYAIAttachment *attachment = [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray objectAtIndex:indexPath.row];
            NSInteger localFilterIdentityView = self.filterIdentityView;
            if (attachment.showDetails)
            {
                localFilterIdentityView = 1;
            }
            switch (localFilterIdentityView)
            {
                case 0:
                {
                    return IDENTITY_CELL_HEIGHT_THUMBNAIL;
                    break;
                }
                case 1:
                {
                    return IDENTITY_CELL_HEIGHT_EXTENDED;
                    break;
                }
                default:
                    return IDENTITY_CELL_HEIGHT_THUMBNAIL;
                    break;
            }
            break;
        }
        case 1:
        {
            AYAIIdentity *identity = [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray objectAtIndex:indexPath.row];
            if ([[AYAISettings load:@"prefShowArchives"] boolValue] == NO && identity.isArchive)
            {
                return 0;
            }
            NSInteger localFilterIdentityView = self.filterIdentityView;
            if (identity.showDetails)
            {
                localFilterIdentityView = 1;
            }
            switch (localFilterIdentityView)
            {
                case 0:
                {
                    return IDENTITY_CELL_HEIGHT_NORMAL;
                    break;
                }
                case 1:
                {
                    if (identity.subjectX509)
                    {
                        return IDENTITY_CELL_HEIGHT_EXTENDED;
                    }
                    else
                    {
                        return IDENTITY_CELL_HEIGHT_MEDIUM;
                    }
                }
                default:
                    return IDENTITY_CELL_HEIGHT_NORMAL;
                    break;
            }
            break;
        }
        default:
            break;
    }
    return IDENTITY_CELL_HEIGHT_NORMAL;
}

#pragma mark - UIRefreshControl Selector

- (void)refreshIdentityTableView
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    NSRange range = NSMakeRange(0, 2);
    NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
    [[[AYAIAppDelegate sharedAppDelegate] getUserData] sortIdentities];
    [self.identityTableView reloadSections:(NSIndexSet *)section withRowAnimation:UITableViewRowAnimationFade];
}

- (void)refreshView:(UIRefreshControl *)refreshControl
{
    [refreshControl beginRefreshing];
    [AYAIAppDelegate sharedAppDelegate].migrationCancelled = NO;
    [[[AYAIAppDelegate sharedAppDelegate] getUserData] releaseTableArrays];
    [refreshControl endRefreshing];
    [self viewDidAppear:TRUE];
}

#pragma mark - UIScrollViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            AYAIAttachment *attachment = [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray objectAtIndex:indexPath.row];
            if (attachment == nil)
            {
                return nil;
            }
            
            UMTableViewCell *cell = [self.identityTableView dequeueReusableCellWithIdentifier:@"UMCell" forIndexPath:indexPath];
            UMTableViewCell __weak *weakCell = cell;
            
            // iOS 8 SDK uses layoutMargins, resulting in cell seperator indent to the left
            // Remove seperator inset
            if ([cell respondsToSelector:@selector(setSeparatorInset:)])
            {
                [cell setSeparatorInset:UIEdgeInsetsZero];
            }
            // Prevent the cell from inheriting the Table View's margin settings
            if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
            {
                [cell setPreservesSuperviewLayoutMargins:NO];
            }
            // Explictly set your cell's layout margins
            if ([cell respondsToSelector:@selector(setLayoutMargins:)])
            {
                [cell setLayoutMargins:UIEdgeInsetsZero];
            }
            
            [cell setAppearanceWithBlock:^{
                weakCell.leftUtilityButtons = nil;
                weakCell.rightUtilityButtons = [self rightAttachmentButtons:attachment];
                weakCell.delegate = self;
                weakCell.containingTableView = identityTableView;
            } force:YES];
            
            [cell setCellHeight:cell.frame.size.height];
            cell.customText.numberOfLines = 2;
            cell.customDetails.numberOfLines = 0;
            [cell.customDetails sizeToFit];
            
            if ([AYAISyncManager hasAttachmentICloudDocument:attachment])
            {
                // white cell if in Cloud
                cell.customText.font = [UIFont boldSystemFontOfSize:15];
                cell.customText.textColor = [UIColor blackColor];
                cell.customText.backgroundColor = [UIColor whiteColor];
                cell.customDetails.backgroundColor = [UIColor whiteColor];
                cell.backgroundColor = [UIColor whiteColor];
            }
            else if ([AYAISyncManager iCloudIsOn] == NO)
            {
                // white cell if iCloud is turned off
                cell.customText.font = [UIFont boldSystemFontOfSize:15];
                cell.customText.textColor = [UIColor blackColor];
                cell.customText.backgroundColor = [UIColor whiteColor];
                cell.customDetails.backgroundColor = [UIColor whiteColor];
                cell.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                // red cell if not in Cloud anymore
                cell.customText.font = [UIFont systemFontOfSize:15];
                cell.customText.textColor = [UIColor darkGrayColor];
                UIColor *red = [UIColor colorWithRed:255.0/255 green:222.0/255 blue:222.0/255 alpha:1.0];
                cell.customText.backgroundColor = red;
                cell.customDetails.backgroundColor = red;
                cell.backgroundColor = red;
            }
            [cell.customCount setHidden:YES];
            cell.customImage.image = attachment.thumbnail;
            cell.customImageIsThumbnail = YES;
            
            NSDictionary *attrDetailRealFilename =  @{   NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                                         NSFontAttributeName:[UIFont systemFontOfSize:13]       };
            NSDictionary *attrDetailKey =           @{   NSForegroundColorAttributeName:[UIColor blackColor],
                                                         NSFontAttributeName:[UIFont boldSystemFontOfSize:12]   };
            NSDictionary *attrDetailValue =         @{   NSForegroundColorAttributeName:[UIColor blackColor],
                                                         NSFontAttributeName:[UIFont systemFontOfSize:12]       };
            NSInteger localFilterIdentityView = self.filterIdentityView;
            
            if (attachment.showDetails)
            {
                localFilterIdentityView = 1;
            }
            switch (localFilterIdentityView)
            {
                case 0:
                {
                    NSMutableAttributedString *details = [[NSMutableAttributedString alloc]
                                                          initWithString:[[NSString alloc] initWithFormat:@"%@", attachment.realfilename]
                                                          attributes:attrDetailRealFilename];
                    cell.customText.text = attachment.comment;
                    cell.customDetails.attributedText = details;
                    [cell setCellHeight:IDENTITY_CELL_HEIGHT_THUMBNAIL];
                    break;
                }
                case 1:
                {
                    NSMutableAttributedString *details = [[NSMutableAttributedString alloc] init];
                    
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:[[NSString alloc] initWithFormat:@"%@", attachment.realfilename]
                                                     attributes:attrDetailRealFilename]];
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:LS("AttachmentCellRealFileSize")
                                                      attributes:attrDetailKey]];
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:[[NSString alloc] initWithFormat:LS("FormatAttachmentCellRealFileSize"),
                                                                      [[NSNumber numberWithInteger:attachment.realfilesize] descriptionWithLocale:[NSLocale currentLocale]]]
                                                      attributes:attrDetailValue]];
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:LS("AttachmentCellRealFileType")
                                                      attributes:attrDetailKey]];
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:[[NSString alloc] initWithFormat:LS("FormatAttachmentCellRealFileType"),
                                                                      attachment.realfiletype]
                                                      attributes:attrDetailValue]];
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:LS("AttachmentCellDocument")
                                                     attributes:attrDetailKey]];
                    [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:[[NSString alloc] initWithFormat:LS("FormatAttachmentCellDocument"),
                                                                     attachment.filename]
                                                     attributes:attrDetailValue]];
                    cell.customText.text = attachment.comment;
                    cell.customDetails.attributedText = details;
                    [cell setCellHeight:IDENTITY_CELL_HEIGHT_EXTENDED];
                    
                    break;
                }
                default:
                    break;
            }
            
            return cell;
            
            break;
        }
        case 1:
        {
            AYAIIdentity *identity = [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray objectAtIndex:indexPath.row];
            if (identity == nil)
            {
                return nil;
            }
            
            UMTableViewCell *cell = [self.identityTableView dequeueReusableCellWithIdentifier:@"UMCell" forIndexPath:indexPath];
            UMTableViewCell __weak *weakCell = cell;
            
            // iOS 8 SDK uses layoutMargins, resulting in cell seperator indent to the left
            // Remove seperator inset
            if ([cell respondsToSelector:@selector(setSeparatorInset:)])
            {
                [cell setSeparatorInset:UIEdgeInsetsZero];
            }
            // Prevent the cell from inheriting the Table View's margin settings
            if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)])
            {
                [cell setPreservesSuperviewLayoutMargins:NO];
            }
            // Explictly set your cell's layout margins
            if ([cell respondsToSelector:@selector(setLayoutMargins:)])
            {
                [cell setLayoutMargins:UIEdgeInsetsZero];
            }
            
            [cell setAppearanceWithBlock:^{
                weakCell.leftUtilityButtons = [self leftIdentityButtons:identity];
                weakCell.rightUtilityButtons = [self rightIdentityButtons:identity];
                weakCell.delegate = self;
                weakCell.containingTableView = identityTableView;
            } force:YES];
            
            [cell setCellHeight:cell.frame.size.height];
            cell.customDetails.numberOfLines = 0;
            [cell.customDetails sizeToFit];
            
            if ([AYAISyncManager hasPublicICloudURL:identity])
            {
                [UIApplication sharedApplication].applicationIconBadgeNumber += 1;
            }
            if ([[AYAISettings load:@"prefShowArchives"] boolValue] == NO && identity.isArchive)
            {
                return cell;
            }
            if ([AYAISyncManager hasPublicICloudURL:identity])
            {
                // blue cell if Public URL still online
                UIColor *blue = [UIColor colorWithRed:222.0/255 green:222.0/255 blue:255.0/255 alpha:1.0];
                cell.customText.backgroundColor = blue;
                cell.customDetails.backgroundColor = blue;
                cell.backgroundColor = blue;
            }
            else if (identity.isArchive == YES)
            {
                // yellow cell if archived key
                UIColor *yellow = [UIColor colorWithRed:255.0/255 green:255.0/255 blue:244.0/255 alpha:1.0];
                cell.customText.backgroundColor = yellow;
                cell.customDetails.backgroundColor = yellow;
                cell.backgroundColor = yellow;
            }
            else if ([AYAISyncManager hasICloudDocument:identity])
            {
                // white cell if in Cloud
                cell.customText.backgroundColor = [UIColor whiteColor];
                cell.customDetails.backgroundColor = [UIColor whiteColor];
                cell.backgroundColor = [UIColor whiteColor];
            }
            else if ([AYAISyncManager iCloudIsOn] == NO)
            {
                // white cell if iCloud is turned off
                cell.customText.backgroundColor = [UIColor whiteColor];
                cell.customDetails.backgroundColor = [UIColor whiteColor];
                cell.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                // red cell if not in Cloud anymore
                UIColor *red = [UIColor colorWithRed:255.0/255 green:222.0/255 blue:222.0/255 alpha:1.0];
                cell.customText.backgroundColor = red;
                cell.customDetails.backgroundColor = red;
                cell.backgroundColor = red;
            }
            if (identity.isArchive == YES)
            {
                [cell.customCount setHidden:NO];
                UIColor *gray = [UIColor colorWithRed:111.0/255 green:111.0/255 blue:111.0/255 alpha:1.0];
                cell.customCount.backgroundColor = gray;
                cell.customCount.textColor = [UIColor whiteColor];
                cell.customCount.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.font = [UIFont boldSystemFontOfSize:10];
                cell.customCount.text = [[NSString alloc] initWithFormat:@"A"];
                cell.customImage.image = nil;
                cell.customImageIsThumbnail = NO;
                cell.customText.font = [UIFont boldSystemFontOfSize:15];
                cell.customText.textColor = [UIColor blackColor];
            }
            else
            {
                NSInteger iArchives = [AYAISyncManager countIdentityArchives:identity];
                if (iArchives > 0)
                {
                    [cell.customCount setHidden:NO];
                    UIColor *blue = [UIColor colorWithRed:0.0/255 green:0.0/255 blue:180.0/255 alpha:1.0];
                    cell.customCount.backgroundColor = blue;
                    cell.customCount.textColor = [UIColor whiteColor];
                    cell.customCount.textAlignment = NSTextAlignmentCenter;
                    cell.textLabel.font = [UIFont boldSystemFontOfSize:10];
                    cell.customCount.text = [[NSString alloc] initWithFormat:@"%ld", (long)iArchives];
                }
                else
                {
                    [cell.customCount setHidden:YES];
                }
                if (identity.subjectX509)
                {
                    cell.customImage.image = [UIImage imageNamed:@"Logo.png"];
                    cell.customImageIsThumbnail = NO;
                    cell.customText.font = [UIFont boldSystemFontOfSize:15];
                    cell.customText.textColor = [UIColor blackColor];
                }
                else
                {
                    cell.customImage.image = nil;
                    cell.customImageIsThumbnail = NO;
                    cell.customText.font = [UIFont systemFontOfSize:15];
                    cell.customText.textColor = [UIColor darkGrayColor];
                }
            }
            
            NSDictionary *attrDetailPerson =    @{   NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                                     NSFontAttributeName:[UIFont systemFontOfSize:13]    };
            NSDictionary *attrDetailIdentity =  @{   NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                                     NSFontAttributeName:[UIFont systemFontOfSize:13]    };
            NSDictionary *attrDetailKey =       @{   NSForegroundColorAttributeName:[UIColor blackColor],
                                                     NSFontAttributeName:[UIFont boldSystemFontOfSize:12]    };
            NSDictionary *attrDetailValue =     @{   NSForegroundColorAttributeName:[UIColor blackColor],
                                                     NSFontAttributeName:[UIFont systemFontOfSize:12]    };
            NSDictionary *attrDetailPassword =  @{   NSForegroundColorAttributeName:[UIColor blackColor],
                                                     NSFontAttributeName:[UIFont fontWithName:@"Menlo" size:12]    };
            NSDictionary *attrDetailNoValues =  @{   NSForegroundColorAttributeName:[UIColor grayColor],
                                                     NSFontAttributeName:[UIFont systemFontOfSize:12]    };
            NSInteger localFilterIdentityView = self.filterIdentityView;
            
            if (identity.showDetails)
            {
                localFilterIdentityView = 1;
            }
            switch (localFilterIdentityView)
            {
                case 0:
                {
                    NSMutableAttributedString *details = [[NSMutableAttributedString alloc]
                                                          initWithString:[[NSString alloc] initWithFormat:@"%@ %@, %@", identity.personFirstName, identity.personLastName, identity.personAddressCity]
                                                          attributes:attrDetailIdentity];
                    cell.customText.text = identity.personEmail;
                    cell.customDetails.attributedText = details;
                    [cell setCellHeight:IDENTITY_CELL_HEIGHT_NORMAL];
                    break;
                }
                case 1:
                {
                    NSMutableAttributedString *details = [[NSMutableAttributedString alloc] init];
                    
                    if (identity.subjectX509)
                    {
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setLocale:[NSLocale currentLocale]];
                        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
                        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
                        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                        
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[[NSString alloc] initWithFormat:@"%@ %@, %@", identity.personFirstName, identity.personLastName, identity.personAddressCity]
                                                         attributes:attrDetailPerson]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellKeysize")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[[NSString alloc] initWithFormat:LS("FormatIdentityCellKeysize"), identity.subjectX509Keysize]
                                                         attributes:attrDetailValue]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellDateNotBefore")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[dateFormatter stringFromDate:identity.subjectX509DateNotBefore]
                                                         attributes:attrDetailValue]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellDateNotAfter")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[dateFormatter stringFromDate:identity.subjectX509DateNotAfter]
                                                         attributes:attrDetailValue]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellSerial")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[[NSString alloc] initWithFormat:LS("FormatIdentityCellSerial"), [identity.subjectX509Serial substringToIndex:12], [identity.subjectX509Serial substringFromIndex:[identity.subjectX509Serial length]-12]]
                                                         attributes:attrDetailValue]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellFingerprint")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[[NSString alloc] initWithFormat:LS("FormatIdentityCellFingerprint"), [identity.subjectX509Fingerprint substringToIndex:17], [identity.subjectX509Fingerprint substringFromIndex:[identity.subjectX509Fingerprint length]-17]]
                                                         attributes:attrDetailValue]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellSignature")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[[NSString alloc] initWithFormat:LS("FormatIdentityCellSignature"), [identity.subjectX509Signature substringToIndex:36]]
                                                         attributes:attrDetailValue]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellPassword")
                                                         attributes:attrDetailKey]];
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:identity.password
                                                         attributes:attrDetailPassword]];
                        [cell setCellHeight:IDENTITY_CELL_HEIGHT_EXTENDED];
                    }
                    else
                    {
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:[[NSString alloc] initWithFormat:@"%@ %@, %@", identity.personFirstName, identity.personLastName, identity.personAddressCity]
                                                         attributes:attrDetailIdentity]];
                        
                        [details appendAttributedString:[[NSMutableAttributedString alloc]
                                                         initWithString:LS("IdentityCellEmpty")
                                                         attributes:attrDetailNoValues]];
                        [cell setCellHeight:IDENTITY_CELL_HEIGHT_MEDIUM];
                    }
                    cell.customText.text = identity.personEmail;
                    cell.customDetails.attributedText = details;
                    break;
                }
                default:
                    break;
            }
            
            return cell;
            
            break;
        }
        default:
            return nil;
            break;
    }
}

- (NSArray *)rightAttachmentButtons:(AYAIAttachment *)attachment
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    if (attachment.localFileURL != nil)
    {
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:LS("Open")];
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:1.0f green:0.78f blue:0.3f alpha:1.0] title:LS("Share")];
    }
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:LS("Delete")];
    
    return rightUtilityButtons;
}

- (NSArray *)leftIdentityButtons:(AYAIIdentity *)identity
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    if (identity.subjectX509)
    {
        [leftUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:0.0f green:0.80f blue:0.0f alpha:1.0] icon:[UIImage imageNamed:@"check.png"] subtitle:LS("Import")];
        [leftUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:0.60f green:0.60f blue:1.0f alpha:1.0] icon:[UIImage imageNamed:@"password.png"] subtitle:LS("Password")];
        [leftUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor orangeColor] icon:[UIImage imageNamed:@"list.png"]  subtitle:LS("Partner")];
        if ([AYAISyncManager hasPublicICloudURL:identity])
        {
            [leftUtilityButtons sw_addUtilityButtonWithColor:
             [UIColor redColor] icon:[UIImage imageNamed:@"cross.png"] subtitle:LS("Unlink")];
        }
    }
    else
    {
        [leftUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:0.0f green:0.80f blue:0.0f alpha:1.0] icon:[UIImage imageNamed:@"add.png"] subtitle:LS("New")];
    }
    
    return leftUtilityButtons;
}

- (NSArray *)rightIdentityButtons:(AYAIIdentity *)identity
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:LS("More")];
    if (identity.isArchive == YES)
    {
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:LS("Delete")];
    }
    else if (identity.subjectPKCS12)
    {
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:LS("Archive")];
    }
    else
    {
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:LS("Delete")];
    }
    
    return rightUtilityButtons;
}

#pragma mark - SWTableViewDelegate Menu handlers

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index
{
    NSIndexPath *cellIndexPath = [self.identityTableView indexPathForCell:cell];
    self.actionIdentity = [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray objectAtIndex:cellIndexPath.row];
    if (self.actionIdentity.subjectX509)
    {
        if ([AYAISyncManager iCloudIsOn])
        {
            switch (index)
            {
                case 0:
                {
                    NSLog(@"left button -check- was pressed -- Launch profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager publishIdentity:self.actionIdentity];
                        [cell hideUtilityButtonsAnimated:YES];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"left button -list- was pressed -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"left button -clock- was pressed -- Send mail to others");
                    if (self.actionIdentity.publicMobileConfig)
                    {
                        [AYAIMailManager sendMailToOthers:self.actionIdentity];
                        [cell hideUtilityButtonsAnimated:YES];
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"left button -cross- was pressed -- Delete profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager unpublishIdentity:self.actionIdentity];
                        [cell hideUtilityButtonsAnimated:YES];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                default:
                    break;
            }
        }
        else
        {
            switch (index)
            {
                case 0:
                {
                    NSLog(@"left button -check- was pressed -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                        [cell hideUtilityButtonsAnimated:YES];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"left button -list- was pressed -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"left button -clock- was pressed -- Send mail to others");
                    if (self.actionIdentity.publicMobileConfig)
                    {
                        [AYAIMailManager sendMailToOthers:self.actionIdentity];
                        [cell hideUtilityButtonsAnimated:YES];
                    }
                    break;
                }
                default:
                    break;
            }
        }
    }
    else
    {
        switch (index)
        {
            case 0:
            {
                NSLog(@"left button 0 was pressed -- Generate new keys");
                [self beginGenerateNewKeys];
                [cell hideUtilityButtonsAnimated:YES];
                break;
            }
            default:
                break;
        }
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    UIActionSheet *rightMenu;
    NSIndexPath *cellIndexPath = [self.identityTableView indexPathForCell:cell];
    
    switch (cellIndexPath.section)
    {
        case 0:
        {
            self.actionAttachment = [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray objectAtIndex:cellIndexPath.row];
            self.actionCellIndexPath = cellIndexPath;

            switch (index)
            {
                case 0: // Open
                {
                    if (self.actionAttachment.localFileURL == nil)
                    {
                        break;
                    }
                    NSError *error = nil;
                    NSData *documentData = [NSData dataWithContentsOfURL:self.actionAttachment.localFileURL
                                                                 options:NSDataReadingMappedAlways
                                                                   error:&error];
                    NSData *plainData = [documentData plainData];
                    if (plainData == nil)
                    {
                        NSLog(@"Decryption failed for %@", self.actionAttachment.localFileURL);
                        REDTOASTER("SyncCannotDecryptLocal");
                    }
                    else
                    {
                        AYAIAttachment *attachment = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
                        plainData = nil;
                        
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsDirectory = [paths objectAtIndex:0];
                        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:attachment.realfilename];
                        //FIXME: delete plain file as soon as possible
                        [attachment.data writeToFile:filePath atomically:YES];
                        self.documentController = [UIDocumentInteractionController
                                                   interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
                        self.documentController.UTI = attachment.realfiletype;
                        [self.documentController presentOptionsMenuFromRect:CGRectNull inView:self.view animated:YES];
                    }
                    [cell hideUtilityButtonsAnimated:YES];
                    break;
                }
                case 1: // Share
                {
                    if (self.actionAttachment.localFileURL == nil)
                    {
                        break;
                    }
                    NSError *error = nil;
                    NSData *documentData = [NSData dataWithContentsOfURL:self.actionAttachment.localFileURL
                                                                 options:NSDataReadingMappedAlways
                                                                   error:&error];
                    NSData *plainData = [documentData plainData];
                    if (plainData == nil)
                    {
                        NSLog(@"Decryption failed for %@", self.actionAttachment.localFileURL);
                        REDTOASTER("SyncCannotDecryptLocal");
                    }
                    else
                    {
                        AYAIAttachment *attachment = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
                        plainData = nil;
                        NSArray * shareItems = @[attachment.data];
                        UIActivityViewController * avc = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
                        [self presentViewController:avc animated:YES completion:nil];
                    }
                    [cell hideUtilityButtonsAnimated:YES];
                    break;
                }
                case 2: // Delete
                {
                    rightMenu = [[UIActionSheet alloc] initWithTitle:LS("MenuDeleteAttachmentTitle")
                                                            delegate:self
                                                   cancelButtonTitle:LS("Cancel")
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:
                                 LS("Delete"),
                                 nil];
                    rightMenu.tag = 116;
                    [rightMenu showFromToolbar:self.identityToolbar];
                    [cell hideUtilityButtonsAnimated:YES];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 1:
        {
            self.actionIdentity = [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray objectAtIndex:cellIndexPath.row];
            self.actionCellIndexPath = cellIndexPath;
            if (self.actionIdentity.subjectX509)
            {
                if ([AYAISyncManager iCloudIsOn])
                {
                    switch (index) // iCloud available
                    {
                        case 0: // More
                        {
                            rightMenu = [[UIActionSheet alloc] initWithTitle:LS("MenuICloudTitle")
                                                                    delegate:self
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:
                                         LS("MenuPublicURL"),
                                         LS("MenuMailSelf"),
                                         LS("MenuPassword"),
                                         nil];
                            if (self.actionIdentity.isArchive == NO)
                            {
                                [rightMenu addButtonWithTitle:LS("MenuMailPartners")];
                            }
                            rightMenu.tag = 11;
                            if ([AYAISyncManager hasPublicICloudURL:self.actionIdentity])
                            {
                                [rightMenu addButtonWithTitle:LS("MenuDeleteURL")];
                                rightMenu.tag = 10;
                            }
                            if (self.actionIdentity.isArchive == YES)
                            {
                                rightMenu.tag += 2; // 12 or 13
                            }
                            [rightMenu addButtonWithTitle:LS("MenuExport")];
                            if (self.actionIdentity.isArchive == YES &&
                                ([[[AYAIAppDelegate sharedAppDelegate] getUserData] canRestoreIdentity:self.actionIdentity] == YES))
                            {
                                [rightMenu addButtonWithTitle:LS("MenuRestore")];
                            }
                            rightMenu.cancelButtonIndex = [rightMenu addButtonWithTitle:LS("Cancel")];
                            [rightMenu showFromToolbar:self.identityToolbar];
                            [cell hideUtilityButtonsAnimated:YES];
                            break;
                        }
                        default:
                            break;
                    }
                }
                else // no iCloud
                {
                    switch (index)
                    {
                        case 0: // More
                        {
                            rightMenu = [[UIActionSheet alloc] initWithTitle:LS("MenuLocalTitle")
                                                                    delegate:self
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:
                                         LS("MenuMailSelf"),
                                         LS("MenuPassword"),
                                         nil];
                            if (self.actionIdentity.isArchive == NO)
                            {
                                [rightMenu addButtonWithTitle:LS("MenuMailPartners")];
                                rightMenu.tag = 20;
                            }
                            else
                            {
                                rightMenu.tag = 21;
                            }
                            [rightMenu addButtonWithTitle:LS("MenuExport")];
                            if (self.actionIdentity.isArchive == YES &&
                                ([[[AYAIAppDelegate sharedAppDelegate] getUserData] canRestoreIdentity:self.actionIdentity] == YES))
                            {
                                [rightMenu addButtonWithTitle:LS("MenuRestore")];
                            }
                            rightMenu.cancelButtonIndex = [rightMenu addButtonWithTitle:LS("Cancel")];
                            [rightMenu showFromToolbar:self.identityToolbar];
                            [cell hideUtilityButtonsAnimated:YES];
                            break;
                        }
                        default:
                            break;
                    }
                }
                switch (index)
                {
                    case 1: // Delete -- clean: remove identity keys and certificates from cell but keep person information
                    {
                        if (self.actionIdentity.isArchive == NO)
                        {
                            rightMenu = [[UIActionSheet alloc] initWithTitle:LS("MenuArchiveTitle")
                                                                    delegate:self
                                                           cancelButtonTitle:LS("Cancel")
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:
                                         LS("MenuArchive"),
                                         LS("Delete"),
                                         nil];
                            rightMenu.tag = 15;
                        }
                        else
                        {
                            rightMenu = [[UIActionSheet alloc] initWithTitle:LS("MenuDeleteTitle")
                                                                    delegate:self
                                                           cancelButtonTitle:LS("Cancel")
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:
                                         LS("Delete"),
                                         nil];
                            rightMenu.tag = 16;
                        }
                        [rightMenu showFromToolbar:self.identityToolbar];
                        [cell hideUtilityButtonsAnimated:YES];
                        break;
                    }
                    default:
                        break;
                }
            }
            else
            {
                switch (index)
                {
                    case 0: // More
                    {
                        rightMenu = [[UIActionSheet alloc] initWithTitle:LS("MenuNewTitle")
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:
                                     LS("MenuGenerate"),
                                     nil];
                        rightMenu.cancelButtonIndex = [rightMenu addButtonWithTitle:LS("Cancel")];
                        rightMenu.tag = 30;
                        [rightMenu showFromToolbar:self.identityToolbar];
                        [cell hideUtilityButtonsAnimated:YES];
                        break;
                    }
                    case 1: // Drop empty identity
                    {
                        NSIndexPath *cellIndexPath = [self.identityTableView indexPathForCell:cell];
                        [AYAISyncManager deleteIdentity:self.actionIdentity];
                        [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray removeObjectAtIndex:cellIndexPath.row];
                        [self.identityTableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        break;
                    }
                    default:
                        break;
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void)actionSheet:(UIActionSheet *)rightMenu clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (rightMenu.tag)
    {
        case 116:
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"Delete menu -- delete attachment");
                    if (self.actionAttachment.filename)
                    {
                        [AYAISyncManager deleteAttachment:self.actionAttachment];
                        [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray removeObjectAtIndex:self.actionCellIndexPath.row];
                        [self.identityTableView deleteRowsAtIndexPaths:@[self.actionCellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        [self refreshIdentityTableView];
                        break;
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 10:    // Actions with identity w/ public profile URL
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"More menu -- Launch profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager publishIdentity:self.actionIdentity];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"More menu -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"More menu -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"More menu -- Send mail to others");
                    if (self.actionIdentity.publicMobileConfig)
                    {
                        [AYAIMailManager sendMailToOthers:self.actionIdentity];
                    }
                    break;
                }
                case 4:
                {
                    NSLog(@"More menu -- Delete profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager unpublishIdentity:self.actionIdentity];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 5:
                {
                    NSLog(@"More menu -- Export private key to iTunes");
                    if (self.actionIdentity.subjectPKCS12)
                    {
                        [AYAISyncManager exportPrivateKey:self.actionIdentity];
                        GREENTOASTER("ToastKeyWasExported");
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 11:    // Actions with identity w/o public profile URL
        {
            
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"More menu -- Launch profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager publishIdentity:self.actionIdentity];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"More menu -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"More menu -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"More menu -- Send mail to others");
                    if (self.actionIdentity.publicMobileConfig)
                    {
                        [AYAIMailManager sendMailToOthers:self.actionIdentity];
                    }
                    break;
                }
                case 4:
                {
                    NSLog(@"More menu -- Export private key to iTunes");
                    if (self.actionIdentity.subjectPKCS12)
                    {
                        [AYAISyncManager exportPrivateKey:self.actionIdentity];
                        GREENTOASTER("ToastKeyWasExported");
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 12:    // Actions with archives w/ public profile URL
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"More menu -- Launch profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager publishIdentity:self.actionIdentity];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"More menu -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"More menu -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"More menu -- Delete profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager unpublishIdentity:self.actionIdentity];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 4:
                {
                    NSLog(@"More menu -- Export private key to iTunes");
                    if (self.actionIdentity.subjectPKCS12)
                    {
                        [AYAISyncManager exportPrivateKey:self.actionIdentity];
                        GREENTOASTER("ToastKeyWasExported");
                    }
                    break;
                }
                case 5:
                {
                    NSLog(@"More menu -- Restore archived identity");
                    if (self.actionIdentity.isArchive == YES &&
                        ([[[AYAIAppDelegate sharedAppDelegate] getUserData] canRestoreIdentity:self.actionIdentity] == YES))
                    {
                        [AYAISyncManager restoreIdentity:self.actionIdentity];
                        [self.identityTableView reloadData];
                        [self.identityTableView beginUpdates];
                        [self refreshIdentityTableView];
                        [self.identityTableView endUpdates];
                        GREENTOASTER("ToastKeyWasRestored");
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 13:    // Actions with archives w/o public profile URL
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"More menu -- Launch profile with public iCloud URL");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAISyncManager publishIdentity:self.actionIdentity];
                        [self refreshIdentityTableView];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"More menu -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"More menu -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"More menu -- Export private key to iTunes");
                    if (self.actionIdentity.subjectPKCS12)
                    {
                        [AYAISyncManager exportPrivateKey:self.actionIdentity];
                        GREENTOASTER("ToastKeyWasExported");
                    }
                    break;
                }
                case 4:
                {
                    NSLog(@"More menu -- Restore archived identity");
                    if (self.actionIdentity.isArchive == YES &&
                        ([[[AYAIAppDelegate sharedAppDelegate] getUserData] canRestoreIdentity:self.actionIdentity] == YES))
                    {
                        [AYAISyncManager restoreIdentity:self.actionIdentity];
                        [self.identityTableView reloadData];
                        [self.identityTableView beginUpdates];
                        [self refreshIdentityTableView];
                        [self.identityTableView endUpdates];
                        GREENTOASTER("ToastKeyWasRestored");
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 15:    // Delete action of identity with keys
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    [AYAISyncManager archiveIdentity:self.actionIdentity];
                    [self.identityTableView reloadData];
                    [self.identityTableView beginUpdates];
                    [self refreshIdentityTableView];
                    [self.identityTableView endUpdates];
                    break;
                }
                case 1:
                {
                    [AYAISyncManager cleanIdentity:self.actionIdentity];
                    [self.identityTableView reloadData];
                    [self.identityTableView beginUpdates];
                    [self refreshIdentityTableView];
                    [self.identityTableView endUpdates];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 16:    // Delete action of archive
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    [AYAISyncManager deleteArchive:self.actionIdentity];
                    [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray removeObjectAtIndex:self.actionCellIndexPath.row];
                    [self.identityTableView deleteRowsAtIndexPaths:@[self.actionCellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                    [self refreshIdentityTableView];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 20:    // Actions with identity, no iCloud
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"More menu -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"More menu -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"More menu -- Send mail to others");
                    if (self.actionIdentity.publicMobileConfig)
                    {
                        [AYAIMailManager sendMailToOthers:self.actionIdentity];
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"More menu -- Export private key to iTunes");
                    if (self.actionIdentity.subjectPKCS12)
                    {
                        [AYAISyncManager exportPrivateKey:self.actionIdentity];
                        GREENTOASTER("ToastKeyWasExported");
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 21:    // Actions with archive, no iCloud
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"More menu -- Send mail to myself");
                    if (self.actionIdentity.privateMobileConfig)
                    {
                        [AYAIMailManager sendMailToMyself:self.actionIdentity];
                    }
                    break;
                }
                case 1:
                {
                    NSLog(@"More menu -- Password into clipboard");
                    if (self.actionIdentity.password)
                    {
                        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                        pasteboard.string = self.actionIdentity.password;
                        BLUETOASTER("ToastPasswordInClipboard");
                    }
                    break;
                }
                case 2:
                {
                    NSLog(@"More menu -- Export private key to iTunes");
                    if (self.actionIdentity.subjectPKCS12)
                    {
                        [AYAISyncManager exportPrivateKey:self.actionIdentity];
                        GREENTOASTER("ToastKeyWasExported");
                    }
                    break;
                }
                case 3:
                {
                    NSLog(@"More menu -- Restore archived identity");
                    if (self.actionIdentity.isArchive == YES &&
                        ([[[AYAIAppDelegate sharedAppDelegate] getUserData] canRestoreIdentity:self.actionIdentity] == YES))
                    {
                        [AYAISyncManager restoreIdentity:self.actionIdentity];
                        [self.identityTableView reloadData];
                        [self.identityTableView beginUpdates];
                        [self refreshIdentityTableView];
                        [self.identityTableView endUpdates];
                        GREENTOASTER("ToastKeyWasRestored");
                    }
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 30:    // Actions with empty identity
        {
            switch (buttonIndex)
            {
                case 0:
                {
                    NSLog(@"left button 0 was pressed -- Generate new keys");
                    [self beginGenerateNewKeys];
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

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            AYAIAttachment *attachment = [[[AYAIAppDelegate sharedAppDelegate] getUserData].attachmentArray objectAtIndex:indexPath.row];
            // Easteregg: Open AYAI clone of SuperGenPass
            if ([attachment.comment isEqualToString:@"SuperGenPass"])
            {
                [self performSegueWithIdentifier:@"MainToPattern" sender:nil];
            }
            else
            {
                attachment.showDetails = !attachment.showDetails;
            }
            break;
        }
        case 1:
        {
            AYAIIdentity *identity = [[[AYAIAppDelegate sharedAppDelegate] getUserData].identityArray objectAtIndex:indexPath.row];
            identity.showDetails = !identity.showDetails;
            break;
        }
        default:
            break;
    }
    [identityTableView deselectRowAtIndexPath:indexPath animated:YES];
    [self refreshIdentityTableView];
}

#pragma mark - iCloud Methods

- (void)iCloudFileUpdateDidBegin
{
    NSLog(@"*** iCloudFileUpdateDidBegin ...");
}

- (void)iCloudFileUpdateDidEnd
{
    NSLog(@"*** ... iCloudFileUpdateDidEnd");
}

- (void)iCloudFilesDidChange:(NSMutableArray *)files withNewFileNames:(NSMutableArray *)fileNames
{
    if ([AYAISyncManager iCloudIsOn])
    {
        bool tableNeedsReload = false;
        float totalSize = 0;
        float loadedSize = 0;
        
        if ([files count])
        {
            NSLog(@"*** iCloudFilesDidChange:\n%@", fileNames);
            
            if ([files count] != [[[AYAIAppDelegate sharedAppDelegate] getUserData] countOfUserDataArrays])
            {
                NSLog(@"*** iCloudFilesDidChange: number of files %+d", (int)([files count] - [[[AYAIAppDelegate sharedAppDelegate] getUserData] countOfUserDataArrays]));
                tableNeedsReload = true;
            }
            
            for (CFIndex idx = 0; idx < [files count]; idx++)
            {
                NSMetadataItem *item = [files objectAtIndex:idx];
                NSString *documentName = [fileNames objectAtIndex:idx];
                NSLog(@"Handling %@", documentName);
                
                NSString *downloadingStatus = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
                NSLog(@"downloadingStatus = %@", downloadingStatus);
                if ([downloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusDownloaded])
                {
                    tableNeedsReload = true;
                }
                else if ([downloadingStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusNotDownloaded])
                {
                    [AYAISyncManager retrieveDocument:documentName];
                }
                
                NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
                BOOL documentExists = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
                if (documentExists == false) NSLog(@"documentExists = %i", documentExists);
                NSNumber *isUbiquitous = [item valueForAttribute:NSMetadataItemIsUbiquitousKey];
                if (isUbiquitous.integerValue != 1) NSLog(@"isUbiquitous = %@", isUbiquitous);
                NSNumber *hasUnresolvedConflicts = [item valueForAttribute:NSMetadataUbiquitousItemHasUnresolvedConflictsKey];
                if (hasUnresolvedConflicts.integerValue != 0) NSLog(@"hasUnresolvedConflicts = %@", hasUnresolvedConflicts);
                
                NSNumber *isDownloading = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
                if (isDownloading.integerValue != 0)
                {
                    NSLog(@"isDownloading = %@", isDownloading);
                }
                NSNumber *percentDownloaded = [item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
                if (percentDownloaded.integerValue != 100)
                {
                    NSNumber *fileSize = [item valueForAttribute:NSMetadataItemFSSizeKey];
                    NSLog(@"file size = %u", (unsigned int)fileSize);
                    NSLog(@"file perc = %@", percentDownloaded);
                    totalSize += fileSize.integerValue;
                    loadedSize += fileSize.integerValue * percentDownloaded.integerValue / 100.0;
                }
                NSNumber *isUploaded = [item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey];
                if (isUploaded.integerValue != 1)
                {
                    NSLog(@"isUploaded = %@", isUploaded);
                }
                NSNumber *isUploading = [item valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey];
                if (isUploading.integerValue != 0)
                {
                    NSLog(@"isUploading = %@", isUploading);
                }
                NSNumber *percentUploaded = [item valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey];
                if (percentUploaded.integerValue != 100)
                {
                    NSNumber *fileSize = [item valueForAttribute:NSMetadataItemFSSizeKey];
                    NSLog(@"file size = %u", (unsigned int)fileSize);
                    NSLog(@"file perc = %@", percentUploaded);
                    totalSize += fileSize.integerValue;
                    loadedSize += fileSize.integerValue * percentUploaded.floatValue / 100.0;
                }
            }
        }
        NSLog(@"*** total size = %u", (unsigned int)totalSize);
        NSLog(@"*** loaded yet = %u", (unsigned int)loadedSize);
        if (totalSize > 0.0)
        {
            float percentage = loadedSize/totalSize*100.0;
            NSLog(@"*** total perc = %f", percentage);
            [self beginProgressViewForICloudLoading:percentage];
        }
        else
        {
            [self endProgressViewForICloudLoading];
            if (tableNeedsReload)
            {
                [self.identityTableView reloadData];
                [self refreshIdentityTableView];
            }
        }
    }
}

- (void)iCloudFileConflictBetweenCloudFile:(NSDictionary *)cloudFile andLocalFile:(NSDictionary *)localFile
{
    NSLog(@"ERROR: unhandled iCloudFileConflictBetweenCloudFile: cloudFile %@ andLocalFile %@ ", cloudFile, localFile);
}

- (void)iCloudDidFinishInitializingWitUbiquityToken:(id)cloudToken withUbiquityContainer:(NSURL *)ubiquityContainer
{
    self.buttonCloud.tintColor = [UIColor blueColor];
    GREENTOASTER("ToastICloudAvailable");
}

- (void)iCloudAvailabilityDidChangeToState:(BOOL)cloudIsAvailable withUbiquityToken:(id)ubiquityToken withUbiquityContainer:(NSURL *)ubiquityContainer
{
    if (cloudIsAvailable)
    {
        self.buttonCloud.tintColor = [UIColor blueColor];
        if ([[AYAIAppDelegate sharedAppDelegate] didAppear] == NO)
        {
            GREENTOASTER("ToastICloudAvailable");
        }
    }
    
    else
    {
        self.buttonCloud.tintColor = [UIColor redColor];
        if ([[AYAIAppDelegate sharedAppDelegate] didAppear] == NO)
        {
            REDTOASTER("ToastICloudNotAvailable");
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mustHandleSharedAttachment = false;
    self.iCloudProgressView.progress = 0.0;
    
    [KeychainUserPass load:@"AESPassword"];
    [KeychainUserPass load:@"AESOldPassword"];
    [KeychainUserPass load:@"AESNewPassword"];
    [KeychainUserPass load:@"PKCS12Password"];
    
    [[AYAIAppDelegate sharedAppDelegate] setMyView:self];

    if ([[AYAIAppDelegate sharedAppDelegate] getUserData] == nil)
    {
        [[AYAIAppDelegate sharedAppDelegate] setCryptoHandler:[[AYAICrypto alloc] init]];
        
        AYAIUserData *userData = [[AYAIUserData alloc] init];
        [[AYAIAppDelegate sharedAppDelegate] setUserData:userData];
        
        self.filterIdentityView = 0;
        self.identityTableView.rowHeight = IDENTITY_CELL_HEIGHT_NORMAL;
        [self.identityTableView setAlpha:0.1];
        [self.identityTableView setUserInteractionEnabled:NO];

        self.angle = 0.0;
        self.motionManager = [[CMMotionManager alloc] init];
        [self.motionManager startGyroUpdates];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1/30.0
                                                      target:self
                                                    selector:@selector(doGyroUpdate)
                                                    userInfo:nil
                                                     repeats:YES];
        [self.progressLabel setText:LS("ProgressLabelRandom")];
        self.randomBits = 0;
        self.randomSeed = @"";
        self.randomSeedInitialized = NO;
        self.opensslLock = NO;
        
        [self beginProgressViewForRandomGeneration];
    }
    else
    {
        [self endProgressViewForRandomGeneration];
    }
    
    self.identityTableView.delegate = self;
    self.identityTableView.dataSource = self;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        self.identityTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor grayColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:LS("PullToRefresh")];
    [self.identityTableView addSubview:refreshControl];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view becomeFirstResponder];
    
    self.buttonCloud.tintColor = [UIColor lightGrayColor];
    if ([AYAISyncManager iCloudIsOn])
    {
        self.buttonCloud.tintColor = [UIColor blueColor];
        if ([[AYAIAppDelegate sharedAppDelegate] didAppear] == NO)
        {
            GREENTOASTER("ToastICloudAvailable");
        }
    }
    else if ([[iCloud sharedCloud] checkCloudAvailability])
    {
        self.buttonCloud.tintColor = [UIColor lightGrayColor];
        if ([[AYAIAppDelegate sharedAppDelegate] didAppear] == NO)
        {
            GRAYTOASTER("ToastICloudDisabled");
        }
    }
    else
    {
        self.buttonCloud.tintColor = [UIColor redColor];
        if ([[AYAIAppDelegate sharedAppDelegate] didAppear] == NO)
        {
            REDTOASTER("ToastICloudNotAvailable");
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"viewDidAppear");
    
    [AYAISyncManager deleteAllLocalFiles:DELETE_LOCAL_EVICTED];
    
    if ([[AYAISettings load:@"prefTutorialOnStartup"] boolValue] == YES)
    {
        [AYAISettings save:@"prefTutorialOnStartup" data:[NSNumber numberWithBool:false]];
        [self performSegueWithIdentifier:@"MainToTutorialPages" sender:nil];
        return;
    }

    if ([KeychainUserPass load:@"AESPassword"] == nil)
    {
        [self performSegueWithIdentifier:@"MainToAESPassword" sender:nil];
        return;
    }

    if ([KeychainUserPass requireNewPassword])
    {
        [self performSegueWithIdentifier:@"MainToAESNewPassword" sender:nil];
        return;
    }
    if ([AYAIAppDelegate sharedAppDelegate].didAppear == NO || [KeychainUserPass requirePasswordRetry] || [[[AYAIAppDelegate sharedAppDelegate] getUserData] countOfUserDataArrays] == 0)
    {
        [[[AYAIAppDelegate sharedAppDelegate] getUserData] initFromFilesAndICloud];
        [self.identityTableView reloadData];
        if ([AYAISyncManager iCloudIsOn])
        {
            [(iCloud *)[iCloud sharedCloud] setDelegate:self];
            [[iCloud sharedCloud] setVerboseLogging:YES];
            NSLog(@"%@", [[iCloud sharedCloud] listCloudFiles]);
            [[iCloud sharedCloud] updateFiles];
        }
    }
    if ([AYAISyncManager countVersion1PFXInITunes] > 0 && [AYAIAppDelegate sharedAppDelegate].migrationCancelled == NO)
    {
        [self migrateLocalFilesVersion1x];
    }
    [self refreshIdentityTableView];
    [[AYAIAppDelegate sharedAppDelegate] setDidAppear:YES];
    
    [self handleSharedAttachment];
    
    [SKStoreReviewController requestReview];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

#pragma mark - Share extension handling

- (void)handleOpenURL
{
    self.mustHandleSharedAttachment = true;
    [self viewDidAppear:TRUE];
}

- (void)handleSharedAttachment
{
    if (self.mustHandleSharedAttachment == false)
    {
        return;
    }
    self.mustHandleSharedAttachment = false;
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.eu.andyouandi"];
    NSURL *url = [sharedDefaults URLForKey:@"url"];
    NSData *data = [sharedDefaults objectForKey:@"data"];
    NSString *type = [sharedDefaults objectForKey:@"type"];

    if (data != nil)
    {
        AYAIAttachment *attachment = [[AYAIAttachment alloc] init];
        attachment.filename = [AYAIPasswordManager newRandomPassword];
        attachment.comment = [sharedDefaults stringForKey:@"comment"];
        attachment.data = data;
        attachment.thumbnail = [AYAIAttachment thumbnailFromData:attachment.data :type];
        attachment.realfilesize = attachment.data.length;
        if (url != nil)
        {
            attachment.realfilename = [url lastPathComponent];
        }
        else
        {
            attachment.realfilename = [[NSString alloc] initWithFormat:LS("AttachmentUnknownFilename")];
        }
        if (type != nil)
        {
            attachment.realfiletype = type;
        }
        else
        {
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                    (__bridge CFStringRef)[attachment.realfilename pathExtension], NULL);
            attachment.realfiletype = (__bridge NSString *)UTI;
            CFRelease(UTI);
        }
        NSLog(@"*** handleSharedAttachment loaded attachment from URL:\n%@\nrealfilename = %@\nrealfiletype = %@\nrealfilesize = %lu",
              url, attachment.realfilename, attachment.realfiletype, (unsigned long)attachment.realfilesize);
        if (attachment.data != nil && [[[AYAIAppDelegate sharedAppDelegate] getUserData] addAttachment:attachment] == YES)
        {
            [AYAISyncManager addAttachment:attachment];
            [self refreshIdentityTableView];
        }
    }
    else
    {
        NSLog(@"*** ERROR in handleSharedAttachment: Cannot load data from URL: %@\n%@", data, url);
        REDTOASTER("ShareExtensionEmptyData");
    }
    [sharedDefaults removeObjectForKey:@"comment"];
    [sharedDefaults removeObjectForKey:@"url"];
    [sharedDefaults removeObjectForKey:@"data"];
    [sharedDefaults removeObjectForKey:@"type"];
}

@end
