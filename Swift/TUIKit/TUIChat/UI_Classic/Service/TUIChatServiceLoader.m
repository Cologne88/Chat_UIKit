#import "TUIChatServiceLoader.h"
#import <TUIChat/TUIChat-Swift.h>

@implementation TUIChatServiceLoader
+ (void)load {
    [TUIChatBaseDataProvider swiftLoad];
    [TUIEmojiMeditorProtocolProvider swiftLoad];
    [TUIChatExtensionObserver swiftLoad];
    [TUIChatObjectFactory swiftLoad];
    [TUIChatService swiftLoad];
    [TUIMessageCellConfig swiftLoad];
}
@end
