    //
//  AYAISyncManager.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAISyncManager.h"
#import "AYAIAppDelegate.h"
#import "AYAIViewController.h"
#import "AYAIIdentity.h"
#import "AYAIAttachment.h"


@implementation AYAISyncManager

+ (BOOL)iCloudIsOn
{
    return ([[iCloud sharedCloud] checkCloudAvailability] == YES &&
            [[iCloud sharedCloud] checkCloudUbiquityContainer] == YES &&
            (BOOL)[[AYAISettings load:@"prefUseICloud"] boolValue] == YES);
}

+ (NSString *)localPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+ (NSString *)localDataPath
{
    NSString *dataPath = [[NSString alloc] initWithString:[[self localPath] stringByAppendingPathComponent:@"data"]];
    [[NSFileManager defaultManager] createDirectoryAtPath:dataPath
                              withIntermediateDirectories:YES
                                               attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey] error:nil];
    
    return dataPath;
}

+ (NSString *)localEvictedPath
{
    NSString *evictedPath = [[NSString alloc] initWithString:[[self localPath] stringByAppendingPathComponent:@"evicted"]];
    [[NSFileManager defaultManager] createDirectoryAtPath:evictedPath
                              withIntermediateDirectories:YES
                                               attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey] error:nil];
    
    return evictedPath;
}

+ (NSString *)localLogPath
{
    NSString *logPath = [[NSString alloc] initWithString:[[self localPath] stringByAppendingPathComponent:@"log"]];
    [[NSFileManager defaultManager] createDirectoryAtPath:logPath
                              withIntermediateDirectories:YES
                                               attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey] error:nil];
    
    return logPath;
}

+ (void)loadTableArrays
{
    if ([AYAISyncManager iCloudIsOn])
    {
        NSArray *iCloudFiles = [[iCloud sharedCloud] listCloudFiles];
        for (CFIndex idx = 0; idx < [iCloudFiles count]; idx++)
        {
            NSError *error = nil;
            NSData *documentData = [NSData dataWithContentsOfFile:[iCloudFiles objectAtIndex:idx]
                                                          options:NSDataReadingMappedAlways error:&error];
            NSString *documentName = [[iCloudFiles objectAtIndex:idx] lastPathComponent];
            if ([[documentName pathExtension] isEqualToString:@"icloud"])
            {
                NSLog(@"Ignoring iCloud metafile: %@", documentName);
            }
            else if ([[documentName pathExtension] isEqualToString:@"ayai"] ||
                     [[documentName pathExtension] isEqualToString:@"ayaix"])
            {
                NSData *plainData = [documentData plainData];
                if (plainData == nil)
                {
                    NSLog(@"Decryption failed for %@", [iCloudFiles objectAtIndex:idx]);
                    REDTOASTER("SyncCannotDecryptLocal");
                }
                else
                {
                    NSObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
                    plainData = nil;
                    if ([object isKindOfClass:[AYAIAttachment class]])
                    {
                        AYAIAttachment *attachment = (AYAIAttachment *)object;
                        attachment.realfilesize = attachment.data.length;
                        attachment.localFileURL = [iCloudFiles objectAtIndex:idx];
                        attachment.thumbnail = [AYAIAttachment thumbnailFromData:attachment.data :attachment.realfiletype];
                        attachment.data = nil;
                        [[[AYAIAppDelegate sharedAppDelegate] getUserData] addAttachment:attachment];
                    }
                    else if ([object isKindOfClass:[AYAIIdentity class]])
                    {
                        [[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:(AYAIIdentity *)object];
                    }
                }
            }
        }
    }
    [AYAISyncManager localFilesArray];
}

+ (void)localFilesArray
{
    NSLog(@"localFilesArray: load all ID and archive files into table");
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *patterns = @[@"*.ayai", @"*.ayai.*", @"*.ayaix"];
    for (CFIndex pidx = 0; pidx < [patterns count]; pidx++)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", [patterns objectAtIndex:pidx]];
        NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
        
        for (CFIndex idx = 0; idx < [matches count]; idx++)
        {
            NSError *error = nil;
            NSData *documentData = [NSData dataWithContentsOfFile:[filePath stringByAppendingPathComponent:[matches objectAtIndex:idx]]
                                                          options:NSDataReadingMappedAlways error:&error];
            NSData *plainData = [documentData plainData];
            if (plainData == nil)
            {
                NSLog(@"Decryption failed for %@", [matches objectAtIndex:idx]);
                REDTOASTER("SyncCannotDecryptLocal");
            }
            else
            {
                NSObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
                plainData = nil;
                if ([object isKindOfClass:[AYAIAttachment class]])
                {
                    AYAIAttachment *attachment = (AYAIAttachment *)object;
                    attachment.realfilesize = attachment.data.length;
                    NSString *url = [[NSString alloc] initWithFormat:@"file://%@/%@",filePath,[matches objectAtIndex:idx]];
                    attachment.localFileURL = [NSURL URLWithString:url];
                    attachment.thumbnail = [AYAIAttachment thumbnailFromData:attachment.data :attachment.realfiletype];
                    attachment.data = nil;
                    [[[AYAIAppDelegate sharedAppDelegate] getUserData] addAttachment:attachment];
                }
                else if ([object isKindOfClass:[AYAIIdentity class]])
                {
                    AYAIIdentity *identity = (AYAIIdentity *)object;
                    identity.localFileName = [matches objectAtIndex:idx];
                    if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:identity] == YES
                        && identity.isArchive == NO && [AYAISyncManager hasICloudDocument:identity] == NO)
                    {
                        [AYAISyncManager addIdentity:identity];
                    }
                }
            }
        }
    }
}

