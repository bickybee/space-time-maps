//
//  ViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GooglePlaces

class ParentViewController: UIViewController {
    
    // Child view controllers
    var placePaletteController : PlacePaletteViewController!
    var itineraryController : ItineraryViewController!
    var mapController : MapViewController!
    
    @IBOutlet weak var paletteContainer: UIView!
    @IBOutlet weak var itineraryContainer: UIView!
    
    // UI outlets
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var travelTimeLabel: UILabel!
    @IBOutlet weak var transportModePicker: UISegmentedControl!
    @IBOutlet weak var paletteSmallWidth: NSLayoutConstraint!
    @IBOutlet weak var paletteBigWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchObject))
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    @objc func pinchObject(_ gesture: UIPinchGestureRecognizer) {
        
        itineraryController.pinchLocationCell(gesture: gesture)
    }
    
    
    // Change the mode of transport for the route calculations
    // FOR NOW just passing this to itineraryController, maybe should be part of that to begin with
    @IBAction func transportModeChanged(_ sender: Any) {
        if let control = sender as? UISegmentedControl {
            let selection = control.selectedSegmentIndex
            var travelMode : TravelMode
            switch selection {
            case 0:
                travelMode = .driving
            case 1:
                travelMode = .walking
            case 2:
                travelMode = .bicycling
            case 3:
                travelMode = .transit
            default:
                travelMode = .driving
            }
            itineraryController.itinerary.travelMode = travelMode
            itineraryController.computeRoute()
        }
    }
    
    @objc func swipeOutPalette(_ sender: Any) {
        
        guard let palette = placePaletteController else { return }
        view.layoutIfNeeded()
        UIView.setAnimationCurve(.easeOut)
        
        if !palette.inEditingMode {
            UIView.animate(withDuration: 0.5, animations: {
                self.paletteSmallWidth.priority = .defaultHigh - 1
                self.paletteBigWidth.priority = .defaultHigh + 1
                palette.groupButton.isEnabled = true
                palette.groupButton.alpha = 1.0
                palette.searchButton.isEnabled = true
                palette.searchButton.alpha = 1.0
                self.view.layoutIfNeeded()
                palette.collectionView.reloadData()
            })
            palette.dragDelegate = palette
            
        } else {
            self.paletteSmallWidth.priority = .defaultHigh + 1
            self.paletteBigWidth.priority = .defaultHigh - 1
            UIView.animate(withDuration: 0.5, animations: {
                
                palette.groupButton.isEnabled = false
                palette.groupButton.alpha = 0.0
                palette.searchButton.isEnabled = true
                palette.searchButton.alpha = 1.0
                self.view.layoutIfNeeded()
                palette.collectionView.reloadData()
            })
            palette.dragDelegate = self.itineraryController
        }
        
        palette.inEditingMode = !palette.inEditingMode
        
        
    }
    
    func markItineraryPlaces() {
        var groups = placePaletteController.groups
        for i in 0 ... (groups.count - 1)  {
            groups[i].places = markItineraryPlaces(for: groups[i])
        }
    }
    
    // Compare itinerary places and saved places, mark which saved places are in the itinerary
    func markItineraryPlaces(for group: Group) -> [Place] {
        let savedPlaces = group.places
        let itineraryEvents = itineraryController.itinerary.events
        savedPlaces.forEach{ $0.isInItinerary = false}
        for savedPlace in savedPlaces {
            for event in itineraryEvents {
                if let destination = event as? Destination {
                    if savedPlace == destination.place {
                        savedPlace.isInItinerary = true
                    }
                }
            }
        }
        return savedPlaces
    }
    
    // Package itinerary and place data to send to map for rendering
    func updateMap() {
        guard mapController.viewIfLoaded != nil else { return }
        
        // Package relevant data
        let itinerary = itineraryController.itinerary
        let groups = placePaletteController.groups
        let palettePlaces = groups.flatMap { $0.places }
        
        let nonItineraryPlaces = palettePlaces.filter { !$0.isInItinerary }
        var itineraryDestinations = [Destination]()
        itinerary.events.forEach( { if let dest = $0 as? Destination {itineraryDestinations.append(dest)} } )
        let itineraryPlaces = itineraryDestinations.map { $0.place }
        let itineraryLegs = itinerary.route
        
        // Send data to map
        mapController.refreshMarkup(destinationPlaces: itineraryPlaces, nonDestinationPlaces: nonItineraryPlaces, routeLegs: itineraryLegs)

    }
    
    func updateTransportTimeLabel() {
        let duration = itineraryController.itinerary.duration
        let travelTime = itineraryController.itinerary.travelTime
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        
        totalTimeLabel.text = formatter.string(from: TimeInterval(duration))!
        travelTimeLabel.text = formatter.string(from: TimeInterval(travelTime))!


    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let placePaletteVC = segue.destination as? PlacePaletteViewController {
            
            if let itineraryController = itineraryController {
                placePaletteVC.dragDelegate = itineraryController as DragDelegate
            }
            placePaletteVC.delegate = self
            placePaletteVC.view.frame.size.width = self.view.frame.size.width / 2 // HACKY!
            placePaletteVC.enlargeButton.addTarget(self, action: #selector(swipeOutPalette(_:)), for: .touchUpInside)
            placePaletteController = placePaletteVC
            
        }
        else if let itineraryVC = segue.destination as? ItineraryViewController {
            
            if let placePaletteController = placePaletteController {
                placePaletteController.dragDelegate = itineraryVC as DragDelegate
            }
            itineraryVC.delegate = self
            itineraryVC.view.frame.size.width = self.view.frame.size.width / 2 // HACKY!
            itineraryController = itineraryVC
            
        } else if let mapVC = segue.destination as? MapViewController {
            
            mapVC.delegate = self
            mapController = mapVC
            updateMap()
            
        }
    }
}

extension ParentViewController : PlacePaletteViewControllerDelegate {
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces groups: [Group]) {
        updateMap()
    }
    
}

extension ParentViewController : ItineraryViewControllerDelegate {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary) {
        markItineraryPlaces()
        updateTransportTimeLabel()
        updateMap()
    }
    
}

extension ParentViewController : MapViewControllerDelegate {
    
    func mapViewController(_ mapViewController: MapViewController, didUpdateBounds bounds: GMSCoordinateBounds) {
        if let placePaletteController = placePaletteController {
            placePaletteController.geographicSearchBounds = bounds
        }
    }
    
}
