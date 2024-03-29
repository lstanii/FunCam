/**
 MIT License

Copyright (c) 2019 Snap Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#import "FCImageOrientationHandler.h"
#import "FCCamera.h"

@import UIKit;

@implementation FCImageOrientationHandler {
    CGSize _aspectSize;
    FCCamera *_camera;
}

#pragma mark - Init

- (instancetype)initWithAspectSize:(CGSize)aspectSize camera:(FCCamera *)camera
{
    self = [super init];
    if (self) {
        _aspectSize = aspectSize;
        _camera = camera;
    }
    return self;
}

#pragma mark - Public Methods

- (void)reorientImage:(CIImage *)image completion:(void (^)(CIImage *outputImage))completion
{
    CIImage *outputImage;
    // Rotate the image
    if (_camera.currentDevicePosition == AVCaptureDevicePositionFront) {
        outputImage = [image imageByApplyingCGOrientation:kCGImagePropertyOrientationLeftMirrored];
    } else {
        outputImage = [image imageByApplyingCGOrientation:kCGImagePropertyOrientationRight];
    }

    // Crop the image to the display
    CGFloat outputAspect = _aspectSize.width / _aspectSize.height;
    CGRect rect = outputImage.extent;
    rect.size.width = rect.size.height * outputAspect;
    rect.origin.x = 0;
    outputImage = [outputImage imageByCroppingToRect:rect];

    completion(outputImage);
}

@end
