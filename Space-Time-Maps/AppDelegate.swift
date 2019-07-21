//
//  AppDelegate.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-06-29.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // WITHOUT STORYBOARD
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.makeKeyAndVisible()
//
//        // Set up root view controller
//        let rootController = MapViewController()
//        rootController.placeManager = PlaceManager()
//        rootController.queryService = QueryService()
//
//        // Set up navigation view controller
//        window?.rootViewController = MyNavigationController(rootViewController: rootController)
        
        // WITH STORYBOARD
        let mapViewController = self.window?.rootViewController?.childViewControllers.first as? MapViewController
        if let mapViewController = mapViewController {
            mapViewController.placeManager = PlaceManager(withStarterPlaces: true)
            mapViewController.queryService = QueryService()
        }

        // Set up API key
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = keys {
            let mapsKey = dict["mapsKey"] as? String
            GMSServices.provideAPIKey(mapsKey!)
            GMSPlacesClient.provideAPIKey(mapsKey!)
            mapViewController?.queryService.apiKey = mapsKey!
        }
        
        return true
    }

}

