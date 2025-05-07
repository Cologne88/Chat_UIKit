#import "TUISearchServiceLoader_Minimalist.h"
#import <TUISearch/TUISearch-Swift.h>

@implementation TUISearchServiceLoader_Minimalist
+ (void)load {
    [TUISearchExtensionObserver_Minimalist swiftLoad];
    [TUISearchService_Minimalist swiftLoad];
}
@end