+ (NSMutableArray *)localVersion1PFXFiles
{
    NSString *pattern = [[NSString alloc] initWithFormat:@"* (*).pfx"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF LIKE %@", pattern];
    NSLog(@"localPFXFiles: %@", predicate);
    NSString* filePath = [self localPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    NSMutableArray *pfxArray = [[NSMutableArray alloc] init];
    for (CFIndex idx = 0; idx < [matches count]; idx++)
    {
        NSData *documentData = [[NSFileManager defaultManager]
                                contentsAtPath:[filePath stringByAppendingPathComponent:[matches objectAtIndex:idx]]];
        if (documentData != nil)
        {
            NSRange range = [[matches objectAtIndex:idx] rangeOfString:@" " options:NSBackwardsSearch];
            if (range.length == 0)
            {
                continue;
            }
            NSMutableArray *pfxObject = [[NSMutableArray alloc] init];
            NSString *id = [[matches objectAtIndex:idx] substringToIndex:range.location];
            [pfxObject addObject:id];
            [pfxObject addObject:documentData];
            [pfxArray addObject:pfxObject];
        }
    }
    
    return pfxArray;
}

+ (void)deleteAllLocalFiles:(DeleteFilesFilter)filter
{
    [self deleteAllLocalFiles:filter:nil];
}

+ (void)deleteAllLocalFiles:(DeleteFilesFilter)filter :(NSString *)idv1x
{
    NSPredicate *predicate;
    switch (filter)
    {
        case DELETE_LOCAL_ALL:
        {
            predicate = [NSPredicate predicateWithFormat:@"SELF LIKE 'data'"];
            GREENTOASTER("SyncDeletedLocal");
            break;
        }
        case DELETE_LOCAL_TRACES:
        {
            predicate = [NSPredicate predicateWithFormat:@"SELF LIKE 'log'"];
            GREENTOASTER("SyncDeletedLocal");
            break;
        }
        case DELETE_LOCAL_KEEPARCHIVES:
        {
            NSString *archive = @"*.ayai.*";
            NSString *pfx = @"*.pfx";
            predicate = [NSPredicate predicateWithFormat:@"NOT ((SELF LIKE %@) OR (SELF LIKE %@))", archive, pfx];
            GREENTOASTER("SyncDeletedLocal");
            break;
        }
        case DELETE_LOCAL_EVICTED:
        {
            predicate = [NSPredicate predicateWithFormat:@"SELF LIKE 'evicted'"];
            break;
        }
        case DELETE_LOCAL_VERSION1:
        {
            NSString *pattern = [[NSString alloc] initWithFormat:@"%@ (*", idv1x];
            predicate = [NSPredicate predicateWithFormat:@"SELF LIKE %@", pattern];
            GREENTOASTER("SyncDeletedLocal");
            break;
        }
        default:
            break;
    }
    NSLog(@"deleteAllLocalFiles: %@", predicate);
    NSString* filePath = [self localPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    for (CFIndex idx = 0; idx < [matches count]; idx++)
    {
        [[NSFileManager defaultManager] removeItemAtPath:[filePath stringByAppendingPathComponent:[matches objectAtIndex:idx]] error:nil];
    }
}

+ (void)deleteAllICLoudPublicURLs
{
    NSString *pattern = @"mobileconfig";
    NSArray *iCloudFiles = [[iCloud sharedCloud] listCloudFiles];
    NSString* filePath = [self localEvictedPath];
    for (CFIndex idx = 0; idx < [iCloudFiles count]; idx++)
    {
        NSString *documentName = [[iCloudFiles objectAtIndex:idx] lastPathComponent];
        if (documentName == nil)
        {
            continue; // avoid to delete whole Documents directory by removeItemAtPath:nil
        }
        if ([[documentName pathExtension] isEqualToString:pattern] == NO)
        {
            continue;
        }
        NSString *fileAtPath = [filePath stringByAppendingPathComponent:documentName];
        [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:nil];
        [[iCloud sharedCloud] evictCloudDocumentWithName:documentName completion:^(NSError *error)
         {
             if (!error)
             {
                 NSString *fileAtPath = [filePath stringByAppendingPathComponent:documentName];
                 [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:nil];
             }
             else
             {
                 REDTOASTER("SyncEvictURLFailed");
             }
         }];
    }
    GREENTOASTER("SyncDeletedAllURL");
}

+ (void)deleteAllICLoudFiles
{
    NSArray *iCloudFiles = [[iCloud sharedCloud] listCloudFiles];
    NSString *filePath = [self localEvictedPath];
    for (CFIndex idx = 0; idx < [iCloudFiles count]; idx++)
    {
        NSString *documentName = [[iCloudFiles objectAtIndex:idx] lastPathComponent];
        if (documentName == nil)
        {
            continue; // avoid to delete whole Documents directory by removeItemAtPath:nil
        }
        NSString *fileAtPath = [filePath stringByAppendingPathComponent:documentName];
        [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:nil];
        [[iCloud sharedCloud] evictCloudDocumentWithName:documentName completion:^(NSError *error)
         {
             if (error)
             {
                 REDTOASTER("SyncEvictFailed");
             }
         }];
    }
    GREENTOASTER("SyncDeletedAllICloud");
}

#pragma mark Export of Identity PFX files
+ (void)exportPrivateKey:(AYAIIdentity *)identity
{
    [self dumpToFile:[identity subjectPKCS12] :[identity fnSubjectPKCS12]];
}

#pragma mark NSData dump to a file in Documents folder
+ (void)dumpToLog:(NSData *)data :(NSString *)filename
{
    NSLog(@"Dumping data to log: %@\n%@", filename, data);
}

+ (void)dumpToFile:(NSData *)data :(NSString *)filename
{
    NSLog(@"Dumping data to file: %@", filename);
    NSString* filePath = [self localPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:filename];
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [data writeToFile:fileAtPath atomically:YES];
}

#pragma mark Attachments - generic methods

+ (void)addAttachment:(AYAIAttachment *)attachment
{
    [self addAttachmentITunes:attachment];
    if ([AYAISyncManager iCloudIsOn])
    {
        attachment.localFileURL = [[[iCloud sharedCloud] ubiquitousDocumentsDirectoryURL] URLByAppendingPathComponent:[attachment.filename stringByAppendingString:@".ayaix"]];
        [self moveAttachmentICloud:attachment];
        // iTunes file was moved to iCloud and disappeared from local app directory thus
    }
}

+ (void)deleteAttachment:(AYAIAttachment *)attachment
{
    if ([AYAISyncManager iCloudIsOn])
    {
        [self deleteAllLocalFiles:DELETE_LOCAL_EVICTED];   // to avoid evict method failures
        [self localEvictedPath];
        [self deleteAttachmentICloud:attachment];
    }
    else
    {
        [self deleteAttachmentITunes:attachment];
    }
}

+ (void)recryptAttachment:(AYAIAttachment *)attachment;
{
    NSLog(@"recryptAttachment: %@", attachment);

    NSError *error = nil;
    NSData *documentData = [NSData dataWithContentsOfURL:attachment.localFileURL
                                                 options:NSDataReadingMappedAlways
                                                   error:&error];
    NSData *plainData = [documentData plainData];
    if (plainData == nil)
    {
        NSLog(@"Decryption failed for %@", attachment.localFileURL);
        REDTOASTER("SyncCannotRecryptAttachment");
    }
    else
    {
        AYAIAttachment *attachmentWithData = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
        plainData = nil;
        if ([AYAISyncManager iCloudIsOn] && attachment.iCloudDocument == YES) // cannot also be an archived ID
        {
            [self recryptAttachmentICloud:attachmentWithData];
        }
        else
        {
            [self recryptAttachmentITunes:attachmentWithData];
        }
    }
}

#pragma mark Attachments - iTunes methods

+ (void)addAttachmentITunes:(AYAIAttachment *)attachment;
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
    NSLog(@"addAttachmentITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [[[NSKeyedArchiver archivedDataWithRootObject:attachment] cryptData] writeToFile:fileAtPath atomically:YES];
    attachment.data = nil;
    attachment.localFileURL = [[NSURL alloc] initWithString:fileAtPath];
}

+ (void)deleteAttachmentITunes:(AYAIAttachment *)attachment
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
    if (documentName == nil)
    {
        return; // avoid to delete whole Documents directory by removeItemAtPath:nil
    }
    NSLog(@"deleteAttachmentITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:&error];
    NSLog(@"deleteAttachmentITunes returns %@", error);
}

+ (void)recryptAttachmentITunes:(AYAIAttachment *)attachment;
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
    NSLog(@"recryptAttachmentITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [[[NSKeyedArchiver archivedDataWithRootObject:attachment] recryptData] writeToFile:fileAtPath atomically:YES];
}

#pragma mark Attachments - iCloud methods

+ (void)moveAttachmentICloud:(AYAIAttachment *)attachment;
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
    
    NSLog(@"moveAttachmentICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        REDTOASTER("SyncMoveFailed");
    }
    else
    {
        // this local document is expected to be already encrypted
        [[iCloud sharedCloud] uploadLocalDocumentToCloudWithName:documentName
                                                      completion:^(NSError *error)
         {
             if (!error)
             {
                 YELLOWTOASTER("SyncMovedSharedAttachment");
             }
             else
             {
                 REDTOASTER("SyncSharedAttachmentFailed");
             }
         }];
    }
}

+ (void)deleteAttachmentICloud:(AYAIAttachment *)attachment
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
    NSLog(@"deleteAttachmentICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        [[iCloud sharedCloud] evictCloudDocumentWithName:documentName
                                              completion:^(NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncEvict");
                 attachment.iCloudDocument = NO;
             }
             else
             {
                 REDTOASTER("SyncEvictFailed");
             }
         }];
    }
}

