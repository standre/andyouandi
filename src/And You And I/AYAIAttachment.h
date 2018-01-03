//
//  AYAIAttachment.h
//  And You And I
//
//  Created by sga on 21.09.15.
//  Copyright © 2015 Stephan André. All rights reserved.
//

@interface AYAIAttachment : NSObject <NSCoding>
@property (readwrite, nonatomic) BOOL iCloudDocument;
@property (readwrite, nonatomic) BOOL showDetails;
// part of ayaix file
@property (strong, nonatomic) NSString *comment;
@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) NSString *realfilename;
@property (strong, nonatomic) NSString *realfiletype;
// generated on the fly
@property (readwrite, nonatomic) NSURL *localFileURL;
@property (readwrite, nonatomic) NSUInteger realfilesize;
@property (strong, nonatomic) UIImage *thumbnail;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

+ (UIImage *)thumbnailFromData:(NSData *)data :(NSString *)type;
+ (UIImage *)thumbnailFromImage:(NSData *)data;
+ (UIImage *)thumbnailFromPDF:(NSData *)data;
+ (UIImage *)thumbnailFromString:(NSString *)string;

@end
