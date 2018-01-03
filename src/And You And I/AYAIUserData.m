//
//  AYAIUserData.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAI.h"
#import "AYAIViewController.h"
#import "AYAIUserData.h"
#import "AYAIIdentity.h"
#import "AYAIAttachment.h"

@implementation AYAIUserData

- (void)changePassword
{
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        [AYAISyncManager recryptIdentity:[self.identityArray objectAtIndex:idx]];
    }
    for (CFIndex idx = 0; idx < [self.attachmentArray count]; idx++)
    {
        [AYAISyncManager recryptAttachment:[self.attachmentArray objectAtIndex:idx]];
    }
    [KeychainUserPass burnNewPassword];
}

- (void)releaseTableArrays
{
    self.identityArray = [[NSMutableArray alloc] init];
    self.attachmentArray = [[NSMutableArray alloc] init];
}

- (NSInteger)countOfUserDataArrays
{
    return [self.identityArray count] + [self.attachmentArray count];
}

- (void)initFromFilesAndICloud
{
    [self releaseTableArrays];
    [AYAISyncManager loadTableArrays];
    if ([KeychainUserPass load:@"AESPassword"] == nil)
    {
        [[[AYAIAppDelegate sharedAppDelegate] getMainView] performSegueWithIdentifier:@"MainToAESPassword" sender:nil];
    }
}

- (BOOL)addAttachment:(AYAIAttachment *)attachment;
{
    if (attachment == nil || [attachment.filename isEqualToString:@""])
    {
        REDTOASTER("MsgUserBadAttachment");
        return NO;
    }
    // new attachment is already in array?
    for (CFIndex idx = 0; idx < [self.attachmentArray count]; idx++)
    {
        AYAIAttachment *arrayAttachment = [self.attachmentArray objectAtIndex:idx];
        if ([attachment.filename isEqualToString:arrayAttachment.filename] == YES)
        {
            return NO;
        }
    }
    [self.attachmentArray addObject:attachment];
    
    return YES;
}

- (BOOL)addIdentity:(AYAIIdentity *)identity
{
    if (identity == nil || [identity.personEmail isEqualToString:@""] || [identity.personFirstName isEqualToString:@""] || [identity.personLastName isEqualToString:@""] || [identity.personAddressCity isEqualToString:@""])
    {
        REDTOASTER("MsgUserBadIdentity");
        return NO;
    }
    // new ID with key is already in array?
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        if ([identity.personEmail isEqualToString:arrayIdentity.personEmail] == NO)
        {
            continue;
        }
        if (identity.subjectX509Fingerprint == nil && arrayIdentity.subjectX509Fingerprint == nil)
        {
            NSLog(@"addIdentity: ID already in table: %@", identity.personEmail);
            return NO;
        }
        if (identity.subjectX509Fingerprint == nil && arrayIdentity.subjectX509Fingerprint != nil)
        {
            NSLog(@"addIdentity: ID already in table: %@, %@", identity.personEmail, identity.subjectX509Fingerprint);
            return NO;
        }
        if (identity.subjectX509Fingerprint != nil && arrayIdentity.subjectX509Fingerprint != nil &&
            [identity.subjectX509Fingerprint isEqualToString:arrayIdentity.subjectX509Fingerprint] == YES &&
            identity.isArchive == NO)
        {
            NSLog(@"addIdentity: ID already in table: %@, %@", identity.personEmail, identity.subjectX509Fingerprint);
            return NO;
        }
        if (identity.subjectX509Fingerprint != nil && arrayIdentity.subjectX509Fingerprint != nil &&
            [identity.subjectX509Fingerprint isEqualToString:arrayIdentity.subjectX509Fingerprint] == YES &&
            identity.isArchive == YES && arrayIdentity.isArchive == YES)
        {
            NSLog(@"addIdentity: ID archive already in table: %@, %@", identity.personEmail, identity.subjectX509Fingerprint);
            return NO;
        }
    }
    // new ID with key is not in array, so we want to add it as new or full or archive ID
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        // not same ID? next of array
        if ([identity.personEmail isEqualToString:arrayIdentity.personEmail] == NO)
        {
            continue;
        }
        // array ID is empty? take new ID instead
        if (arrayIdentity.subjectX509 == nil && identity.subjectX509 != nil && identity.isArchive == NO)
        {
            NSLog(@"addIdentity: replaced empty ID: %@, %@", identity.personEmail, identity.subjectX509Fingerprint);
            [self.identityArray removeObject:arrayIdentity];
            break;
        }
        // array ID and new ID with different keys? add new ID as archive
        if (identity.subjectX509Fingerprint != nil && arrayIdentity.subjectX509Fingerprint != nil &&
            [identity.subjectX509Fingerprint isEqualToString:arrayIdentity.subjectX509Fingerprint] == NO)
        {
            NSLog(@"addIdentity: added ID as archive: %@, %@", identity.personEmail, identity.subjectX509Fingerprint);
            [AYAISyncManager archiveITunes:identity];
            return YES;
        }
    }
    [self.identityArray addObject:identity];
    
    return YES;
}