+ (void)recryptAttachmentICloud:(AYAIAttachment *)attachment;
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
    NSLog(@"recryptAttachmentICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        [[iCloud sharedCloud] saveAndCloseDocumentWithName:documentName
                                               withContent:[[NSKeyedArchiver archivedDataWithRootObject:attachment] recryptData]
                                                completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncRecrypedAttachment");
             }
             else
             {
                 REDTOASTER("SyncRecryptingFailed");
             }
         }];
    }
    else
    {
        REDTOASTER("SyncRecryptingFailedNotExist");
    }
}

#pragma mark Identities - generic methods

+ (void)addIdentity:(AYAIIdentity *)identity
{
    [self addITunes:identity];
    if ([AYAISyncManager iCloudIsOn])
    {
        [self moveICloud:identity];
        // iTunes file was moved to iCloud and disappeared from local app directory thus
    }
}

+ (void)updateIdentity:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn])
    {
        [self updateICloud:identity];
    }
    else
    {
        [self updateITunes:identity];
    }
}

+ (void)recryptIdentity:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn] && identity.iCloudDocument == YES) // cannot also be an archived ID
    {
        [self recryptICloud:identity];
    }
    else if (identity.isArchive == NO)
    {
        [self recryptITunes:identity];
    }
    else
    {
        [self recryptArchive:identity];
    }
}

