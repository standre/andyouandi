//
//  AYAIPageController.h
//  And You And I
//
//  Created by sga on 07.04.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#define TUTORIAL_PAGES_COUNT 12

#import <UIKit/UIKit.h>

@interface AYAIPageController : UIPageViewController <UIPageViewControllerDataSource>
@property (strong, nonatomic) UIPageViewController *pageController;

@end
