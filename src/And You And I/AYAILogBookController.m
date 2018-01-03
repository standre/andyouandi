//
//  AYAILogBookController.m
//  And You And I
//
//  Created by sga on 28.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAILogBookController.h"
#import "AYAIAppDelegate.h"

@implementation AYAILogBookController
{
    @private BOOL viewTraces;
}

- (IBAction)doneLogBook:(id)sender
{
    [self performSegueWithIdentifier:@"LogBookToSettings" sender:sender];
}

- (IBAction)showTraces:(id)sender
{
    viewTraces = !viewTraces;
    if (viewTraces)
    {
        [self.textLog setText:[[AYAIAppDelegate sharedAppDelegate] readConsoleLog]];
    }
    else
    {
        [self.textLog setText:[[AYAIAppDelegate sharedAppDelegate] logBookMessage]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenRect.origin.y = 64;
    screenRect.size.height -= 64;
    [self.mainView setFrame:screenRect];
    [self.scrollView setContentSize:CGSizeMake(640,416)];
    [self.textLog setText:[[AYAIAppDelegate sharedAppDelegate] logBookMessage]];
    [self.buttonShowTraces setEnabled:[[AYAIAppDelegate sharedAppDelegate] consoleLogFile] != nil];
    
    viewTraces = NO;
}

- (void)viewDidAppear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
