//
//  ItineraryViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryViewController: DraggableContentViewController {
    
    var optionsVC: OptionsViewController!
    var collectionVC: ItineraryCollectionViewController!

    // Itinerary editing
    var editingSession : ItineraryEditingSession?
    var previousTouchHour : Double?
    var defaultDuration = TimeInterval.from(hours: 1.0)

    // Delegate (subscribes to itinerary updates)
    weak var delegate : ItineraryViewControllerDelegate?
    
    // Collection view data source!
    var itinerary = Itinerary()
    let scheduler = Scheduler()
    
    var dragging = false
    
    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showDraggingView = false
        setupChildViews()

    }

    
    func setupChildViews() {
        
        collectionVC = ItineraryCollectionViewController(with: itinerary, layout: ItineraryLayout())
        
        add(collectionVC, frame: self.view.frame)
        
    }
    
    func computeRoute() {
        // This is called when the mode of transport changes, but needs to be fixed because it won't update asManyOf blocks if they change to no longer fit their dests...
        scheduler.reschedule(blocks: itinerary.schedule, callback: didEditItinerary)
        
    }
    
    func updateScheduler(_ places: [Place]) {
        scheduler.updatePlaces(places)
    }
    
    func updateScheduler(_ travelMode: TravelMode) {
        scheduler.travelMode = travelMode
        scheduler.reschedule(blocks: itinerary.schedule, callback: didEditItinerary(blocks:route:))
    }
    
    @objc func pinchLocationCell(gesture: UIPinchGestureRecognizer) {
        
        guard let editingSession = editingSession else { return }
        
        let dir = Double(gesture.scale - 1.0)
        let thresh = 0.05
        
        if abs(dir) >= thresh {
            let step = dir > 0 ? 1 : -1
            let deltaTime = TimeInterval.from(minutes: step * 15)
            editingSession.changeBlockDuration(with: deltaTime)
            gesture.scale = 1.0
        }
        
    }

}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        guard let block = blockFromObject(object) else { return }
        var editingBlocks = itinerary.schedule
        var index : Int?
        
        if draggableContentViewController is ItineraryViewController {
            editingBlocks.remove(at: indexPath.item)
            index = indexPath.item
        }
        
        editingSession = ItineraryEditingSession(scheduler: scheduler, movingBlock: block, withIndex: index, inBlocks: editingBlocks, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionVC.view)
        
        if !collectionVC.view.frame.contains(location) {
            if previousTouchHour != nil {
                editingSession.removeBlock()
                previousTouchHour = nil
            }
            return
        }
        
        let y = gesture.location(in: view).y
        let hour = collectionVC.roundedHourInCollection(forY: y)
        
        if hour != previousTouchHour {
            editingSession.moveBlock(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        editingSession = nil
        previousTouchHour = nil
        
    }
    
    func didEditItinerary(blocks: [ScheduleBlock]?, route: Route?) {
        
        if let blocks = blocks {
            self.itinerary.schedule = blocks
        }
        
        if let route = route {
            self.itinerary.route = route
        }
        
        DispatchQueue.main.async {
            self.collectionVC.collectionView.reloadData()
            self.delegate?.itineraryViewController(self, didUpdateItinerary: self.itinerary)
        }

    }
    
    func blockFromObject(_ object : Any) -> ScheduleBlock? {
        
        // If we're dragging within the itinerary, object is and stays a block
        if let scheduleObject = object as? ScheduleBlock {
            return scheduleObject
        } else { // Otherwise we're dragging a place or placegroup from the palette into the itinerary, meaning we need to turn it into a block
            if let place = object as? Place {
                return SingleBlock(timing: Timing(start: 0, duration: place.timeSpent), place: place)
                
            } else if let group = object as? PlaceGroup {
                switch group.kind {
                case .asManyOf:
                    return AsManyOfBlock(placeGroup: group, timing: Timing(start: 0, duration: TimeInterval.from(hours: 2)))
                case .oneOf,
                     .none:
                    return  OneOfBlock(placeGroup: group, timing: Timing(start: 0, duration: defaultDuration))
                }
                
            } else {
                return nil
            }
        }
        
    }
    
}

extension ItineraryViewController: DragDataDelegate {
    
    func objectFor(draggable: UIView) -> Any? {
        guard let draggable = draggable as? UICollectionViewCell,
              let indexPath = collectionVC.collectionView.indexPath(for: draggable),
              let obj = collectionVC.eventFor(indexPath: indexPath) else { return nil }
        
        if obj is ScheduleBlock {
            return obj
        } else if obj is Destination {
            return blockOfDestination(at: indexPath.item)
        } else {
            return nil
        }
    
    }
    
    func indexPathFor(draggable: UIView) -> IndexPath? {
        guard let draggable = draggable as? UICollectionViewCell,
              let indexPath = collectionVC.collectionView.indexPath(for: draggable) else { return nil}
        
        return indexPath
    }
    
    // this is bad i think?? lol TODO make not bad!
    func blockOfDestination(at index: Int) -> ScheduleBlock? {
        
        var count = 0
        
        for block in itinerary.schedule {
            
            if let destinations = block.destinations {
                count += destinations.count
            }
            
            if count > index {
                return block
            }

        }
        
        return nil
        
    }
    
}

// MARK: - Self delegate protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
