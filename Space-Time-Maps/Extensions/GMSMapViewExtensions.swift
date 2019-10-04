//
//  GMSMapViewExtension.swift
//  Space-Time-Maps
//
//  Created by Vicky on 15/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps.GMSMapView
import GoogleMaps.GMSMarker


extension GMSMapView {
    
    func add(overlays: [GMSOverlay]) {
        overlays.forEach( { $0.map = self } )
    }
    
    func wrapBoundsTo(markers: [GMSMarker]) -> GMSCoordinateBounds {
        
        var bounds = GMSCoordinateBounds()
        for marker in markers {
            bounds = bounds.includingCoordinate(marker.position)
        }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 60)
        self.animate(with: update)
        
        return bounds
        
    }
    
    func moveCameraTo(latitude: Double, longitude: Double) {
        let camera = GMSCameraPosition.camera(withLatitude: latitude,
                                              longitude: longitude,
                                              zoom: 12.0) // default zoom?
        
        if self.isHidden {
            self.isHidden = false
            self.camera = camera
        } else {
            self.animate(to: camera)
        }
    }
}
