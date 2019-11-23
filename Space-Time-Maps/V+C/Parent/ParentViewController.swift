//
//  ViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

class ParentViewController: UIViewController {
    
    var initialPlacesLoaded = false
    
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
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchObject)))
    }
    
    override func viewDidLayoutSubviews() {
        updateMap()
        print("layout subviews")
        if !initialPlacesLoaded {
            itineraryController.updateScheduler(placePaletteController.groups.flatMap({$0.places}))
            initialPlacesLoaded = true
        }
    }
    
    // Pass pinches down to itinerary
    @objc func pinchObject(_ gesture: UIPinchGestureRecognizer) {
        itineraryController.pinchLocationCell(gesture: gesture)
    }
    
    // Pass travel mode changes down to itinerary
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
            itineraryController.updateScheduler(travelMode)
            itineraryController.computeRoute()
        }
    }
    
    
    @objc func swipeOutPalette(_ sender: Any) {
        
        guard let palette = placePaletteController else { return }
        view.layoutIfNeeded()
        UIView.setAnimationCurve(.easeOut)
        
        palette.inEditingMode = !palette.inEditingMode
        
        if palette.inEditingMode {
            
            // Maximize palette
            UIView.animate(withDuration: 0.5, animations: {
                
                self.paletteSmallWidth.priority = .defaultHigh - 1
                self.paletteBigWidth.priority = .defaultHigh + 1
                palette.groupButton.toggle()
                palette.searchButton.toggle()
                self.view.layoutIfNeeded()
                palette.setupCellWidth()
                palette.collectionView.reloadData()
                
            })
            
            // Enable palette editing
            palette.dragDelegate = palette
            
        } else {
            
            // Minimize palette
            UIView.animate(withDuration: 0.5, animations: {
                
                self.paletteSmallWidth.priority = .defaultHigh + 1
                self.paletteBigWidth.priority = .defaultHigh - 1
                palette.groupButton.toggle()
                palette.searchButton.toggle()
                self.view.layoutIfNeeded()
                palette.setupCellWidth()
                palette.collectionView.reloadData()
                
            })
            
            // Return drag-and-drop functionality to itinerary
            palette.dragDelegate = self.itineraryController
        }
    
    }
    
    // Package itinerary and place data to send to map for rendering
    // TODO: REDO!!!
    func updateMap() {
        guard mapController.viewIfLoaded != nil else { return }
        
        // Package relevant data
        let itinerary = itineraryController.itinerary
        let groups = placePaletteController.groups
        let itineraryLegs = itinerary.route.legs
        
        // Send data to map
        mapController.refreshMarkup(placeGroups: groups, routeLegs: itineraryLegs)

    }
    
    func updateTransportTimeLabel() {
        let duration = itineraryController.itinerary.duration
        let travelTime = itineraryController.itinerary.route.travelTime
        
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
            placePaletteController = placePaletteVC
            
        }
        else if let itineraryVC = segue.destination as? ItineraryViewController {
            
            if let placePaletteController = placePaletteController {
                placePaletteController.dragDelegate = itineraryVC as DragDelegate
            }
            if let mapVC = mapController {
                itineraryVC.timeQueryDelegate = mapVC as! TimeQueryDelegate
            }
            itineraryVC.delegate = self
            itineraryController = itineraryVC
            
        } else if let mapVC = segue.destination as? MapViewController {
            if let itineraryVC = itineraryController {
                itineraryVC.timeQueryDelegate = mapVC as! TimeQueryDelegate
            }
            mapVC.delegate = self
            mapController = mapVC
            updateMap()
            
        }
    }
    
    
}

extension ParentViewController : PlacePaletteViewControllerDelegate {
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didAddPlace place: Place, toGroups groups: [PlaceGroup]) {
        print("add place")
        updateMap()
        let places = groups.flatMap({ $0.places })
        itineraryController.updateSchedulerWithPlace(place, in: places)
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didRemovePlace place: Place, fromGroups: [PlaceGroup]) {
        print("removed places")
        updateMap()
    }
    
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces groups: [PlaceGroup]) {
        print("update places")
        updateMap()
        let places = groups.flatMap({ $0.places })
        itineraryController.updateScheduler(places)
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didPressEdit sender: Any) {
        swipeOutPalette(sender)
    }
    
}

extension ParentViewController : ItineraryViewControllerDelegate {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary) {
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
