#import "GoogleCastManager.h"
#import "GoogleCast.h"
#import <React/RCTBridge.h>
#import <React/UIView+React.h>
#import <Foundation/Foundation.h>

@implementation GoogleCastManager

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (UIView *)view {
    
    CGRect frame = CGRectMake(0, 0, 24, 24);
    GCKUICastButton *castButton = [[GCKUICastButton alloc] initWithFrame:frame];
    castButton.tintColor = [UIColor whiteColor];
    castButton.triggersDefaultCastDialog = NO;    
    return castButton;
}
@end


