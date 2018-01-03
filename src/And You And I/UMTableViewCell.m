//
//  UMTableViewCell.m
//  SWTableViewCell
//
//  Created by Matt Bowman on 12/2/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import "UMTableViewCell.h"

@implementation UMTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.customImageIsThumbnail == YES)
    {
        CGRect contentViewBound = self.contentView.bounds;
        
        CGRect textLabelFrame = self.customText.frame;
        textLabelFrame.size.width = contentViewBound.size.width - 90;
        textLabelFrame.size.height = 40;
        textLabelFrame.origin.y = 5;
        textLabelFrame.origin.x = 10;
        self.customText.frame = textLabelFrame;
        
        CGRect detailTextLabelFrame = self.customDetails.frame;
        detailTextLabelFrame.size.width = contentViewBound.size.width - 90;
        detailTextLabelFrame.size.height = contentViewBound.size.height - 50;
        detailTextLabelFrame.origin.y = 45;
        detailTextLabelFrame.origin.x = 10;
        self.customDetails.frame = detailTextLabelFrame;
        self.customDetails.numberOfLines = 0;
        [self.customDetails sizeToFit];
        
        CGRect imageViewFrame = self.customImage.frame;
        imageViewFrame.size.width = 80;
        imageViewFrame.size.height = 80;
        imageViewFrame.origin.y = 0;
        imageViewFrame.origin.x = contentViewBound.size.width - 80;
        
        self.customImage.frame = imageViewFrame;
        self.customImage.layer.zPosition = MAXFLOAT;
        
        [self.customCount setHidden:YES];
    }
    else
    {
        CGRect contentViewBound = self.contentView.bounds;
        
        CGRect textLabelFrame = self.customText.frame;
        textLabelFrame.size.width = contentViewBound.size.width - 10;
        textLabelFrame.size.height = 20;
        textLabelFrame.origin.y = 5;
        textLabelFrame.origin.x = 10;
        self.customText.frame = textLabelFrame;
        
        CGRect detailTextLabelFrame = self.customDetails.frame;
        detailTextLabelFrame.size.width = contentViewBound.size.width - 10;
        detailTextLabelFrame.size.height = contentViewBound.size.height - 30;
        detailTextLabelFrame.origin.y = 25;
        detailTextLabelFrame.origin.x = 10;
        self.customDetails.frame = detailTextLabelFrame;
        self.customDetails.numberOfLines = 0;
        [self.customDetails sizeToFit];
        
        CGRect imageViewFrame = self.customImage.frame;
        imageViewFrame.size.width = 30;
        imageViewFrame.size.height = 30;
        imageViewFrame.origin.y = 6;
        imageViewFrame.origin.x = contentViewBound.size.width - 40;
        
        self.customImage.frame = imageViewFrame;
        self.customImage.layer.zPosition = MAXFLOAT;
        
        CGRect countTextLabelFrame = self.customCount.frame;
        countTextLabelFrame.size.width = 20;
        countTextLabelFrame.size.height = 14;
        countTextLabelFrame.origin.y = 30;
        countTextLabelFrame.origin.x = contentViewBound.size.width - 26;
        self.customCount.frame = countTextLabelFrame;
        self.customCount.layer.cornerRadius = 6.0f;
        self.customImage.layer.zPosition = MAXFLOAT;
    }
}

@end
