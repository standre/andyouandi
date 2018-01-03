//
//  ayai_Crypto.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAI.h"
#import "AYAICrypto.h"
#import "AYAIAppDelegate.h"
#import "AYAIPasswordManager.h"
#import "AYAIUserData.h"
#import "AYAISyncManager.h"

@implementation AYAICrypto
{
@protected
    NSString *passwordAES;
    EVP_CIPHER_CTX encAESCTX;
    EVP_CIPHER_CTX decAESCTX;
}

- (AYAICrypto *)init
{
    SSLeay_add_all_algorithms();
    SSLeay_add_all_ciphers();
    SSLeay_add_all_digests();
   
    return self;
}

- (BOOL)loadPassword:(BOOL)useNewPassword
{
    passwordAES = [KeychainUserPass load:(useNewPassword ? @"AESNewPassword" : @"AESPassword")];
    
    if (passwordAES == nil)
    {
        REDTOASTER("KeychainNoPassword");
        
        return NO;
    }
    
    self.iterations = (int)[[AYAISettings load:@"prefIterations"] intValue];
    if (self.iterations < 10)
    {
        self.iterations = 10;   // bad default, but compatible with version 2.0
    }
    unsigned char key[32], iv[32];
    NSTimeInterval time1 = [[NSDate date] timeIntervalSince1970];
    EVP_BytesToKey(EVP_aes_128_cbc(),       // AES128 is as strong as AES256 but faster
                   EVP_sha256(),            // SHA256 is stronger than SHA1
                   0,                       // no salt
                   (unsigned char *)[passwordAES cStringUsingEncoding:NSISOLatin1StringEncoding],
                   (unsigned int)[passwordAES length],
                   (int)self.iterations,    // iterations: the higher the harder to be cracked by brute force
                   key,                     // AES key derived from password
                   iv);                     // IV derived from password
    NSLog(@"*** EVP_BytesToKey took %f with %ld iterations", [[NSDate date] timeIntervalSince1970] - time1, (long)self.iterations);
    EVP_CIPHER_CTX_init(&encAESCTX);
    EVP_EncryptInit_ex(&encAESCTX, EVP_aes_128_cbc(), NULL, key, iv);
    EVP_CIPHER_CTX_init(&decAESCTX);
    EVP_DecryptInit_ex(&decAESCTX, EVP_aes_128_cbc(), NULL, key, iv);
    
    return YES;
}

- (void)setKeyGenProgressBar:(UIProgressView *)progressBar
{
    self.progressBar = progressBar;
    [self.progressBar setProgress:0.0];
    self.keygencbcnt = 0;
}

#pragma mark AES encryption/decryption with password derived key

- (NSData *)encryptData:(NSData *)plainData
{
    if ([self loadPassword:NO] == NO)
    {
        NSLog(@"ERROR in encryptData, no password in keychain!");
        
        return nil;
    }
    
    NSTimeInterval time1 = [[NSDate date] timeIntervalSince1970];

    int resLen = 0;
    int cryptLen = (int)[plainData length] + AES_BLOCK_SIZE;
    unsigned char *cryptBytes = malloc(cryptLen);
    
    EVP_EncryptInit_ex(&encAESCTX, NULL, NULL, NULL, NULL);
    EVP_EncryptUpdate(&encAESCTX, cryptBytes, &cryptLen, [plainData bytes], (int)[plainData length]);
    EVP_EncryptFinal_ex(&encAESCTX, cryptBytes+cryptLen, &resLen);
    
    NSData *cryptData = [[NSData alloc] initWithBytes:cryptBytes length:(NSInteger)(cryptLen + resLen)];

    free(cryptBytes);

    NSLog(@"*** encryptData took %f for %ld bytes", [[NSDate date] timeIntervalSince1970] - time1, (long)cryptLen);

    return cryptData;
}