+ (void)cleanIdentity:(AYAIIdentity *)identity
{
    [self unpublishIdentity:identity];
    [identity cleanKeys];
    if ([AYAISyncManager iCloudIsOn])
    {
        [self updateICloud:identity];
    }
    else
    {
        [self updateITunes:identity];
    }
}

+ (void)archiveIdentity:(AYAIIdentity *)identity
{
    [self archiveITunes:identity];
    [self cleanIdentity:identity];
}

+ (void)deleteIdentity:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn])
    {
        [self deleteAllLocalFiles:DELETE_LOCAL_EVICTED];   // to avoid evict method failures
        [self localEvictedPath];
        [self deleteICloud:identity];
    }
    else
    {
        [self deleteITunes:identity];
    }
}

+ (void)publishIdentity:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn])
    {
        [self publishITunes:identity];
        identity.iCloudPublishTrials = 0;
        [self publishICloud:identity];
    }
}

+ (void)unpublishIdentity:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn])
    {
        [self deleteAllLocalFiles:DELETE_LOCAL_EVICTED];   // to avoid evict method failures
        [self localEvictedPath];
        [self unpublishICloud:identity];
    }
}

+ (void)restoreIdentity:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    
    NSLog(@"restoreIdentity: %@", documentName);
    
    if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] restoreIdentity:identity] == YES)
    {        
        [self addITunes:identity];
        if ([AYAISyncManager iCloudIsOn])
        {
            [self moveICloud:identity];
        }
        [self deleteArchive:identity];
    }
}

