//
//  AYAITutorialController.h
//  And You And I
//
//  Created by sga on 07.04.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AYAITutorialController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *viewTutorialController;
@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end
