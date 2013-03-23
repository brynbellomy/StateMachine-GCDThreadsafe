#ifndef StateMachine_LSStateMachineMacros_h
#define StateMachine_LSStateMachineMacros_h
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "LSStateMachineDynamicAdditions.h"

#define STATE_MACHINE(definition) \
+ (LSStateMachine *)stateMachine {\
    return LSStateMachineSetDefinitionForClass(self, definition);\
}\
+ (void) initialize {\
    LSStateMachineInitializeClass(self);\
}\
\
\
@synthesize state = _state; \
\
- (NSString *) state {\
    __block NSString *state;\
    [self runCriticalReadonlySection:^{\
        state = [_state copy];\
    }];\
    return state;\
}\
- (void) setState:(NSString *)state {\
    NSString *theState = [state copy];\
    [self runCriticalMutableSection:^{\
        _state = theState;\
    }];\
}
#endif
