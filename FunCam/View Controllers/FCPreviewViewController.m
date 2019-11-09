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

#import "FCPreviewViewController.h"
#import "FCMediaExporter.h"
#import "FCImageProcessorPipeline.h"
#import "FCFilterCollectionViewController.h"
#import "UIImage+CIImage.h"

@interface FCPreviewViewController () <FCFilterCollectionViewControllerDelegate>
@end

@implementation FCPreviewViewController {
    __weak IBOutlet UIView *_filterCollectionViewContainer;
    CIImage *_image;
    UIImage *_uiImage;
    FCImageProcessorPipeline *_imageProcessingPipeline;
    FCMediaExporter *_mediaExporter;
    __weak IBOutlet UIImageView *_imageView;
}

#pragma mark - Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    _mediaExporter = [FCMediaExporter new];
}

#pragma mark - Public Methods

- (void)displayImage:(CIImage *)image
    imageProcessingPipeline:(FCImageProcessorPipeline *)imageProcessingPipeline
           availableFilters:(NSArray<FCImageProcessorFilter *> *)availableFilters
              activeFilters:(NSArray<FCImageProcessorFilter *> *)activeFilters
{
    // Load the view if not loaded
    [self view];
    _image = image;
    _imageProcessingPipeline = imageProcessingPipeline;
    [self _processPipeline];

    // Set up collection view controller

    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.minimumInteritemSpacing = 0;
    FCFilterCollectionViewController *viewController =
        [[FCFilterCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    viewController.filterCollectionViewControllerDelegate = self;
    viewController.availableFilters = availableFilters;
    viewController.activeFilters = activeFilters;
    viewController.imageProcessorPipeline = imageProcessingPipeline;

    // Attach collection view controller

    [self addChildViewController:viewController];
    viewController.view.frame = _filterCollectionViewContainer.bounds;
    [_filterCollectionViewContainer addSubview:viewController.view];
    _filterCollectionViewContainer.backgroundColor = [UIColor clearColor];
    [viewController didMoveToParentViewController:self];
    [_filterCollectionViewContainer setHidden:YES];
}

#pragma mark - Actions

- (IBAction)close:(id)sender
{
    [self _dismiss];
}

- (IBAction)saveImage:(UIButton *)sender
{
    [sender setEnabled:NO];
    [self _saveToCameraRoll:nil];
    [self _dismiss];
}

- (IBAction)toggleFilters:(UIButton *)sender
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         sender.transform = CGAffineTransformRotate(sender.transform, M_PI_4);
                     }];
    [_filterCollectionViewContainer setHidden:!_filterCollectionViewContainer.hidden];
}

#pragma mark - FCFilterCollectionViewControllerDelegate

- (void)filterCollectionViewControllerDidUpdate:(FCFilterCollectionViewController *)filterCollectionViewController
{
    [self _processPipeline];
}

#pragma mark - Private Methods

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_processPipeline
{
    [_imageProcessingPipeline processImage:_image
                                completion:^(CIImage *outputImage) {
                                    UIImage *uiImage = [UIImage getImageFromCIImage:outputImage];
                                    self->_uiImage = uiImage;
                                    self->_imageView.image = uiImage;
                                }];
}

- (void)_saveToCameraRoll:(dispatch_block_t)completion
{
    if (!_uiImage) {
        NSAssert(NO, @"UIImage must not be nil, in order to save to camera roll");
        if (completion) {
            completion();
        }
        return;
    }
    [_mediaExporter saveImageToCameraRoll:_uiImage completion:completion];
}

@end
