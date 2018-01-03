//
//  ayai_Identity.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYAI.h"
#import "AYAICrypto.h"
#import "AYAISyncManager.h"
#import "AYAIPasswordManager.h"

@interface AYAIIdentity : NSObject <NSCoding>
@property (readwrite, nonatomic) BOOL showDetails;
@property (readwrite, nonatomic) BOOL isArchive;
@property (strong, nonatomic) NSString *localFileName;
@property (readwrite, nonatomic) BOOL iCloudDocument;
@property (readwrite, nonatomic) BOOL iCloudPublicURL;
@property (readwrite, nonatomic) NSInteger iCloudPublishTrials;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *personEmail;
@property (strong, nonatomic) NSString *personFirstName;
@property (strong, nonatomic) NSString *personLastName;
@property (strong, nonatomic) NSString *personAddressCity;
@property (strong, nonatomic) NSData *subjectPKCS12;
@property (strong, nonatomic) NSData *subjectX509;
@property (strong, nonatomic) NSData *issuerX509;
@property (strong, nonatomic) NSDate *subjectX509DateNotBefore;
@property (strong, nonatomic) NSDate *subjectX509DateNotAfter;
@property (strong, nonatomic) NSString *subjectX509Serial;
@property (strong, nonatomic) NSString *subjectX509Fingerprint;
@property (strong, nonatomic) NSString *subjectX509Signature;
@property (readwrite, nonatomic) NSInteger subjectX509Keysize;
@property (strong, nonatomic) NSData *privateMobileConfig;
@property (strong, nonatomic) NSData *publicMobileConfig;
@property (strong, nonatomic) NSString *fnSubjectPKCS12;
@property (strong, nonatomic) NSString *fnSubjectX509;
@property (strong, nonatomic) NSString *fnIssuerX509;
@property (strong, nonatomic) NSString *fnPrivateMobileConfig;
@property (strong, nonatomic) NSString *fnPublicMobileConfig;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;
- (void)cleanKeys;
- (void)generateKeysAndCertificates;
- (BOOL)completeIdentity;
- (void)completeWithKey:(EVP_PKEY *)subjectKey;
@end
