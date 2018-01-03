//
//  ayai_Identity.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAIViewController.h"
#import "AYAIIdentity.h"
#import "AYAICrypto.h"
#import "AYAIPasswordManager.h"
#import "AYAISyncManager.h"

@implementation AYAIIdentity

@synthesize showDetails, isArchive, iCloudDocument, iCloudPublicURL, password, personEmail, personFirstName, personLastName, personAddressCity, subjectPKCS12, subjectX509, issuerX509, privateMobileConfig, publicMobileConfig, subjectX509DateNotBefore, subjectX509DateNotAfter, subjectX509Keysize, subjectX509Serial, subjectX509Fingerprint, subjectX509Signature, fnIssuerX509, fnSubjectPKCS12, fnSubjectX509, fnPrivateMobileConfig, fnPublicMobileConfig;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    self.isArchive = [decoder decodeBoolForKey:@"isArchive"];
    self.personEmail = [decoder decodeObjectForKey:@"personEmail"];
    self.personFirstName = [decoder decodeObjectForKey:@"personFirstName"];
    self.personLastName = [decoder decodeObjectForKey:@"personLastName"];
    self.personAddressCity = [decoder decodeObjectForKey:@"personAddressCity"];
    self.password = [decoder decodeObjectForKey:@"password"];
    self.subjectPKCS12 = [decoder decodeObjectForKey:@"subjectPKCS12"];
    [self completeIdentity];
    NSLog(@"initWithCoder: %@", self.personEmail);
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeBool:self.isArchive forKey:@"isArchive"];
    [encoder encodeObject:self.personEmail forKey:@"personEmail"];
    [encoder encodeObject:self.personFirstName forKey:@"personFirstName"];
    [encoder encodeObject:self.personLastName forKey:@"personLastName"];
    [encoder encodeObject:self.personAddressCity forKey:@"personAddressCity"];
    [encoder encodeObject:self.password forKey:@"password"];
    [encoder encodeObject:self.subjectPKCS12 forKey:@"subjectPKCS12"];
    NSLog(@"encodeWithCoder: %@", self.personEmail);
}

- (void)cleanKeys
{
    NSLog(@"encodeWithCoder: %@", self.personEmail);
    self.subjectPKCS12 = nil;
    self.subjectX509 = nil;
    self.issuerX509 = nil;
    self.subjectX509DateNotBefore = nil;
    self.subjectX509DateNotAfter = nil;
    self.subjectX509Fingerprint = nil;
    self.subjectX509Signature = nil;
    self.subjectX509Keysize = 0;
    self.subjectX509Serial = nil;
    self.privateMobileConfig = nil;
    self.publicMobileConfig = nil;
    self.fnPrivateMobileConfig = nil;
    self.fnPublicMobileConfig = nil;
    self.fnSubjectPKCS12 = nil;
    self.fnSubjectX509 = nil;
    self.fnIssuerX509 = nil;
}

- (BOOL)completeIdentity
{
    NSLog(@"completeIdentity: opening own PKCS#12 data with password");
    if (self.subjectPKCS12 == nil || self.password == nil)
    {
        NSLog(@"Identity has no PKCS#12 data or password.");
        return NO;
    }
    AYAIPKCS12 *pkcs12 = [[AYAIPKCS12 alloc] initWithData:self.subjectPKCS12];
    if (pkcs12 == nil)
    {
        NSLog(@"No valid PKCS#12 data.");
        return NO;
    }
    if ([pkcs12 decryptWithPassword:self.password] == NO)
    {
        NSLog(@"Unable to decrypt PFX file. Password may be wrong.");
        return NO;
    }
    self.subjectX509 = [pkcs12 subjectCertData];
    self.issuerX509 = [pkcs12 issuerCertData];
    [self completeWithKey:[pkcs12 subjectKey]];

    return YES;
}