- (BOOL)restoreIdentity:(AYAIIdentity *)identity
{
    if (identity == nil || [identity.personEmail isEqualToString:@""] || [identity.personFirstName isEqualToString:@""] || [identity.personLastName isEqualToString:@""] || [identity.personAddressCity isEqualToString:@""])
    {
        REDTOASTER("MsgUserBadIdentity");
        return NO;
    }
    // Main ID still in table?
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        if (arrayIdentity.isArchive == NO && [identity.personEmail isEqualToString:arrayIdentity.personEmail] == YES)
        {
            NSLog(@"restoreIdentity: Main ID found in table, cannot offer restore: %@", arrayIdentity.personEmail);
            return NO;
        }
    }
    [self.identityArray removeObject:identity];
    identity.isArchive = NO;
    [self.identityArray addObject:identity];
    
    return YES;
}

- (BOOL)canRestoreIdentity:(AYAIIdentity *)identity
{
    if (identity == nil || [identity.personEmail isEqualToString:@""] || [identity.personFirstName isEqualToString:@""] || [identity.personLastName isEqualToString:@""] || [identity.personAddressCity isEqualToString:@""])
    {
        REDTOASTER("MsgUserBadIdentity");
        return NO;
    }
    // Main ID still in table?
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        if (arrayIdentity.isArchive == NO && [identity.personEmail isEqualToString:arrayIdentity.personEmail] == YES)
        {
            NSLog(@"canRestoreIdentity: Main ID found in table, cannot offer restore: %@", arrayIdentity.personEmail);
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)duplicateIdentity:(AYAIIdentity *)identity
{
    if (identity == nil || [identity.personEmail isEqualToString:@""] || [identity.personFirstName isEqualToString:@""] || [identity.personLastName isEqualToString:@""] || [identity.personAddressCity isEqualToString:@""])
    {
        REDTOASTER("MsgUserBadIdentity");
        return NO;
    }
    [self.identityArray addObject:identity];
    
    return YES;
}

#pragma mark iCloud ON/OFF operations

- (void)persistAllDocuments
{
    [self persistAllIdentities];
    [self persistAllAttachments];
    [self releaseTableArrays];
    GREENTOASTER("SyncPersistedAllDocuments");
}

- (void)moveAllDocuments
{
    [self moveAllIdentities];
    [self moveAllAttachments];
    [self releaseTableArrays];
    GREENTOASTER("SyncMovedAllDocuments");
}

- (void)persistAllAttachments
{
    for (CFIndex idx = 0; idx < [self.attachmentArray count]; idx++)
    {
        AYAIAttachment *arrayAttachment = [self.attachmentArray objectAtIndex:idx];
        if (arrayAttachment.data == nil)
        {
            NSError *error = nil;
            NSData *documentData = [NSData dataWithContentsOfURL:arrayAttachment.localFileURL
                                                         options:NSDataReadingMappedAlways
                                                           error:&error];
            NSData *plainData = [documentData plainData];
            if (plainData == nil)
            {
                NSLog(@"Decryption failed for %@", arrayAttachment.localFileURL);
                REDTOASTER("SyncCannotDecryptLocal");
            }
            else
            {
                AYAIAttachment *attachment = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
                plainData = nil;
                [AYAISyncManager addAttachmentITunes:attachment];
            }
        }
        else
        {
            [AYAISyncManager addAttachmentITunes:arrayAttachment];
        }
    }
}

- (void)moveAllAttachments
{
    CFIndex count = [self.attachmentArray count]; // array may grow, so use start value
    for (CFIndex idx = 0; idx < count; idx++)
    {
        AYAIAttachment *arrayAttachment = [self.attachmentArray objectAtIndex:idx];
        [AYAISyncManager moveAttachmentICloud:arrayAttachment];
    }
}

- (void)persistAllIdentities
{
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        if (arrayIdentity.isArchive == NO)
        {
            [AYAISyncManager addITunes:arrayIdentity];
        }
    }
}

