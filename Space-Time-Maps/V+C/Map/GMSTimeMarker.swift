//
//  GMSTimeMarker.swift
//  Space-Time-Maps
//
//  Created by Vicky on 23/11/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps

class GMSTimeMarker : GMSMarker {
    
    var timeLabel : UILabel!
    var time : TimeInterval! {
        didSet {
            timeLabel?.text = Utils.secondsToAbsoluteTimeString(time)
        }
    }
    var pos : Coordinate! {
        didSet {
            self.position = CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude)
        }
    }
    var color : UIColor! {
        didSet {
            self.iconView?.backgroundColor? = color.withAlphaComponent(0.8)
        }
    }
    
    static func markerWithPosition(_ position: Coordinate, time: TimeInterval) -> GMSTimeMarker {
        
        let marker = GMSTimeMarker()
        marker.time = time
        marker.pos = position
        marker.position = Coordinate(latitude: position.latitude, longitude: position.longitude)
        
        let frame = CGRect(x: 0, y: 0, width: 50, height: 25)
        let overlayView = UIView(frame: frame)
        let label = UILabel(frame: frame)
        overlayView.addSubview(label)
        overlayView.backgroundColor = .black
        overlayView.layer.cornerRadius = 5
        label.textColor = .white
        label.text = Utils.secondsToAbsoluteTimeString(time)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        marker.timeLabel = label
        
        marker.iconView = overlayView
        marker.zIndex = 10
        
        return marker
    }
    
}
