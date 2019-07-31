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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set up custom services
        locationService = LocationService()
        let queryService = QueryService()
        let savedPlaces = PlaceManager(withStarterPlaces: true)
        let itineraryManager = ItineraryManager(queryService)
        
        // Inject into root view
//        let homeViewController = self.window?.rootViewController?.childViewControllers.first as? HomeViewController
        let homeViewController = self.window?.rootViewController?.children.first as? PlannerViewController
        if let homeViewController = homeViewController {
            homeViewController.savedPlaces = savedPlaces
            homeViewController.itineraryManager = itineraryManager
//            homeViewController.queryService = queryService
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
            queryService.apiKey = mapsKey!
//            homeViewController?.queryService.apiKey = mapsKey!
        }
        
        return true
    }
    
}

