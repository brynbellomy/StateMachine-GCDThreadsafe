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

- (id)init {
    self = [super init];
    if (self) {
        _queueCritical = dispatch_queue_create("LSSubscription critical queue", 0);
        [self initializeStateMachine];
    }
    return self;
}



@end


