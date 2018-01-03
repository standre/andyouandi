//
//  AYAILogBookController.h
//  And You And I
//
//  Created by sga on 28.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AYAILogBookController : UIViewController
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonShowTraces;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UITextView *textLog;
- (IBAction)doneLogBook:(id)sender;
- (IBAction)showTraces:(id)sender;
@end
