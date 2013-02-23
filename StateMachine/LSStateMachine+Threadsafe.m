//
//  LSStateMachine+Threadsafe.m
//  StateMachine
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 Luis Solano Bonet. All rights reserved.
//

#import <libextobjc/EXTSynthesize.h>
#import "LSStateMachine+Threadsafe.h"

@interface LSStateMachine()
    @property (nonatomic, assign, readwrite) NSNumber *SEStativeState;
@end

@implementation LSStateMachine (Threadsafe)

@synthesizeAssociation(LSStateMachine, SEStativeState);


/**
 * queueCritical
 *
 *
 */

- (dispatch_queue_t) queueCritical
{
    static dispatch_queue_t queue = nil;

    if (queue == nil) {
        queue = dispatch_queue_create([NSString stringWithFormat: @"com.signalenvelope.SEStative.%@", [self class].name].UTF8String, 0);
    }

    return queue;
}



/**
 * runCriticalMutableSection:
 *
 *
 */

- (void) runCriticalMutableSection: (dispatch_block_t)blockCritical
{
    dispatch_barrier_async(self.queueCritical, blockCritical);
}



/**
 * runCriticalReadonlySection:
 *
 *
 */

- (void) runCriticalReadonlySection: (dispatch_block_t)blockCritical
{
    if (NSThread.isMainThread || (dispatch_get_current_queue() == self.queueCritical)) {
        blockCritical();
    } else {
        dispatch_sync(self.queueCritical, blockCritical);
    }
}



@end