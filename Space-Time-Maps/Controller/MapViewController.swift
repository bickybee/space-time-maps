//
//  GMapViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//
//  MapViewController: responsible for rendering Google Maps and overlays to the map.

import UIKit
import GoogleMaps
import GooglePlaces

struct PlaceVisual {
    let place : Place
    let color : UIColor
}

struct RouteVisual {
    let route : String
    let color : UIColor
}

class MapViewController: UIViewController {

    var mapView : GMSMapView!
    let defaultLocation = CLLocation(latitude: 43.6532, longitude: -79.3832) // Toronto
    let defaultZoom: Float = 13.0
    
    var placeVisuals = [PlaceVisual]()
    var routeVisuals = [RouteVisual]()

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
        refreshMarkup()
        
    }
    
    // Parent should respond to user input, eventually trickle down only what should be rendered
    override func didMove(toParent parent: UIViewController?) {
        self.mapView.delegate = parent as? GMSMapViewDelegate
    }
    
    // Refresh all map markup
    func refreshMarkup() {
        clearMap()
        displayRoutes()
        displayPlaces()
    }

    // Clear all map markup
    func clearMap() {
        self.mapView.clear()
    }
    
    // Pass in data needed to create place marker overlays
    func setPlaces(_ places: [PlaceVisual]) {
        placeVisuals = places
    }
    
    // Pass in data needed to visualize routes
    func setRoutes(_ routes: [RouteVisual]) {
        routeVisuals = routes
    }

    // Render place markers
    func displayPlaces() {
        for placeVisual in placeVisuals {
            let place = placeVisual.place
            let color = placeVisual.color
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: place.coordinate.lat, longitude: place.coordinate.lon)
            marker.title = place.name
            marker.icon = GMSMarker.markerImage(with: color)
            marker.map = self.mapView
        }
    }
    
    // Render route polylines
    func displayRoutes() {
        for routeVisual in routeVisuals {
            let route = routeVisual.route
            let color = routeVisual.color
            let path = GMSPath(fromEncodedPath: route)
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = color
            polyline.map = self.mapView
        }
    }
    
    // Respond to notification updates by displaying current location on the map
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