- (NSData *)reencryptData:(NSData *)plainData
{
    if ([self loadPassword:YES] == NO)
    {
        NSLog(@"ERROR in reencryptData, no password in keychain!");

        return nil;
    }
    
    NSTimeInterval time1 = [[NSDate date] timeIntervalSince1970];

    int resLen = 0;
    int cryptLen = (int)[plainData length] + AES_BLOCK_SIZE;
    unsigned char *cryptBytes = malloc(cryptLen);
    
    EVP_EncryptInit_ex(&encAESCTX, NULL, NULL, NULL, NULL);
    EVP_EncryptUpdate(&encAESCTX, cryptBytes, &cryptLen, [plainData bytes], (int)[plainData length]);
    EVP_EncryptFinal_ex(&encAESCTX, cryptBytes+cryptLen, &resLen);
    
    NSData *cryptData = [[NSData alloc] initWithBytes:cryptBytes length:(NSInteger)(cryptLen + resLen)];
    
    free(cryptBytes);
    
    NSLog(@"*** reencryptData took %f for %ld bytes", [[NSDate date] timeIntervalSince1970] - time1, (long)cryptLen);
    
    return cryptData;
}

- (NSData *)decryptData:(NSData *)cryptData
{
    if ([self loadPassword:NO] == NO)
    {
        NSLog(@"ERROR in decryptData, no password in keychain!");

        return nil;
    }
    
    NSTimeInterval time1 = [[NSDate date] timeIntervalSince1970];

    int resLen = 0;
    int plainLen = (int)[cryptData length];
    unsigned char *plainBytes = malloc(plainLen + AES_BLOCK_SIZE);
    
    EVP_DecryptInit_ex(&decAESCTX, NULL, NULL, NULL, NULL);
    EVP_DecryptUpdate(&decAESCTX, plainBytes, &plainLen, [cryptData bytes], (int)[cryptData length]);
    EVP_DecryptFinal_ex(&decAESCTX, plainBytes+plainLen, &resLen);
    
    // as we only encrypt encoded and archived NSData objects, this is our magic word
    if (strncmp((const char *)plainBytes, "bplist", 6))
    {
        [KeychainUserPass forcePasswordRetry];
        REDTOASTER("KeychainBadPassword");
        NSData *faultyData = [[NSData alloc] initWithBytes:plainBytes length:(NSInteger)(plainLen + resLen)];
        [AYAISyncManager dumpToLog:faultyData :@"decryptData_faulty"];
        NSLog(@"decryptData FAILED because result is no NSData object.");

        return nil;
    }
    
    NSData *clearData = [[NSData alloc] initWithBytes:plainBytes length:(NSInteger)(plainLen + resLen)];
    
    free(plainBytes);
    
    NSLog(@"*** decryptData took %f for %ld bytes", [[NSDate date] timeIntervalSince1970] - time1, (long)plainLen);
    
    return clearData;
}

#pragma mark RSA Key Generation

typedef void (^BlockCallback)(int,int);

static void callback(int p, int n, void *anon)
{
    BlockCallback theBlock = (__bridge BlockCallback)anon;  // cast the void * back to a block
    theBlock(p, n);                                         // and call the block
}

- (void)genReq:(BlockCallback)progressCallback completionCallback:(void (^)())completionCallback
{
    self.rsa = RSA_new();
    // pass the C wrapper as the function pointer and the block as the callback argument
    self.rsa = RSA_generate_key((int)self.keysize, RSA_F4, callback, (__bridge void *)progressCallback);
    completionCallback();
}

