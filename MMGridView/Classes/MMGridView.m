//
// Copyright (c) 2010-2011 René Sprotte, Provideal GmbH
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "MMGridView.h"


@interface MMGridView()

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic) NSUInteger currentPageIndex;
@property (nonatomic) NSUInteger numberOfPages;

- (void)createSubviews;
- (void)cellWasSelected:(MMGridViewCell *)cell;
- (void)cellWasDoubleTapped:(MMGridViewCell *)cell;
- (void)updateCurrentPageIndex;
@end


@implementation MMGridView

@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize numberOfRows;
@synthesize numberOfColumns;
@synthesize cellMargin;
@synthesize currentPageIndex;
@synthesize numberOfPages;


- (void)dealloc
{
    [scrollView release];
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
        [self createSubviews];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self createSubviews];
    }
    
    return self;
}


- (void)createSubviews
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; 
    self.contentMode = UIViewContentModeRedraw;
    
    self.cellMargin = 3;
    self.numberOfRows = 3;
    self.numberOfColumns = 2;
    self.currentPageIndex = 0;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectNull];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.scrollView.alwaysBounceHorizontal = NO;
    self.scrollView.alwaysBounceVertical = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    [self addSubview:self.scrollView];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


- (void)setDataSource:(id<MMGridViewDataSource>)aDataSource
{
    dataSource = aDataSource;
    [self reloadData];
}


- (void)setNumberOfColumns:(NSUInteger)value
{
    numberOfColumns = value;
    [self reloadData];
}


- (void)setNumberOfRows:(NSUInteger)value
{
    numberOfRows = value;
    [self reloadData];
}


- (void)setCellMargin:(NSUInteger)value
{
    cellMargin = value;
    [self reloadData];
}


- (NSUInteger)numberOfPages
{
    NSUInteger numberOfCells = [self.dataSource numberOfCellsInGridView:self];
    NSUInteger cellsPerPage = self.numberOfColumns * self.numberOfRows;
    return (uint)(ceil((float)numberOfCells / (float)cellsPerPage));
}


- (void)layoutSubviews
{
    self.scrollView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self reloadData];
}


- (void)reloadData
{
    for (UIView *v in self.scrollView.subviews) {
        [v removeFromSuperview];
    }
    
    if (self.dataSource) {
        NSInteger noOfCols = self.numberOfColumns;
        NSInteger noOfRows = self.numberOfRows;
        NSUInteger cellsPerPage = self.numberOfColumns * self.numberOfRows;
        
        BOOL isLandscape = UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation]) || UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
        if (isLandscape) {
            // In landscape mode switch rows and columns
            noOfRows = self.numberOfColumns;
            noOfCols = self.numberOfRows;
        }
        
        CGRect gridBounds = self.scrollView.bounds;
        CGRect cellBounds = CGRectMake(0, 0, gridBounds.size.width / (float)noOfCols, 
                                       gridBounds.size.height / (float)noOfRows);
        CGSize contentSize = CGSizeMake(self.numberOfPages * gridBounds.size.width, gridBounds.size.height);
        [self.scrollView setContentSize:contentSize];
        
        for (NSInteger i = 0; i < [self.dataSource numberOfCellsInGridView:self]; i++) {
            NSInteger page = (int)floor((float)i / (float)cellsPerPage);
            NSInteger row  = (int)floor((float)i / (float)noOfCols) - (page * noOfRows);
            if (self.numberOfPages <= self.currentPageIndex || page == self.currentPageIndex || page == self.currentPageIndex-1 || page == self.currentPageIndex+1) {
                
                MMGridViewCell *cell = [self.dataSource gridView:self cellAtIndex:i];
                [cell performSelector:@selector(setGridView:) withObject:self];
                [cell performSelector:@selector(setIndex:) withObject:[NSNumber numberWithInt:i]];            
                
                CGPoint origin = CGPointMake((page * gridBounds.size.width) + ((i % noOfCols) * cellBounds.size.width), 
                                             (row * cellBounds.size.height));
                
                CGRect f = CGRectMake(origin.x, origin.y, cellBounds.size.width, cellBounds.size.height);
                cell.frame = CGRectInset(f, self.cellMargin, self.cellMargin);
                
                [self.scrollView addSubview:cell];
                
            }
        }
    }
}


- (void)cellWasSelected:(MMGridViewCell *)cell
{
    if (delegate) {
        [delegate gridView:self didSelectCell:cell atIndex:cell.index];
    }
}


- (void)cellWasDoubleTapped:(MMGridViewCell *)cell
{
    if (delegate) {
        [delegate gridView:self didDoubleTappedCell:cell atIndex:cell.index];
    }
}


- (void)updateCurrentPageIndex
{
    CGFloat pageWidth = scrollView.frame.size.width;
    NSUInteger cpi = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.currentPageIndex = cpi;
    
    if (delegate) {
        [self.delegate gridView:self changedPageToIndex:self.currentPageIndex];
    }
}

// ----------------------------------------------------------------------------------

#pragma - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateCurrentPageIndex];
}

@end
