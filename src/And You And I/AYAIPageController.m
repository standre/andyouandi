//
//  AYAIPageController.m
//  And You And I
//
//  Created by sga on 07.04.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "AYAIPageController.h"
#import "AYAITutorialController.h"

@implementation AYAIPageController

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [(AYAITutorialController *)viewController index];
    if (index == 0)
    {
        return nil;
    }
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [(AYAITutorialController *)viewController index];
    index++;
    if (index == TUTORIAL_PAGES_COUNT)
    {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

- (AYAITutorialController *)viewControllerAtIndex:(NSUInteger)index
{
    AYAITutorialController *childViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]   instantiateViewControllerWithIdentifier:@"TutorialController"];
    childViewController.index = index;
    
    return childViewController;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return TUTORIAL_PAGES_COUNT;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageController.dataSource = self;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenRect.origin.y = 0;
    [self.view setFrame:screenRect];
    screenRect = [[UIScreen mainScreen] bounds];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
    {
        screenRect.origin.y = -2;
        screenRect.size.height -= 75;
    }
    else
    {
        screenRect.origin.y = -7;
        screenRect.size.height -= 65;
    }
    screenRect.origin.x = -4;
    screenRect.size.width += 8;
    [[self.pageController view] setFrame:screenRect];
    UIPageControl* proxy = [UIPageControl appearanceWhenContainedInInstancesOfClasses:@[[UIPageViewController class]]];
    [proxy setPageIndicatorTintColor:[UIColor lightGrayColor]];
    [proxy setCurrentPageIndicatorTintColor:[UIColor blueColor]];
    [proxy setBackgroundColor:[UIColor whiteColor]];
    AYAITutorialController *initialViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
