#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import <objc/message.h>
#define UIView NHBHostView
#define NHB_GRABBER "NHBHostGrabber"
#define NHB_COVERSHEET "NHBHostCoverSheet"
#define NHB_LUMA "NHBHostLuma"
#define NHB_STATIC "NHBHostStatic"
#define NHB_AOD "NHBHostAlwaysOn"
#define NHB_AFFORDANCE "NHBHostAffordance"
static NSString *NHBHostLogPath;
static NSUInteger allocatedViews,deallocatedViews,alphaCalls,hookCount;
@interface NHBHostView:NSObject {
    CGFloat _alpha;
}
@property(nonatomic) CGFloat alpha;
@property(nonatomic) CGRect frame;
@property(nonatomic) BOOL hidden;
@property(nonatomic) BOOL userInteractionEnabled;
@property(nonatomic) NSUInteger gestureToken;
@end
@implementation NHBHostView
- (id)init {self=[super init];if(self){allocatedViews++;_alpha=1;self.frame=CGRectMake(2,3,144,5);self.gestureToken=0x1234;self.userInteractionEnabled=YES;}return self;}
- (CGFloat)alpha {return _alpha;}
- (void)setAlpha:(CGFloat)value {alphaCalls++;_alpha=value;}
- (void)dealloc {deallocatedViews++;[super dealloc];}
@end
static void MSHookMessageEx(Class cls,SEL selector,IMP hook,IMP *original) {
    Method method=class_getInstanceMethod(cls,selector);IMP previous=method_getImplementation(method);
    if(class_addMethod(cls,selector,hook,method_getTypeEncoding(method)))*original=previous;
    else *original=method_setImplementation(class_getInstanceMethod(cls,selector),hook);
    hookCount++;
}