- (X509 *)generateIssuer:(EVP_PKEY **)privateKey :(NSString *)personEmail :(NSString *)personFirstName :(NSString *)personLastName :(NSString *)personAddressCity
{
    if (!privateKey) return NULL;
    
    X509 *x = X509_new();
	EVP_PKEY *pk = *privateKey;
	X509_NAME *name = NULL;

    self.keysize = (int)[[AYAISettings load:@"prefKeySize"] intValue];

    [self genReq:^(int p, int n)
     {
         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
             float percent = (float)self.keygencbcnt++ / (float)self.keysize * 1000;
             [self.progressBar setProgress:percent/100 animated:YES];
         }];
     }
    completionCallback:^{
        NSLog(@"RSA_generate_key %ld bit took %ld rounds", (long)self.keysize, (long)self.keygencbcnt);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        }];
    }];
    
    if (self.progressBar.tag == 1)
    {
        return NULL;
    }

    EVP_PKEY_assign_RSA(pk,self.rsa);
    
    X509_set_version(x,2);
    
    // serial number is sha1 hash of own mail address, i.e. always the same for an address
    unsigned char md[SHA_DIGEST_LENGTH];
    //    SHA1((const unsigned char *)[personEmail cStringUsingEncoding:NSASCIIStringEncoding], [personEmail length], md);
    NSString *randSerial = [AYAIPasswordManager newRandomPassword];
    SHA1((const unsigned char *)[randSerial cStringUsingEncoding:NSASCIIStringEncoding], [randSerial length], md);
    // --
    BIGNUM *bn = BN_bin2bn((const unsigned char *)&md, SHA_DIGEST_LENGTH, NULL);
    ASN1_INTEGER *serial = BN_to_ASN1_INTEGER(bn, NULL);
    serial->data[0] &= 0x7f;
    X509_set_serialNumber(x, serial);
    
	X509_gmtime_adj(X509_get_notBefore(x),0);
	X509_gmtime_adj(X509_get_notAfter(x),(long)60*60*24*365*10);
	X509_set_pubkey(x,pk);
    
	name = X509_get_subject_name(x);
	X509_NAME_add_entry_by_txt(name,"O",
                               MBSTRING_ASC, (const unsigned char *)"And You And I", -1, -1, 0);
	X509_NAME_add_entry_by_txt(name,"OU",
                               MBSTRING_ASC, (const unsigned char *)[LS("X509IssuerOU") UTF8String], -1, -1, 0);
	X509_NAME_add_entry_by_txt(name,"L",
                               MBSTRING_UTF8, (const unsigned char *)[personAddressCity UTF8String], -1, -1, 0);
    NSString *tout = [[NSString alloc] initWithFormat:LS("X509IssuerFormatCN"),
                      personFirstName, personLastName];
	X509_NAME_add_entry_by_txt(name,"CN",
                               MBSTRING_UTF8, (const unsigned char *)[tout UTF8String], -1, -1, 0);
	X509_set_issuer_name(x,name);
    
    tout = [[NSString alloc] initWithFormat:@"email:%@", personEmail];
    X509_EXTENSION *ex;
    ex = X509V3_EXT_conf_nid(NULL, NULL, NID_key_usage, "critical,keyCertSign");
    X509_add_ext(x, ex, -1);
    X509_EXTENSION_free(ex);
    ex = X509V3_EXT_conf_nid(NULL, NULL, NID_basic_constraints, "critical,CA:TRUE");
    X509_add_ext(x, ex, -1);
    X509_EXTENSION_free(ex);
    ex = X509V3_EXT_conf_nid(NULL, NULL, NID_subject_alt_name, (char *)[tout UTF8String]);
    X509_add_ext(x, ex, -1);
    X509_EXTENSION_free(ex);
    
    X509_sign(x,pk,EVP_sha256());
    
    return x;
}

- (X509 *)generateSubject:(EVP_PKEY **)privateKey :(EVP_PKEY *)issuerKey :(NSString *)personEmail :(NSString *)personFirstName :(NSString *)personLastName :(NSString *)personAddressCity
{
    if (!privateKey) return NULL;
    
    X509 *x = X509_new();
	EVP_PKEY *pk = *privateKey;
	X509_NAME *name = NULL;

    self.keysize = (int)[[AYAISettings load:@"prefKeySize"] intValue];

    [self genReq:^(int p, int n)
     {
         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
             float percent = (float)self.keygencbcnt++ / (float)self.keysize * 1000;
             [self.progressBar setProgress:percent/100 animated:YES];
         }];
     }
    completionCallback:^{
        NSLog(@"RSA_generate_key %ld bit took %ld rounds", (long)self.keysize, (long)self.keygencbcnt);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        }];
    }];
    
    if (self.progressBar.tag == 1)
    {
        return NULL;
    }
    
    EVP_PKEY_assign_RSA(pk,self.rsa);
    X509_set_version(x,2);
    
    // serial number is double sha1 hash of own mail address, i.e. always the same for an address
    unsigned char md[SHA_DIGEST_LENGTH];
//    SHA1((const unsigned char *)[personEmail cStringUsingEncoding:NSASCIIStringEncoding], [personEmail length], md);
    NSString *randSerial = [AYAIPasswordManager newRandomPassword];
    SHA1((const unsigned char *)[randSerial cStringUsingEncoding:NSASCIIStringEncoding], [randSerial length], md);
