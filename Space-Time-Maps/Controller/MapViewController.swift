//
//  GMapViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController {

    var mapView : GMSMapView!
    let defaultLocation = CLLocation(latitude: 43.6532, longitude: -79.3832) // Toronto
    let defaultZoom: Float = 13.0
    
    // Map mark-up
    var polylines: [String] = []
    var markers: [GMSMarker] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: defaultZoom)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        //Style map w/ json file
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }
        } catch {
            NSLog("Failed to load style.")
        }
        
        // Subscribe to location updates
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateLocation(_:)), name: .didUpdateLocation, object: nil)
        
        // Set our view to be the map
        view = mapView
        
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        self.mapView.delegate = parent as? GMSMapViewDelegate
    }

    func clearMap() {
        self.mapView.clear()
    }
    
    func displayPlaces(_ places: [Place]) {
        displayPlaces(places, color: .gray)
    }

    func displayPlaces(_ places: [Place], color: UIColor) {
        for place in places {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: place.coordinate.lat, longitude: place.coordinate.lon)
            marker.title = place.name
            marker.icon = GMSMarker.markerImage(with: color)
            marker.map = self.mapView
        }
    }
    
    func displayRoute(_ route: String) {
        let path = GMSPath(fromEncodedPath: route)
        let polyline = GMSPolyline(path: path)
        polyline.map = self.mapView
    }

    func displayRoutes(_ routes: [String]) {
        for line in routes {
            displayRoute(line)
        }
    }
    
    @objc func onDidUpdateLocation(_ notification: Notification) {
        if let location = notification.userInfo?["location"] as? CLLocation {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  zoom: defaultZoom)
            
            if mapView.isHidden {
                mapView.isHidden = false
                mapView.camera = camera
            } else {
                mapView.animate(to: camera)
            }
        } else {
            print("Could not unwrap notification")
        }
    }

}
