//
//  ayai_AppDelegate.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <StoreKit/StoreKit.h>

@class AYAIUserData;
@class AYAICrypto;

@interface AYAIAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *myView;
@property (strong, nonatomic) AYAIUserData *myUserData;
@property (strong, nonatomic) AYAICrypto *cryptoHandler;
@property (strong, nonatomic) NSString *logBookMessage;
@property (strong, nonatomic) NSString *consoleLogFile;
@property (readwrite, nonatomic) BOOL didAppear;
@property (readwrite, nonatomic) BOOL tutorialShown;
@property (readwrite, nonatomic) BOOL migrationCancelled;
@property (strong, nonatomic) UIStoryboard * storyboard;

+ (AYAIAppDelegate *)sharedAppDelegate;
- (void)redirectConsoleLog;
- (NSString *)readConsoleLog;
- (void)restoreConsoleLog;
- (void)setMainView:(UIViewController *)view;
- (UIViewController *)getMainView;
- (void)setUserData:(AYAIUserData *)userData;
- (AYAIUserData *)getUserData;
- (void)appendLogBook:(NSString *)message;
+ (BOOL)is64bitHardware;
@end
