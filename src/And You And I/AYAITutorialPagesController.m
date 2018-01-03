//
//  AYAITutorialPagesController.m
//  And You And I
//
//  Created by sga on 07.04.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAITutorialPagesController.h"
#import "AYAIPageController.h"
#import "AYAIUserData.h"

@implementation AYAITutorialPagesController

- (IBAction)doneTutorialPages:(id)sender
{
    [[AYAIAppDelegate sharedAppDelegate] setTutorialShown:YES];
    [self performSegueWithIdentifier:@"TutorialPagesToMain" sender:sender];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    AYAIPageController *subView = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]   instantiateViewControllerWithIdentifier:@"PageController"];
    [self addChildViewController:subView];
    [self.containerView addSubview:[subView view]];
    [subView didMoveToParentViewController:self];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
    {
        screenRect.origin.y = 45;
        screenRect.size.height -= 65;
    }
    else
    {
        screenRect.origin.y = 65;
        screenRect.size.height -= 65;
    }
    [self.containerView setFrame:screenRect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
