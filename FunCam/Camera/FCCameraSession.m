//
//  FCCameraSession.m
//  FunCam
//
//  Created by Lorenzo Stanton on 11/6/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import "FCCameraSession.h"

@implementation FCCameraSession {
    AVCaptureDevice *_captureDevice;
    AVCaptureInput *_captureDeviceInput;
    AVCaptureSession *_captureSession;
    NSLock *_captureSessionLock;
    AVCaptureDevicePosition _devicePosition;
    AVCapturePhotoOutput *_photoOutput;
    AVCaptureVideoDataOutput *_videoDataOutput;
    dispatch_queue_t _serialSampleBufferQueue;
}

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
}

- (AVCaptureDevicePosition)currentDevicePosition
{
    [_captureSessionLock lock];
    AVCaptureDevicePosition position = _devicePosition;
    [_captureSessionLock unlock];
    return position;
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

- (void)_configureSession:(dispatch_block_t)context
{
    [_captureSession beginConfiguration];
    context();
    [_captureSession commitConfiguration];
}

- (void)_configurePhotoOutput
{
    _photoOutput = [AVCapturePhotoOutput new];
    NSAssert([_captureSession canAddOutput:_photoOutput], @"Cannot add input");
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    [_captureSession addOutput:_photoOutput];
}

- (void)_configureVideoOutput
{
    _videoDataOutput = [AVCaptureVideoDataOutput new];
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
    
    [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
     AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
}

@end
