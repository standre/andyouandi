//
//  AYANewIdentityController.h
//  And You And I
//
//  Created by sga on 04.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "TargetConditionals.h"
#import <UIKit/UIKit.h>
#import "AYAI.h"

@interface AYAINewIdentityController : UIViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *textMail;
@property (strong, nonatomic) IBOutlet UITextField *textFirstName;
@property (strong, nonatomic) IBOutlet UITextField *textLastName;
@property (strong, nonatomic) IBOutlet UITextField *textCity;
@end

