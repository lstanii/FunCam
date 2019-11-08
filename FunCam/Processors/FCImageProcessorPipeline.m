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

#import "FCImageProcessorPipeline.h"

#import "FCImageProcessorFilter.h"

@import CoreImage;

@implementation FCImageProcessorPipeline {
    NSArray<FCImageProcessorFilter *> *_filters;
}

- (void)setFilters:(NSArray<FCImageProcessorFilter *> *)filters
{
    _filters = filters;
}

- (NSArray<FCImageProcessorFilter *> *)filters
{
    return _filters;
}

- (void)processImage:(CIImage *)image
      devicePosition:(AVCaptureDevicePosition)devicePosition
          completion:(void (^)(CIImage *outputImage))completion
{
    [self _processImage:image devicePosition:devicePosition forFilters:_filters atIndex:0 completion:completion];
}

- (void)_processImage:(CIImage *)image
       devicePosition:(AVCaptureDevicePosition)devicePosition
           forFilters:(NSArray<FCImageProcessorFilter *> *)filters
              atIndex:(NSInteger)index
           completion:(void (^)(CIImage *outputImage))completion
{
    if (index >= filters.count) {
        completion(image);
        return;
    }
    [filters[index] processImage:image
                  devicePosition:devicePosition
                      completion:^(CIImage *outputImage) {
                          [self _processImage:outputImage
                               devicePosition:devicePosition
                                   forFilters:filters
                                      atIndex:index + 1
                                   completion:completion];
                      }];
}

@end
