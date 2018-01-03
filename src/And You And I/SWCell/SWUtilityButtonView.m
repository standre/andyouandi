//
//  SWUtilityButtonView.m
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "SWUtilityButtonView.h"
#import "SWUtilityButtonTapGestureRecognizer.h"
#import "SWConstants.h"

@implementation SWUtilityButtonView

#pragma mark - SWUtilityButtonView initializers

- (id)initWithUtilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector
{
    self = [super init];
    
    if (self) {
        self.utilityButtons = utilityButtons;
        self.utilityButtonWidth = [self calculateUtilityButtonWidth];
        self.parentCell = parentCell;
        self.utilityButtonSelector = utilityButtonSelector;
    }
    for (UIButton * button in utilityButtons)
    {
        if (button.imageView.image)
        {
            [button setImageEdgeInsets:UIEdgeInsetsMake(-15.0f, (float)(self.utilityButtonWidth/2.0f - button.imageView.image.size.width/2.0f), 0.0f, 0.0f)];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(30.0f, -button.titleLabel.bounds.size.width, 0.0f, 0.0f)];
        }
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame utilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.utilityButtons = utilityButtons;
        self.utilityButtonWidth = [self calculateUtilityButtonWidth];
        self.parentCell = parentCell;
        self.utilityButtonSelector = utilityButtonSelector;
    }
    
    return self;
}

#pragma mark Populating utility buttons

- (CGFloat)calculateUtilityButtonWidth
{
    CGFloat buttonWidth = kUtilityButtonWidthDefault;
    if (buttonWidth * _utilityButtons.count > kUtilityButtonsWidthMax)
    {
        CGFloat buffer = (buttonWidth * _utilityButtons.count) - kUtilityButtonsWidthMax;
        buttonWidth -= (buffer / _utilityButtons.count);
    }
    return buttonWidth;
}

- (CGFloat)utilityButtonsWidth
{
    return (_utilityButtons.count * _utilityButtonWidth);
}

- (void)populateUtilityButtons
{
    NSUInteger utilityButtonsCounter = 0;
    for (UIButton *utilityButton in _utilityButtons)
    {
        CGFloat utilityButtonXCord = 0;
        if (utilityButtonsCounter >= 1) utilityButtonXCord = _utilityButtonWidth * utilityButtonsCounter;
        [utilityButton setFrame:CGRectMake(utilityButtonXCord, 0, _utilityButtonWidth, CGRectGetHeight(self.bounds))];
        [utilityButton setTag:utilityButtonsCounter];
        SWUtilityButtonTapGestureRecognizer *utilityButtonTapGestureRecognizer = [[SWUtilityButtonTapGestureRecognizer alloc] initWithTarget:_parentCell
                                                                                                                                      action:_utilityButtonSelector];
        utilityButtonTapGestureRecognizer.buttonIndex = utilityButtonsCounter;
        [utilityButton addGestureRecognizer:utilityButtonTapGestureRecognizer];
        [self addSubview: utilityButton];
        utilityButtonsCounter++;
    }
}

- (void)setHeight:(CGFloat)height
{
    for (NSUInteger utilityButtonsCounter = 0; utilityButtonsCounter < _utilityButtons.count; utilityButtonsCounter++)
    {
        UIButton *utilityButton = (UIButton *)_utilityButtons[utilityButtonsCounter];
        CGFloat utilityButtonXCord = 0;
        if (utilityButtonsCounter >= 1) utilityButtonXCord = _utilityButtonWidth * utilityButtonsCounter;
        [utilityButton setFrame:CGRectMake(utilityButtonXCord, 0, _utilityButtonWidth, height)];
    }
}

@end

