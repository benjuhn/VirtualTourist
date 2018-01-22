//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Ben Juhn on 7/24/17.
//  Copyright © 2017 Ben Juhn. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let travelLocationsVC = TravelLocationsMapViewController()
        
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.set(40, forKey: "CenterLat")
            UserDefaults.standard.set(-95, forKey: "CenterLong")
            UserDefaults.standard.set(20, forKey: "SpanLatDelta")
            UserDefaults.standard.set(65, forKey: "SpanLongDelta")
            travelLocationsVC.firstLaunch = true
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = UINavigationController(rootViewController: travelLocationsVC)
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        UserDefaults.standard.synchronize()
        CoreDataStack.shared.saveContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UserDefaults.standard.synchronize()
        CoreDataStack.shared.saveContext()
    }

}

