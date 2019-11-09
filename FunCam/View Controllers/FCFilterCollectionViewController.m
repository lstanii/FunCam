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

#import "FCFilterCollectionViewController.h"

#import "FCConstants.h"
#import "FCImageProcessorPipeline.h"
#import "FCFilterViewCell.h"

@interface FCFilterCollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource,
                                                UICollectionViewDelegateFlowLayout>
@end

@implementation FCFilterCollectionViewController {
    NSMutableSet<FCImageProcessorFilter *> *_activeFilters;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([FCFilterViewCell class]) bundle:nil]
          forCellWithReuseIdentifier:FCFilterCollectionViewCellReuseID];

    _activeFilters = _activeFilters ?: [NSMutableSet new];
}

- (void)_toggleFilter:(FCImageProcessorFilter *)filter
{
    if ([_activeFilters containsObject:filter]) {
        [_activeFilters removeObject:filter];
    } else {
        [_activeFilters addObject:filter];
    }
    [self resume];
}

- (NSArray<FCImageProcessorFilter *> *)activeFilters
{
    return _activeFilters.allObjects;
}

- (void)setActiveFilters:(NSArray<FCImageProcessorFilter *> *)activeFilters
{
    _activeFilters = [NSMutableSet setWithArray:activeFilters];
    [self.collectionView reloadData];
}

- (void)resume
{
    [self.imageProcessorPipeline setFilters:_activeFilters.allObjects];
}

// UICollectionViewDataSource

- (nonnull FCFilterViewCell *)collectionView:(nonnull UICollectionView *)collectionView
                      cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    FCFilterViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:FCFilterCollectionViewCellReuseID
                                                                       forIndexPath:indexPath];
    FCImageProcessorFilter *filter = [_availableFilters objectAtIndex:indexPath.item];
    [cell setSelected:[_activeFilters containsObject:filter]];
    [cell applyFilter:filter];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _availableFilters.count;
}

// UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self _toggleFilter:[_availableFilters objectAtIndex:indexPath.item]];
    [collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
    [self.filterCollectionViewControllerDelegate filterCollectionViewControllerDidUpdate:self];
}

// UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CGRectGetHeight(collectionView.frame), CGRectGetHeight(collectionView.frame));
}

@end
