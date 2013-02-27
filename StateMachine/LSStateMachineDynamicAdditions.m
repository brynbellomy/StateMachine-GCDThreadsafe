#import <objc/runtime.h>
#import <BrynKit/NSObject+GCDThreadsafe.h>
#import <libextobjc/EXTScope.h>

#import "LSStateMachineDynamicAdditions.h"
#import "LSStateMachine.h"
#import "LSEvent.h"
#import "LSStative.h"

extern void * LSStateMachineDefinitionKey;

BOOL LSStateMachineTriggerEvent(id<LSStative> self, SEL _cmd);
void LSStateMachineInitializeInstance(id<LSStative> self, SEL _cmd);

// This is the implementation of all the event instance methods
BOOL LSStateMachineTriggerEvent(id<LSStative> self, SEL _cmd) {
    __block BOOL success;

    NSString *eventName = NSStringFromSelector(_cmd);

    @weakify(self);
    [(NSObject *)self runCriticalReadonlySection:^{
        @strongify(self);
        NSString *currentState = self.state;
        LSStateMachine *sm     = [[self class] performSelector:@selector(stateMachine)];
        NSString *nextState    = [sm nextStateFrom:currentState forEvent:eventName];

        if (nextState) {
            LSEvent *event = [sm eventWithName:eventName];
            NSArray *beforeCallbacks = event.beforeCallbacks;
            for (void(^beforeCallback)(id) in beforeCallbacks) {
                beforeCallback(self);
            }
            self.state = nextState;

            NSArray *afterCallbacks = event.afterCallbacks;
            for (LSStateMachineTransitionCallback afterCallback in afterCallbacks) {
                afterCallback(self);
            }
            success = YES;
        } else {
            success = NO;
        }
    }];
    return success;
}

// This is the implementation of the initializeStateMachine instance method
void LSStateMachineInitializeInstance(id<LSStative> self, SEL _cmd) {
    @weakify(self);
    [(NSObject *)self runCriticalMutableSection:^{
        @strongify(self);
        LSStateMachine *sm = [[self class] performSelector:@selector(stateMachine)];
        self.state = sm.initialState;
    }];
}

// This is the implementation of all the is<StateName> instance methods
BOOL LSStateMachineCheckState(id<LSStative> self, SEL _cmd) {
    __block BOOL is;

    @weakify(self);
    [(NSObject *)self runCriticalReadonlySection:^{
        @strongify(self);
        NSString *query = [[NSStringFromSelector(_cmd) substringFromIndex:2] lowercaseString];
        is = [query isEqualToString:self.state];
    }];
    return is;
}

// This is the implementation of all the can<EventName> instance methods
BOOL LSStateMachineCheckCanTransition(id<LSStative> self, SEL _cmd) {
    __block NSString *nextState;

    @weakify(self);
    [(NSObject *)self runCriticalReadonlySection:^{
        @strongify(self);
        LSStateMachine *sm = [[self class] performSelector:@selector(stateMachine)];
        NSString *currentState = self.state;
        NSString *query = [[NSStringFromSelector(_cmd) substringFromIndex:3] lowercaseString];

        nextState = [sm nextStateFrom:currentState forEvent:query];
    }];

    return nextState != nil;
}

// This is called in the initilize class method in the STATE_MACHINE macro
void LSStateMachineInitializeClass(Class klass) {
    LSStateMachine *sm = [klass performSelector:@selector(stateMachine)];
    for (LSEvent *event in sm.events) {
        class_addMethod(klass, NSSelectorFromString(event.name), (IMP) LSStateMachineTriggerEvent, "i@:");

        NSString *transitionQueryMethodName = [NSString stringWithFormat:@"can%@", [event.name capitalizedString]];
        class_addMethod(klass, NSSelectorFromString(transitionQueryMethodName), (IMP) LSStateMachineCheckCanTransition, "i@:");
    }

    for (NSString *state in sm.states) {
        NSString *queryMethodName = [NSString stringWithFormat:@"is%@", [state capitalizedString]];
        class_addMethod(klass, NSSelectorFromString(queryMethodName), (IMP) LSStateMachineCheckState, "i@:");
    }
    class_addMethod(klass, @selector(initializeStateMachine), (IMP) LSStateMachineInitializeInstance, "v@:");
}

// This is called in the stateMachine class method defined by the STATE_MACHINE macro
LSStateMachine * LSStateMachineSetDefinitionForClass(Class klass,void(^definition)(LSStateMachine *)) {
    LSStateMachine *sm = (LSStateMachine *)objc_getAssociatedObject(klass, &LSStateMachineDefinitionKey);
    if (!sm) {
        sm = [[LSStateMachine alloc] init];
        objc_setAssociatedObject (
                                  klass,
                                  &LSStateMachineDefinitionKey,
                                  sm,
                                  OBJC_ASSOCIATION_RETAIN
                                  );
        definition(sm);
    }
    return sm;

}