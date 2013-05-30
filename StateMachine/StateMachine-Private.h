//
//  StateMachine-Private.h
//  StateMachine-GCDThreadsafe
//
//  Created by bryn austin bellomy on 03.26.13.
//  Copyright (c) 2013 bryn austin bellomy. All rights reserved.
//

#import "StateMachine.h"

#if defined(lllog)
#   undef lllog
#endif

#define lllog(severity, __FORMAT__, ...)         metamacro_concat(StateMachineLog,severity)((__FORMAT__), ## __VA_ARGS__)
#define StateMachineLogError(__FORMAT__, ...)    SYNC_LOG_OBJC_MAYBE([LSStateMachine ddLogLevel], LOG_FLAG_ERROR,   StateMachine_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define StateMachineLogWarn(__FORMAT__, ...)     SYNC_LOG_OBJC_MAYBE([LSStateMachine ddLogLevel], LOG_FLAG_WARN,    StateMachine_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define StateMachineLogSuccess(__FORMAT__, ...)  SYNC_LOG_OBJC_MAYBE([LSStateMachine ddLogLevel], LOG_FLAG_SUCCESS, StateMachine_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define StateMachineLogInfo(__FORMAT__, ...)     SYNC_LOG_OBJC_MAYBE([LSStateMachine ddLogLevel], LOG_FLAG_INFO,    StateMachine_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define StateMachineLogVerbose(__FORMAT__, ...)  SYNC_LOG_OBJC_MAYBE([LSStateMachine ddLogLevel], LOG_FLAG_VERBOSE, StateMachine_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)