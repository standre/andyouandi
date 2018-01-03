//
//  AYAIUserData.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import "AYAI.h"
#import "AYAICrypto.h"

@class AYAIIdentity;
@class AYAIAttachment;

@interface AYAIUserData : NSObject
@property (strong, nonatomic) NSMutableArray *identityArray;
@property (strong, nonatomic) NSMutableArray *attachmentArray;
- (void)releaseTableArrays;
- (NSInteger)countOfUserDataArrays;
- (void)initFromFilesAndICloud;
- (BOOL)addAttachment:(AYAIAttachment *)attachment;
- (BOOL)addIdentity:(AYAIIdentity *)identity;
- (BOOL)restoreIdentity:(AYAIIdentity *)identity;
- (BOOL)canRestoreIdentity:(AYAIIdentity *)identity;
- (BOOL)duplicateIdentity:(AYAIIdentity *)identity;
- (void)resetViewAllIdentities;
- (void)persistAllDocuments;
- (void)persistAllAttachments;
- (void)persistAllIdentities;
- (void)moveAllDocuments;
- (void)moveAllAttachments;
- (void)moveAllIdentities;
- (void)sortIdentities;
- (void)changePassword;
@end

@interface AYAISettings : NSObject
+ (void)save:(NSString *)key data:(id)data;
+ (id)load:(NSString *)key;
@end

@interface AYAIMobileConfig : NSObject
+ (NSString *)GetUUID;
+ (NSData *)generatePrivateMobileConfig:(EVP_PKEY *)subjectKey :(AYAIIdentity *)identity;
+ (NSData *)generateArchiveMobileConfig:(EVP_PKEY *)subjectKey :(AYAIIdentity *)identity;
+ (NSData *)generatePublicMobileConfig:(EVP_PKEY *)subjectKey :(AYAIIdentity *)identity;
@end
@class AYAIIdentity;

@interface AYAIMailManager : NSObject
+ (void)sendMailToMyself:(AYAIIdentity *)identity;
+ (void)sendMailToOthers:(AYAIIdentity *)identity;
@end