// --
    SHA1(md, SHA_DIGEST_LENGTH, md);
    BIGNUM *bn = BN_bin2bn((const unsigned char *)&md, SHA_DIGEST_LENGTH, NULL);
    ASN1_INTEGER *serial = BN_to_ASN1_INTEGER(bn, NULL);
    serial->data[0] &= 0x7f;
    X509_set_serialNumber(x, serial);
    
	X509_gmtime_adj(X509_get_notBefore(x),0);
	X509_gmtime_adj(X509_get_notAfter(x),(long)60*60*24*365*10);
	X509_set_pubkey(x,pk);
    
	name = X509_get_subject_name(x);
	X509_NAME_add_entry_by_txt(name,"O",
                               MBSTRING_ASC, (const unsigned char *)"And You And I", -1, -1, 0);
	X509_NAME_add_entry_by_txt(name,"OU",
                               MBSTRING_ASC, (const unsigned char *)[LS("X509SubjectOU") UTF8String], -1, -1, 0);
	X509_NAME_add_entry_by_txt(name,"L",
                               MBSTRING_UTF8, (const unsigned char *)[personAddressCity UTF8String], -1, -1, 0);
    NSString *tout = [[NSString alloc] initWithFormat:@"%@ %@",
                      personFirstName, personLastName];
	X509_NAME_add_entry_by_txt(name,"CN",
                               MBSTRING_UTF8, (const unsigned char *)[tout UTF8String], -1, -1, 0);
	name = X509_get_issuer_name(x);
	X509_NAME_add_entry_by_txt(name,"O",
                               MBSTRING_ASC, (const unsigned char *)"And You And I", -1, -1, 0);
	X509_NAME_add_entry_by_txt(name,"OU",
                               MBSTRING_ASC, (const unsigned char *)[LS("X509IssuerOU") UTF8String], -1, -1, 0);
	X509_NAME_add_entry_by_txt(name,"L",
                               MBSTRING_UTF8, (const unsigned char *)[personAddressCity UTF8String], -1, -1, 0);
    tout = [[NSString alloc] initWithFormat:LS("X509IssuerFormatCN"),
            personFirstName, personLastName];
	X509_NAME_add_entry_by_txt(name,"CN",
                               MBSTRING_UTF8, (const unsigned char *)[tout UTF8String], -1, -1, 0);
    
    tout = [[NSString alloc] initWithFormat:@"email:%@", personEmail];
    X509_EXTENSION *ex;
    ex = X509V3_EXT_conf_nid(NULL, NULL, NID_key_usage, "critical,digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment");
    X509_add_ext(x, ex, -1);
    X509_EXTENSION_free(ex);
    ex = X509V3_EXT_conf_nid(NULL, NULL, NID_subject_alt_name, (char *)[tout UTF8String]);
    X509_add_ext(x, ex, -1);
    X509_EXTENSION_free(ex);
    ex = X509V3_EXT_conf_nid(NULL, NULL, NID_ext_key_usage, "emailProtection");
    X509_add_ext(x, ex, -1);
    X509_EXTENSION_free(ex);
    
    X509_sign(x,issuerKey,EVP_sha256());
    
    return x;
}

- (NSData *)generatePFX:(NSString *)password :(NSString *)personEmail :(EVP_PKEY *)subjectKey :(X509 *)subjectCert :(X509 *)issuerCert
{
    STACK_OF(X509)  *caCertStack;
    PKCS12          *p12;
    BIO             *bpout = BIO_new(BIO_s_mem());
    
    caCertStack = sk_X509_new_null();
    sk_X509_push(caCertStack, issuerCert);
    p12 = PKCS12_create(
                        (char *)[password cStringUsingEncoding:NSISOLatin1StringEncoding],  // certbundle access password
                        (char *)[personEmail cStringUsingEncoding:NSASCIIStringEncoding], // friendly certname
                        subjectKey,   // the certificate private key
                        subjectCert,  // the main certificate
                        caCertStack, // stack of CA cert chain
                        0,           // int nid_key (default NID_pbe_WithSHA1And3_Key_TripleDES_CBC)
                        0,           // int nid_cert NID_pbe_WithSHA1And40BitRC2_CBC)
                        PKCS12_DEFAULT_ITER,    // int iter (default 2048)
                        PKCS12_DEFAULT_ITER,    // int mac_iter (default 1)
                        0                       // int keytype (default no flag
                        );
    i2d_PKCS12_bio(bpout, p12);
    
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSData * newP12Data = [[NSData alloc] initWithBytes:outputBuffer length:outputLength];
    
    sk_X509_free(caCertStack);
    PKCS12_free(p12);
    BIO_free_all(bpout);
    
    return newP12Data;
}

