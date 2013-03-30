
# // StateMachine-GCDThreadsafe

Grand Central Dispatch-backed threadsafe state machine library for iOS.

This library was inspired by the Ruby gem [state_machine](https://github.com/pluginaweek/state_machine) and the letter 5.


# features

* __Threadsafe and FAST__.  All transition code executes within barrier blocks on a critical-section-only async dispatch queue.
* __Open architecture__. You can submit your own blocks to this queue as well.  Everything will be threadsafed for you under the hood.
* __Easy, block-based DSL__ for defining your classes' state machines.  Block-based `before` and `after` transition hooks.
* __Less boilerplate to write__.  Dynamically generates all state machine methods directly onto your classes using some Objective-C runtime voodoo jah.


     
# installation
    
1. __[CocoaPods](http://cocoapods.org/) is the way and the light__.  Just add to your `Podfile`:

    ```ruby
    pod 'StateMachine-GCDThreadsafe', '>= 2.0.0'
    ```

2. __The direct approach__.  You should be able to add StateMachine to your source tree.  Create an Xcode workspace containing your project and then import the `StateMachine-GCDThreadsafe` project into it.
3. __The indirect approach__. If you are using git, consider using a `git submodule`.

Seriously though, get with CocoaPods already, y'know?



# basic usage for humans with an concrete objective

Let's model a `Subscription` class.

### 1. @interface

Declare your class to conform to the `SEThreadsafeStateMachine` protocol (which is defined in
`LSStative.h`, if you're curious).

```objective-c
@interface Subscription : NSObject <SEThreadsafeStateMachine>
@property (nonatomic, strong, readwrite) NSDate *terminatedAt;
- (void) stopBilling;
@end
```

### 2. the `@gcd_threadsafe` macro.

`@gcd_threadsafe` is defined in `<BrynKit/GCDThreadsafe.h>`.  Import that.  The macro itself should be placed within your `@implementation` block.  Preferably at the very top, so it's more self-documenting.

*This macro defines a couple of methods on your class for dispatching critical section code onto `self.queueCritical` -- the show-stopper, the main attraction -- the private `dispatch_queue_t` on which shit be GITTAN RIAL.*

```objective-c
#import <BrynKit/GCDThreadsafe.h>

@implementation Subscription
@gcd_threadsafe

// methods, etc. ...
```

### 3. the state machine dsl

In the implementation of the class, we use the `StateMachine` DSL to define our valid states and events.

1. _"The DSL is a work in progress and will change."_ - [@luisobo](http://github.com/luisobo)
1. _"I'onno mate I think i'ss quite nice, really"_ - [@brynbellomy](http://github.com/brynbellomy)
1. Conclusion: \*shrug\*

```objective-c
STATE_MACHINE(^(LSStateMachine *sm) {
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
    
    [sm before:@"terminate" do:^(Subscription *self){
        self.terminatedAt = [NSDate dateWithTimeIntervalSince1970:123123123];
    }];
    
    [sm after:@"suspend" do:^(Subscription *self) {
        [self stopBilling];
    }];
});
```

### 4. designated initializer

1. __Use the `@gcd_threadsafe_init(...)` macro__ in your designated initializer (`-init`, etc.).  Place it before anything else in the `if (self)` block.  It takes two parameters, both of which concern the critical section dispatch queue:
    * its concurrency mode: SERIAL or CONCURRENT
    * and its label: a regular C string
2. __Call `[self initializeStateMachine]`__ right after that.
3. C'mon just do it

```objective-c
- (id) init
{
    self = [super init];
    if (self) {
        @gcd_threadsafe_init(CONCURRENT, "com.pton.KnowsHowToParty.queueCritical");
        [self initializeStateMachine];
    }
    return self;
}
```

*`@gcd_threadsafe_init(...)` initializes the `self.queueCritical` property.*

### the metamorphosis    

Once given a particular configuration of transitions and states, __StateMachine-GCDThreadsafe__ will dynamically add the appropriate methods to your class to reflect that configuration.  You'll find yourself facing a few compiler warnings regarding these methods.  Wanna shut the compiler up?  Easy enough: __define a class category and don't implement it__.  The category can live hidden inside your implementation file (if the methods need to be private), in your header file (if the methods ought to be publicly callable), or split between the two.

```objective-c
@interface Subscription (StateMachine)
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
```

In addition to your class's main `state` property being KVO-observable, **StateMachine** will define query methods to check if the object is in a given state (`isPending`, `isActive`, etc.) and to check whether an event will trigger a valid transition (`canActivate`, `canSuspend`, etc).

### triggering events

```objective-c
Subscription *subscription = [[Subscription alloc] init];
subscription.state;                 // will be set to @"pending", the value of the initialState property
```

Start triggering events...

```objective-c
[subscription activate];            // retuns YES because it's a valid transition
subscription.state;                 // @"active"

[subscription suspend];             // also, `-stopBilling` is called by `-suspend`
                                    // retuns YES because it's a valid transition

subscription.state;                 // @"suspended"

[subscription terminate];           // retuns YES because it's a valid transition
subscription.state;                 // @"terminated"

subscription.terminatedAt;           // [NSDate dateWithTimeIntervalSince1970:123123123];
```

But!  If we trigger an invalid event...

```objective-c
// the subscription is now suspended

[subscription activate];            // returns NO because it's not a valid transition
subscription.state;                 // @"suspended"
```

    
# is it re-entrant?

duh, son, c'mon now.



# tips n' tricks

1. It's almost always a BAD, BAD idea to `dispatch_sync(...)` a synchronous block to the main queue from inside
   one of your critical section blocks.  Why?  If the main thread happens to be waiting on your critical section
   code before moving forward, you'll deadlock.  You should generally be sending things to the main queue that
   don't need to be synchronous (UI updates, certain kinds of NSNotifications, KVO messages, etc.).  If
   it seems impossible to rewrite your main thread code in an asynchronous way, you may have an architectural
   problem.
2. If you're implementing a GCD-threadsafe `StateMachine` on one of your `UIViewController`s, keep in mind
   all of `UIViewController`'s `-viewDidX...` and `-viewWillY...` methods are called from the main thread.  Given
   tip #1 just above, this means that you have to be especially careful of deadlocks in `UIViewController` state
   machines (and in `GCDThreadsafe` code inside these `UIViewController` methods more generally).



# contributing

1. Brush up on your [ReactiveCocoa](http://github.com/ReactiveCocoa/ReactiveCocoa).  That's the direction that this fork of the code is overwhelmingly likely to head.
2. Fork this project.
3. Create a new feature branch.
4. Commit your changes.
5. Push to the branch.
6. Create new pull request.



# top scores

- Luis Solano Bonet < <contact@luissolano.com> >, the original fork's author
- bryn austin bellomy < <bryn@signals.io> >, a rookie, a failure


