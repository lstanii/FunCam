//
//  FCFilterViewCell.h
//  FunCam
//
//  Created by Cheng Jiang on 11/8/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FCImageProcessorFilter;

NS_ASSUME_NONNULL_BEGIN

@interface FCFilterViewCell : UICollectionViewCell

- (void)applyFilter:(FCImageProcessorFilter *)filter;
- (void)handleTap;

@end

NS_ASSUME_NONNULL_END
