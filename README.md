# // StateMachine-GCDThreadsafe

Grand Central Dispatch-backed threadsafe state machine library for iOS.

This library was inspired by the Ruby gem [state_machine](https://github.com/pluginaweek/state_machine).


## Features

* __Threadsafe and FAST__.  All transition code executes within barrier blocks on a critical-section-only async dispatch queue.
* You can submit your own blocks to this queue as well.  Everything will be threadsafed for you under the hood.
* __Easy, block-based DSL__ for defining your classes' state machines.
* __Less boilerplate to write__.  Dynamically generates all state machine methods directly onto your classes using some Objective-C runtime voodoo jah.
* Methods to query if an object is in a certain state (`isActive`, `isPending`, etc)
* Methods to query whether an event will trigger a valid transition or not (`canActive`, `canSuspend`, etc.)
* Block-based "before" and "after" transition hooks.

## a wee word aboat GCD threadsafe'ing (ah blarney queue)

The GCD foundation upon which `StateMachine-GCDThreadsafe` relies is very simple, very concise, and very widely applicable.
Its primary implementation resides in the [BrynKit library](http://github.com/brynbellomy/BrynKit) (also on CocoaPods),
in `GCDThreadsafe.h`.

The main idea here is that it more or less looks and acts like an old-school Objective-C `@synchronized` block (yeah, that's
right, "old school" -- I'm forcefully phasing out `@synchronized` as of right nowish since that's some slow ass grandma shit).

In practice, it sometimes looks like this:

```objective-c
@weakify(self);
[self runCriticalMutableSection:^{
    @strongify(self);
    self.someProperty = @"a new value";
    [self.otherProperty someMutationMethod];
}];
```

...and sometimes like this:

```objective-c
__block NSString *synchronizedValue = nil;
@weakify(self);
[self runCriticalReadonlySection:^{
    @strongify(self);
    
    synchronizedValue = [_someHiddenIvar copy];
    
    // mutation is fine in "read" sections.  obviously need to rename this method.
    self.someProperty = @"a new value";
}];
NSLog(@"synchronizedValue = %@", synchronizedValue);
```

You can add this functionality to any class easily:

1. `#import <StateMachine-GCDThreadsafe/LSStative.h>` (or the umbrella
    header, `<StateMachine-GCDThreadsafe/StateMachine.h>`)
    
2. Add the `@gcd_threadsafe` macro/annotation to your class's `@implementation` block.  This macro
    is syntactical fuckin maple syrup -- take a look at its definition so you know what's going down
    in the trap.

    ```objective-c
    @implementation ScranglyBones
    @gcd_threadsafe
    
    - (instancetype) initWithScrangleTums:(WangleBums *)tanglyChums
    {
    ```

3. In your designated initializer, initialize `_queueCritical`, the private `dispatch_queue_t` ivar
    on which shit's gonna be goin down.  And make sure you initialize it before doing anything else
    or you might accidentally call methods that rely on GCD synchronization before it's had a chance
    to get bootstrapped:
    
    ```objective-c
    self = [super init];
    if (self) {
        _queueCritical = dispatch_queue_create("com.pton.queueCritical", 0);
        // ...
    ```

As long as you divide your critical sections into two groups:

+ **"mutate" sections**
    - can write to anything  read values out through the boundaries of the synchronizer queue.
    - dispatched as __async__ barrier blocks.  fast as lightning.  synchronized but don't
      necessarily run immediately.
+ **"read" sections**
    - can do anything, including read values through synchronizer queue boundaries.
    - dispatched as __sync__ barrier blocks.  synchronized and run immediately.

... the framework will (should? ... might???) line everything up as it oughta be.  This is an alpha release, to be
sure, so I'd very much welcome any traffic that would like to make its way into the issue queue.



## Installation

1. As a [CocoaPod](http://cocoapods.org/)

    Just add this to your `Podfile`:

    ```ruby
    pod 'StateMachine-GCDThreadsafe', '>= 2.0.0'
    ```

2. __The direct approach__.  You should be able to add StateMachine to your source tree.  Create an Xcode
    workspace containing your project and then import the `StateMachine-GCDThreadsafe` project into it.
3. __The indirect approach__. If you are using git, consider using a `git submodule`.

## Usage

### Defining the state machine of a class

When defining your model class, make sure it implements the `SEThreadsafeStateMachine` protocol (in `LSStative.h` if you're curious).

Let's model a `Subscription` class.  

```objective-c
@interface Subscription : NSObject <SEThreadsafeStateMachine>

@property (nonatomic, strong, readwrite) NSDate *terminatedAt;

- (void) stopBilling;

@end
```

Here's the fun part.  In the implementation of the class, we use the `StateMachine` DSL to define our valid states and events.  _The DSL is a work in progress and will change._

**Three steps.**

1. The `@gcd_threadsafe` macro (defined in `<BrynKit/GCDThreadsafe.h>`) must be placed within your `@implementation` block.  Preferably at the very top, so it's more self-documenting.  This macro defines a custom GCD-backed setter and getter for `state`, the property responsible for tracking the current state of the machine.

    ```objective-c
    @implementation Subscription
    @gcd_threadsafe
    STATE_MACHINE(^(LSStateMachine *sm) {
    ```

2. For each event, you define which are the valid transitions.

    ```objective-c
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
        
        [sm before:@"terminate" do:^(Subscription *subscription){
            subscription.terminatedAt = [NSDate dateWithTimeIntervalSince1970:123123123];
        }];
        
        [sm after:@"suspend" do:^(Subscription *subscription) {
            [subscription stopBilling];
        }];
    });
    ```

3. Make sure you include a call to `-initializeStateMachine` in your designated initializer (`-init`, etc.).

    ```objective-c
    - (id) init
    {
        self = [super init];
        if (self) {
            [self initializeStateMachine];
        }
        return self;
    }

    - (void) stopBilling
    {
        // Yeah, sure...
    }

    @end
    ```

### The metamorphosis    

**StateMachine-GCDThreadsafe** will dynamically add methods to your class to trigger events.  In order to keep the compiler quiet, you need to tell it that these methods can be expected to exist at runtime.  How?  Simply define a class category.  You can define it in your implementation file (if the methods need to be private), in your header (if they ought to be publicly callable), or spit between the two.

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

In addition to your class's main `state` property being KVO-observable, **StateMachine** will define query methods to check if the object is in a certain state (`isPending`, `isActive`, etc.) and to check whether an event will trigger a valid transition (`canActivate`, `canSuspend`, etc).

### Triggering events

Now you can create instances of your class as you would normally do:

```objective-c
Subscription *subscription = [[Subscription alloc] init];
```

It has an initialState of `pending`.

```objective-c
subscription.state;                 // @"pending"
```

You can trigger events:

```objective-c
[subscription activate];            // retuns YES because it's a valid transition
subscription.state;                 // @"active"

[subscription suspend];             // retuns YES because it's a valid transition

//
// `-stopBilling` was called by `-suspend`, just above
//

subscription.state;                 // @"suspended"

[subscription terminate];           // retuns YES because it's a valid transition
subscription.state;                 // @"terminated"
subcription.terminatedAt;           // [NSDate dateWithTimeIntervalSince1970:123123123];
```

If we trigger an invalid event...

```objective-c
//
// The subscription is now suspended
//

[subscription activate];            // returns NO because it's not a valid transition
subscription.state;                 // @"suspended"
```

# Contributing

1. Brush up on your [ReactiveCocoa](http://github.com/ReactiveCocoa/ReactiveCocoa).  That's the direction that this fork of the code is overwhelmingly likely to head.
2. Fork this project.
3. Create a new feature branch.
4. Commit your changes.
5. Push to the branch.
6. Create new pull request.



# Top scores

- Luis Solano Bonet < <contact@luissolano.com> >, the original fork's author
- bryn austin bellomy < <bryn@signals.io> >, a rookie, a failure


