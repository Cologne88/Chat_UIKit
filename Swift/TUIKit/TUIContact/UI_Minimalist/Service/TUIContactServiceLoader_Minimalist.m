#import "TUIContactServiceLoader_Minimalist.h"
#import <TUIContact/TUIContact-Swift.h>

@implementation TUIContactServiceLoader_Minimalist

+ (void)load {
    [TUIContactExtensionObserver_Minimalist swiftLoad];
    [TUIContactObjectFactory_Minimalist swiftLoad];
    [TUIContactService_Minimalist swiftLoad];
}
@end
