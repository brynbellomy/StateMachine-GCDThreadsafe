#import <objc/runtime.h>
#import <BrynKit/GCDThreadsafe.h>
#import <BrynKit/BrynKit.h>
#import <libextobjc/EXTScope.h>

#import "StateMachine-Private.h"
#import "LSStateMachineDynamicAdditions.h"
#import "LSStateMachine.h"
#import "LSEvent.h"
#import "LSStative.h"

extern void *LSStateMachineDefinitionKey;

BOOL LSStateMachineTriggerEvent(id<GCDThreadsafe, LSStative> self, SEL _cmd);
void LSStateMachineInitializeInstance(id<GCDThreadsafe, LSStative> self, SEL _cmd);

// This is the implementation of all the event instance methods
BOOL LSStateMachineTriggerEvent(id<GCDThreadsafe, LSStative> self, SEL _cmd) {
    __block BOOL success;

    [(NSObject *)self willChangeValueForKey:@"state"];

    @weakify(self);
    [self runCriticalReadSection:^{
        @strongify(self);

        NSString *eventName    = NSStringFromSelector(_cmd);
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
            lllog(Warn, @"no nextState found (current state = %@, event = %@)", currentState, eventName);

            for (NSString *state in sm.states) {
                lllog(Warn, @"state = %@", state);
            }
            for (LSEvent *event in sm.events) {
                lllog(Warn, @"event = %@", event.name);
            }
            success = NO;
        }
    }];

    [(NSObject *)self didChangeValueForKey:@"state"];

    return success;
}

// This is the implementation of the initializeStateMachine instance method
void LSStateMachineInitializeInstance(id<GCDThreadsafe, LSStative> self, SEL _cmd) {
    @weakify(self);
    [self runCriticalReadSection:^{
        @strongify(self);
        LSStateMachine *sm = [[self class] performSelector:@selector(stateMachine)];
        self.state = sm.initialState;
    }];
}

// This is the implementation of all the is<StateName> instance methods
BOOL LSStateMachineCheckState(id<GCDThreadsafe, LSStative> self, SEL _cmd) {
    __block BOOL is;

    @weakify(self);
    [self runCriticalReadSection:^{
        @strongify(self);
//        NSString *currentState = self.state;
        NSString *query = [NSStringFromSelector(_cmd) substringFromIndex:2];
        NSString *head = [[query substringToIndex:1] lowercaseString];
        NSString *tail = [query substringFromIndex:1];
        query = [head stringByAppendingString:tail];

        is = [query isEqualToString:self.state];
    }];
    return is;
}

// This is the implementation of all the can<EventName> instance methods
BOOL LSStateMachineCheckCanTransition(id<GCDThreadsafe, LSStative> self, SEL _cmd) {
    __block NSString *nextState;

    @weakify(self);
    [self runCriticalReadSection:^{
        @strongify(self);
        LSStateMachine *sm = [[self class] performSelector:@selector(stateMachine)];
        NSString *currentState = self.state;
        NSString *query = [NSStringFromSelector(_cmd) substringFromIndex:3];
        NSString *head = [[query substringToIndex:1] lowercaseString];
        NSString *tail = [query substringFromIndex:1];
        query = [head stringByAppendingString:tail];

        nextState = [sm nextStateFrom:currentState forEvent:query];
    }];

    return nextState != nil;
}

// This is called in the initialize class method in the STATE_MACHINE macro
void LSStateMachineInitializeClass(Class klass) {
    LSStateMachine *sm = [klass performSelector:@selector(stateMachine)];
    for (LSEvent *event in sm.events) {
        class_addMethod(klass, NSSelectorFromString(event.name), (IMP) LSStateMachineTriggerEvent, "i@:");

        NSString *head = [[event.name substringToIndex:1] capitalizedString];
        NSString *tail = [event.name substringFromIndex:1];
        NSString *transitionQueryMethodName = [NSString stringWithFormat:@"can%@%@", head, tail];
        class_addMethod(klass, NSSelectorFromString(transitionQueryMethodName), (IMP) LSStateMachineCheckCanTransition, "i@:");
    }

    for (NSString *state in sm.states) {
        NSString *head = [[state substringToIndex:1] capitalizedString];
        NSString *tail = [state substringFromIndex:1];
        NSString *queryMethodName = [NSString stringWithFormat:@"is%@%@", head, tail];
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



