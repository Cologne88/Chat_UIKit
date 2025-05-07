#import "TIMCommonLoader.h"
#import <TIMCommon/TIMCommon-Swift.h>

@implementation TIMCommonLoader
+ (void)load {
    [TIMConfig swiftLoad];
    [UIButton swiftLoad];
    [UINavigationController swiftLoad];
}
@end