#pragma mark Identities - iTunes methods

+ (void)addITunes:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    NSLog(@"addITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [[[NSKeyedArchiver archivedDataWithRootObject:identity] cryptData] writeToFile:fileAtPath atomically:YES];
}

+ (void)updateITunes:(AYAIIdentity *)identity
{
    NSLog(@"updateITunes: call addITunes");
    [self addITunes:identity];
}

+ (void)recryptITunes:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    NSLog(@"recryptITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [[[NSKeyedArchiver archivedDataWithRootObject:identity] recryptData] writeToFile:fileAtPath atomically:YES];
}

+ (void)deleteITunes:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    if (documentName == nil)
    {
        return; // avoid to delete whole Documents directory by removeItemAtPath:nil
    }
    NSLog(@"deleteITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:&error];
    NSLog(@"deleteITunes returns %@", error);
}

+ (void)archiveITunes:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai.%@", identity.personEmail, identity.subjectX509DateNotBefore];
    NSLog(@"archiveITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    AYAIIdentity *archivedIdentity = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:identity]];
    archivedIdentity.isArchive = YES;
    archivedIdentity.localFileName = documentName;
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [[[NSKeyedArchiver archivedDataWithRootObject:archivedIdentity] cryptData] writeToFile:fileAtPath atomically:YES];
    [[[AYAIAppDelegate sharedAppDelegate] getUserData] duplicateIdentity:archivedIdentity];
    [archivedIdentity completeIdentity];
}

+ (void)recryptArchive:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai.%@", identity.personEmail, identity.subjectX509DateNotBefore];
    NSLog(@"archiveITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    AYAIIdentity *archivedIdentity = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:identity]];
    archivedIdentity.isArchive = YES;
    archivedIdentity.localFileName = documentName;
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [[[NSKeyedArchiver archivedDataWithRootObject:archivedIdentity] recryptData] writeToFile:fileAtPath atomically:YES];
}

+ (void)deleteArchive:(AYAIIdentity *)identity
{
    NSString *documentName = identity.localFileName;
    if (documentName == nil)
    {
        return; // avoid to delete whole Documents directory by removeItemAtPath:nil
    }
    NSLog(@"deleteArchive: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString* fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:nil];
}

+ (void)publishITunes:(AYAIIdentity *)identity
{
    NSString *documentName = identity.fnPrivateMobileConfig;
    NSLog(@"publishITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString *fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] createFileAtPath:fileAtPath
                                            contents:nil
                                          attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    [identity.privateMobileConfig writeToFile:fileAtPath atomically:YES];
}

+ (void)unpublishITunes:(AYAIIdentity *)identity
{
    NSString *documentName = identity.fnPrivateMobileConfig;
    if (documentName == nil)
    {
        return; // avoid to delete whole Documents directory by removeItemAtPath:nil
    }
    NSLog(@"unpublishITunes: %@", documentName);
    NSString* filePath = [self localDataPath];
    NSString *fileAtPath = [filePath stringByAppendingPathComponent:documentName];
    [[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:nil];
}

#pragma mark Identities - iCloud methods

+ (void) moveICloud:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    
    NSLog(@"moveICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        REDTOASTER("SyncMoveFailed");
    }
    else
    {
        // this local document is expected to be already encrypted
        [[iCloud sharedCloud] uploadLocalDocumentToCloudWithName:documentName
                                                      completion:^(NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncMovedIdentity");
                 identity.iCloudDocument = YES;
             }
             else
             {
                 REDTOASTER("SyncMovingFailed");
             }
         }];
    }
}

+ (void) updateICloud:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    NSLog(@"updateICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        [[iCloud sharedCloud] saveAndCloseDocumentWithName:documentName
                                               withContent:[[NSKeyedArchiver archivedDataWithRootObject:identity] cryptData]
                                                completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncUpdatedIdentity");
             }
             else
             {
                 REDTOASTER("SyncUpdatingFailed");
             }
         }];
    }
    else
    {
        [self moveICloud:identity];
    }
}

