//
//  ItineraryViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryViewController: DraggableContentViewController {

    // CollectionView Cell constants
    private let locationReuseIdentifier = "locationCell"
    private let legReuseIdentifier = "legCell"
    
    // Child views
    @IBOutlet weak var collectionView: UICollectionView!
    var timelineController: TimelineViewController!

    // Itinerary editing
    var editingSession : ItineraryEditingSession?
    var previousTouchHour : Double?
    var defaultDuration = TimeInterval.from(hours: 0.5)

    // Delegate (subscribes to itinerary updates)
    weak var delegate : ItineraryViewControllerDelegate?
    
    // Collection view data source!
    var itinerary = Itinerary(destinations: [Destination](), route:[Leg](), travelMode: .driving) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dragDelegate = self as DragDelegate
        self.dragDataDelegate = self as DragDataDelegate
        
        setupCollectionView()
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action:#selector(pinchLocationCell)))

    }
    
    override func viewDidLayoutSubviews() {
        timelineController.setSidebarWidth(collectionView.frame.minX)
    }
    
    func setupCollectionView() {
        if let layout = collectionView?.collectionViewLayout as? ItineraryLayout {
            layout.delegate = self
        }
        collectionView.register(DestinationCell.self, forCellWithReuseIdentifier: locationReuseIdentifier)
        collectionView.register(LegCell.self, forCellWithReuseIdentifier: legReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
    }
    
    func computeRoute() {
        let scheduler = Scheduler()
        scheduler.schedule(destinations: itinerary.destinations, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let timelineVC = segue.destination as? TimelineViewController {
            
            timelineVC.delegate = self
            timelineController = timelineVC
            
        }
    }
    
    @objc func pinchLocationCell(gesture: UIPinchGestureRecognizer) {
        guard let editingSession = editingSession else { return }
        
        print("pinch!")
        let scale = Double(gesture.scale)
        editingSession.scaleDestinationDuration(with: scale)
        gesture.scale = 1.0
    }

}

// MARK: - CollectionView delegate methods
extension ItineraryViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return itinerary.destinations.count
        } else {
            return itinerary.route.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestinationCell
            return setupLocationCell(cell, with: indexPath.item)
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! LegCell
            return setupLegCell(cell, with: indexPath.item)
        }
        
    }
    
    func setupLocationCell(_ cell: DestinationCell, with index: Int) -> DestinationCell {
        
        guard let destination = itinerary.destinations[safe: index] else { return cell }
//        if editingSession != nil {
//            cell.setupWith(name: destination.place.name, color: .lightGray, constrained: destination.constraints.areEnabled)
//        } else {
        let fraction = Double(index) / Double(itinerary.destinations.count - 1)
        cell.setupWith(name: destination.place.name, fraction: fraction, constrained: destination.constraints.areEnabled)
    
        addDragRecognizerTo(draggable: cell)
        return cell
        
    }
    
    func setupLegCell(_ cell: LegCell, with index: Int) -> LegCell {
        
        let legs = itinerary.route
        guard let leg = legs[safe: index] else { return cell }
        
        let startFraction = Double(index) / Double(legs.count)
        let endFraction = Double(index + 1) / Double(legs.count + 1)
        cell.setupWith(duration: leg.travelTiming.duration, hourHeight: timelineController.hourHeight, startFraction: startFraction, endFraction: endFraction)
        
        return cell
    }
}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func didEditItinerary(destinations: [Destination]?, route: Route?) {
        
        guard let destinations = destinations, let route = route else { return }
        
        self.itinerary.destinations = destinations
        self.itinerary.route = route
        delegate?.itineraryViewController(self, didUpdateItinerary: itinerary)
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        let destination : Destination
        if let place = object as? Place {
            destination = Destination(place: place, timing: Timing(start: 0, duration: defaultDuration), constraints: Constraints())
        } else if let dest = object as? Destination {
            destination = dest
        } else {
            return
        }
        
        var editingDestinations = itinerary.destinations
        
        if draggableContentViewController as? ItineraryViewController != nil {
            editingDestinations.remove(at: indexPath.item)
        }
        
        editingSession = ItineraryEditingSession(movingDestination: destination, withIndex: indexPath.item, inDestinations: editingDestinations, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionView)
        
        if !collectionView.frame.contains(location) {
            editingSession.removeDestination()
            return
        }
        
        let cell = draggableContentViewController.draggingView!
        let y = location.y - cell.frame.height / 2
        let hour = timelineController.roundedHourInTimeline(forY: y)
        if hour != previousTouchHour {
            
            editingSession.moveDestination(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
//        editingSession?.end()
        editingSession = nil
        previousTouchHour = nil
        
    }
    
    func cellForIndex(_ indexPath: IndexPath) -> Draggable? {
        
        return collectionView.cellForItem(at: indexPath) as? Draggable
        
    }
    
}

extension ItineraryViewController: DragDataDelegate {
    
    func objectFor(draggable: Draggable) -> Any? {
        guard let draggable = draggable as? UICollectionViewCell,
            let indexPath = collectionView.indexPath(for: draggable),
              let destination = itinerary.destinations[safe: indexPath.item] else { return nil }
        
        return destination
    }
    
    func indexPathFor(draggable: Draggable) -> IndexPath? {
        guard let draggable = draggable as? UICollectionViewCell,
            let indexPath = collectionView.indexPath(for: draggable) else { return nil}
        return indexPath
    }
    
}


// MARK: - Custom CollectionView Layout delegate methods
extension ItineraryViewController : ItineraryLayoutDelegate {
    
    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat {
        return timelineController.startHour
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return timelineController.hourHeight
    }
    
    func collectionView(_ collectionView:UICollectionView, timingForSchedulableAtIndexPath indexPath: IndexPath) -> Timing {
        guard let schedulable = schedulableFor(indexPath: indexPath) else { return Timing() }
        return schedulable.timing
    }
    
    func schedulableFor(indexPath: IndexPath) -> Schedulable? {
        
        let section = indexPath.section
        let item = indexPath.item
        
        if section == 0 {
            return itinerary.destinations[safe: item]
        } else if section == 1 {
            return itinerary.route[safe: item]
        } else {
            return nil
        }
        
    }
}

extension ItineraryViewController: TimelineViewDelegate {
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateStartHour: CGFloat) {
        collectionView.reloadData()
    }
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat) {
        collectionView.reloadData()
    }
    
}

// MARK: - Self delegate protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