+ (NSString *)dumpedPKEY:(EVP_PKEY *)privateKey
{
    BIO *bpout = BIO_new(BIO_s_mem());
    EVP_PKEY_print_private(bpout, privateKey, 0, 0);
    EVP_PKEY_print_params(bpout, privateKey, 0, 0);
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSString *dumpString = [[NSString alloc] initWithBytes:(const void *)outputBuffer length:outputLength encoding:NSASCIIStringEncoding];
    BIO_free_all(bpout);
    
    return dumpString;
}

@end

#pragma mark PKCS12 parser for migration and import

@implementation AYAIPKCS12
{
@protected
    NSData *pkcs12Data;
    NSString *pkcs12Password;
@private
    X509 *subjectCert;
    X509 *issuerCert;
    EVP_PKEY *subjectKey;
}

- (AYAIPKCS12 *)initWithData:(NSData *)data
{
    if (data == nil)
    {
        return nil;
    }
    if (self == nil)
    {
        self = [[AYAIPKCS12 alloc] init];
    }
    pkcs12Data = data;
    subjectKey = NULL;
    subjectCert = NULL;
    issuerCert = NULL;
    pkcs12Password = nil;
    
    return self;
}

- (BOOL)decryptWithPassword:(NSString *)password
{
    SSLeay_add_all_algorithms();
    SSLeay_add_all_ciphers();
    SSLeay_add_all_digests();

    EVP_PKEY        *evpSubject;
    X509            *x509Subject;
    STACK_OF(X509)  *caCertStack;
    BIO             *bpin = BIO_new_mem_buf((void *)[pkcs12Data bytes], (int)[pkcs12Data length]);
    PKCS12          *pkcs12 = d2i_PKCS12_bio(bpin, NULL);

    if (pkcs12 == NULL)
    {
        NSLog(@"PKCS#12 data cannot be decoded. Bad file?");
        return FALSE;
    }

    caCertStack = sk_X509_new_null();
    int ret = PKCS12_parse(
                           pkcs12,
                           (const char *)[password cStringUsingEncoding:NSISOLatin1StringEncoding],
                           &evpSubject,
                           &x509Subject,
                           &caCertStack
                           );
    if (ret == 0)
    {
        NSLog(@"PKCS#12 data cannot be decrypted, error code %d. Wrong password?", ret);
        return FALSE;
    }
    if (evpSubject == NULL)
    {
        NSLog(@"PKCS#12 incomplete, no subject private key included. No original And You And I file?");
        return FALSE;
    }
    if (x509Subject == NULL)
    {
        NSLog(@"PKCS#12 incomplete, no subject certificate included. No original And You And I file?");
        return FALSE;
    }
    if (caCertStack == NULL)
    {
        NSLog(@"PKCS#12 incomplete, no issuer certificate included. No original And You And I file?");
        return FALSE;
    }
    pkcs12Password = password;
    subjectKey = evpSubject;
    subjectCert = x509Subject;
    issuerCert = sk_X509_pop(caCertStack);

    return YES;
}

- (EVP_PKEY *)subjectKey
{
    return subjectKey;
}

- (NSData *)subjectCertData
{
    return [NSData x509Data:subjectCert];
}

- (NSData *)issuerCertData
{
    return [NSData x509Data:issuerCert];
}

@end

#pragma mark Crypto Helpers

@implementation NSData (AES)

- (NSData *)cryptData
{
    return [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] encryptData:self];
}

- (NSData *)recryptData
{
    return [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] reencryptData:self];
}

- (NSData *)plainData
{
    return [[[AYAIAppDelegate sharedAppDelegate] cryptoHandler] decryptData:self];
}

@end

@implementation NSData (Base64)

