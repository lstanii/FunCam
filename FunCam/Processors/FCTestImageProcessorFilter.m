//
//  FCTestImageProcessorFilter.m
//  FunCam
//
//  Created by Lorenzo Stanton on 11/7/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import "FCTestImageProcessorFilter.h"

@import CoreImage;

@implementation FCTestImageProcessorFilter

- (void)processImage:(CIImage *)image completion:(void (^)(CIImage *))completion
{
    CIFilter *vignetteFilter = [CIFilter filterWithName:@"CIVignetteEffect"];
    [vignetteFilter setValue:image forKey:kCIInputImageKey];
    [vignetteFilter setValue:[CIVector vectorWithX:image.extent.size.width / 2 Y:image.extent.size.height / 2]
                      forKey:kCIInputCenterKey];
    [vignetteFilter setValue:@(image.extent.size.width / 2) forKey:kCIInputRadiusKey];
    CIImage *filteredImage = [vignetteFilter outputImage];

    CIFilter *effectFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
    [effectFilter setValue:filteredImage forKey:kCIInputImageKey];
    filteredImage = [effectFilter outputImage];
    completion(filteredImage);
}

@end
