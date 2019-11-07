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

#import "FCLiveDisplayView.h"

#import "FCCamera.h"
#import "FCImageProcessorPipeline.h"

@import GLKit;

@implementation FCLiveDisplayView {
    GLKView *_videoPreviewView;
    CIContext *_ciContext;
    EAGLContext *_eaglContext;
    CGRect _videoPreviewViewBounds;
    AVCaptureDevicePosition _currentPosition;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)_setup
{
    _currentPosition = AVCaptureDevicePositionUnspecified;
    self.backgroundColor = [UIColor clearColor];
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _videoPreviewView = [[GLKView alloc] initWithFrame:self.bounds context:_eaglContext];
    _videoPreviewView.enableSetNeedsDisplay = NO;
    _videoPreviewView.frame = self.bounds;
    [self _applyTransformation];
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];

    [self insertSubview:_videoPreviewView atIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)_didEnterBackground
{
}

- (void)_applyTransformation
{
    _videoPreviewView.transform = CGAffineTransformMakeRotation(M_PI_2);
    if (self.camera && self.camera.currentDevicePosition == AVCaptureDevicePositionFront) {
        _videoPreviewView.transform = CGAffineTransformScale(_videoPreviewView.transform, 1, -1);
    }
}

- (void)layoutSubviews
{
    _videoPreviewView.frame = self.bounds;
    [_videoPreviewView bindDrawable];

    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;

    [super layoutSubviews];
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!self.camera || CGRectEqualToRect(_videoPreviewViewBounds, CGRectZero)) {
        return;
    }
    if (self.camera.currentDevicePosition != _currentPosition) {
        _currentPosition = self.camera.currentDevicePosition;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _applyTransformation];
        });
    }
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
    CGRect sourceExtent = sourceImage.extent;

    CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    CGFloat previewAspect = _videoPreviewViewBounds.size.width / _videoPreviewViewBounds.size.height;

    // we want to maintain the aspect radio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;
    if (sourceAspect > previewAspect) {
        // use full height of the video image, and center crop the width
        // drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
        drawRect.size.width = drawRect.size.height * previewAspect;
    } else {
        // use full width of the video image, and center crop the height
        // drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
        drawRect.size.height = drawRect.size.width / previewAspect;
    }

    // Process Image
    [self.camera.imageProcessorPipeline
        processImage:sourceImage
          completion:^(CIImage *outputImage) {
              [self->_videoPreviewView bindDrawable];

              if (self->_eaglContext != [EAGLContext currentContext])
                  [EAGLContext setCurrentContext:self->_eaglContext];

              // clear eagl view to grey
              glClearColor(0.5, 0.5, 0.5, 1.0);
              glClear(GL_COLOR_BUFFER_BIT);

              // set the blend mode to "source over" so that CI will use that
              glEnable(GL_BLEND);
              glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

              [self->_ciContext drawImage:outputImage inRect:self->_videoPreviewViewBounds fromRect:drawRect];

              [self->_videoPreviewView display];
          }];
}

@end
