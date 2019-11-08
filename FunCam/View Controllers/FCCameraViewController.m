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
#import "FCMediaExporter.h"

@implementation FCCameraViewController {
    FCCamera *_camera;
    __weak IBOutlet UIImageView *_previewTestImageView;
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
    [_camera.imageProcessorPipeline setFilters:@[ [FCImageOrientationHandler new] ]];
}

- (void)setCameraAPI:(FCCamera *)camera
{
    _camera = camera;
}

- (IBAction)testFilter:(UIButton *)sender
{
    if (sender.tag == 0) {
        sender.tag = 1;
        [sender setTitle:@"Turn Test Filter Off" forState:UIControlStateNormal];
        [_camera.imageProcessorPipeline
            setFilters:@[ [FCImageOrientationHandler new], [FCTestImageProcessorFilter new] ]];
    } else {
        sender.tag = 0;
        [sender setTitle:@"Turn Test Filter On" forState:UIControlStateNormal];
        [_camera.imageProcessorPipeline setFilters:@[ [FCImageOrientationHandler new] ]];
    }
}

- (IBAction)toggleFlash:(UIButton *)sender
{
    [sender setEnabled:NO];
    [_camera toggleFlash:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setEnabled:YES];
        });
    }];
}

- (IBAction)toggleCamera:(UIButton *)sender
{
    [sender setEnabled:NO];
    [_camera toggleCamera:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setEnabled:YES];
        });
    }];
}

- (IBAction)captureImage:(id)sender
{

    [_camera captureImage:^(UIImage *_Nullable image) {
        self->_previewTestImageView.image = image;
        [[FCMediaExporter new] saveImageToCameraRoll:image completion:nil];
    }];
}

@end
