//
//  DelayedProperty.swift
//  RXDemo3
//
//  Created by fan yang on 2017/11/8.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import Foundation


class TimerBlockTarget {
    
    var block: () -> ()
    
    init(_ block: @escaping () -> ()){
        self.block = block
    }
    
    @objc func onTimer() {
        self.block()
    }
    
}


class DelayedProperty<T> where T: Equatable {
    
    private(set) var currentValue: T
    private(set) var targetValue: T
    private(set) var changeHandlerBlock: (T) -> ()
    private(set) var timer: Timer?
    
    init(_ value: T, changeHandlerBlock: @escaping (T) -> ()) {
        self.currentValue = value
        self.targetValue = value
        self.changeHandlerBlock = changeHandlerBlock
    }
    
    func setValue(_ value: T, withDelay ti: TimeInterval) {
        targetValue = value
        if currentValue != targetValue {
            if ti < 0.01 {
                doChange()
                timer?.invalidate()
                timer = nil
            }
            else {
                configTimer(withDelay: ti)
            }
            
        }
        else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func configTimer(withDelay ti: TimeInterval) {
        if timer == nil {
            let target = TimerBlockTarget.init({ [weak self] in
                self?.doChange()
            })
            timer = Timer.scheduledTimer(timeInterval: 0, target: target, selector: #selector(TimerBlockTarget.onTimer), userInfo: nil, repeats: false)
        }
        timer?.fireDate = Date().addingTimeInterval(ti)
    }
    
    @objc func doChange() {
        currentValue = targetValue
        changeHandlerBlock(currentValue)
        timer = nil
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
}
