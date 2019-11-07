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

#import "FCCamera.h"

#import <AVKit/AVKit.h>

#import "FCCameraSession.h"
#import "FCLiveDisplayView.h"
#import "FCSampleBufferObserver.h"
#import "FCImageProcessorPipeline.h"

@interface FCCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation FCCamera {
    FCCameraSession *_cameraSession;
    FCLiveDisplayView *_liveDisplayView;
    NSMutableSet<id<FCSampleBufferObserver>> *_sampleBufferObservers;
    NSLock *_observerLock;
    dispatch_queue_t _backgroundQueue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cameraSession = [FCCameraSession new];
        _liveDisplayView = [FCLiveDisplayView new];
        _liveDisplayView.camera = self;
        _observerLock = [NSLock new];
        _sampleBufferObservers = [NSMutableSet new];
        dispatch_queue_attr_t attr =
            dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
        _backgroundQueue = dispatch_queue_create("com.fun.camera.camera.queue", attr);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopCamera)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startCamera)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        _imageProcessorPipeline = [FCImageProcessorPipeline new];
    }
    return self;
}

#pragma mark - Public Methods

- (void)captureImage:(void (^)(UIImage *image))image
{
    // TODO: Implement
}

- (AVCaptureDevicePosition)currentDevicePosition
{
    return _cameraSession.currentDevicePosition;
}

- (FCLiveDisplayView *)liveDisplay
{
    return _liveDisplayView;
}

- (void)setupCamera
{
    dispatch_async(_backgroundQueue, ^{
        [self->_cameraSession configure];
        [self->_cameraSession setSampleBufferDelegate:self];
    });
}

- (void)startCamera
{
    dispatch_async(_backgroundQueue, ^{
        [self->_cameraSession start];
    });
}

- (void)stopCamera
{
    dispatch_async(_backgroundQueue, ^{
        [self->_cameraSession stop];
    });
}

- (void)toggleCamera:(dispatch_block_t)completion
{
    dispatch_async(_backgroundQueue, ^{
        AVCaptureDevicePosition updatedPosition =
            self->_cameraSession.currentDevicePosition == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront
                                                                                      : AVCaptureDevicePositionBack;
        [self->_cameraSession setDevicePosition:updatedPosition];
        completion();
    });
}

- (void)toggleFlash:(dispatch_block_t)completion
{
    // TODO: Implement
}

#pragma mark - Sample Buffer Observing

- (void)addSampleBufferObserver:(id<FCSampleBufferObserver>)observer
{
    [_observerLock lock];
    [_sampleBufferObservers addObject:observer];
    [_observerLock unlock];
}

- (void)removeSampleBufferObserver:(id<FCSampleBufferObserver>)observer
{
    [_observerLock lock];
    [_sampleBufferObservers removeObject:observer];
    [_observerLock unlock];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    [_observerLock lock];
    NSSet<id<FCSampleBufferObserver>> *sampleBufferObservers = [_sampleBufferObservers copy];
    [_observerLock unlock];
    for (id<FCSampleBufferObserver> observer in sampleBufferObservers) {
        [observer enqueueSampleBuffer:sampleBuffer];
    }
}

@end
