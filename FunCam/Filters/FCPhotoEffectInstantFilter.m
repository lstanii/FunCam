//
//  FCSampleFilter2.m
//  FunCam
//
//  Created by Cheng Jiang on 11/8/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import "FCPhotoEffectInstantFilter.h"

@implementation FCPhotoEffectInstantFilter

- (void)processImage:(CIImage *)image completion:(void (^)(CIImage *outputImage))completion
{
    CIFilter *effectFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
    [effectFilter setValue:image forKey:kCIInputImageKey];
    completion([effectFilter outputImage]);
}

- (void)toggle
{
    self.enabled = !self.enabled;
}

@end
