
# // StateMachine-GCDThreadsafe

Grand Central Dispatch-backed threadsafe state machine library for iOS.

This library was inspired by the Ruby gem [state_machine](https://github.com/pluginaweek/state_machine).

## features

* DSL for defining the state machine of your classes
* Dynamically added methods to trigger events in the instances of your classes
* Methods to query if an object is in a certain state (isActive, isPending, etc)
* Methods to query wheter an event will trigger a valid transition or not (canActive, canSuspend, etc)
* Transition callbacks. Execute arbitrary code before and after a transition occurs.

## installation

### As a [CocoaPod](http://cocoapods.org/)

Just add this to your `Podfile`:

```ruby
pod 'StateMachine-GCDThreadsafe', '>= 2.0.0'
```

### Other approaches

* You should be able to add StateMachine to your source tree.  Create an Xcode workspace containing your project and then import the `StateMachine-GCDThreadsafe` project into it.
* If you are using git, consider using a `git submodule`.

## Usage

### Defining the state machine of a class

When defining your model class, make sure it implements the `SEThreadsafeStateMachine` protocol (in `LSStative.h` if you're curious).

Let's model a `Subscription` class.  

```objective-c
@interface Subscription : NSObject <SEThreadsafeStateMachine>

@property (nonatomic, retain) NSDate *terminatedAt;

- (void) stopBilling;

@end
```

Here's the fun part.  In the implementation of the class, we use the `StateMachine` DSL to define our valid states and events.  _The DSL is a work in progress and will change._

**Three steps.**

**one**. The `@gcd_threadsafe` macro (defined in `<BrynKit/GCDThreadsafe.h>`) must be placed within your `@implementation` block.  Preferably at the very top, so it's more self-documenting.  This macro defines a custom GCD-backed setter and getter for `state`, the property responsible for tracking the current state of the machine.

```objective-c
@implementation Subscription
@gcd_threadsafe

STATE_MACHINE(^(LSStateMachine *sm) {
```

**two**. For each event, you define which are the valid transitions.

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

**three**. Make sure you include a call to `-initializeStateMachine` in your designated initializer (`-init`, etc.).

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

**StateMachine** will methods to your class to trigger events.  In order to make the compiler happy you need to tell it that this methods will be there at runtime.  You can achieve this by defining the header of an Objective-C category with one method per event (returning BOOL) and the method `-initializeStateMachine`.  Just like this:

```objective-c
@interface Subscription (State)
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
// Method stopBilling was called...
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

## Contributing

1. Fork it
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create new Pull Request


