//
//  BNRRecordScreen.m
//  RecordScreen
//
//  Created by JustinYang on 2021/3/20.
//

#import "BNRRecordScreen.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
@interface BNRRecordScreen()
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic,strong) CADisplayLink *link;
@property (nonatomic,weak) UIView *recordView;
@property (nonatomic,assign) BOOL isStart;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic,copy) NSString *path;
@end
@implementation BNRRecordScreen
-(void)startRecordWithFileName:(NSString *)name recordView:(UIView *)view{
    self.recordView = view;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths.firstObject stringByAppendingPathComponent:name];
    
    self.path = path;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:&err];
    }
    NSAssert(err == nil, @"删除已经存在的路径文件出错");
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4 error:&err];
    NSAssert(err == nil, @"出错了");
    
    CGSize size = view.frame.size;
    NSDictionary * videoProps = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:size.height*size.width*8],AVVideoAverageBitRateKey, nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecTypeH264,
                                   AVVideoCodecKey,[NSNumber numberWithInt:size.width],
                                   AVVideoWidthKey,[NSNumber numberWithInt:size.height],
                                   AVVideoHeightKey,videoProps,
                                   AVVideoCompressionPropertiesKey,nil];
    self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    self.writerInput.expectsMediaDataInRealTime = YES;
    NSDictionary *sourcePixelBuffAttr = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey, nil];
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:sourcePixelBuffAttr];
    
    NSAssert([self.videoWriter canAddInput:self.writerInput], @"出错了");
    [self.videoWriter addInput:self.writerInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
    
 
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(record)];
    [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}
-(void)record{
    if (self.recordView == nil) {
        return;
    }
    
    if (self.isStart == NO) {
        self.startTime = self.link.timestamp;
        self.isStart = YES;
    }
    @autoreleasepool {
        CGSize size = self.recordView.frame.size;
        
        NSDictionary *options = @{(NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                                  (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                                  (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]};
        
        CVPixelBufferRef pixelBuffer = NULL;
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height,
                                              kCVPixelFormatType_32ARGB,
                                                           (__bridge CFDictionaryRef) options,
                                              &pixelBuffer);
        NSAssert(status == kCVReturnSuccess && pixelBuffer != NULL, @"创建CVPixelBufferRef出错");
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        GLubyte *data = CVPixelBufferGetBaseAddress(pixelBuffer);
        
        CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        CGContextRef context =
            CGBitmapContextCreate(data,
                                  size.width, size.height,
                                  8, bytesPerRow,
                                  colourSpace,
                                  kCGImageAlphaPremultipliedFirst);
        
        CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
        CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, size.height);
        CGContextConcatCTM(context, flipVertical);

        
        CGColorSpaceRelease(colourSpace);

        [self.recordView.layer.presentationLayer renderInContext:context];
        
        if ([self.writerInput isReadyForMoreMediaData]) {
            CMTime time = CMTimeMake((int64_t)((self.link.timestamp - self.startTime) * 1000), 1000);
            [self.adaptor appendPixelBuffer:pixelBuffer withPresentationTime:time];
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        CVPixelBufferRelease(pixelBuffer);
    }
}
-(void)stopRecord{
    [self.link invalidate];
    self.link = nil;
    [self.writerInput markAsFinished];
    __weak typeof(self) weakSelf = self;
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"写入视频成功");
        if (weakSelf) {
            [weakSelf clear];
        }
        
    }];
}
-(void)saveVideoToAlbum{
    NSFileManager *fileManager = [NSFileManager defaultManager];
   
    if (![fileManager fileExistsAtPath:self.path]) {
        NSLog(@"没有视频");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.path)) {
            UISaveVideoAtPathToSavedPhotosAlbum(self.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    });
}
-(void)clear{
    self.videoWriter = nil;
    self.writerInput = nil;
    self.adaptor = nil;
    self.isStart = NO;
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存相册出错");
    }
}
-(bool)isRecording{
    return self.isStart;
}
-(void)dealloc{
    if (self.link != nil) {
        [self.link invalidate];
        self.link = nil;
    }
}
@end

