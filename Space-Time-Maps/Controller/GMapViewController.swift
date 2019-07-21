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

class GMapViewController: UIViewController {
    
    var placeManager: PlaceManager!
    
    // Google Maps stuff
    var placesClient: GMSPlacesClient!
    var mapView : GMSMapView!
    let defaultLocation = CLLocation(latitude: 43.6532, longitude: -79.3832) // Toronto
    let defaultZoom: Float = 13.0

    override func viewDidLoad() {
        super.viewDidLoad()

    }
//    
//    @objc func onDidUpdateLocation(_ notification: Notification) {
//        if let location = notification.userInfo?["location"] as? CLLocation {
//            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
//                                                  longitude: location.coordinate.longitude,
//                                                  zoom: defaultZoom)
//            
//            if mapView.isHidden {
//                mapView.isHidden = false
//                mapView.camera = camera
//            } else {
//                mapView.animate(to: camera)
//            }
//        } else {
//            print("Could not unwrap notification")
//        }
//    }
//    
//    func refreshMapMarkup() {
//        self.mapView.clear()
//        displayPlaces()
//        displayRoutes()
//    }
//    
//    func displayPlaces() {
//        for place in self.placeManager.getPlaces() {
//            let marker = GMSMarker()
//            marker.position = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
//            marker.title = place.name
//            marker.map = self.mapView
//        }
//    }
//    
//    func displayRoutes() {
//        for line in self.polylines {
//            let path = GMSPath(fromEncodedPath: line)
//            let polyline = GMSPolyline(path: path)
//            polyline.map = self.mapView
//        }
//    }


}
