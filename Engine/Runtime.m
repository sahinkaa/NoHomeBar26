#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <stdatomic.h>
#include <string.h>
#if __has_feature(objc_arc)
#error This runtime must use manual reference counting to preserve owned factory returns.
#endif
#ifdef NHB_HOST_TEST
#import "HostRuntime.h"
#else
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
#import <roothide.h>
#endif
#endif

// This file deliberately uses manual reference counting. The _new... factory
// originals return owned objects. Each replacement passes that exact ownership
// through without adding a retain, release or autorelease to the returned view.
typedef id (*NHBFactoryIMP)(id,SEL);
typedef void (*NHBAlphaIMP)(id,SEL,CGFloat);
typedef struct { const char *className;const char *selector;NHBFactoryIMP original;BOOL observed; } NHBFactorySlot;
typedef struct { const char *className;NHBAlphaIMP original; } NHBAlphaSlot;
#ifndef NHB_HOST_TEST
#define NHB_GRABBER "SBHomeGrabberView"
#define NHB_COVERSHEET "CSHomeAffordanceView"
#define NHB_LUMA "MTLumaDodgePillView"
#define NHB_STATIC "MTStaticColorPillView"
#define NHB_AOD "CSAlwaysOnHomeAffordancePillView"
#define NHB_AFFORDANCE "SBFHomeAffordanceView"
#endif
static NHBFactorySlot NHBFactories[]={
    {NHB_GRABBER,"_newPillView",NULL,NO},
    {NHB_GRABBER,"_newHomeAffordanceView",NULL,NO},
    {NHB_COVERSHEET,"_newHomeAffordanceView",NULL,NO},
    {NHB_COVERSHEET,"_newStaticColorPillView",NULL,NO},
    {NHB_COVERSHEET,"_newLumaDodgePillView",NULL,NO},
    {NHB_COVERSHEET,"_newAlwaysOnHomeAffordancePillView",NULL,NO}
};
static NHBAlphaSlot NHBAlphas[]={
    {NHB_LUMA,NULL},{NHB_STATIC,NULL},{NHB_AOD,NULL},{NHB_AFFORDANCE,NULL}
};
static char NHBIndicatorKey;
static NSMutableDictionary *NHBReport;

static void NHBRecord(NSString *key,id value) {
    if(![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(),^{NHBRecord(key,value);});return; }
    if(!NHBReport)NHBReport=[[NSMutableDictionary alloc] init];
    NHBReport[key]=value;NHBReport[@"build"]=@"1.0";
#ifdef NHB_HOST_TEST
    NSString *path=NHBHostLogPath;
#elif defined(THEOS_PACKAGE_SCHEME_ROOTHIDE)
    NSString *path=jbroot(@"/var/mobile/Library/Logs/NoHomeBar26-SpringBoard.plist");
#elif defined(THEOS_PACKAGE_SCHEME_ROOTLESS)
    NSString *path=@"/var/mobile/Library/Logs/NoHomeBar26-SpringBoard.plist";
#else
#error Choose native RootHide or rootless
#endif
    if(!path)return;
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [NHBReport writeToFile:path atomically:YES];
}
static BOOL NHBHasType(Method method,NSUInteger count,const char *result,const char *argument) {
    if(!method || method_getNumberOfArguments(method)!=count)return NO;
    char *ret=method_copyReturnType(method);BOOL match=ret && !strcmp(ret,result);free(ret);
    if(!match)return NO;
    char *selfType=method_copyArgumentType(method,0),*selectorType=method_copyArgumentType(method,1);
    match=selfType && selectorType && !strcmp(selfType,"@") && !strcmp(selectorType,":");
    free(selfType);free(selectorType);
    if(match && argument) {char *arg=method_copyArgumentType(method,2);match=arg && !strcmp(arg,argument);free(arg);}
    return match;
}
static void NHBSetAlpha(id view,SEL command,CGFloat alpha,unsigned slot) {
    // Only a view returned by a home-indicator factory gets the marker.
    // Other MaterialKit pills keep their original alpha, including zero, NaN
    // and animation values. Gesture owners and all UIView methods stay intact.
    if(objc_getAssociatedObject(view,&NHBIndicatorKey))alpha=0;
    NHBAlphas[slot].original(view,command,alpha);
}
#define NHB_ALPHA_WRAPPER(N) static void NHBAlpha##N(id view,SEL command,CGFloat alpha) {NHBSetAlpha(view,command,alpha,N);}
NHB_ALPHA_WRAPPER(0) NHB_ALPHA_WRAPPER(1) NHB_ALPHA_WRAPPER(2) NHB_ALPHA_WRAPPER(3)
static IMP const NHBAlphaHooks[]={(IMP)NHBAlpha0,(IMP)NHBAlpha1,(IMP)NHBAlpha2,(IMP)NHBAlpha3};

