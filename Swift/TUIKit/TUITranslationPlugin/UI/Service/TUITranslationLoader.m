#import "TUITranslationLoader.h"
#import <TUITranslationPlugin/TUITranslationPlugin-Swift.h>

@implementation TUITranslationLoader

+ (void)load {
    [TUITranslationExtensionObserver swiftLoad];
}

@end