- (void)completeWithKey:(EVP_PKEY *)subjectKey
{
    if (self.personEmail == nil)
    {
        self.personEmail = [self.subjectX509 x509Email];
    }
    if (self.personFirstName == nil)
    {
        self.personFirstName = [self.subjectX509 x509FirstName];
    }
    if (self.personLastName == nil)
    {
        self.personLastName = [self.subjectX509 x509LastName];
    }
    if (self.personAddressCity == nil)
    {
        self.personAddressCity = [self.subjectX509 x509Locality];
    }
    if (self.subjectPKCS12 != nil)
    {
        self.fnPrivateMobileConfig = [[NSString alloc] initWithFormat:LS("FormatFileNameMobileConfig"), self.personEmail, [subjectPKCS12 pkcs12Fingerprint]];
    }
    self.subjectX509DateNotBefore = [self.subjectX509 x509DateNotBefore];
    self.subjectX509DateNotAfter = [self.subjectX509 x509DateNotAfter];
    self.subjectX509Keysize = [self.subjectX509 x509Keysize];
    self.subjectX509Serial = [self.subjectX509 x509Serial];
    self.subjectX509Fingerprint = [self.subjectX509 x509Fingerprint];
    self.subjectX509Signature = [self.subjectX509 x509Signature];
    self.fnSubjectPKCS12 = [[NSString alloc] initWithFormat:LS("FormatFileNamePFX"),  self.personEmail, [self.subjectX509Fingerprint stringByReplacingOccurrencesOfString:@":" withString:@""]];
    self.fnSubjectX509 = [[NSString alloc] initWithFormat:LS("FormatFileNameSubjectCRT"), self.personEmail];
    self.fnIssuerX509 = [[NSString alloc] initWithFormat:LS("FormatFileNameIssuerCRT"), self.personEmail];
    self.fnPublicMobileConfig = [[NSString alloc] initWithFormat:LS("FormatFileNameMobileConfigPublic"), self.personEmail];
    if (self.isArchive)
    {
        self.privateMobileConfig = [AYAIMobileConfig generateArchiveMobileConfig:subjectKey:self];
    }
    else
    {
        self.privateMobileConfig = [AYAIMobileConfig generatePrivateMobileConfig:subjectKey:self];
    }
    self.publicMobileConfig = [AYAIMobileConfig generatePublicMobileConfig:subjectKey:self];
}

- (void)generateKeysAndCertificates
{
    NSLog(@"generateKeysAndCertificates: begins ...");
    
    AYAIViewController *identityViewController = (AYAIViewController *)[[AYAIAppDelegate sharedAppDelegate] getMainView];
    [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] setKeyGenProgressBar:identityViewController.progressBar];
    
    EVP_PKEY *evpIssuer = EVP_PKEY_new();
    X509 *x509Issuer = [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] generateIssuer:&evpIssuer:self.personEmail:self.personFirstName:self.personLastName:self.personAddressCity];
    if (x509Issuer == NULL)
    {
        // user canceled key generation
        [identityViewController endGenerateNewKeys];
        return;
    }
    self.issuerX509 = [NSData x509Data:x509Issuer];
    EVP_PKEY *evpSubject = EVP_PKEY_new();
    X509 *x509Subject = [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] generateSubject:&evpSubject:evpIssuer:self.personEmail:self.personFirstName:self.personLastName:self.personAddressCity];
    if (x509Subject == NULL)
    {
        // user canceled key generation
        [identityViewController endGenerateNewKeys];
        return;
    }
    self.subjectX509 = [NSData x509Data:x509Subject];
    self.password = [AYAIPasswordManager newRandomPassword];
    self.subjectPKCS12 = [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] generatePFX:self.password:self.personEmail:evpSubject:x509Subject:x509Issuer];
    [self completeWithKey:evpSubject];
    [AYAISyncManager updateIdentity:self];
    
    [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[issuerX509 dumpedX509]];
    if ([[AYAISettings load:@"prefLogDetails"] boolValue])
    {
        [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[AYAICrypto dumpedPKEY:evpIssuer]];
    }
    [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[subjectX509 dumpedX509]];
    if ([[AYAISettings load:@"prefLogDetails"] boolValue])
    {
        [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[AYAICrypto dumpedPKEY:evpSubject]];
    }
    
    self.showDetails = YES;
    
    NSLog(@"generateKeysAndCertificates: ... ends.");
    
    [identityViewController endGenerateNewKeys];
}

@end
