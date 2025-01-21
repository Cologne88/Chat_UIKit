#import "TUIChatServiceLoader_Minimalist.h"
#import <TUIChat/TUIChat-Swift.h>

@implementation TUIChatServiceLoader_Minimalist
+ (void)load {
    [TUIChatBaseDataProvider swiftLoad];
    [TUIEmojiMeditorProtocolProvider swiftLoad];
    [TUIChatExtensionObserver_Minimalist swiftLoad];
    [TUIChatObjectFactory_Minimalist swiftLoad];
    [TUIChatService_Minimalist swiftLoad];
    [TUIMessageCellConfig_Minimalist swiftLoad];
}
@end
