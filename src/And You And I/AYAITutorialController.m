//
//  AYAITutorialController.m
//  And You And I
//
//  Created by sga on 07.04.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAITutorialController.h"

@implementation AYAITutorialController
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.webView.scrollView setPagingEnabled:YES];
    [self.webView setUserInteractionEnabled:(self.index == 0)];
    CGRect webViewFrame = self.webView.frame;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
    {
        webViewFrame.size.height = 529;     // bottom pdf shadow outside view
    }
    else
    {
        webViewFrame.size.height = 562;     // bottom pdf shadow outside view
    }
    self.webView.frame = webViewFrame;

    NSArray* availableLocalizations = [[NSBundle mainBundle] localizations];
    NSArray* userPrefered = [NSBundle preferredLocalizationsFromArray:availableLocalizations forPreferences:[NSLocale preferredLanguages]];
    NSString *pdfFile = [[NSBundle mainBundle] pathForResource:[[NSString alloc] initWithFormat:@"tutorial%02d", (int)self.index] ofType:@"pdf" inDirectory:nil forLocalization:[userPrefered objectAtIndex:0]];
    if (pdfFile != nil)
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:pdfFile]]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
