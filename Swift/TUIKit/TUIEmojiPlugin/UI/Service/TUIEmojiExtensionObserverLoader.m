#import "TUIEmojiExtensionObserverLoader.h"
#import <TUIEmojiPlugin/TUIEmojiPlugin-Swift.h>

@implementation TUIEmojiExtensionObserverLoader
+ (void)load {
    [TUIEmojiExtensionObserver swiftLoad];
}
@end
