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

#import "FCMediaExporter.h"

@implementation FCMediaExporter {
    dispatch_block_t _completion;
    dispatch_queue_t _queue;
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_queue_attr_t attr =
            dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
        _queue = dispatch_queue_create("com.fun.camera.media.exporter", attr);
    }
    return self;
}

#pragma mark - Public Methods

- (void)saveImageToCameraRoll:(UIImage *)image completion:(dispatch_block_t)completion
{
    dispatch_async(_queue, ^{
        self->_completion = completion;
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(_image:didFinishSavingWithError:contextInfo:), nil);
    });
}

#pragma mark - Private Methods

- (void)_image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (_completion) {
        _completion();
    }
}

@end
