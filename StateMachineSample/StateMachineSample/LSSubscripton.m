#import <BrynKit/BrynKit.h>
#import <BrynKit/GCDThreadsafe.h>
#import "LSSubscripton.h"
#import "StateMachine.h"

@interface LSSubscripton ()
@end

@implementation LSSubscripton
@gcd_threadsafe

STATE_MACHINE(^(LSStateMachine * sm) {
    sm.initialState = @"pending";
    
    [sm addState:@"pending"];
    [sm addState:@"active"];
    [sm addState:@"suspended"];
    [sm addState:@"terminated"];
    
    [sm when:@"activate" transitionFrom:@"pending" to:@"active"];
    [sm when:@"suspend" transitionFrom:@"active" to:@"suspended"];
    [sm when:@"unsuspend" transitionFrom:@"suspended" to:@"active"];
    [sm when:@"terminate" transitionFrom:@"active" to:@"terminated"];
    [sm when:@"terminate" transitionFrom:@"suspended" to:@"terminated"];
})

- (id) init {
    self = [super init];
    if (self) {
        @gcd_threadsafe_init(CONCURRENT, "com.signalenvelope.StateMachineSample.Subscription.queueCritical");

        yssert_notNil(_queueCritical)
        yssert_notNil(self.queueCritical)
        yssert(self.queueCritical == _queueCritical);

        [self initializeStateMachine];
    }
    return self;
}



@end


