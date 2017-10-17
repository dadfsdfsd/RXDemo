//
//  BaseTabBarController.swift
//  RXDemo3
//
//  Created by fan yang on 2017/10/10.
//  Copyright © 2017年 fan yang. All rights reserved.
//

import UIKit

class BaseTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configSubviewControllers()
    }
    
    func configSubviewControllers() {
        
        let mainViewController = MainViewController()
        let mainScene = UINavigationController(rootViewController: mainViewController)
        if #available(iOS 11.0, *) {
            mainScene.navigationBar.prefersLargeTitles = false
        } else {
            // Fallback on earlier versions
        }
        mainScene.tabBarItem = UITabBarItem.init(tabBarSystemItem: UITabBarSystemItem.favorites, tag: 0)
        
        let secondViewController = MainViewController()
        let secondScene = UINavigationController(rootViewController: secondViewController)
        if #available(iOS 11.0, *) {
            secondScene.navigationBar.prefersLargeTitles = false
        } else {
            // Fallback on earlier versions
        }
        secondScene.tabBarItem = UITabBarItem.init(tabBarSystemItem: UITabBarSystemItem.history, tag: 1)
        
        self.setViewControllers([mainScene, secondScene], animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
