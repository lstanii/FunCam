//
//  FCVignetteEffectFilter.m
//  FunCam
//
//  Created by Cheng Jiang on 11/8/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import "FCVignetteEffectFilter.h"

@import CoreImage;

@implementation FCVignetteEffectFilter

- (void)processImage:(CIImage *)image completion:(void (^)(CIImage *outputImage))completion
{
    CIFilter *vignetteFilter = [CIFilter filterWithName:@"CIVignetteEffect"];
    [vignetteFilter setValue:image forKey:kCIInputImageKey];
    [vignetteFilter setValue:[CIVector vectorWithX:image.extent.size.width / 2 Y:image.extent.size.height / 2]
                      forKey:kCIInputCenterKey];
    [vignetteFilter setValue:@(image.extent.size.width / 2) forKey:kCIInputRadiusKey];
    completion([vignetteFilter outputImage]);
}

- (void)toggle
{
    self.enabled = !self.enabled;
}

@end

