//
//  UMTableViewCell.h
//  SWTableViewCell
//
//  Created by Matt Bowman on 12/2/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface UMTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *customImage;
@property (weak, nonatomic) IBOutlet UILabel *customText;
@property (weak, nonatomic) IBOutlet UILabel *customDetails;
@property (weak, nonatomic) IBOutlet UILabel *customCount;
@property (nonatomic, nonatomic) BOOL customImageIsThumbnail;

@end
