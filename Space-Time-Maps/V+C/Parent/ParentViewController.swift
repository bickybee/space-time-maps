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
    
    var timePickerController : PopupViewController?
    
    @IBOutlet weak var paletteContainer: UIView!
    @IBOutlet weak var itineraryContainer: UIView!
    
    // UI outlets
    
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var travelTimeLabel: UILabel!
    @IBOutlet weak var transportModePicker: UISegmentedControl!
    @IBOutlet weak var paletteSmallWidth: NSLayoutConstraint!
    @IBOutlet weak var paletteBigWidth: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        travelTimeLabel.adjustsFontSizeToFitWidth = true
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinchObject)))
        NotificationCenter.default.addObserver(self, selector: #selector(onDidStartContentDrag), name: .didStartContentDrag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidEndContentDrag), name: .didEndContentDrag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidTapDestination), name: .didTapDestination, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(onDidContinueContentDrag), name: .didContinueContentDrag, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        if !initialPlacesLoaded {
            itineraryController.updateScheduler(placePaletteController.groups.flatMap({$0.places}), nil)
            updateMap()
            fitMapToAllMarkers()
            initialPlacesLoaded = true
        }
    }
    
    @objc func onDidStartContentDrag(_ notification: Notification) {
        var places = [Place]()
        if let block = notification.object as? ScheduleBlock {
            places = block.places
        } else if let place = notification.object as? Place {
            places = [place]
        } else if let placeGroup = notification.object as? PlaceGroup {
            places = placeGroup.places
        }
        
        mapController!.currentDraggingPlaces = places
        updateMap()
    }
    
    @objc func onDidEndContentDrag(_ notification: Notification) {
        mapController!.currentDraggingPlaces = []
        updateMap()
    }
    
//    @objc func onDidContinueContentDrag(_ notification: Notification) {
//        mapController!.currentDraggingPlaces = []
//    }
    
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
            itineraryController.updateScheduler(placePaletteController.groups.flatMap({$0.places})) {
                self.itineraryController.computeRoute()
            }
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
                palette.enlargeButton.setTitle("done", for: .normal)
                self.view.layoutIfNeeded()
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
                palette.enlargeButton.setTitle("edit ", for: .normal)
                self.view.layoutIfNeeded()
                palette.collectionView.reloadData()
                
            })
            
            // Return drag-and-drop functionality to itinerary
            palette.dragDelegate = self.itineraryController
        }
    
    }
    
    @objc func onDidTapDestination(_ notification: Notification) {
        
        guard let obj = notification.object as? (Schedulable, Int) else { return }
        
        let schedulable = obj.0
        let index = obj.1

        timePickerController?.dismiss(animated: false, completion: {})
        timePickerController?.removeFromParent()
        timePickerController?.view.removeFromSuperview()

        showTimePickerForSchedulable(schedulable, at: index)
    
    }
    
    func showTimePickerForSchedulable(_ schedulable: Schedulable, at index: Int) {
        if let block = schedulable as? ScheduleBlock {
            showTimePickerForBlock(block, at: index)
        } else if let dest = schedulable as? Destination{
            showTimePickerForDestination(dest, inBlockIndex: index)
        }
    }
    
    func showTimePickerForDestination(_ dest: Destination, inBlockIndex index: Int) {
        let frame = mapController.mapView.frame.insetBy(dx: 50, dy: 20).offsetBy(dx: 0, dy: 80)
        let timePickerVC = DurationTimeViewController(dest)
        timePickerVC.view.frame = frame
        timePickerVC.onUpdatedDurationBlock = { duration in
            self.itineraryController.updateBlockPlaceDuration(index, duration)
        }
        timePickerVC.onDoneBlock = {
            
            UIView.animate(withDuration: 0.25, animations: {
                timePickerVC.view.alpha = 0.0
            }, completion: { success in
                timePickerVC.dismiss(animated: false, completion: {
                    self.timePickerController = nil
                })
            })
            
            self.placePaletteController.collectionView.reloadData()
            self.itineraryController.endEditingSession()
        }
        
        addChild(timePickerVC)
        view.addSubview(timePickerVC.view)
        timePickerVC.didMove(toParent: self)
        
        timePickerController = timePickerVC
    }
    
    func showTimePickerForBlock(_ block: ScheduleBlock, at index: Int) {
        
        let frame = mapController.mapView.frame.insetBy(dx: 50, dy: 20).offsetBy(dx: 0, dy: 80)
        let timePickerVC = StartEndTimeViewController(block)
        timePickerVC.view.frame = frame
        timePickerVC.onUpdatedTimingBlock = itineraryController.editBlockTiming
        timePickerVC.onDoneBlock = {
            
            UIView.animate(withDuration: 0.25, animations: {
                timePickerVC.view.alpha = 0.0
            }, completion: { success in
                timePickerVC.dismiss(animated: false, completion: {})
            })
            
            self.placePaletteController.collectionView.reloadData()
            self.itineraryController.endEditingSession()
        }
        
        addChild(timePickerVC)
        view.addSubview(timePickerVC.view)
        timePickerVC.didMove(toParent: self)
        
        timePickerController = timePickerVC
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
        mapController.refreshMarkup(placeGroups: groups, itinerary: itinerary)

    }
    
    func fitMapToAllMarkers() {
        mapController.fitToAllMarkers()
    }
    
    func updateTransportTimeLabel() {
        let startTime = itineraryController.itinerary.startTime
        let endTime = itineraryController.itinerary.endTime
        let travelTime = itineraryController.itinerary.route.travelTime
        
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "hh:mma"
        
        var startText = "00:00AM"
        var endText = "00:00AM"
        if let startTime = startTime {
            startText = formatter2.string(from: startTime)
        }
        if let endTime = endTime {
            endText = formatter2.string(from: endTime)
        }
        startTimeLabel.text = startText
        endTimeLabel.text = endText
        travelTimeLabel.text = Utils.secondsToRelativeTimeString(seconds: travelTime)


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
            fitMapToAllMarkers()
            
        }
    }
    
    
}

extension ParentViewController : PlacePaletteViewControllerDelegate {
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didAddPlace place: Place, toGroups groups: [PlaceGroup]) {
        updateMap()
        let places = groups.flatMap({ $0.places })
        itineraryController.updateSchedulerWithPlace(place, in: places)
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didRemovePlace place: Place, fromGroups groups: [PlaceGroup]) {
        updateMap()
        itineraryController.removePlace(place, in: groups)
    }
    
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didUpdatePlaces groups: [PlaceGroup]) {
        itineraryController.updatePlaceGroups(groups)
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didPressEdit sender: Any) {
        swipeOutPalette(sender)
    }
    
    func placePaletteViewController(_ placePaletteViewController: PlacePaletteViewController, didRemoveGroupfromGroups groups: [PlaceGroup]) {
        updateMap()
        itineraryController.removedGroupFrom(groups)
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
