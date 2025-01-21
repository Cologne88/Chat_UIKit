//
//  THelper.m
//  TUIKit
//
//  Created by lynx on 2024/11/1.
//  Copyright © 2024 Tencent. All rights reserved.
//

#import "TUISwift.h"
#import <ReactiveObjC/ReactiveObjC.h>

@implementation TUISwift
+ (UIColor *)tuiDemoDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TUIDemoDynamicColor(colorKey, defaultColor);
}

+ (UIColor *)tuiConversationDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TUIConversationDynamicColor(colorKey, defaultColor);
}

+ (UIImage *)tuiDemoDynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    return TUIDemoDynamicImage(imageKey, defaultImage);
}

+ (UIImage *)tuiCoreDynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    return TUICoreDynamicImage(imageKey, defaultImage);
}

+ (UIImage *)timCommonDynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    return TIMCommonDynamicImage(imageKey, defaultImage);
}

+ (UIImage *)tuiContactDynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    return TUIContactDynamicImage(imageKey, defaultImage);
}

+ (UIColor *)timCommonDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TIMCommonDynamicColor(colorKey, defaultColor);
}

+ (UIColor *)tuiDynamicColor:(NSString *)colorKey module:(TUIThemeModule)module defaultColor:(NSString *)defaultColor {
    return TUIDynamicColor(colorKey, module, defaultColor);
}

+ (UIImage *)defaultGroupAvatarImageByGroupType:(NSString *)groupType {
    return DefaultGroupAvatarImageByGroupType(groupType);
}

+ (NSString *)tuiDemoImagePath:(NSString *)path {
    return TUIDemoImagePath(path);
}

+ (NSString *)tuiDemoImagePath_Minimalist:(NSString *)path{
    return TUIDemoImagePath_Minimalist(path);
}

+ (NSString *)tuiCoreImagePath:(NSString *)path {
    return TUICoreImagePath(path);
}

+ (NSString *)timCommonImagePath:(NSString *)path {
    return TIMCommonImagePath(path);
}

+(NSString *)tuiConversationImagePath:(NSString *)imageName {
    return TUIConversationImagePath(imageName);
}

+(UIImage *)tuiConversationDynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    return TUIConversationDynamicImage(imageKey, defaultImage);
}

+(NSString *)timCommonLocalizableString:(NSString *)str {
    return [TUIGlobalization getLocalizedStringForKey:str bundle:TIMCommonLocalizableBundle];
}

+ (NSString *)tuiChatLocalizableString:(NSString *)str {
    return [TUIGlobalization getLocalizedStringForKey:str bundle:TUIChatLocalizableBundle];
}

+ (UIImage *)defaultAvatarImage {
    return DefaultAvatarImage;
}

+ (UIImage *)tuiCoreBundleThemeImage:(NSString *)imageKey defaultImageName:(NSString *)defaultImageName {
    return TUICoreBundleThemeImage(imageKey, defaultImageName);
}

+ (UIImage *)timCommonBundleImage:(NSString *)key {
    return TIMCommonBundleImage(key);
}

+ (UIImage *)tuiConversationCommonBundleImage:(NSString *)key {
    return TUIConversationCommonBundleImage(key);
}

+ (UIColor *)tuiChatDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TUIChatDynamicColor(colorKey, defaultColor);
}

+ (UIColor *)tuiContactDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TUIContactDynamicColor(colorKey, defaultColor);
}

+ (UIColor *)RGB:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b {
    return RGB(r, g, b);
}

+ (UIColor *)RGB:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a {
    return RGBA(r, g, b, a);
}

+ (CGFloat)kScale375:(CGFloat)x {
    return kScale375(x);
}

+ (CGFloat)kScale390:(CGFloat)x {
    return kScale390(x);
}

+ (UIImage *)tuiDynamicImage:(NSString *)imageKey themeModule:(TUIThemeModule)themeModule defaultImg:(UIImage *)defaultImage {
    return TUIDynamicImage(imageKey, themeModule, defaultImage);
}

+ (NSString *)tuiContactImagePath:(NSString *)imageName {
    return TUIContactImagePath(imageName);
}

+ (NSString *)tuiContactImagePath_Minimalist:(NSString *)imageName {
    return TUIContactImagePath_Minimalist(imageName);
}

+ (void)tuiRegisterThemeResourcePath:(NSString *)path themeModule:(TUIThemeModule)themeModule {
    TUIRegisterThemeResourcePath(path, themeModule);
}

