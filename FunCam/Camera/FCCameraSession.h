//
//  FCCameraSession.h
//  FunCam
//
//  Created by Lorenzo Stanton on 11/6/19.
//  Copyright © 2019 Snapchat. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FCCameraSession : NSObject

@property (nonatomic, getter=isFlashEnabled) BOOL flashEnabled;
@property (nonatomic, readonly) BOOL isFlashSupported;

- (void)captureImage:(void (^)(CIImage *_Nullable image))completion;
- (void)configure;
- (AVCaptureDevicePosition)currentDevicePosition;
- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition;
- (void)setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)delegate;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
