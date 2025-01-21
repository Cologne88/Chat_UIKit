#import "TUIConversationServiceLoader.h"
#import <TUIConversation/TUIConversation-Swift.h>

@implementation TUIConversationServiceLoader
+ (void)load {
    [TUIConversationObjectFactory swiftLoad];
    [TUIConversationService swiftLoad];
}
@end
