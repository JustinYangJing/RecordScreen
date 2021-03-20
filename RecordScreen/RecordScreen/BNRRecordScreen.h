//
//  BNRRecordScreen.h
//  RecordScreen
//
//  Created by JustinYang on 2021/3/20.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

/// 请自行持有该对象
@interface BNRRecordScreen : NSObject

@property (nonatomic,readonly) bool isRecording;
/// 开始录屏函数
/// @param name 文件名称需要带.mp4的后缀
/// @param view 要录的view, 可以传入uiwidow，但在录制过程中，要保证view(window)的frame大小不变
-(void)startRecordWithFileName:(NSString *)name recordView:(UIView *)view;

/// 停止录制
-(void)stopRecord;

/// 视频存到相册，请确保info.plist加入了Privacy - Photo Library Additions Usage Description的说明
-(void)saveVideoToAlbum;


@end

NS_ASSUME_NONNULL_END