- (NSString *)base64EncodedString
{
    BIO *context = BIO_new(BIO_s_mem());
    BIO *command = BIO_new(BIO_f_base64());
    BIO_set_flags(context, BIO_FLAGS_BASE64_NO_NL);
    BIO_set_flags(command, BIO_FLAGS_BASE64_NO_NL);
    context = BIO_push(command, context);
    BIO_write(context, [self bytes], (int)[self length]);
    BIO_flush(context);
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(context, &outputBuffer);
    NSString *encodedString = [[NSString alloc] initWithBytes:(const void *)outputBuffer length:outputLength encoding:NSASCIIStringEncoding];
    BIO_free_all(context);
    
    return encodedString;
}

@end

@implementation NSData (PKCS12)

- (NSString *)pkcs12Fingerprint;
{
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    PKCS12 *p;
    if (NULL == (p = d2i_PKCS12_bio(bpin, NULL)))
    {
        return NULL;
    }
    unsigned char md[EVP_MAX_MD_SIZE];
    SHA1((void *)[self bytes], (int)[self length], md);
    NSString *string = [[NSString alloc] init];
    for (NSInteger idx = 0; idx < 10; ++idx)
    {
        string = [string stringByAppendingFormat:@"%02x", md[idx]];
    }
    BIO_free_all(bpin);
    
    return string;
}

@end

@implementation NSData (X509)

+ (NSData *)x509Data:(X509 *)a
{
    if (!a) return NULL;
    BIO *bpout = BIO_new(BIO_s_mem());
    i2d_X509_bio(bpout, a);
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSData * certData = [[NSData alloc] initWithBytes:outputBuffer length:outputLength];
    BIO_free_all(bpout);
    
    return certData;
}

- (X509 *)dataX509
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    BIO_free_all(bpin);
    
    return x;
}

- (NSString *)dumpedX509
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    BIO *bpout = BIO_new(BIO_s_mem());
    X509_print(bpout, x);
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    NSString *dumpString = [[NSString alloc] initWithBytes:(const void *)outputBuffer length:outputLength encoding:NSASCIIStringEncoding];
    BIO_free_all(bpin);
    BIO_free_all(bpout);
    
    return dumpString;
}

- (NSInteger)x509Keysize
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return 0;
    }
    EVP_PKEY *public_key = X509_get_pubkey(x);
    BIO_free_all(bpin);
    
    return BN_num_bits(public_key->pkey.rsa->n);
}

- (NSDate *)x509DateNotBefore;
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    BIO_free_all(bpin);
    NSDate *date = nil;
    ASN1_TIME *asn1 = X509_get_notBefore(x);
    ASN1_GENERALIZEDTIME *gt = ASN1_TIME_to_generalizedtime(asn1, NULL);
    unsigned char *string = ASN1_STRING_data(gt);
    NSString *utc = [NSString stringWithUTF8String:(char *)string];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year   = [[utc substringWithRange:NSMakeRange(0, 4)] intValue];
    components.month  = [[utc substringWithRange:NSMakeRange(4, 2)] intValue];
    components.day    = [[utc substringWithRange:NSMakeRange(6, 2)] intValue];
    components.hour   = [[utc substringWithRange:NSMakeRange(8, 2)] intValue];
    components.minute = [[utc substringWithRange:NSMakeRange(10, 2)] intValue];
    components.second = [[utc substringWithRange:NSMakeRange(12, 2)] intValue];
    components.timeZone = [NSTimeZone localTimeZone];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    date = [calendar dateFromComponents:components];
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: date];
    
    return [NSDate dateWithTimeInterval: seconds sinceDate: date];
}

- (NSDate *)x509DateNotAfter;
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    BIO_free_all(bpin);
    NSDate *date = nil;
    ASN1_TIME *asn1 = X509_get_notAfter(x);
    ASN1_GENERALIZEDTIME *gt = ASN1_TIME_to_generalizedtime(asn1, NULL);
    unsigned char *string = ASN1_STRING_data(gt);
    NSString *utc = [NSString stringWithUTF8String:(char *)string];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year   = [[utc substringWithRange:NSMakeRange(0, 4)] intValue];
    components.month  = [[utc substringWithRange:NSMakeRange(4, 2)] intValue];
    components.day    = [[utc substringWithRange:NSMakeRange(6, 2)] intValue];
    components.hour   = [[utc substringWithRange:NSMakeRange(8, 2)] intValue];
    components.minute = [[utc substringWithRange:NSMakeRange(10, 2)] intValue];
    components.second = [[utc substringWithRange:NSMakeRange(12, 2)] intValue];
    components.timeZone = [NSTimeZone localTimeZone];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    date = [calendar dateFromComponents:components];
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: date];
    
    return [NSDate dateWithTimeInterval: seconds sinceDate: date];
}

