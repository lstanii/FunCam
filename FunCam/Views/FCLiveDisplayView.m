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
    CIContext *_ciContext;
    AVCaptureDevicePosition _currentPosition;
    EAGLContext *_eaglContext;
    GLKView *_videoPreviewView;
    CGRect _videoPreviewViewBounds;
}

#pragma mark - Init

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

#pragma mark - Private Methods

- (void)_didEnterBackground
{
    [_videoPreviewView deleteDrawable];
    [_videoPreviewView setHidden:YES];
}

- (void)_setup
{
    _currentPosition = AVCaptureDevicePositionUnspecified;
    self.backgroundColor = [UIColor clearColor];
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _videoPreviewView = [[GLKView alloc] initWithFrame:self.bounds context:_eaglContext];
    _videoPreviewView.enableSetNeedsDisplay = NO;
    _videoPreviewView.frame = self.bounds;
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]}];

    [self insertSubview:_videoPreviewView atIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

#pragma mark - Overrides

- (void)layoutSubviews
{
    _videoPreviewView.frame = self.bounds;
    [_videoPreviewView bindDrawable];

    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;

    [super layoutSubviews];
}

#pragma mark - FCSampleBufferObserver

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!self.camera || CGRectEqualToRect(_videoPreviewViewBounds, CGRectZero)) {
        return;
    }

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];

    // Process Image
    [self.camera.imageProcessorPipeline
        processImage:sourceImage
          completion:^(CIImage *outputImage) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  if (self->_videoPreviewView.isHidden) {
                      [self->_videoPreviewView setHidden:NO];
                  }
              });
              // Resize the image to the view
              CGRect extent = outputImage.extent;
              CGFloat previewAspect =
                  self->_videoPreviewViewBounds.size.width / self->_videoPreviewViewBounds.size.height;
              CGRect drawRect = extent;
              drawRect.size.width = previewAspect * drawRect.size.height;
              drawRect.origin.x = (extent.size.width - drawRect.size.width) / 2.0;

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