+ (void) recryptICloud:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    NSLog(@"recryptICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        [[iCloud sharedCloud] saveAndCloseDocumentWithName:documentName
                                               withContent:[[NSKeyedArchiver archivedDataWithRootObject:identity] recryptData]
                                                completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncRecrypedIdentity");
             }
             else
             {
                 REDTOASTER("SyncRecryptingFailed");
             }
         }];
    }
    else
    {
        REDTOASTER("SyncRecryptingFailedNotExist");
    }
}

+ (void)deleteICloud:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
    NSLog(@"deleteICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        [[iCloud sharedCloud] evictCloudDocumentWithName:documentName
                                              completion:^(NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncEvict");
                 identity.iCloudDocument = NO;
             }
             else
             {
                 REDTOASTER("SyncEvictFailed");
             }
         }];
    }
}

+ (void)publishICloud:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@", identity.fnPrivateMobileConfig];
    NSLog(@"publishICloud: %@", documentName);
    DARKTOASTER("MsgLaunchSafari");

    if (identity.iCloudPublishTrials > 9)
    {
        REDTOASTER("SyncURLFailed");
        return;
    }
    
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        NSLog(@"publishICloud: doesFileExistInCloud %@", documentName);

        [[iCloud sharedCloud] shareDocumentWithName:documentName
                                         completion:^(NSURL *sharedURL, NSDate *expirationDate, NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncURL");
                 identity.iCloudPublicURL = YES;
                 [[UIApplication sharedApplication] openURL:sharedURL];
             }
             else
             {
                 NSLog(@"publishICloud sleeping %d seconds...", (int)identity.iCloudPublishTrials);
                 sleep((int)identity.iCloudPublishTrials);
                 identity.iCloudPublishTrials++;
                 [self publishICloud:identity];
             }
         }];
    }
    else
    {
        NSLog(@"publishICloud: does not exist in cloud %@", documentName);

        [[iCloud sharedCloud] uploadLocalDocumentToCloudWithName:documentName
                                                      completion:^(NSError *error)
         {
             if (!error)
             {
                 identity.iCloudPublishTrials++;
                 [self publishICloud:identity];
             }
             else
             {
                 REDTOASTER("SyncUploadFailed");
             }
         }];
    }
}

+ (void)unpublishICloud:(AYAIIdentity *)identity
{
    NSString *documentName = [[NSString alloc] initWithFormat:@"%@", identity.fnPrivateMobileConfig];
    NSLog(@"unpublishICloud: %@", documentName);
    if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
    {
        [[iCloud sharedCloud] evictCloudDocumentWithName:documentName
                                              completion:^(NSError *error)
         {
             if (!error)
             {
                 GREENTOASTER("SyncEvictURL");
                 identity.iCloudPublicURL = NO;
                 // and delete the new copy in iTunes, created by evict
                 [self unpublishITunes:identity];
             }
             else
             {
                 REDTOASTER("SyncEvictURLFailed");
             }
         }];
    }
}

#pragma mark Common iCloud helper methods

+ (void)retrieveDocument:(NSString *)documentName
{
    if ([AYAISyncManager iCloudIsOn])
    {
        [self retrieveICloud:documentName];
    }
}