static id NHBCreate(id owner,SEL command,unsigned slot) {
    id view=NHBFactories[slot].original(owner,command);
    if(!view)return view;
    if(![NSThread isMainThread]) {NHBRecord(@"factory.nonMainThread",@YES);return view;}
    if(![view isKindOfClass:[UIView class]]) {
        if(!NHBFactories[slot].observed) {NHBFactories[slot].observed=YES;NHBRecord([NSString stringWithFormat:@"factory.%u.unexpectedResult",slot],NSStringFromClass([view class]));}
        return view;
    }
    objc_setAssociatedObject(view,&NHBIndicatorKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [view setAlpha:0];
    if(!NHBFactories[slot].observed) {
        NHBFactories[slot].observed=YES;
        NHBRecord([NSString stringWithFormat:@"factory.%u.hiddenClass",slot],NSStringFromClass([view class]));
    }
    return view;
}
#define NHB_FACTORY_WRAPPER(N) static id NHBFactory##N(id owner,SEL command) {return NHBCreate(owner,command,N);}
NHB_FACTORY_WRAPPER(0) NHB_FACTORY_WRAPPER(1) NHB_FACTORY_WRAPPER(2)
NHB_FACTORY_WRAPPER(3) NHB_FACTORY_WRAPPER(4) NHB_FACTORY_WRAPPER(5)
static IMP const NHBFactoryHooks[]={(IMP)NHBFactory0,(IMP)NHBFactory1,(IMP)NHBFactory2,(IMP)NHBFactory3,(IMP)NHBFactory4,(IMP)NHBFactory5};

static void NHBInstall(void) {
    // Hook these four concrete visual classes, never UIView or CALayer.
    for(unsigned i=0;i<sizeof(NHBAlphas)/sizeof(NHBAlphas[0]);i++) {
        if(NHBAlphas[i].original)continue;
        Class cls=objc_getClass(NHBAlphas[i].className);if(!cls)continue;
        NSString *key=[NSString stringWithFormat:@"alpha.%u",i];
        Method method=class_getInstanceMethod(cls,@selector(setAlpha:));
        if(![cls isSubclassOfClass:[UIView class]] || !NHBHasType(method,3,"v","d")) {NHBRecord(key,@"unsupported signature or class");continue;}
        MSHookMessageEx(cls,@selector(setAlpha:),NHBAlphaHooks[i],(IMP *)&NHBAlphas[i].original);
        NHBRecord(key,NHBAlphas[i].original ? @"installed" : @"failed");
    }
    for(unsigned i=0;i<sizeof(NHBFactories)/sizeof(NHBFactories[0]);i++) {
        if(NHBFactories[i].original)continue;
        Class cls=objc_getClass(NHBFactories[i].className);if(!cls)continue;
        SEL selector=sel_registerName(NHBFactories[i].selector);
        Method method=class_getInstanceMethod(cls,selector);
        NSString *key=[NSString stringWithFormat:@"factory.%u",i];
        if(![cls isSubclassOfClass:[UIView class]] || !NHBHasType(method,2,"@",NULL)) {NHBRecord(key,@"unsupported signature or class");continue;}
        MSHookMessageEx(cls,selector,NHBFactoryHooks[i],(IMP *)&NHBFactories[i].original);
        NHBRecord(key,NHBFactories[i].original ? @"installed" : @"failed");
    }
}
#ifndef NHB_HOST_TEST
static void NHBImageLoaded(const struct mach_header *header,intptr_t slide) {
    static atomic_bool pending=false;
    if(atomic_exchange(&pending,true))return;
    dispatch_async(dispatch_get_main_queue(),^{atomic_store(&pending,false);NHBInstall();});
}
__attribute__((constructor)) static void NHBInitialize(void) {
    @autoreleasepool {
        if(![[[NSBundle mainBundle] bundleIdentifier] isEqual:@"com.apple.springboard"])return;
        NHBInstall();NHBRecord(@"loaded",@YES);
        _dyld_register_func_for_add_image(NHBImageLoaded);
    }
}
#endif
