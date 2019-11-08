//
//  FCFilterViewCell.m
//  FunCam
//
//  Created by Cheng Jiang on 11/8/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import "FCFilterViewCell.h"
#import "FCImageProcessorFilter.h"

@implementation FCFilterViewCell {
    __weak IBOutlet UIImageView *_imageView;
    BOOL _selected;
    
}

- (void)applyFilter:(FCImageProcessorFilter *)filter
{
    [filter processImage:[CIImage imageWithCGImage:_imageView.image.CGImage] completion:^(CIImage *outputImage) {
        self->_imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self->_imageView setImage:[UIImage imageWithCIImage:outputImage]];
    }];
}

- (void)handleTap
{
    _selected = !_selected;
    if (_selected) {
        
    } else {
        
    }
}

@end
