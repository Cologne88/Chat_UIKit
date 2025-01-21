#import "TUIConversationServiceLoader_Minimalist.h"
#import <TUIConversation/TUIConversation-Swift.h>

@implementation TUIConversationServiceLoader_Minimalist
+ (void)load {
    [TUIConversationObjectFactory_Minimalist swiftLoad];
    [TUIConversationService_Minimalist swiftLoad];
}
@end
