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

#import <UIKit/UIKit.h>

#import <AVKit/AVKit.h>

@protocol FCSampleBufferObserver;
@class FCLiveDisplayView;
@class FCImageProcessorPipeline;

NS_ASSUME_NONNULL_BEGIN

@interface FCCamera : NSObject

#pragma mark - Public Properties

@property (nonatomic, nonnull, readonly) FCLiveDisplayView *liveDisplay;
@property (nonatomic, nonnull, readonly) FCImageProcessorPipeline *imageProcessorPipeline;
@property (nonatomic, readonly) BOOL isFlashSupported;

#pragma mark - Public Methods

- (void)captureImage:(void (^)(CIImage *_Nullable image))image;
- (AVCaptureDevicePosition)currentDevicePosition;
- (BOOL)isFlashEnabled;

/**sets up the camera hardware and prepares for rendering*/
- (void)setupCamera;
/** starts the camera session */
- (void)startCamera;
/** stops the camera session, when in background, and/or to conserve battery consumption */
- (void)stopCamera;
- (void)toggleFlash:(dispatch_block_t)completion;
- (void)toggleCameraPosition:(dispatch_block_t)completion;

#pragma mark - Sample Buffer Observing

/** adds an observer, receive sample buffers*/
- (void)addSampleBufferObserver:(id<FCSampleBufferObserver>)observer;
/** removes an observe, no longer receive sample buffers*/
- (void)removeSampleBufferObserver:(id<FCSampleBufferObserver>)observer;

@end

NS_ASSUME_NONNULL_END
