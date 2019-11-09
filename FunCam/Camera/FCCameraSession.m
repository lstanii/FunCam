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

#import "FCCameraSession.h"
#import "FCNotification.h"

@import CoreImage;

@interface FCCameraSession () <AVCapturePhotoCaptureDelegate>
@end

@implementation FCCameraSession {
    AVCaptureDevice *_captureDevice;
    AVCaptureInput *_captureDeviceInput;
    AVCaptureSession *_captureSession;
    NSLock *_captureSessionLock;
    AVCaptureDevicePosition _devicePosition;
    void (^_imageCaptureCompletion)(CIImage *image);
    BOOL _isFlashEnabled;
    AVCapturePhotoOutput *_photoOutput;
    dispatch_queue_t _serialSampleBufferQueue;
    AVCaptureVideoDataOutput *_videoDataOutput;
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _captureSession = [AVCaptureSession new];
        _captureSessionLock = [NSLock new];
        dispatch_queue_attr_t attr =
            dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
        _serialSampleBufferQueue = dispatch_queue_create("com.fun.camera.serial.sample.buffer.queue", attr);
    }
    return self;
}

#pragma mark - Public Methods

- (void)captureImage:(void (^)(CIImage *image))completion
{
    if (_imageCaptureCompletion) {
        completion(nil);
        return;
    }
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    photoSettings.highResolutionPhotoEnabled = YES;
    if (_isFlashSupported) {
        photoSettings.flashMode = _isFlashEnabled ? AVCaptureFlashModeOn : AVCaptureFlashModeOff;
    }
    _imageCaptureCompletion = completion;
    [_photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

- (void)configure
{
    [_captureSessionLock lock];
    [self _configureSession:^{
        [self _configurePhotoOutput];
        [self _configureVideoOutput];
        [self _setDevicePosition:AVCaptureDevicePositionBack];
    }];
    [_captureSessionLock unlock];
}

- (AVCaptureDevicePosition)currentDevicePosition
{
    [_captureSessionLock lock];
    AVCaptureDevicePosition position = _devicePosition;
    [_captureSessionLock unlock];
    return position;
}

- (BOOL)isFlashEnabled
{
    [_captureSessionLock lock];
    BOOL enabled = _isFlashEnabled;
    [_captureSessionLock unlock];
    return enabled;
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    [_captureSessionLock lock];
    if (_devicePosition == devicePosition) {
        [_captureSessionLock unlock];
        return;
    }
    
    [self _configureSession:^{
        [self _setDevicePosition:devicePosition];
    }];
    
    [_captureSessionLock unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:FCNotificationDevicePositionDidChange object:nil];
}

- (void)setFlashEnabled:(BOOL)enabled
{
    [_captureSessionLock lock];
    if (enabled == _isFlashEnabled) {
        [_captureSessionLock unlock];
        return;
    }
    _isFlashEnabled = enabled;
    [_captureSessionLock unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:FCNotificationFlashEnabledDidChange object:nil];
}

- (void)setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate
{
    NSAssert(_videoDataOutput, @"Configure must be called before setting a sample buffer delegate");
    [_videoDataOutput setSampleBufferDelegate:delegate queue:_serialSampleBufferQueue];
}

- (void)start
{
    [_captureSessionLock lock];
    [_captureSession startRunning];
    [_captureSessionLock unlock];
}

- (void)stop
{
    [_captureSessionLock lock];
    [_captureSession stopRunning];
    [_captureSessionLock unlock];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output
    didFinishProcessingPhoto:(nonnull AVCapturePhoto *)photo
                       error:(nullable NSError *)error
{
    if (!_imageCaptureCompletion) {
        return;
    }
    if (error) {
        _imageCaptureCompletion(nil);
        _imageCaptureCompletion = nil;
        return;
    }

    CIImage *outputImage = [CIImage imageWithCGImage:photo.CGImageRepresentation];
    _imageCaptureCompletion(outputImage);
    _imageCaptureCompletion = nil;
}

- (void)captureOutput:(AVCapturePhotoOutput *)output
    didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
                                  error:(NSError *)error
{
    if (_imageCaptureCompletion && error) {
        _imageCaptureCompletion(nil);
        _imageCaptureCompletion = nil;
    }
}

#pragma mark - Private Methods

- (void)_configurePhotoOutput
{
    _photoOutput = [AVCapturePhotoOutput new];
    _photoOutput.highResolutionCaptureEnabled = YES;
    NSAssert([_captureSession canAddOutput:_photoOutput], @"Cannot add input");
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [_captureSession addOutput:_photoOutput];
}

- (void)_configureSession:(dispatch_block_t)context
{
    [_captureSession beginConfiguration];
    context();
    [_captureSession commitConfiguration];
}

- (void)_configureVideoOutput
{
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    NSAssert([_captureSession canAddOutput:_videoDataOutput], @"Cannot add input");
    [_captureSession addOutput:_videoDataOutput];
}

- (void)_setDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    if (_captureDeviceInput) {
        [_captureSession removeInput:_captureDeviceInput];
    }
    _captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                        mediaType:AVMediaTypeVideo
                                                         position:devicePosition];
    NSError *error;
    _captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    NSAssert(!error, @"%@", error);
    NSAssert([_captureSession canAddInput:_captureDeviceInput], @"Cannot add input");
    [_captureSession addInput:_captureDeviceInput];
    _devicePosition = devicePosition;
    _isFlashSupported = [_photoOutput.supportedFlashModes containsObject:@(AVCaptureFlashModeOn)];
}

@end
