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
    private let nilReuseIdentifier = "nilCell"
    
    private let scheduler = Scheduler()
    
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
    var itinerary = Itinerary()
    var dragging = false
    
    // MARK: - Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dragDelegate = self as DragDelegate
        self.dragDataDelegate = self as DragDataDelegate
        
        setupCollectionView()

    }
    
    override func viewDidLayoutSubviews() {
        timelineController.setSidebarWidth(collectionView.frame.minX)
    }
    
    func setupCollectionView() {
        
        if let layout = collectionView?.collectionViewLayout as? ItineraryLayout {
            layout.delegate = self
        }
        
        let destNib = UINib(nibName: "DestCell", bundle: nil)
        let groupNib = UINib(nibName: "GroupCell", bundle: nil)
        let routeNib = UINib(nibName: "RouteCell", bundle: nil)
        collectionView.register(routeNib, forCellWithReuseIdentifier: legReuseIdentifier)
        collectionView.register(destNib, forCellWithReuseIdentifier: locationReuseIdentifier)
        collectionView.register(groupNib, forCellWithReuseIdentifier: groupReuseIdentifier)
        collectionView.register(NilCell.self, forCellWithReuseIdentifier: nilReuseIdentifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        
        showDraggingView = false
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action:#selector(pinchLocationCell)))
    }
    
    func computeRoute() {
        
        scheduler.schedule(blocks: itinerary.schedule, travelMode: itinerary.travelMode, callback: didEditItinerary)
        
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
            editingSession.changeBlockDuration(with: deltaTime)
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
        
        switch section {
        case 0:
            return itinerary.destinations.count
        case 1:
            return itinerary.route.count
        case 2:
            return itinerary.schedule.count
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = indexPath.section
        switch section {
        case 0:
            return setupDestinationCell(with: indexPath)
        case 1:
            return setupLegCell(with: indexPath)
        case 2:
            return setupBlockCell(with: indexPath)
        default:
            return UICollectionViewCell()
        }
    }
    
    func setupDestinationCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.item
        let destination = itinerary.destinations[index]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
        cell.configureWith(destination)
        addDragRecognizerTo(draggable: cell)
        return cell
        
    }
    
    func setupLegCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.item
        let leg = itinerary.route.legs[index]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! RouteCell
        let gradient = [leg.startPlace.color, leg.endPlace.color]
        
        cell.configureWith(timing: leg.timing, duration: leg.travelTiming.duration, hourHeight: timelineController.hourHeight, gradient: gradient)
        return cell
    }
    
    func setupBlockCell(with indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        guard let block = itinerary.schedule[index] as? OptionBlock else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupReuseIdentifier, for: indexPath) as! GroupCell
        
        cell.nextBtn.tag = index
        cell.nextBtn.addTarget(self, action: #selector(nextOption(_:)), for: .touchUpInside)
        cell.prevBtn.tag = index
        cell.prevBtn.addTarget(self, action: #selector(prevOption(_:)), for: .touchUpInside)
        cell.configureWith(block)
        addDragRecognizerTo(draggable: cell)
        
        return cell
    }
    
    @objc func prevOption(_ sender: UIButton) {
        let blockIndex = sender.tag
        var block = itinerary.schedule[blockIndex] as! OptionBlock
        guard let index = block.optionIndex else { return }
        
        let newIndex = (index - 1) >= 0 ? index - 1 : block.optionCount - 1
        block.optionIndex = newIndex
        
        scheduler.schedule(blocks: itinerary.schedule, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }

    @objc func nextOption(_ sender: UIButton) {
        let blockIndex = sender.tag
        var block = itinerary.schedule[blockIndex] as! OptionBlock
        guard let index = block.optionIndex else { return }
        
        let newIndex = (index + 1) % (block.optionCount)
        block.optionIndex = newIndex
        
        scheduler.schedule(blocks: itinerary.schedule, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        guard let block = blockFromObject(object) else { return }
        var editingBlocks = itinerary.schedule
        
        if draggableContentViewController is ItineraryViewController {
            editingBlocks.remove(at: indexPath.item)
        }
        
        editingSession = ItineraryEditingSession(scheduler: scheduler, movingBlock: block, withIndex: indexPath.item, inBlocks: editingBlocks, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionView)
        
        if !collectionView.frame.contains(location) {
            editingSession.removeBlock()
            return
        }
        
        let y = gesture.location(in: view).y
        let hour = timelineController.roundedHourInTimeline(forY: y)
        if hour != previousTouchHour {
            editingSession.moveBlock(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UIPanGestureRecognizer) {
        
//        editingSession?.end()
        editingSession = nil
        previousTouchHour = nil
        
    }
    
    func cellForIndex(_ indexPath: IndexPath) -> UIView? {
        
        return collectionView.cellForItem(at: indexPath)
        
    }
    
    func didEditItinerary(blocks: [ScheduleBlock]?, route: Route?) {
        
        if let blocks = blocks {
            self.itinerary.schedule = blocks
        }
        
        if let route = route {
            self.itinerary.route = route
        }
        
        collectionView.reloadData()
    
        delegate?.itineraryViewController(self, didUpdateItinerary: itinerary)
    }
    
    func blockFromObject(_ object : Any) -> ScheduleBlock? {
        
        
        if let scheduleObject = object as? ScheduleBlock {
            print("found schedule object")
            return scheduleObject
        } else {
            if let place = object as? Place {
                return SingleBlock(timing: Timing(start: 0, duration: place.timeSpent), place: place)
                
            } else if let group = object as? PlaceGroup {
                switch group.kind {
                case .asManyOf:
                    return AsManyOfBlock(placeGroup: group, timing: Timing(start: 0, duration: TimeInterval.from(hours: 2)), permutations: [[]])
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
              let indexPath = collectionView.indexPath(for: draggable),
              let obj = eventFor(indexPath: indexPath) else { return nil }
        
        if obj is OptionBlock {
            return obj
        } else if obj is Destination {
            return blockOfDestination(at: indexPath.item)
        } else {
            return nil
        }
    
    }
    
    func indexPathFor(draggable: UIView) -> IndexPath? {
        guard let draggable = draggable as? UICollectionViewCell,
              let indexPath = collectionView.indexPath(for: draggable) else { return nil}
        
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
    
    func eventFor(indexPath: IndexPath) -> Schedulable? {
        
        let section = indexPath.section
        let item = indexPath.item
        
        switch section {
        case 0:
            return itinerary.destinations[safe: item]
        case 1:
            return itinerary.route.legs[safe: item]
        case 2:
            return itinerary.schedule[safe: item]
        default:
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
