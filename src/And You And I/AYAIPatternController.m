//
//  AYAIPatternController.m
//  And You And I
//
//  Created by sga on 05.01.16.
//  Copyright © 2013-2017 Stephan André. All rights reserved.
//

#import "AYAIPatternController.h"

@implementation AYAIPatternController

- (IBAction)handleSwipeGesture:(id)sender
    {
        [self performSegueWithIdentifier:@"PatternToMain" sender:sender];
    }
    
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(handleSwipeGesture:)];
    UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc]
                                                  initWithTarget:self action:@selector(handleSwipeGesture:)];
    rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.swipeView addGestureRecognizer:rightSwipeGesture];
    [self.swipeView addGestureRecognizer:leftSwipeGesture];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"html/index" withExtension:@"html"];
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:theConfiguration];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:url];
    [wkWebView loadRequest:nsrequest];
    [self.webView addSubview:wkWebView];
}

@end
