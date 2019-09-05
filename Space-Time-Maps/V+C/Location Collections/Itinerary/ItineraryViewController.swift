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
    private let oneOfReuseIdentifier = "oneOfCell"
    private let groupReuseIdentifier = "groupCell"
    
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
    var itinerary = Itinerary(events: [Event](), route:[Leg](), travelMode: .driving) {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var dragging = false
    
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
//        collectionView.register(DestinationCell.self, forCellWithReuseIdentifier: locationReuseIdentifier)
        collectionView.register(LegCell.self, forCellWithReuseIdentifier: legReuseIdentifier)
        let oneOfNib = UINib(nibName: "OneOfCell", bundle: nil)
        let destNib = UINib(nibName: "DestCell", bundle: nil)
        let groupNib = UINib(nibName: "GroupCell", bundle: nil)
        collectionView.register(oneOfNib, forCellWithReuseIdentifier: oneOfReuseIdentifier)
        collectionView.register(destNib, forCellWithReuseIdentifier: locationReuseIdentifier)
        collectionView.register(groupNib, forCellWithReuseIdentifier: groupReuseIdentifier)

//        collectionView.register(GroupCell.self, forCellWithReuseIdentifier: groupReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
    }
    
    func computeRoute() {
        let scheduler = Scheduler()
        // TEMP BEFORE I figure out how to actually schedule groups-- only do scheduling if all items are destinations! for now!! just doing interface stuff first...
//        var allDestinations = true
//        var destinations = [Destination]()
//        itinerary.events.forEach({ event in
//            guard let dest = event as? Destination else { allDestinations = false; return }
//            destinations.append(dest)
//        })
        scheduler.schedule(events: itinerary.events, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let timelineVC = segue.destination as? TimelineViewController {
            
            timelineVC.delegate = self
            timelineController = timelineVC
            
        }
    }
    
    @objc func pinchLocationCell(gesture: UIPinchGestureRecognizer) {
        guard let editingSession = editingSession else { return }
        
        let dir = Double(gesture.scale - 1.0)
        let thresh = 0.05
        
        if abs(dir) >= thresh {
            let step = dir > 0 ? 1 : -1
            let deltaTime = TimeInterval.from(minutes: step * 15)
            editingSession.changeEventDuration(with: deltaTime)
            gesture.scale = 1.0
        }
        
    }

}

// MARK: - CollectionView delegate methods
extension ItineraryViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return itinerary.events.count
        } else if section == 1 {
            return itinerary.route.count
        } else {
            let count = itinerary.events.filter({$0 as? OneOfBlock != nil}).count
            return count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            return setupDestinationCell(with: indexPath)
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! LegCell
            return setupLegCell(cell, with: indexPath.item)
        } else {
            return setupGroupCell(with: indexPath)
        }
        
    }
    
    func groupForIndex(_ index: Int) -> OneOfBlock {
        let group = itinerary.events.filter({ $0 as? OneOfBlock != nil})[index] as! OneOfBlock
        return group
    }
    
    func setupGroupCell(with indexPath: IndexPath) -> GroupCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupReuseIdentifier, for: indexPath) as! GroupCell
        let group = groupForIndex(indexPath.item)
        cell.nextBtn.tag = indexPath.item
        cell.nextBtn.addTarget(self, action: #selector(nextOption(_:)), for: .touchUpInside)
        cell.prevBtn.tag = indexPath.item
        cell.prevBtn.addTarget(self, action: #selector(prevOption(_:)), for: .touchUpInside)
        cell.configureWith(group)
        return cell
    }
    
    func setupDestinationCell(with indexPath: IndexPath) -> DestCell {
        
        let event = itinerary.events[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
        
        if let destination = event as? Destination {
            cell.configureWith(name: destination.place.name, duration: destination.timing.duration)
        } else if let group = event as? OneOfBlock {
            if let destination = group.selectedDestination {
                cell.configureWith(name: destination.place.name, duration: destination.timing.duration)
            } else {
                cell.configureWith(name: "No destination selected", duration: group.timing.duration)
            }
        }
        addDragRecognizerTo(draggable: cell)
        return cell
        
    }
    
    @objc func prevOption(_ sender: UIButton) {
        print("PREV")
        let groupIndex = sender.tag
        let group = groupForIndex(groupIndex)
        guard let index = group.selectedIndex else { return }
        let newIndex = (index - 1) >= 0 ? index - 1 : group.places.count - 1
        group.selectedIndex = newIndex
        let scheduler = Scheduler()
        scheduler.schedule(events: itinerary.events, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    @objc func nextOption(_ sender: UIButton) {
        print("next")
        let groupIndex = sender.tag
        let group = groupForIndex(groupIndex)
        guard let index = group.selectedIndex else { return }
        group.selectedIndex = (index + 1) % (group.places.count)
        let scheduler = Scheduler()
        scheduler.schedule(events: itinerary.events, travelMode: itinerary.travelMode, callback: didEditItinerary)
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
    
    func didEditItinerary(events: [Event]?, route: Route?) {
        
        guard let events = events, let route = route else { return }
        
        self.itinerary.events = events
        self.itinerary.route = route
        delegate?.itineraryViewController(self, didUpdateItinerary: itinerary)
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        let event : Event
        
        if let eventObject = object as? Event {
            event = eventObject
        } else {
            if let place = object as? Place {
                event = Destination(place: place, timing: Timing(start: 0, duration: defaultDuration))
            } else if let group = object as? Group {
                event = OneOfBlock(name: group.name, places: group.places, timing: Timing(start: 0, duration: defaultDuration), selectedIndex: nil)
            } else {
                return
            }
        }
        
        var editingEvents = itinerary.events
        
        if draggableContentViewController as? ItineraryViewController != nil {
            editingEvents.remove(at: indexPath.item)
        }
        
        editingSession = ItineraryEditingSession(movingEvent: event, withIndex: indexPath.item, inEvents: editingEvents, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionView)
        
        if !collectionView.frame.contains(location) {
            editingSession.removeEvent()
            return
        }
        
        let y = gesture.location(in: view).y
        let hour = timelineController.roundedHourInTimeline(forY: y)
        if hour != previousTouchHour {
            editingSession.moveEvent(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
//        let spaceFromBottom = collectionView.frame.height - y
//        print (spaceFromBottom)
//        if spaceFromBottom <= 100 {
//            timelineController.shiftTimeline(by: 2.0)
//        }
        
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
              let event = itinerary.events[safe: indexPath.item] else { return nil }
        
        return event
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
    
    func collectionView(_ collectionView:UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
        guard let event = eventFor(indexPath: indexPath) else { return Timing() }
        return event.timing
    }
    
    func eventFor(indexPath: IndexPath) -> Event? {
        
        let section = indexPath.section
        let item = indexPath.item
        
        if section == 0 {
            return itinerary.events[safe: item]
        } else if section == 1 {
            return itinerary.route[safe: item]
        } else if section == 2 {
            let groups = itinerary.events.filter({ $0 as? OneOfBlock != nil})
            return groups[safe: item]
        } else {
            return nil
        }
        
    }
}

// Reload collection when there are changes to the timeline (timeline panning, timeline pinching)
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
