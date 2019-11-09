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
#import "FCFilterCollectionViewController.h"
#import "FCLiveDisplayView.h"
#import "FCImageProcessorPipeline.h"
#import "FCImageOrientationHandler.h"
#import "FCPreviewViewController.h"
#import "FCConstants.h"
#import "FCVignetteEffectFilter.h"
#import "FCPhotoEffectInstantFilter.h"

@implementation FCCameraViewController {
    __weak IBOutlet UIButton *_toggleCameraBtn;
    __weak IBOutlet UIButton *_toggleFlashBtn;
    __weak IBOutlet UIView *_filterCollectionViewContainer;

    FCCamera *_camera;
    FCFilterCollectionViewController *_filterCollectionViewController;
}

#pragma mark - Public Methods

- (void)setCameraAPI:(FCCamera *)camera
{
    _camera = camera;
    // load view
    [self view];
    UIView *preview = camera.liveDisplay;
    [self.view insertSubview:preview atIndex:0];
    preview.frame = self.view.bounds;
    preview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [camera setupCamera];
    [camera addSampleBufferObserver:camera.liveDisplay];
    [camera startCamera];

    [_camera.imageProcessorPipeline
        setOrientationHandler:[[FCImageOrientationHandler alloc] initWithAspectSize:_camera.liveDisplay.bounds.size
                                                                             camera:_camera]];
    UITapGestureRecognizer *doubleTapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_toggleCamera)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    [_filterCollectionViewContainer setHidden:YES];
    [self _setupFilters];
}

#pragma mark - Actions

- (IBAction)toggleFilters:(UIButton *)sender
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         sender.transform = CGAffineTransformRotate(sender.transform, M_PI_4);
                     }];
    [_filterCollectionViewContainer setHidden:!_filterCollectionViewContainer.hidden];
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

- (IBAction)captureImage:(UIButton *)sender
{
    [self.view setUserInteractionEnabled:NO];
    [self _animateToggle:sender];
    __weak typeof(self) weakSelf = self;
    [_camera captureImage:^(CIImage *_Nullable image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            if (!image || !strongSelf) {
                [strongSelf.view setUserInteractionEnabled:YES];
                return;
            }
            FCPreviewViewController *previewViewController =
                [strongSelf.storyboard instantiateViewControllerWithIdentifier:FCPreviewViewControllerStoryBoardKey];
            previewViewController.modalPresentationStyle = UIModalPresentationPopover;

            // Copy the pipleline so changes do not affect the current pipline
            FCImageProcessorPipeline *copiedPipeline = strongSelf->_camera.imageProcessorPipeline.copy;

            [previewViewController displayImage:image
                        imageProcessingPipeline:copiedPipeline
                               availableFilters:strongSelf->_filterCollectionViewController.availableFilters
                                  activeFilters:strongSelf->_filterCollectionViewController.activeFilters];
            [strongSelf presentViewController:previewViewController animated:YES completion:nil];
            [strongSelf.view setUserInteractionEnabled:YES];
        });
    }];
}

#pragma mark - Private Methods

- (void)_animateToggle:(UIView *)view
{
    CGAffineTransform currentTransform = view.transform;
    [UIView animateWithDuration:0.2
        animations:^{
            view.transform = CGAffineTransformScale(currentTransform, 1.75, 1.75);
        }
        completion:^(BOOL finished) {
            if (!finished) {
                view.transform = currentTransform;
            } else {
                [UIView animateWithDuration:0.2
                    animations:^{
                        view.transform = currentTransform;
                    }
                    completion:^(BOOL finished) {
                        view.transform = currentTransform;
                    }];
            }
        }];
}

- (void)_setupFilters
{
    NSMutableArray<FCImageProcessorFilter *> *array = [NSMutableArray new];
    // TODO: implement your filters
    [array addObject:[[FCVignetteEffectFilter alloc] init]];
    [array addObject:[[FCPhotoEffectInstantFilter alloc] init]];

    NSArray<FCImageProcessorFilter *> *availableFilters = [array copy];
    [_camera.imageProcessorPipeline setFilters:@[]];

    // Set up collection view controller

    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.minimumInteritemSpacing = 0;
    FCFilterCollectionViewController *viewController =
        [[FCFilterCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    viewController.availableFilters = availableFilters;
    viewController.imageProcessorPipeline = _camera.imageProcessorPipeline;
    _filterCollectionViewController = viewController;

    // Attach collection view controller

    [self addChildViewController:viewController];
    viewController.view.frame = _filterCollectionViewContainer.bounds;
    [_filterCollectionViewContainer addSubview:viewController.view];
    _filterCollectionViewContainer.backgroundColor = [UIColor clearColor];
    [viewController didMoveToParentViewController:self];
}

- (void)_toggleCamera
{
    [_toggleCameraBtn setEnabled:NO];
    [self _animateToggle:_toggleCameraBtn];
    [_camera toggleCameraPosition:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_toggleCameraBtn setEnabled:YES];
            [self->_toggleFlashBtn setHidden:!self->_camera.isFlashSupported];
        });
    }];
}

@end
