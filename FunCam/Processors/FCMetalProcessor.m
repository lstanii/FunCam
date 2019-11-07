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

#import "FCMetalProcessor.h"

#import "FCMetalProcessingShader.h"

@import Metal;

id<MTLDevice> metalDevice() {
    static dispatch_once_t onceToken;
    static id<MTLDevice> metalDevice;
    dispatch_once(&onceToken, ^{
       metalDevice = MTLCreateSystemDefaultDevice();
    });
    return metalDevice;
}

@implementation FCMetalProcessor {
    NSArray<FCMetalProcessingShader *> *_shaders;
}

- (void)setShaders:(NSArray<FCMetalProcessingShader *> *)shaders
{
    _shaders = shaders;
}

- (NSArray<FCMetalProcessingShader *> *)shaders
{
    return _shaders;
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer completion:(void (^)(CMSampleBufferRef))completion
{
    [self _processSampleBuffer:sampleBuffer forShaders:_shaders atIndex:0 completion:completion];
}

- (void)_processSampleBuffer:(CMSampleBufferRef)sampleBuffer
                  forShaders:(NSArray<FCMetalProcessingShader *> *)shaders
                     atIndex:(NSInteger)index
                  completion:(void (^)(CMSampleBufferRef))completion
{
    if (index >= shaders.count) {
        completion(sampleBuffer);
        return;
    }

    [shaders[index] processSampleBuffer:sampleBuffer
                             completion:^(CMSampleBufferRef _Nonnull sampleBuffer) {
                                 [self _processSampleBuffer:sampleBuffer
                                                 forShaders:shaders
                                                    atIndex:index + 1
                                                 completion:completion];
                             }];
}

@end