- (void)moveAllIdentities
{
    CFIndex count = [self.identityArray count]; // array may grow, so use start value
    for (CFIndex idx = 0; idx < count; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        // keep archived IDs locally
        if (arrayIdentity.isArchive == NO)
        {
            // remove empty IDs locally if already in iCloud
            if (arrayIdentity.subjectX509 == nil && [AYAISyncManager hasICloudDocument:arrayIdentity] == YES)
            {
                [AYAISyncManager deleteITunes:arrayIdentity];
            }
            // archive ID locally if already in iCloud
            else if (arrayIdentity.subjectX509 != nil && [AYAISyncManager hasICloudDocument:arrayIdentity] == YES)
            {
                [AYAISyncManager archiveITunes:arrayIdentity];
                [AYAISyncManager deleteITunes:arrayIdentity];
            }
            else
            {
                [AYAISyncManager moveICloud:arrayIdentity];
            }
        }
    }
}

#pragma mark Details mode and sorting

- (void)resetViewAllIdentities
{
    for (CFIndex idx = 0; idx < [self.identityArray count]; idx++)
    {
        AYAIIdentity *arrayIdentity = [self.identityArray objectAtIndex:idx];
        arrayIdentity.showDetails = NO;
    }
    for (CFIndex idx = 0; idx < [self.attachmentArray count]; idx++)
    {
        AYAIAttachment *arrayAttachment = [self.attachmentArray objectAtIndex:idx];
        arrayAttachment.showDetails = NO;
    }
}

- (void)sortIdentities
{
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"personEmail"
                                 ascending:YES
                                 selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject: sorter];
    [self.identityArray sortUsingDescriptors:sortDescriptors];
}

@end

#pragma mark User Settings

@implementation AYAISettings

+ (void)save:(NSString *)key data:(id)data
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:key];
    [defaults synchronize];
}

+ (id)load:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

@end

#pragma mark Mobile Config Files
@implementation AYAIMobileConfig

+ (NSString *)GetUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *uuid = [[NSString alloc] initWithFormat:@"%@", string];
    CFRelease(string);
    
    return uuid;
}

+ (NSData *)generatePrivateMobileConfig:(EVP_PKEY *)subjectKey :(AYAIIdentity *)identity
{
    NSError *error;
    NSString *mobcfg = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"andyouandi-pfx" ofType:@"mobileconfig"] encoding:NSUTF8StringEncoding error:&error];
    
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION$"
                                               withString:LS("PayloadDescription")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-SUBJECT$"
                                               withString:LS("PayloadDescriptionSubject")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-ISSUER$"
                                               withString:LS("PayloadDescriptionIssuer")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-PFX$"
                                               withString:LS("PayloadDescriptionPFX")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-VERSION$"
                                               withString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-DATA$" withString:[identity.issuerX509 base64EncodedString]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-DATA$" withString:[identity.subjectX509 base64EncodedString]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-DATA$" withString:[identity.subjectPKCS12 base64EncodedString]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-FILENAME$" withString:identity.fnIssuerX509];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-FILENAME$" withString:identity.fnSubjectX509];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-FILENAME$" withString:identity.fnSubjectPKCS12];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$MAILADDRESS$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$FULLNAME$" withString:[[NSString alloc] initWithFormat:@"%@ %@", identity.personFirstName, identity.personLastName]];
    NSString *ownMailID = [[NSString alloc] initWithFormat:@"%@", identity.personEmail];
    ownMailID = [ownMailID stringByReplacingOccurrencesOfString:@"@" withString:@"."];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$MAILID$" withString:ownMailID];
    
    NSData *data = [mobcfg dataUsingEncoding:NSUTF8StringEncoding];
    
    PKCS7 *pkcs7 = nil;
    X509 *subject = [identity.subjectX509 dataX509];
    X509 *issuer = [identity.issuerX509 dataX509];
    STACK_OF(X509) *caCertStack;
    caCertStack = sk_X509_new_null();
    sk_X509_push(caCertStack, issuer);
    
    BIO *bpin = BIO_new_mem_buf((char *)[data bytes], (int)[data length]);
    BIO *bpout = BIO_new(BIO_s_mem());
    
    pkcs7 = PKCS7_sign(subject, subjectKey, caCertStack, bpin, 0);
    
    i2d_PKCS7_bio(bpout, pkcs7);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSData * signedData = [[NSData alloc] initWithBytes:outputBuffer length:outputLength];
    
    BIO_free_all(bpout);
    sk_X509_free(caCertStack);
    PKCS7_free(pkcs7);
    
    return signedData;
}

