#import "TUIVoiceToTextLoader.h"
#import <TUIVoiceToTextPlugin/TUIVoiceToTextPlugin-Swift.h>

@implementation TUIVoiceToTextLoader

+ (void)load {
    [TUIVoiceToTextExtensionObserver swiftLoad];
}

@end
