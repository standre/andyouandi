//
//  ayai_Password.m
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAIAppDelegate.h"
#import "AYAIUserData.h"
#import "AYAIPasswordManager.h"
#import "AYAICrypto.h"

@implementation AYAIPasswordManager

#pragma mark Password Generator

// generate strong random password of format ccccc-ccccc-ccccc-ccccc-ccccc
// i.e. 25 random bytes from character set 0-9, a-z, A-Z (62)
//      which is 25^62 combinations
+ (NSString *)newRandomPassword
{
    NSString *string = [[NSString alloc] init];
    unsigned char randByte[2];
    for (int segment = 0; segment < 5; segment++)
    {
        for (int chars = 0; chars < 5; chars++)
        {
            do
            {
                RAND_bytes(randByte, 1);
            }
            while ( ! isalnum(randByte[0]));
            string = [string stringByAppendingFormat:@"%c", randByte[0]];
        }
        string = [string stringByAppendingString:@"-"];
    }
    
    return [string substringToIndex:[string length]-1];
}

@end

#pragma mark Keychain methods

@implementation KeychainUserPass

+ (BOOL)requireNewPassword
{
    if ([self load:@"AESPassword"] == nil && [self load:@"AESNewPassword"] == nil && [self load:@"AESOldPassword"] == nil)
    {
        NSLog(@"Password INIT is required.");
        
        return YES;
    }
    
    return NO;
}

// AES password retry required if current password is nil but old password is set
// which is either caused by failed decryption after iCloud / iTunes sync, or forced by settings
+ (BOOL)requirePasswordRetry
{
    if ([self load:@"AESPassword"] == nil && [self load:@"AESOldPassword"] != nil)
    {
        NSLog(@"Password RETRY is required.");
        
        return YES;
    }
    
    return NO;
}

// AES password change required if current and new password is set, which allows to re-encrypt
+ (BOOL)requirePasswordChange;
{
    if ([self load:@"AESPassword"] != nil && [self load:@"AESNewPassword"] != nil)
    {
        NSLog(@"Password CHANGE is required.");

        return YES;
    }
    
    return NO;
}

// take over new password as current, as well as old password
// which can be used to check if app is initialized
+ (void)burnNewPassword
{
    NSLog(@"KeychainUserPass BURN new password");
    [self save:@"AESPassword" data:[self load:@"AESNewPassword"]];
    [self save:@"AESOldPassword" data:[self load:@"AESNewPassword"]];
    [self delete:@"AESNewPassword"];
}

+ (void)forcePasswordRetry
{
    if ([self load:@"AESPassword"] != nil)
    {
        [self save:@"AESOldPassword" data:[self load:@"AESPassword"]];
        [self delete:@"AESPassword"];
    }
    NSLog(@"Password INPUT is required.");
}

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)service
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
            nil];
}

+ (void)save:(NSString *)service data:(id)data
{
    [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[NSString stringWithFormat:@"KeychainUserPass SAVE %@: %@",
                                                        service,
                                                        ([[AYAISettings load:@"prefLogDetails"] boolValue]) ? data : @"****"]];
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

+ (id)load:(NSString *)service
{
    id ret = nil;
    
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr)
    {
        @try
        {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e)
        {
            NSLog(@"Unarchive of %@ failed: %@", service, e);
        }
        @finally {}
    }
    if (keyData)
    {
        CFRelease(keyData);
    }
    [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[NSString stringWithFormat:@"KeychainUserPass LOAD %@: %@",
                                                        service,
                                                        ([[AYAISettings load:@"prefLogDetails"] boolValue]) ? ret : @"****"]];
    
    return ret;
}

//+ (id)load:(NSString *)service
//{
//    id ret = nil;
//    
//    if ([self isTouchIDDone] == FALSE)
//        return nil;
//    
//    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
//    [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
//    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
//    CFDataRef keyData = NULL;
//    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr)
//    {
//        @try
//        {
//            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
//        }
//        @catch (NSException *e)
//        {
//            NSLog(@"Unarchive of %@ failed: %@", service, e);
//        }
//        @finally {}
//    }
//    if (keyData)
//    {
//        CFRelease(keyData);
//    }
//    [[AYAIAppDelegate sharedAppDelegate] appendLogBook:[NSString stringWithFormat:@"KeychainUserPass LOAD %@: %@",
//                                                        service,
//                                                        ([[AYAISettings load:@"prefLogDetails"] boolValue]) ? ret : @"****"]];
//    
//    return ret;
//}

+ (void)delete:(NSString *)service
{
    NSLog(@"KeychainUserPass DELETE %@", service);

    NSMutableDictionary *keychainQuery = [self getKeychainQuery:service];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

@end