+ (NSData *)generateArchiveMobileConfig:(EVP_PKEY *)subjectKey :(AYAIIdentity *)identity
{
    NSError *error;
    NSString *mobcfg = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"andyouandi-arc" ofType:@"mobileconfig"] encoding:NSUTF8StringEncoding error:&error];
    
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION$"
                                               withString:LS("PayloadDescriptionArchive")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-SUBJECT$"
                                               withString:LS("PayloadDescriptionSubject")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-ISSUER$"
                                               withString:LS("PayloadDescriptionIssuer")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-PFX$"
                                               withString:LS("PayloadDescriptionPFX")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-VERSION$"
                                               withString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-DATA$" withString:[identity.subjectPKCS12 base64EncodedString]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-PFX-FILENAME$" withString:identity.fnSubjectPKCS12];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$MAILADDRESS$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$FULLNAME$" withString:[[NSString alloc] initWithFormat:@"%@ %@", identity.personFirstName, identity.personLastName]];
    NSString *ownMailID = [[NSString alloc] initWithFormat:@"%@", identity.personEmail];
    ownMailID = [ownMailID stringByReplacingOccurrencesOfString:@"@" withString:@"."];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$MAILID$" withString:ownMailID];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ARCHIVEID$" withString:identity.subjectX509Serial];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ARCHIVE-PAYLOADUUID$" withString:[self GetUUID]];
    
    NSData *data = [mobcfg dataUsingEncoding:NSUTF8StringEncoding];
    
    PKCS7 *pkcs7 = nil;
    X509 *subject = [identity.subjectX509 dataX509];
    X509 *issuer = [identity.issuerX509 dataX509];
    STACK_OF(X509) *caCertStack;
    caCertStack = sk_X509_new_null();
    sk_X509_push(caCertStack, issuer);
    
    BIO *bpin = BIO_new_mem_buf((char *)[data bytes], (int)[data length]);
    BIO *bpout = BIO_new(BIO_s_mem());
    
    pkcs7 = PKCS7_sign(subject, subjectKey, caCertStack, bpin, 0);
    
    i2d_PKCS7_bio(bpout, pkcs7);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSData * signedData = [[NSData alloc] initWithBytes:outputBuffer length:outputLength];
    
    BIO_free_all(bpout);
    sk_X509_free(caCertStack);
    PKCS7_free(pkcs7);
    
    return signedData;
}

+ (NSData *)generatePublicMobileConfig:(EVP_PKEY *)subjectKey :(AYAIIdentity *)identity
{
    NSError *error;
    NSString *mobcfg = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"andyouandi-crt" ofType:@"mobileconfig"] encoding:NSUTF8StringEncoding error:&error];
    
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-PUBLIC$"
                                               withString:LS("PayloadDescriptionPublic")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-SUBJECT$"
                                               withString:LS("PayloadDescriptionSubject")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$PAYLOAD-DESCRIPTION-ISSUER$"
                                               withString:LS("PayloadDescriptionIssuer")];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-VERSION$"
                                               withString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-PAYLOADUUID$" withString:[self GetUUID]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-DATA$" withString:[identity.issuerX509 base64EncodedString]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-DATA$" withString:[identity.subjectX509 base64EncodedString]];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-DISPLAYNAME$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ISSUER-CRT-FILENAME$" withString:identity.fnIssuerX509];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$SUBJECT-CRT-FILENAME$" withString:identity.fnSubjectX509];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$ANDYOUANDI-DISPLAYNAME$" withString:identity.personEmail];
    
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$MAILADDRESS$" withString:identity.personEmail];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$FULLNAME$" withString:[[NSString alloc] initWithFormat:@"%@ %@", identity.personFirstName, identity.personLastName]];
    NSString *ownMailID = [[NSString alloc] initWithFormat:@"%@", identity.personEmail];
    ownMailID = [ownMailID stringByReplacingOccurrencesOfString:@"@" withString:@"."];
    mobcfg = [mobcfg stringByReplacingOccurrencesOfString:@"$MAILID$" withString:ownMailID];
    
    NSData *data = [mobcfg dataUsingEncoding:NSUTF8StringEncoding];
    
    PKCS7 *pkcs7 = nil;
    X509 *subject = [identity.subjectX509 dataX509];
    X509 *issuer = [identity.issuerX509 dataX509];
    STACK_OF(X509) *caCertStack;
    caCertStack = sk_X509_new_null();
    sk_X509_push(caCertStack, issuer);
    
    BIO *bpin = BIO_new_mem_buf((char *)[data bytes], (int)[data length]);
    BIO *bpout = BIO_new(BIO_s_mem());
    
    pkcs7 = PKCS7_sign(subject, subjectKey, caCertStack, bpin, 0);
    
    i2d_PKCS7_bio(bpout, pkcs7);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSData * signedData = [[NSData alloc] initWithBytes:outputBuffer length:outputLength];
    
    BIO_free_all(bpout);
    sk_X509_free(caCertStack);
    PKCS7_free(pkcs7);
    
    return signedData;
}

