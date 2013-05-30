#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDLog.h>
#import "LSStateMachineTypedefs.h"

@class LSEvent;

@interface LSStateMachine : NSObject <DDRegisteredDynamicLogging>
@property (nonatomic, strong, readonly) NSSet *states;
@property (nonatomic, strong, readonly) NSSet *events;
@property (nonatomic, strong) NSString *initialState;
- (void)addState:(NSString *)state;
- (void)when:(NSString *)eventName transitionFrom:(NSString *)from to:(NSString *)to;
- (LSEvent *)eventWithName:(NSString *)name;

- (void)before:(NSString *)eventName do:(LSStateMachineTransitionCallback)callback;
- (void)after:(NSString *)eventName do:(LSStateMachineTransitionCallback)callback;

- (NSString *)nextStateFrom:(NSString *)from forEvent:(NSString *)event;

@end



@class LSStateMachine;

#define StateMachine_LOG_CONTEXT 6868


