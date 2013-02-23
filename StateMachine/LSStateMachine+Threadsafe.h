//
//  LSStateMachine+Threadsafe.h
//  StateMachine
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 Luis Solano Bonet. All rights reserved.
//



@interface LSStateMachine (Threadsafe)
    @property (nonatomic, assign, readonly) dispatch_queue_t queueCritical;
    - (void) runCriticalMutableSection:(dispatch_block_t)blockCritical;
    - (void) runCriticalReadonlySection:(dispatch_block_t)blockCritical;
@end