- (NSString *)x509Serial
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    BIO *bpout = BIO_new(BIO_s_mem());
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    ASN1_INTEGER *serialNumber = X509_get_serialNumber(x);
    i2a_ASN1_INTEGER(bpout, serialNumber);
    char cBuffer[41];
    char *outputBuffer;
    long outputLength = BIO_get_mem_data(bpout, &outputBuffer);
    strncpy(cBuffer, outputBuffer, outputLength);
    cBuffer[40] = 0;
    NSString *serial = [NSString stringWithCString:(const char *)cBuffer encoding:NSASCIIStringEncoding];
    BIO_free_all(bpin);
    BIO_free_all(bpout);
    
    return serial;
}

- (NSString *)x509Fingerprint
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    BIO_free_all(bpin);
    const EVP_MD *digest = EVP_get_digestbyname("sha1");
    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int n;
    X509_digest(x, digest, md, &n);
    NSString *string = [[NSString alloc] init];
    for (NSInteger idx = 0; idx < n; ++idx)
    {
        string = [string stringByAppendingFormat:@"%02x:", md[idx]];
    }
    
    return [string substringToIndex:[string length]-1];
}

- (NSString *)x509Signature
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    if (NULL == (x = d2i_X509_bio(bpin, NULL)))
    {
        return NULL;
    }
    BIO_free_all(bpin);
    
    NSString *string = [[NSString alloc] init];
    for (NSInteger idx = 0; idx < x->signature->length; ++idx)
    {
        string = [string stringByAppendingFormat:@"%02X ", x->signature->data[idx]];
    }
    
    return [string substringToIndex:[string length]-1];
}

- (NSString *)x509Email
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    
    x = d2i_X509_bio(bpin, NULL);
    if (NULL == x) return @"";
    
    GENERAL_NAMES* subjectAltNames = (GENERAL_NAMES*)X509_get_ext_d2i(x, NID_subject_alt_name, NULL, NULL);
    
    int altNameCount = sk_GENERAL_NAME_num(subjectAltNames);
    NSString * subjectAltName = @"";
    for (int i = 0; i < altNameCount; ++i)
    {
        GENERAL_NAME* generalName = sk_GENERAL_NAME_value(subjectAltNames, i);
        if (generalName->type == GEN_EMAIL)
        {
            subjectAltName = [subjectAltName stringByAppendingString:
                              [[NSString alloc] initWithBytes:(ASN1_STRING_data(generalName->d.rfc822Name))
                                                       length:(ASN1_STRING_length(generalName->d.rfc822Name))
                                                     encoding:NSASCIIStringEncoding]];
        }
    }
    BIO_free_all(bpin);
    
    return subjectAltName;
}

- (NSString *)x509FirstName
{
    NSString *name = [self x509Name:NID_commonName];
    NSRange range = [name rangeOfString:@" " options:NSBackwardsSearch];
    NSString *first = [name substringToIndex:range.location];
    
    return first;
}

- (NSString *)x509LastName
{
    NSString *name = [self x509Name:NID_commonName];
    NSRange range = [name rangeOfString:@" " options:NSBackwardsSearch];
    NSString *last = [name substringFromIndex:range.location + 1];
    
    return last;
}

- (NSString *)x509Locality
{
    return [self x509Name:NID_localityName];
}

- (NSString *)x509Name:(int)nid
{
    X509 *x = nil;
    BIO *bpin = BIO_new_mem_buf((void *)[self bytes], (int)[self length]);
    x = d2i_X509_bio(bpin, NULL);
    if (NULL == x)
    {
        return NULL;
    }
    char outputBuffer[1024] = "";
    long outputLength = 1024;
    X509_NAME *subject = X509_get_subject_name(x);
    X509_NAME_get_text_by_NID(subject, nid, (char *)&outputBuffer, (int)outputLength);
    NSString *certInfo = [NSString stringWithCString:(const char *)outputBuffer encoding:NSASCIIStringEncoding];
    BIO_free_all(bpin);
    
    return certInfo;
}

@end