+ (NSInteger)countAttachmentsInICloud
{
    if ([AYAISyncManager iCloudIsOn] == NO) return 0;
    
    NSArray *iCloudURLs = [[iCloud sharedCloud] listCloudFiles];
    NSMutableArray *iCloudFiles = [[NSMutableArray alloc] init];
    for (CFIndex idx = 0; idx < [iCloudURLs count]; idx++)
    {
        [iCloudFiles addObject:[[iCloudURLs objectAtIndex:idx] absoluteString]];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ayaix'"];
    NSLog(@"countAttachmentsInICloud: %@", predicate);
    NSArray *matches = [iCloudFiles filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countIdentitiesInICloud
{
    if ([AYAISyncManager iCloudIsOn] == NO) return 0;
    
    NSArray *iCloudURLs = [[iCloud sharedCloud] listCloudFiles];
    NSMutableArray *iCloudFiles = [[NSMutableArray alloc] init];
    for (CFIndex idx = 0; idx < [iCloudURLs count]; idx++)
    {
        [iCloudFiles addObject:[[iCloudURLs objectAtIndex:idx] absoluteString]];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ayai'"];
    NSLog(@"countIdentitiesInICloud: %@", predicate);
    NSArray *matches = [iCloudFiles filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countProfilesInICloud
{
    if ([AYAISyncManager iCloudIsOn] == NO) return 0;
    
    NSArray *iCloudURLs = [[iCloud sharedCloud] listCloudFiles];
    NSMutableArray *iCloudFiles = [[NSMutableArray alloc] init];
    for (CFIndex idx = 0; idx < [iCloudURLs count]; idx++)
    {
        [iCloudFiles addObject:[[iCloudURLs objectAtIndex:idx] absoluteString]];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.mobileconfig'"];
    NSLog(@"countProfilesInICloud: %@", predicate);
    NSArray *matches = [iCloudFiles filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countTotalFilesInICloud
{
    if ([AYAISyncManager iCloudIsOn] == NO) return 0;
    
    NSArray *iCloudFiles = [[iCloud sharedCloud] listCloudFiles];
    
    return [iCloudFiles count];
}

+ (BOOL)hasPublicICloudURL:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn])
    {
        if (identity.fnPrivateMobileConfig)
        {
            NSString *documentName = identity.fnPrivateMobileConfig;
            if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
            {
                NSLog(@"hasPublicICloudURL: %@", documentName);
                identity.iCloudPublicURL = YES;
                return YES;
            }
        }
    }
    identity.iCloudPublicURL = NO;

    return NO;
}

+ (BOOL)hasICloudDocument:(AYAIIdentity *)identity
{
    if ([AYAISyncManager iCloudIsOn])
    {
        if (identity.personEmail)
        {
            NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayai", identity.personEmail];
            if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
            {
                NSLog(@"hasICloudDocument: %@", documentName);
                identity.iCloudDocument = YES;
                return YES;
            }
        }
    }
    identity.iCloudDocument = NO;
    
    return NO;
}

+ (BOOL)hasAttachmentICloudDocument:(AYAIAttachment *)attachment
{
    if ([AYAISyncManager iCloudIsOn])
    {
        if (attachment.filename)
        {
            NSString *documentName = [[NSString alloc] initWithFormat:@"%@.ayaix", attachment.filename];
            if ([[iCloud sharedCloud] doesFileExistInCloud:documentName])
            {
                NSLog(@"hasAttachmentICloudDocument: %@", documentName);
                attachment.iCloudDocument = YES;
                return YES;
            }
        }
    }
    attachment.iCloudDocument = NO;
    
    return NO;
}

+ (void)retrieveICloud:(NSString *)documentName
{
    [[iCloud sharedCloud] documentStateForFile:documentName
                                    completion:^(UIDocumentState *documentState, NSString *userReadableDocumentState, NSError *error)
     {
         if (!error && documentState != nil)
         {
             NSLog(@"Retrieving encrypted iCloud file %@", documentName);
             [[iCloud sharedCloud] retrieveCloudDocumentWithName:documentName
                                                      completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error)
              {
                  if (!error)
                  {
                      NSData *plainData = [documentData plainData];
                      if (plainData == nil)
                      {
                          NSLog(@"Decryption failed for %@", [cloudDocument fileURL]);
                          REDTOASTER("SyncICloudDecryptFailed");
                      }
                      else
                      {
                          NSObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:plainData];
                          if ([object isKindOfClass:[AYAIAttachment class]])
                          {
                              AYAIAttachment *attachment = (AYAIAttachment *)object;
                              attachment.thumbnail = [AYAIAttachment thumbnailFromData:attachment.data :attachment.realfiletype];
                              attachment.realfilesize = attachment.data.length;
                              attachment.data = nil;

                              if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addAttachment:attachment] == YES)
                              {
                                  GREENTOASTER("SyncICloud");
                              }
                          }
                          else if ([object isKindOfClass:[AYAIIdentity class]])
                          {
                              if ([[[AYAIAppDelegate sharedAppDelegate] getUserData] addIdentity:(AYAIIdentity *)object] == YES)
                              {
                                  GREENTOASTER("SyncICloud");
                              }
                          }
                      }
                  }
                  else
                  {
                      REDTOASTER("SyncICloudFailed");
                  }
              }];
         }
     }];
}

+ (void)logAllCloudStorageKeysForMetadataItem:(NSMetadataItem *)item
{
    NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
    NSLog(@"%@", url);
    NSString *downloadingStatus = [item valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
    NSLog(@"downloadingStatus = %@", downloadingStatus);

    BOOL documentExists = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
    if (documentExists == false) NSLog(@"documentExists = %i", documentExists);
    NSNumber *isUbiquitous = [item valueForAttribute:NSMetadataItemIsUbiquitousKey];
    if (isUbiquitous.integerValue != 1) NSLog(@"isUbiquitous = %@", isUbiquitous);
    NSNumber *hasUnresolvedConflicts = [item valueForAttribute:NSMetadataUbiquitousItemHasUnresolvedConflictsKey];
    if (hasUnresolvedConflicts.integerValue != 0) NSLog(@"hasUnresolvedConflicts = %@", hasUnresolvedConflicts);
    
    NSNumber *isDownloading = [item valueForAttribute:NSMetadataUbiquitousItemIsDownloadingKey];
    if (isDownloading.integerValue != 0) NSLog(@"isDownloading = %@", isDownloading);
    NSNumber *percentDownloaded = [item valueForAttribute:NSMetadataUbiquitousItemPercentDownloadedKey];
    if (percentDownloaded.integerValue != 100) NSLog(@"percentDownloaded = %@", percentDownloaded);

    NSNumber *isUploaded = [item valueForAttribute:NSMetadataUbiquitousItemIsUploadedKey];
    if (isUploaded.integerValue != 1) NSLog(@"isUploaded = %@", isUploaded);
    NSNumber *isUploading = [item valueForAttribute:NSMetadataUbiquitousItemIsUploadingKey];
    if (isUploading.integerValue != 0) NSLog(@"isUploading = %@", isUploading);
    NSNumber *percentUploaded = [item valueForAttribute:NSMetadataUbiquitousItemPercentUploadedKey];
    if (percentUploaded.integerValue != 100) NSLog(@"percentUploaded = %@", percentUploaded);
}

#pragma mark Common iTunes helper methods

+ (NSInteger)countAttachmentsInITunes
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ayaix'"];
    NSLog(@"countAttachmentsInITunes: %@", predicate);
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countIdentityArchives:(AYAIIdentity *)identity
{
    NSString *pattern = [[NSString alloc] initWithFormat:@"%@.ayai.*", identity.personEmail];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", pattern];
    NSLog(@"countIdentityArchives: %@", predicate);
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countIdentitiesInITunes
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.ayai'"];
    NSLog(@"countIdentitiesInITunes: %@", predicate);
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countArchivesInITunes
{
    NSString *pattern = @"*.ayai.*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", pattern];
    NSLog(@"countArchivesInITunes: %@", predicate);
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countProfilesInITunes
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH '.mobileconfig'"];
    NSLog(@"countProfilesInITunes: %@", predicate);
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countVersion1PFXInITunes
{
    NSString *pattern = @"* (*).pfx";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", pattern];
    NSLog(@"countVersion1PFXInITunes: %@", predicate);
    NSString* filePath = [self localPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countLogsInITunes
{
    NSString *pattern = @"*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", pattern];
    NSLog(@"countLogsInITunes: %@", predicate);
    NSString* filePath = [self localLogPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

+ (NSInteger)countTotalFilesInITunes
{
    NSString *pattern = @"*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", pattern];
    NSLog(@"countTotalFilesInITunes: %@", predicate);
    NSString* filePath = [self localDataPath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    NSArray *matches = [directoryContents filteredArrayUsingPredicate:predicate];
    
    return [matches count];
}

@end
