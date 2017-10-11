//
//  MetuxLock.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/11.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation


open class MutexLock {
    public enum MutexLockType {
        case Normal
        case Errorcheck
        case Recursive
        case Default
    }
    
    fileprivate var attr = pthread_mutexattr_t()
    
    fileprivate func changeType() {
        pthread_mutexattr_init(&attr)
        switch _type {
        case .Normal:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
        case .Errorcheck:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK)
        case .Recursive:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        case .Default:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT)
        }
    }
    
    fileprivate var _lock: pthread_mutex_t
    fileprivate let _type: MutexLockType
    
    public init(_ type: MutexLockType = .Normal) {
        _type = type
        _lock = pthread_mutex_t()
        changeType()
        pthread_mutex_init(&_lock, &attr)
    }
    
    open func lock() {
        pthread_mutex_lock(&_lock)
    }
    
    open func unlock() {
        pthread_mutex_unlock(&_lock)
    }
    
    open func run(_ block: () throws -> Void) rethrows {
        lock()
        try block()
        unlock()
    }
    
    deinit {
        pthread_mutex_destroy(&_lock)
    }
}