@end

#pragma mark Mail Manager

@implementation AYAIMailManager

+ (void)sendMailToMyself:(AYAIIdentity *)identity
{
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    AYAIViewController *identityViewController = (AYAIViewController *)[[AYAIAppDelegate sharedAppDelegate] getMainView];
    controller.mailComposeDelegate = identityViewController;
    NSArray *toRecipients = [NSArray arrayWithObject: identity.personEmail];
    [controller setToRecipients:toRecipients];
    [controller setSubject:LS("MailSubjectYourPrivatekey")];
    NSMutableString *emailBody = [[NSMutableString alloc] initWithCapacity:20];
    UIImage *img = [UIImage imageNamed:@"LogoMail.png"];
    NSData *imgData = UIImagePNGRepresentation(img);
    NSString *dataString = [imgData base64EncodedString];
    [emailBody appendFormat:@"<a href='https://itunes.apple.com/app/and-you-and-i/id717480794?l=de&ls=1&mt=8'><img height='60' src='data:image/png;base64,%@' alt='And You And I'></a>", dataString];
    [emailBody appendString:LS("MailBodyYourPrivatekey")];
    [controller setMessageBody:emailBody isHTML:YES];
    [controller addAttachmentData:identity.privateMobileConfig mimeType:@"application/xml"
                         fileName:LS("FormatAttachmentNameMobileConfig")];
    [controller addAttachmentData:identity.issuerX509 mimeType:@"application/pkix-cert"
                         fileName:LS("FormatAttachmentNameIssuerCRT")];
    [controller addAttachmentData:identity.subjectX509 mimeType:@"application/pkix-cert"
                         fileName:LS("FormatAttachmentNameSubjectCRT")];
    [controller addAttachmentData:identity.subjectPKCS12 mimeType:@"application/pkcs12"
                         fileName:LS("FormatAttachmentNamePFX")];
    [identityViewController presentViewController:controller animated:YES completion:nil];
}

+ (void)sendMailToOthers:(AYAIIdentity *)identity
{
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    AYAIViewController *identityViewController = (AYAIViewController *)[[AYAIAppDelegate sharedAppDelegate] getMainView];
    controller.mailComposeDelegate = identityViewController;
    [controller setSubject:LS("MailSubjectMyCertificates")];
    NSMutableString *emailBody = [[NSMutableString alloc] initWithCapacity:20];
    UIImage *img = [UIImage imageNamed:@"LogoMail.png"];
    NSData *imgData = UIImagePNGRepresentation(img);
    NSString *dataString = [imgData base64EncodedString];
    [emailBody appendFormat:@"<a href='https://itunes.apple.com/app/and-you-and-i/id717480794?l=de&ls=1&mt=8'><img height='60' src='data:image/png;base64,%@' alt='And You And I'></a>", dataString];
    [emailBody appendString:LS("MailBodyMyCertificates")];
    [controller setMessageBody:emailBody isHTML:YES];
    [controller addAttachmentData:identity.publicMobileConfig mimeType:@"application/xml"
                         fileName:LS("FormatAttachmentNameMobileConfig")];
    [controller addAttachmentData:identity.issuerX509 mimeType:@"application/pkix-cert"
                         fileName:LS("FormatAttachmentNameIssuerCRT")];
    [controller addAttachmentData:identity.subjectX509 mimeType:@"application/pkix-cert"
                         fileName:LS("FormatAttachmentNameSubjectCRT")];
    [identityViewController presentViewController:controller animated:YES completion:nil];
}

@end

