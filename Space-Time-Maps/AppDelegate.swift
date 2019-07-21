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
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationService: LocationService?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Set up custom services
        locationService = LocationService()
        let placeManager = PlaceManager(withStarterPlaces: true)
        let queryService = QueryService()
        
        // Inject into root view
        let homeViewController = self.window?.rootViewController?.childViewControllers.first as? HomeViewController
        if let homeViewController = homeViewController {
            homeViewController.placeManager = placeManager
            homeViewController.queryService = queryService
        }

        // Set up GMaps API w/ key
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = keys {
            let mapsKey = dict["mapsKey"] as? String
            GMSServices.provideAPIKey(mapsKey!)
            GMSPlacesClient.provideAPIKey(mapsKey!)
            homeViewController?.queryService.apiKey = mapsKey!
        }
        
        return true
    }
    
}

