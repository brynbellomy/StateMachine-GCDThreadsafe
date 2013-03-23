//
//  LSStative.h
//  StateMachine
//
//  Created by bryn austin bellomy on 2.27.13.
//  Copyright (c) 2013 Luis Solano Bonet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BrynKit/GCDThreadsafe.h>

@protocol LSStative <NSObject>
@required
    @property (nonatomic, copy, readwrite) NSString *state;
@end

@protocol SEThreadsafeStateMachine <LSStative, GCDThreadsafe>
@end
