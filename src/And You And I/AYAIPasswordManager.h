//
//  ayai_Password.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AYAIPasswordManager : NSObject
+ (NSString *)newRandomPassword;
@end

@interface KeychainUserPass : NSObject
+ (void)save:(NSString *)service data:(id)data;
+ (id)load:(NSString *)service;
+ (void)delete:(NSString *)service;
+ (void)burnNewPassword;
+ (BOOL)requireNewPassword;
+ (BOOL)requirePasswordRetry;
+ (BOOL)requirePasswordChange;
+ (void)forcePasswordRetry;
@end