//
//  AYAIPasswordController.h
//  And You And I
//
//  Created by sga on 25.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AYAI.h"

@class AYAIPKCS12;

typedef NS_ENUM(NSUInteger, PasswordMode)
{
    PASSWORD_AES,
    PASSWORD_AES_NEW,
    PASSWORD_AES_CHANGE,
    PASSWORD_PKCS12
};

@interface AYAIPasswordController : UIViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationTitle;
@property (strong, nonatomic) IBOutlet UILabel *labelPassword;
@property (strong, nonatomic) IBOutlet UIView *viewPassword;
@property (strong, nonatomic) IBOutlet UITextField *textPassword;
@property (strong, nonatomic) IBOutlet UITextField *textConfirmation;
@property (readwrite, nonatomic) PasswordMode passwordMode;
@property (strong, nonatomic) NSString *pkcs12ID;
@property (strong, nonatomic) NSData *pkcs12Data;
- (IBAction)textChanged:(id)sender;
- (IBAction)donePassword:(id)sender;
- (IBAction)cancelPassword:(id)sender;
@end
