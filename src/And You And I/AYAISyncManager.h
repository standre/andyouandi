//
//  ayai_FileSync.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYAI.h"
#import "iCloud/iCloud.h"

@class AYAIIdentity;
@class AYAIAttachment;

typedef NS_ENUM(NSUInteger, DeleteFilesFilter)
{
    DELETE_LOCAL_ALL,
    DELETE_LOCAL_TRACES,
    DELETE_LOCAL_KEEPARCHIVES,
    DELETE_LOCAL_EVICTED,
    DELETE_LOCAL_VERSION1
};

@interface AYAISyncManager : NSObject
+ (NSString *)localDataPath;
+ (NSString *)localEvictedPath;
+ (NSString *)localLogPath;
+ (void)loadTableArrays;
+ (void)localFilesArray;
+ (NSMutableArray *)localVersion1PFXFiles;

+ (BOOL)iCloudIsOn;
+ (void)deleteAllICLoudPublicURLs;
+ (void)deleteAllICLoudFiles;
+ (void)deleteAllLocalFiles:(DeleteFilesFilter)filter;
+ (void)deleteAllLocalFiles:(DeleteFilesFilter)filter :(NSString *)idv1x;
+ (void)dumpToLog:(NSData *)data :(NSString *)filename;
+ (void)dumpToFile:(NSData *)data :(NSString *)filename;
+ (void)exportPrivateKey:(AYAIIdentity *)identity;

+ (void)addIdentity:(AYAIIdentity *)identity;
+ (void)updateIdentity:(AYAIIdentity *)identity;
+ (void)recryptIdentity:(AYAIIdentity *)identity;
+ (void)cleanIdentity:(AYAIIdentity *)identity;
+ (void)archiveIdentity:(AYAIIdentity *)identity;
+ (void)deleteIdentity:(AYAIIdentity *)identity;
+ (void)publishIdentity:(AYAIIdentity *)identity;
+ (void)unpublishIdentity:(AYAIIdentity *)identity;
+ (void)retrieveDocument:(NSString *)documentName;
+ (void)restoreIdentity:(AYAIIdentity *)identity;

+ (void)addITunes:(AYAIIdentity *)identity;
+ (void)updateITunes:(AYAIIdentity *)identity;
+ (void)recryptITunes:(AYAIIdentity *)identity;
+ (void)archiveITunes:(AYAIIdentity *)identity;
+ (void)recryptArchive:(AYAIIdentity *)identity;
+ (void)deleteArchive:(AYAIIdentity *)identity;
+ (void)deleteITunes:(AYAIIdentity *)identity;
+ (void)publishITunes:(AYAIIdentity *)identity;
+ (void)unpublishITunes:(AYAIIdentity *)identity;

+ (void)moveICloud:(AYAIIdentity *)identity;
+ (void)updateICloud:(AYAIIdentity *)identity;
+ (void)recryptICloud:(AYAIIdentity *)identity;
+ (void)deleteICloud:(AYAIIdentity *)identity;
+ (void)publishICloud:(AYAIIdentity *)identity;
+ (void)unpublishICloud:(AYAIIdentity *)identity;
+ (BOOL)hasPublicICloudURL:(AYAIIdentity *)identity;
+ (BOOL)hasICloudDocument:(AYAIIdentity *)identity;
+ (void)retrieveICloud:(NSString *)documentName;

+ (void)addAttachment:(AYAIAttachment *)attachment;
+ (void)addAttachmentITunes:(AYAIAttachment *)attachment;
+ (void)deleteAttachment:(AYAIAttachment *)attachment;
+ (void)deleteAttachmentITunes:(AYAIAttachment *)attachment;
+ (void)deleteAttachmentICloud:(AYAIAttachment *)attachment;
+ (void)moveAttachmentICloud:(AYAIAttachment *)attachment;
+ (BOOL)hasAttachmentICloudDocument:(AYAIAttachment *)attachment;
+ (void)recryptAttachment:(AYAIAttachment *)attachment;
+ (void)recryptAttachmentITunes:(AYAIAttachment *)attachment;
+ (void)recryptAttachmentICloud:(AYAIAttachment *)attachment;

+ (NSInteger)countAttachmentsInICloud;
+ (NSInteger)countIdentitiesInICloud;
+ (NSInteger)countProfilesInICloud;
+ (NSInteger)countTotalFilesInICloud;
+ (NSInteger)countAttachmentsInITunes;
+ (NSInteger)countIdentityArchives:(AYAIIdentity *)identity;
+ (NSInteger)countIdentitiesInITunes;
+ (NSInteger)countArchivesInITunes;
+ (NSInteger)countProfilesInITunes;
+ (NSInteger)countVersion1PFXInITunes;
+ (NSInteger)countLogsInITunes;
+ (NSInteger)countTotalFilesInITunes;

+ (void)logAllCloudStorageKeysForMetadataItem:(NSMetadataItem *)item;

@end
