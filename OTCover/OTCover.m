//
//  OTCover.m
//  OTMediumCover
//
//  Created by yechunxiao on 14-9-21.
//  Copyright (c) 2014年 yechunxiao. All rights reserved.
//

#import "OTCover.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

@interface OTCover()

@property (nonatomic, strong) NSMutableArray *blurImages;

@end

@implementation OTCover

- (OTCover*)initTableViewOTCoverWithHeaderImage:(UIImage*)headerImage{
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self = [[OTCover alloc] initWithFrame:bounds];
    
    self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, OTCoverViewHeight)];
    [self.headerImageView setImage:headerImage];
    [self addSubview:self.headerImageView];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.frame];
    self.tableView.tableHeaderView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, OTCoverViewHeight)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.tableView];
    
    self.blurImages = [[NSMutableArray alloc] init];
    [self prepareForBlurImages];
    
    return self;
}

- (OTCover*)initWithHeaderImage:(UIImage*)headerImage withContentHeight:(CGFloat)contentHeight{
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self = [[OTCover alloc] initWithFrame:bounds];
    
    self.headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, OTCoverViewHeight)];
    [self.headerImageView setImage:headerImage];
    [self addSubview:self.headerImageView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
    
    self.scrollContentView = [[UIView alloc] initWithFrame:CGRectMake(0, OTCoverViewHeight, bounds.size.width, contentHeight)];
    self.scrollContentView.backgroundColor = [UIColor whiteColor];
    self.scrollView.contentSize = self.scrollContentView.frame.size;
    [self.scrollView addSubview:self.scrollContentView];
   
    self.blurImages = [[NSMutableArray alloc] init];
    [self prepareForBlurImages];
    
    return self;
}

- (void)setHeaderImage:(UIImage *)headerImage{
    [self.headerImageView setImage:headerImage];
    [self.blurImages removeAllObjects];
    [self prepareForBlurImages];
}

- (void)prepareForBlurImages
{
    CGFloat factor = 0.1;
    [self.blurImages addObject:self.headerImageView.image];
    for (NSUInteger i = 0; i < 30; i++) {
        [self.blurImages addObject:[self.headerImageView.image boxblurImageWithBlur:factor]];
        factor+=0.04;
    }
}

-(void)scrollViewDidScroll:(UIScrollView*)scrollView{
    CGFloat offset = scrollView.contentOffset.y;
    
    if (scrollView.contentOffset.y > 0) {
        
        NSInteger index = offset / 10;
        if (index < 0) {
            index = 0;
        }
        else if(index >= self.blurImages.count) {
            index = self.blurImages.count - 1;
        }
        UIImage *image = self.blurImages[index];
        if (self.headerImageView.image != image) {
            [self.headerImageView setImage:image];
            
        }
        scrollView.backgroundColor = [UIColor clearColor];
        
    }
    else {
        self.headerImageView.frame = CGRectMake(offset,0, 320+ (-offset) * 2, OTCoverViewHeight + (-offset));
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %d",indexPath.row + 1];
    
    return cell;
}

@end

@implementation UIImage (Blur)

-(UIImage *)boxblurImageWithBlur:(CGFloat)blur {
    
    NSData *imageData = UIImageJPEGRepresentation(self, 1); // convert to jpeg
    UIImage* destImage = [UIImage imageWithData:imageData];
    
    
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = destImage.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    
    //create vImage_Buffer with data from CGImageRef
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    // Create a third buffer for intermediate processing
    void *pixelBuffer2 = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data = pixelBuffer2;
    outBuffer2.width = CGImageGetWidth(img);
    outBuffer2.height = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //perform convolution
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    error = vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             (CGBitmapInfo)kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    free(pixelBuffer2);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}

@end
