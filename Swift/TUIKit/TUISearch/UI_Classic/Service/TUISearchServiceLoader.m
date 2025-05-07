#import "TUISearchServiceLoader.h"
#import <TUISearch/TUISearch-Swift.h>

@implementation TUISearchServiceLoader
+ (void)load {
    [TUISearchExtensionObserver swiftLoad];
    [TUISearchService swiftLoad];
}
@end
