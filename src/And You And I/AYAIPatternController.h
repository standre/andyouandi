//
//  AYAIPatternController.h
//  And You And I
//
//  Created by sga on 05.01.16.
//  Copyright © 2013-2017 Stephan André. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface AYAIPatternController : UIViewController <UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UIView *viewPatternController;
@property (strong, nonatomic) IBOutlet UIView *webView;
@property (strong, nonatomic) IBOutlet UIView *swipeView;

- (IBAction)handleSwipeGesture:(id)sender;

@end
