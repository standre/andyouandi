//
//  ayai_Crypto.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <Security/SecBase.h>
#import <CommonCrypto/CommonCryptor.h>
#import <openssl/evp.h>
#import <openssl/err.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#import "openssl/pkcs12.h"
#import "openssl/rand.h"
#import "openssl/aes.h"
#import "AYAI.h"

@interface AYAICrypto : NSObject
@property (nonatomic, nonatomic) RSA *rsa;
@property (nonatomic, nonatomic) NSInteger keysize;
@property (nonatomic, nonatomic) NSInteger keygencbcnt;
@property (nonatomic, nonatomic) UIProgressView *progressBar;
@property (nonatomic, nonatomic) NSInteger iterations;
- (AYAICrypto *)init;
- (BOOL)loadPassword:(BOOL)useNewPassword;
+ (NSString *)dumpedPKEY:(EVP_PKEY *)privateKey;
- (void)setKeyGenProgressBar:(UIProgressView *)progressBar;
- (NSData *)encryptData:(NSData *)plainData;
- (NSData *)reencryptData:(NSData *)plainData;
- (NSData *)decryptData:(NSData *)cryptData;
- (X509 *)generateIssuer:(EVP_PKEY **)privateKey :(NSString *)personEmail :(NSString *)personFirstName :(NSString *)personLastName :(NSString *)personAddressCity;
- (X509 *)generateSubject:(EVP_PKEY **)privateKey :(EVP_PKEY *)issuerKey :(NSString *)personEmail :(NSString *)personFirstName :(NSString *)personLastName :(NSString *)personAddressCity;
- (NSData *)generatePFX:(NSString *)password :(NSString *)personEmail :(EVP_PKEY *)subjectKey :(X509 *)subjectCert :(X509 *)issuerCert;
@end

@interface AYAIPKCS12 : NSObject
- (AYAIPKCS12 *)initWithData:(NSData *)pkcs12;
- (BOOL)decryptWithPassword:(NSString *)password;
- (EVP_PKEY *)subjectKey;
- (NSData *)subjectCertData;
- (NSData *)issuerCertData;
@end

@interface NSData (PKCS12)
- (NSString *)pkcs12Fingerprint;
@end

@interface NSData (AES)
- (NSData *)cryptData;
- (NSData *)recryptData;
- (NSData *)plainData;
@end

@interface NSData (Base64)
- (NSString *)base64EncodedString;
@end

@interface NSData (X509)
+ (NSData *)x509Data:(X509 *)a;
- (X509 *)dataX509;
- (NSString *)dumpedX509;
- (NSDate *)x509DateNotBefore;
- (NSDate *)x509DateNotAfter;
- (NSString *)x509Serial;
- (NSString *)x509Fingerprint;
- (NSString *)x509Signature;
- (NSInteger)x509Keysize;
- (NSString *)x509Email;
- (NSString *)x509FirstName;
- (NSString *)x509LastName;
- (NSString *)x509Locality;

@end