+ (NSString *)tuiBundlePath:(NSString *)name key:(NSString *)key {
    return TUIBundlePath(name, key);
}

+ (NSString *)tuiChatImagePath_Minimalist:(NSString *)name {
    return TUIChatImagePath_Minimalist(name);
}

+ (NSString *)tuiChatImagePath:(NSString *)name {
    return TUIChatImagePath(name);
}

+ (NSString *)tuiConversationImagePath_Minimalist:(NSString *)imageName {
    return TUIConversationImagePath_Minimalist(imageName);
}

+ (BOOL)isRTL {
    return isRTL();
}

+ (UIImage *)tuiChatBundleThemeImage:(NSString *)imageName defaultImage:(NSString *)defaultImage {
    return TUIChatBundleThemeImage(imageName, defaultImage);
}

+ (CGFloat)tTextView_TextView_Height_Min {
    return TTextView_TextView_Height_Min;
}

+ (CGFloat)tTextView_TextView_Height_Max {
    return 80;
}

+ (CGSize)timDefaultEmojiSize {
    return CGSizeMake(23, 23);
}

+ (UIImage *)tuiChatCommonBundleImage:(NSString *)imageName {
    return TUIChatCommonBundleImage(imageName);
}

+ (UIImage *)tuiConversationBundleThemeImage:(NSString *)imageKey defaultImageName:(NSString *)defaultImageName {
    return TUIConversationBundleThemeImage(imageKey, defaultImageName);
}

+ (NSString *)tuiKit_Image_Path {
    return TUIKit_Image_Path;
}

+ (NSString *)tuiKit_Video_Path {
    return TUIKit_Video_Path;
}

+ (NSString *)tuiKit_Voice_Path {
    return TUIKit_Voice_Path;
}

+ (NSString *)tuiKit_File_Path {
    return TUIKit_File_Path;
}

+ (NSString *)tuiKit_DB_Path {
    return TUIKit_DB_Path;
}

+ (CGSize)tuiPopView_Arrow_Size {
    return TUIPopView_Arrow_Size;
}

+ (CGFloat)statusBar_Height {
    return StatusBar_Height;
}

+ (CGFloat)navBar_Height {
    return NavBar_Height;
}

+ (CGFloat)tabBar_Height {
    return TabBar_Height;
}

+ (CGFloat)screen_Width {
    return Screen_Width;
}

+ (CGFloat)screen_Height {
    return Screen_Height;
}

+ (CGFloat)bottom_SafeHeight {
    return Bottom_SafeHeight;
}

+ (NSString *)tuiKitLocalizableString:(NSString *)key {
    return [TUIGlobalization getLocalizedStringForKey:key bundle:TUIKitLocalizableBundle];
}

+ (CGFloat)tTextView_Height {
    return TTextView_Height;
}

+ (CGFloat)tTextMessageCell_Text_Width_Max {
    return TTextMessageCell_Text_Width_Max;
}

+ (CGFloat)tFaceMessageCell_Image_Height_Max {
    return TFaceMessageCell_Image_Height_Max;
}

+ (CGFloat)tFaceMessageCell_Image_Width_Max {
    return TFaceMessageCell_Image_Width_Max;
}

+ (UIColor *)tImageMessageCell_Progress_Color {
    return TImageMessageCell_Progress_Color;
}

+ (CGFloat)tMenuCell_Margin {
    return TMenuCell_Margin;
}

+ (CGFloat)tMergeMessageCell_Width_Max {
    return TMergeMessageCell_Width_Max;
}

+ (CGFloat)tMergeMessageCell_Height_Max {
    return TMergeMessageCell_Height_Max;
}

+ (CGSize)tVideoMessageCell_Play_Size {
    return TVideoMessageCell_Play_Size;
}

+ (UIColor *)tVideoMessageCell_Progress_Color {
    return TVideoMessageCell_Progress_Color;
}

+ (NSString *)tuiChatFaceImagePath:(NSString *)imageName {
    return TUIChatFaceImagePath(imageName);
}

+ (UIColor *)tControllerBackgroundColor {
    return TController_Background_Color;
}

+ (UIColor *)tControllerBackgroundColorDark{
    return TController_Background_Color_Dark;
}

