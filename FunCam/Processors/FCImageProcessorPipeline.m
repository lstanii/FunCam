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
#import "FCImageOrientationHandler.h"
#import "FCImageProcessorFilter.h"

@import CoreImage;

@implementation FCImageProcessorPipeline {
    FCImageOrientationHandler *_orientationHandler;
    NSArray<FCImageProcessorFilter *> *_filters;
}

- (void)setOrientationHandler:(FCImageOrientationHandler *)orientationHandler
{
    _orientationHandler = orientationHandler;
}

- (void)setFilters:(NSArray<FCImageProcessorFilter *> *)filters
{
    _filters = filters;
}

- (NSArray<FCImageProcessorFilter *> *)filters
{
    return _filters;
}

- (void)processImage:(CIImage *)image completion:(void (^)(CIImage *outputImage))completion
{
    if (_orientationHandler) {
        [_orientationHandler
            processImage:image
              completion:^(CIImage *outputImage) {
                  [self _processImage:outputImage forFilters:self->_filters atIndex:0 completion:completion];
              }];
    } else {
        [self _processImage:image forFilters:self->_filters atIndex:0 completion:completion];
    }
}

- (void)_processImage:(CIImage *)image
           forFilters:(NSArray<FCImageProcessorFilter *> *)filters
              atIndex:(NSInteger)index
           completion:(void (^)(CIImage *outputImage))completion
{
    if (index >= filters.count) {
        completion(image);
        return;
    }
    [filters[index] processImage:image
                      completion:^(CIImage *outputImage) {
                          [self _processImage:outputImage forFilters:filters atIndex:index + 1 completion:completion];
                      }];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    FCImageProcessorPipeline *copy = [FCImageProcessorPipeline new];
    [copy setOrientationHandler:_orientationHandler];
    [copy setFilters:_filters];

    return copy;
}

@end
