#import "TUIContactServiceLoader.h"
#import <TUIContact/TUIContact-Swift.h>

@implementation TUIContactServiceLoader

+ (void)load {
    [TUIContactExtensionObserver swiftLoad];
    [TUIContactObjectFactory swiftLoad];
    [TUIContactService swiftLoad];
}
@end
