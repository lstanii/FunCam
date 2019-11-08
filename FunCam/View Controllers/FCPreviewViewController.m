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

@implementation FCPreviewViewController {
    UIImage *_image;
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

- (void)displayImage:(UIImage *)image imageProcessingPipeline:(FCImageProcessorPipeline *)imageProcessingPipeline
{
    _imageProcessingPipeline = imageProcessingPipeline;
    _image = image;
    
}

#pragma mark - Actions

- (IBAction)close:(id)sender
{
    [self _dismiss];
}

- (IBAction)saveImage:(id)sender {
    [self _saveToCameraRoll];
    [self _dismiss];
}

#pragma mark - Private Methods

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_saveToCameraRoll {
    [_mediaExporter saveImageToCameraRoll:_image completion:^{
        
    }];
}

@end