+ (void)racObserveTUIConfig_displayOnlineStatusIcon:(UITableViewCell *)cell subscribeNext:(void(^)(id))subscribeNext {
    [[RACObserve(TUIConfig.defaultConfig, displayOnlineStatusIcon) takeUntil:cell.rac_prepareForReuseSignal] subscribeNext:^(id _Nullable x) {
        if (subscribeNext) {
            subscribeNext(x);
        }
    }];
}

+ (BOOL)is_IPhoneX {
    return Is_IPhoneX;
}

+ (CGFloat)tFaceView_Margin {
    return TFaceView_Margin;
}

+ (CGFloat)tFaceView_Page_Padding {
    return TFaceView_Page_Padding;
}

+ (NSString *)tFaceCell_ReuseId {
    return TFaceCell_ReuseId;
}

+ (CGFloat)tLine_Height {
    return TLine_Heigh;
}

+ (CGFloat)tFaceView_Page_Height {
    return TFaceView_Page_Height;
}

+ (NSString *)tFileMessageCell_ReuseId {
    return TFileMessageCell_ReuseId;
}

+ (NSString *)tImageMessageCell_ReuseId {
    return TImageMessageCell_ReuseId;
}

+ (UIImage *)tuiChatDynamicImage:(NSString *)imageKey defaultImage:(UIImage *)defaultImage {
    return TUIChatDynamicImage(imageKey, defaultImage);
}

+ (NSString *)tuiTranslationThemePath {
    return TUITranslationThemePath;
}

+ (UIColor *)tuiTranslationDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TUITranslationDynamicColor(colorKey, defaultColor);
}

+ (UIImage *)tuiTranslationBundleThemeImage:(NSString *)imageName defaultImage:(NSString *)defaultImage {
    return TUITranslationBundleThemeImage(imageName, defaultImage);
}

+ (NSString *)tuiVoiceToTextThemePath {
    return TUIVoiceToTextThemePath;
}

+ (UIColor *)tuiVoiceToTextDynamicColor:(NSString *)colorKey defaultColor:(NSString *)defaultColor {
    return TUIVoiceToTextDynamicColor(colorKey, defaultColor);
}

+ (UIImage *)tuiVoiceToTextBundleThemeImage:(NSString *)imageName defaultImage:(NSString *)defaultImage {
    return TUIVoiceToTextBundleThemeImage(imageName, defaultImage);
}

+ (CGSize)tFileMessageCell_Container_Size {
    return TFileMessageCell_Container_Size;
}

+ (UIImage *)timCommonBundleThemeImage:(NSString *)imageName defaultImage:(NSString *)defaultImage {
    return TIMCommonBundleThemeImage(imageName, defaultImage);
}

+ (CGFloat)tImageMessageCell_Image_Width_Max {
    return TImageMessageCell_Image_Width_Max;
}

+ (CGFloat)tImageMessageCell_Image_Height_Max {
    return TImageMessageCell_Image_Height_Max;
}

+ (CGFloat)tVideoMessageCell_Image_Height_Max {
    return TVideoMessageCell_Image_Height_Max;
}

+ (CGFloat)tVideoMessageCell_Image_Width_Max {
    return TVideoMessageCell_Image_Width_Max;
}

+ (CGFloat)tVoiceMessageCell_Back_Width_Min {
    return TVoiceMessageCell_Back_Width_Min;
}

+ (CGFloat)tVoiceMessageCell_Back_Width_Max {
    return TVoiceMessageCell_Back_Width_Max;
}

+ (CGSize)tVoiceMessageCell_Duration_Size {
    return TVoiceMessageCell_Duration_Size;
}

+ (CGFloat)tVoiceMessageCell_Max_Duration {
    return TVoiceMessageCell_Max_Duration;
}

+ (CGSize)tTextView_Button_Size {
    return TTextView_Button_Size;
}

+ (CGFloat)tTextView_Margin {
    return TTextView_Margin;
}

+ (NSString *)tuiChatThemePath {
    return TUIChatThemePath;
}

+ (UIImage *)tuiContactCommonBundleImage:(NSString *)imageName {
    return TUIContactCommonBundleImage(imageName);
}

+ (CGFloat)tConversationCell_Height {
    return TConversationCell_Height;
}

+ (CGSize)tPersonalCommonCell_Image_Size {
    return TPersonalCommonCell_Image_Size;
}

+ (CGSize)tGroupMemberCell_Head_Size {
    return TGroupMemberCell_Head_Size;
}
@end
