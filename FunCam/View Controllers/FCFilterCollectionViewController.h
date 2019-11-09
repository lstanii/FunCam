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

#import <UIKit/UIKit.h>

@class FCImageProcessorFilter;
@class FCImageProcessorPipeline;
@class FCFilterCollectionViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol FCFilterCollectionViewControllerDelegate <NSObject>

- (void)filterCollectionViewControllerDidUpdate:(FCFilterCollectionViewController *)filterCollectionViewController;

@end

@interface FCFilterCollectionViewController : UICollectionViewController

@property (nonatomic, strong, readwrite) NSArray<FCImageProcessorFilter *> *availableFilters;
@property (nonatomic, strong, readwrite) NSArray<FCImageProcessorFilter *> *activeFilters;
@property (nonatomic, nonnull, readwrite) FCImageProcessorPipeline *imageProcessorPipeline;

@property (nonatomic, weak, nullable) id<FCFilterCollectionViewControllerDelegate> filterCollectionViewControllerDelegate;

- (void)resume;

@end

NS_ASSUME_NONNULL_END
