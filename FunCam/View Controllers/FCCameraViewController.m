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

#import "FCCameraViewController.h"

#import "FCCamera.h"
#import "FCLiveDisplayView.h"
#import "FCTestImageProcessorFilter.h"
#import "FCImageProcessorPipeline.h"
#import "FCImageOrientationHandler.h"
#import "FCPreviewViewController.h"
#import "FCConstants.h"

@implementation FCCameraViewController {
    FCCamera *_camera;
    __weak IBOutlet UIButton *_toggleCameraBtn;
    __weak IBOutlet UIButton *_toggleFlashBtn;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    FCCamera *camera = [FCCamera new];
    [self setCameraAPI:camera];
    UIView *preview = camera.liveDisplay;
    [self.view insertSubview:preview atIndex:0];
    preview.frame = self.view.bounds;
    preview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [camera setupCamera];
    [camera addSampleBufferObserver:camera.liveDisplay];
    [camera startCamera];
    [_camera.imageProcessorPipeline setFilters:@[
        [[FCImageOrientationHandler alloc] initWithAspectSize:_camera.liveDisplay.bounds.size camera:_camera]
    ]];
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_toggleCamera)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
}

- (void)setCameraAPI:(FCCamera *)camera
{
    _camera = camera;
}

- (IBAction)toggleFlash:(UIButton *)sender
{
    [sender setEnabled:NO];
    [self _animateToggle:sender];
    [_camera toggleFlash:^{
        NSString *imageName = self->_camera.isFlashEnabled ? @"ToggleFlash-active" : @"ToggleFlash-inactive";
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setEnabled:YES];
            [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        });
    }];
}

- (IBAction)toggleCamera:(UIButton *)sender
{
    [self _toggleCamera];
}

- (IBAction)captureImage:(id)sender
{

    __weak typeof(self) weakSelf = self;
    [_camera captureImage:^(CIImage *_Nullable image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            FCPreviewViewController *previewViewController =
                [strongSelf.storyboard instantiateViewControllerWithIdentifier:FCPreviewViewControllerStoryBoardKey];
            previewViewController.modalPresentationStyle = UIModalPresentationPopover;
            [previewViewController displayImage:image
                        imageProcessingPipeline:strongSelf->_camera.imageProcessorPipeline];
            [strongSelf presentViewController:previewViewController animated:YES completion:nil];
        });
    }];
}

- (void)_animateToggle:(UIView *)view
{
    CGAffineTransform currentTransform = view.transform;
    [UIView animateWithDuration:0.15
        animations:^{
            view.transform = CGAffineTransformScale(currentTransform, 1.5, 1.5);
        }
        completion:^(BOOL finished) {
            if (!finished) {
                view.transform = currentTransform;
            } else {
                [UIView animateWithDuration:0.15
                    animations:^{
                        view.transform = currentTransform;
                    }
                    completion:^(BOOL finished) {
                        view.transform = currentTransform;
                    }];
            }
        }];
}

- (void)_toggleCamera
{
    [_toggleCameraBtn setEnabled:NO];
    [self _animateToggle:_toggleCameraBtn];
    [_camera toggleCamera:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_toggleCameraBtn setEnabled:YES];
            [self->_toggleFlashBtn setHidden:!self->_camera.isFlashSupported];
        });
    }];
}

@end
