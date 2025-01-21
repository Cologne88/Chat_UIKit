#import "AppDelegateLoader.h"

@implementation AppDelegateLoader

+ (void)load {
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(swiftLoad)]) {
        [self performSelector:@selector(swiftLoad)];
    }
}
@end
