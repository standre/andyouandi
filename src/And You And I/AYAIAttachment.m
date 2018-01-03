//
//  AYAIAttachment.m
//  And You And I
//
//  Created by sga on 21.09.15.
//  Copyright © 2015 Stephan André. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYAIAttachment.h"
#import "UIImage+Alpha.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

@implementation AYAIAttachment

@synthesize iCloudDocument, comment, realfilename, realfiletype, data;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    self.comment = [decoder decodeObjectForKey:@"comment"];
    self.realfilename = [decoder decodeObjectForKey:@"realfilename"];
    self.filename = [decoder decodeObjectForKey:@"filename"];
    self.realfiletype = [decoder decodeObjectForKey:@"realfiletype"];
    self.data = [decoder decodeObjectForKey:@"data"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.comment forKey:@"comment"];
    [encoder encodeObject:self.filename forKey:@"filename"];
    [encoder encodeObject:self.realfilename forKey:@"realfilename"];
    [encoder encodeObject:self.realfiletype forKey:@"realfiletype"];
    [encoder encodeObject:self.data forKey:@"data"];
}

+ (UIImage *)thumbnailFromData:(NSData *)data :(NSString *)type
{
    UIImage *image = [self thumbnailFromImage:data];
    if (image == nil)
    {
        image = [self thumbnailFromPDF:data];
    }
    if (image == nil)
    {
        image = [self thumbnailFromString:type];
    }
    
    return [image thumbnailImage:80 transparentBorder:3 cornerRadius:5 interpolationQuality:0];
}

+ (UIImage *)thumbnailFromImage:(NSData *)data
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    UIImage *image = [UIImage imageWithData:data scale:screenScale];
    
    return image;
}

+ (UIImage *)thumbnailFromPDF:(NSData *)data
{
    UIImage* image = nil;
    CFDataRef myPDFData        = (__bridge CFDataRef)data;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
    CGPDFDocumentRef pdf       = CGPDFDocumentCreateWithProvider(provider);
    if (pdf != nil)
    {
        CGRect aRect = CGRectMake(0, 0, 78, 78);
        UIGraphicsBeginImageContext(aRect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, 0.0, aRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetGrayFillColor(context, 1.0, 1.0);
        CGContextFillRect(context, aRect);
        CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);
        CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFMediaBox, aRect, 0, true);
        CGContextConcatCTM(context, pdfTransform);
        CGContextDrawPDFPage(context, page);
        image = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRestoreGState(context);
        UIGraphicsEndImageContext();
        CGPDFDocumentRelease(pdf);
    }
    
    return image;
}

+ (UIImage *)thumbnailFromString:(NSString *)string
{
    UIImage *image = [UIImage imageNamed:@"AndYouAndI"];
    CGSize size = CGSizeMake(80, 80);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, size.width, size.height);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    CGContextSetAlpha(ctx, 0.2);
    CGContextDrawImage(ctx, area, image.CGImage);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSArray* parts = [string componentsSeparatedByString: @"."];
    NSString* text = [parts objectAtIndex: [parts count]-1];
    text = [text stringByReplacingOccurrencesOfString:@"-" withString:@"\n"];
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0);
    UIFont *font = [UIFont systemFontOfSize:12];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle,
                                  NSForegroundColorAttributeName: [UIColor blueColor]};
    CGPoint point = CGPointMake(image.size.width/2 - [text sizeWithAttributes:attributes].width/2,
                                image.size.height/2 - [text sizeWithAttributes:attributes].height/2);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, [text sizeWithAttributes:attributes].width, [text sizeWithAttributes:attributes].height);
    [text drawInRect:CGRectIntegral(rect) withAttributes:attributes];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
