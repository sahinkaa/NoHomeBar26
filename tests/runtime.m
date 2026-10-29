#define NHB_HOST_TEST 1
#include "../Engine/Runtime.m"
#include <math.h>
#include <stdlib.h>
@interface NHBHostLuma:NHBHostView @end
@implementation NHBHostLuma @end
@interface NHBHostStatic:NHBHostView @end
@implementation NHBHostStatic @end
// Deliberately inherit from another hooked class to exercise original-IMP chaining.
@interface NHBHostAlwaysOn:NHBHostStatic @end
@implementation NHBHostAlwaysOn @end
@interface NHBHostAffordance:NHBHostView @end
@implementation NHBHostAffordance @end
static NSUInteger factoryCalls[6];static unsigned resultMode;
static id NativeFactory(unsigned index,Class cls) {
    factoryCalls[index]++;
    if(resultMode==1)return nil;
    if(resultMode==2)return [[NSObject alloc] init];
    return [[cls alloc] init];
}
@interface NHBHostGrabber:NHBHostView
- (id)_newPillView;
- (id)_newHomeAffordanceView;
@end
@implementation NHBHostGrabber
- (id)_newPillView {return NativeFactory(0,[NHBHostLuma class]);}
- (id)_newHomeAffordanceView {return NativeFactory(1,[NHBHostAffordance class]);}
@end
@interface NHBHostCoverSheet:NHBHostView
- (id)_newHomeAffordanceView;
- (id)_newStaticColorPillView;
- (id)_newLumaDodgePillView;
- (id)_newAlwaysOnHomeAffordancePillView;
@end
@implementation NHBHostCoverSheet
- (id)_newHomeAffordanceView {return NativeFactory(2,[NHBHostAffordance class]);}
- (id)_newStaticColorPillView {return NativeFactory(3,[NHBHostStatic class]);}
- (id)_newLumaDodgePillView {return NativeFactory(4,[NHBHostLuma class]);}
- (id)_newAlwaysOnHomeAffordancePillView {return NativeFactory(5,[NHBHostAlwaysOn class]);}
@end
@interface NHBHostWrong:NHBHostView
- (double)_newPillView;
- (void)wrongAlpha:(float)value;
@end
@implementation NHBHostWrong
- (double)_newPillView {return 42;}
- (void)wrongAlpha:(float)value {}
@end
static void Check(BOOL ok,NSString *message) {if(!ok){NSLog(@"FAIL: %@",message);abort();}}
static id Create(id owner,unsigned index) {
    return ((id(*)(id,SEL))objc_msgSend)(owner,sel_registerName(NHBFactories[index].selector));
}
int main(int argc,const char **argv) {
    @autoreleasepool {
        NHBHostLogPath=[@(argv[1]) copy];
        const char *className=NHBAlphas[0].className;NHBAlphas[0].className="NHBAbsentClass";
        const char *factoryClass=NHBFactories[0].className;NHBFactories[0].className="NHBHostWrong";
        NHBInstall();Check(!NHBAlphas[0].original && !NHBFactories[0].original && hookCount==8,@"missing class and incompatible factory skipped safely");
        NHBAlphas[0].className=className;NHBFactories[0].className=factoryClass;NHBInstall();
        Check(hookCount==10,@"late classes can install all ten narrowly scoped hooks");NHBInstall();Check(hookCount==10,@"installation is idempotent");
        Check(!NHBHasType(class_getInstanceMethod([NHBHostWrong class],@selector(wrongAlpha:)),3,"v","d"),@"float setter rejected for CGFloat ABI");
        Check(method_getImplementation(class_getInstanceMethod([NHBHostView class],@selector(setAlpha:)))!=(IMP)NHBAlpha0,@"base UIView alpha implementation untouched");
        NHBHostGrabber *grabber=[[NHBHostGrabber alloc] init];NHBHostCoverSheet *cover=[[NHBHostCoverSheet alloc] init];
        CGRect ownerFrame=grabber.frame;
        for(unsigned i=0;i<6;i++) {
            NSUInteger calls=factoryCalls[i];NHBHostView *view=Create(i<2?grabber:cover,i);
            Check(view!=nil && factoryCalls[i]==calls+1,@"each factory original called exactly once and real view returned");
            Check(view.alpha==0 && !view.hidden && view.userInteractionEnabled && view.gestureToken==0x1234 && CGRectEqualToRect(view.frame,ownerFrame),@"visual opacity alone changes; geometry and interaction fields preserved");
            for(int j=0;j<100;j++) {NSUInteger before=alphaCalls;[view setAlpha:(j%2?1:0.45)];Check(view.alpha==0 && alphaCalls==before+1,@"native attempts to unhide indicator remain transparent with one base setter call");}
            [view release];
        }
        Check(grabber.alpha==1 && !grabber.hidden && grabber.userInteractionEnabled && grabber.gestureToken==0x1234 && CGRectEqualToRect(grabber.frame,ownerFrame),@"gesture owner unchanged");
        for(Class cls in @[[NHBHostView class],[NHBHostLuma class],[NHBHostStatic class],[NHBHostAlwaysOn class],[NHBHostAffordance class]]) {
            NHBHostView *other=[[cls alloc] init];CGFloat values[]={0,0.6,-0.5,INFINITY,NAN};
            for(unsigned j=0;j<5;j++) {NSUInteger before=alphaCalls;[other setAlpha:values[j]];CGFloat actual=other.alpha;Check(!memcmp(&actual,&values[j],sizeof(CGFloat)) && alphaCalls==before+1,@"unrelated pill alpha values forwarded unchanged through inherited hooks");}
            [other release];
        }
        resultMode=1;Check(Create(grabber,0)==nil,@"nil factory result remains nil");
        resultMode=2;id opaque=Create(grabber,0);Check([opaque class]==[NSObject class],@"unexpected result is returned untouched");[opaque release];resultMode=0;
        __block id backgroundView=nil;
        void *backgroundOwner=(void *)grabber;
        dispatch_semaphore_t finished=dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(0,0),^{@autoreleasepool {backgroundView=Create((id)backgroundOwner,0);}dispatch_semaphore_signal(finished);});
        Check(dispatch_semaphore_wait(finished,dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC))==0,@"background fixture completed");
        dispatch_release(finished);
        Check([backgroundView alpha]==1,@"off-main factory leaves original UI result untouched");[backgroundView release];
        for(unsigned i=0;i<1000;i++){id v=Create(grabber,0);[v release];}
        [grabber release];[cover release];
        Check(allocatedViews==deallocatedViews,@"owned factory results release exactly once without leaked or autoreleased views");
        NSLog(@"PASS: app/lock-screen factory hooks, alpha clamping, inherited hook chaining, exact original calls, owned-result lifetime, unrelated pills/gesture owners/geometry preserved, nil and unexpected results, invalid signatures and missing/late classes, idempotence and non-main fallback. No UIKit or device behavior was simulated as verified.");
        [NHBHostLogPath release];NHBHostLogPath=nil;
    }
    return 0;
}
