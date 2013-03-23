#import <Foundation/Foundation.h>
#import <BrynKit/GCDThreadsafe.h>
#import <LSStative.h>

@interface LSSubscripton : NSObject <SEThreadsafeStateMachine>
@end

@interface LSSubscripton (State)
- (void)initializeStateMachine;
- (BOOL)activate;
- (BOOL)suspend;
- (BOOL)unsuspend;
- (BOOL)terminate;

- (BOOL)isPending;
- (BOOL)isActive;
- (BOOL)isSuspended;
- (BOOL)isTerminated;

- (BOOL)canActivate;
- (BOOL)canSuspend;
- (BOOL)canUnsuspend;
- (BOOL)canTerminate;
@end