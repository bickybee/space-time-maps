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
    private let groupReuseIdentifier = "groupCell"
    private let nilReuseIdentifier = "nilCell"
    private let hoursReuseIdentifier = "hoursCell"
    private let timelineReuseIdentifier = "timelineCell"
    
    private let scheduler = Scheduler()
    private let hourHeight = 50.0
    
    // Child views
    @IBOutlet weak var collectionView: UICollectionView!
    var timelineController: TimelineViewController!
    var optionView : UIView?
    var optionsVC = OptionsViewController()

    // Itinerary editing
    var editingSession : ItineraryEditingSession?
    var previousTouchHour : Double?
    var defaultDuration = TimeInterval.from(hours: 1.0)

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
        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollToPlaceWithName), name: .didTapMarker, object: nil)
        timelineController = TimelineViewController()
        self.addChild(timelineController)
        timelineController.didMove(toParent: self)
        timelineController.delegate = self

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
        collectionView.register(HoursCell.self, forCellWithReuseIdentifier: hoursReuseIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: timelineReuseIdentifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.delaysContentTouches = false
        
        showDraggingView = false
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action:#selector(pinch)))

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let timelineVC = segue.destination as? TimelineViewController {
            
            timelineVC.delegate = self
            timelineController = timelineVC
            
        }
    }
    
// MARK:- Updates & Interaction
    
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
    
    @objc func pinch (_ sender: UIPinchGestureRecognizer) {
    
        if editingSession != nil {
            pinchLocationCell(gesture: sender)
        } else {
            let startingContentHeight = timelineController.hourHeight * 24.5
            let centerFrac = (collectionView.contentOffset.y + (collectionView.frame.height / 2.0)) / startingContentHeight
            timelineController.pinchTime(sender)
            collectionView.collectionViewLayout.invalidateLayout()
            let endingContentHeight = timelineController.hourHeight * 24.5
            let newCenter = endingContentHeight * centerFrac
            let newOffset = newCenter - (collectionView.frame.height / 2.0)
            collectionView.contentOffset.y = newOffset
            timelineController.offset = newOffset
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
    
    @objc func didTapDestination(_ sender: UITapGestureRecognizer) {
        let placeName = itinerary.destinations[sender.view!.tag].place.name
        NotificationCenter.default.post(name: .didTapDestination, object: placeName)
    }
    
    @objc func scrollToPlaceWithName(_ notification: Notification) {
        let placeName = notification.object! as! String
        guard let index = itinerary.blockIndexOfPlaceWithName(placeName) else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 2), at: .centeredVertically, animated: true)
    }

}

// MARK: - CollectionView delegate methods
extension ItineraryViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5
    }
    
    func shouldShowHoursOfOperation() -> Bool {
        if let editingSession = editingSession {
            return editingSession.movingBlock.destinations != nil
        }
        return false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timelineController.offset = collectionView.contentOffset.y
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return itinerary.destinations.count
        case 1:
            return itinerary.route.count
        case 2:
            return itinerary.schedule.count
        case 3:
            return shouldShowHoursOfOperation() ? editingSession!.movingBlock.destinations!.count * 2 : 0
        case 4:
            return 1
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = indexPath.section
        var cell : UICollectionViewCell!
        switch section {
        case 0:
            cell = setupDestinationCell(with: indexPath)
        case 1:
            cell = setupLegCell(with: indexPath)
        case 2:
            cell = setupBlockCell(with: indexPath)
        case 3:
            cell = setupHoursCell(with: indexPath)
        case 4:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: timelineReuseIdentifier, for: indexPath)
            if !cell.contentView.subviews.contains(timelineController.view) {
                cell.contentView.addSubview(timelineController.view)
                timelineController.view.frame = cell.contentView.frame
                timelineController.view.setNeedsDisplay()
            }
            cell.isUserInteractionEnabled = false
        default:
            cell = UICollectionViewCell()
        }
        
        return cell
    }
    
    
// MARK: - Cell setup
    func setupHoursCell(with indexPath: IndexPath) -> UICollectionViewCell {
        let movingBlock = editingSession!.movingBlock
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hoursReuseIdentifier, for: indexPath) as! HoursCell
        cell.configureWith(movingBlock.destinations![0])
        return cell
    }
    
    func setupDestinationCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.item
        let destination = itinerary.destinations[index]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
        var currentlyDragging = false
        if let editingSession = editingSession, let movingBlockIndex = editingSession.lastPosition  {
            if indexOfBlockContainingDestination(at: index)! == movingBlockIndex {
                currentlyDragging = true
            }
        }
        if (cell.gestureRecognizers == nil || cell.gestureRecognizers?.count == 0) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDestination))
            tapGesture.numberOfTapsRequired = 1
            tapGesture.delegate = self
            cell.addGestureRecognizer(tapGesture)
            addDragRecognizerTo(draggable: cell)
        }
        cell.tag = index
        cell.configureWith(destination, currentlyDragging)
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
        var cell: UICollectionViewCell!
        
        if let block = itinerary.schedule[index] as? OptionBlock {
            let blockCell = collectionView.dequeueReusableCell(withReuseIdentifier: groupReuseIdentifier, for: indexPath) as! GroupCell
            blockCell.tag = index
            blockCell.delegate = self
            var currentlyDragging = false
            if let editingSession = editingSession, let movingBlockIndex = editingSession.lastPosition  {
                if index == movingBlockIndex {
                    currentlyDragging = true
                }
            }
            blockCell.configureWith(block, currentlyDragging)
            cell = blockCell
            
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
        }
        
        if (cell.gestureRecognizers == nil || cell.gestureRecognizers?.count == 0) {
            addDragRecognizerTo(draggable: cell)
        }
        
        return cell
    }
    
// MARK: - OptionView setup
    func setupOptionViewForBlockIndex(_ blockIndex: Int) -> UIView? {
        
        guard let block = itinerary.schedule[blockIndex] as? OptionBlock else { return nil }
        let enteringLeg = itinerary.route.legEndingAt(block.destinations![0].place)
        let exitingLeg = itinerary.route.legStartingAt(block.destinations!.last!.place)
        let startTime = enteringLeg != nil ? enteringLeg!.timing.start : block.timing.start
        let endTime = exitingLeg != nil ? exitingLeg!.timing.end : block.timing.end
        
        let offsetHour = timelineController.hourInTimeline(forY: collectionView.contentOffset.y)
        let offsetTime = TimeInterval.from(hours: offsetHour)
        let minY = timelineController.yFromTime(startTime - offsetTime/2.0)
        let maxY = timelineController.yFromTime(endTime - offsetTime/2.0)
        let minX = timelineController.timelineView.sidebarWidth
        let frame = CGRect(x: minX, y: minY, width: collectionView.frame.width - minX, height: maxY - minY)
        
        let newOptionView = UIView(frame: frame)
        newOptionView.tag = blockIndex
        let bgSnapshotFrame = collectionView.convert(newOptionView.frame, to: timelineController.view)
        newOptionView.backgroundColor = UIColor.init(patternImage: timelineController.view.snapshot(of: bgSnapshotFrame, afterScreenUpdates: false))
        
        optionsVC.view.frame = CGRect(x: 0, y: 0, width: newOptionView.frame.width, height: newOptionView.frame.height)
        optionsVC.delegate = self
        optionsVC.blockIndex = blockIndex
        optionsVC.selectedOption = block.selectedOption!
        optionsVC.hourHeight = timelineController.hourHeight
        optionsVC.timelineOffset = -(startTime)
        optionsVC.view.backgroundColor = .clear
        
        if optionsVC.itineraries == nil {
            // Create itineraries from options!!!
            let itineraries = itinerariesFromOptionsBlockIndex(blockIndex)
            optionsVC.itineraries = itineraries
        }
        
        addChild(optionsVC)
        newOptionView.addSubview(optionsVC.view)
        optionsVC.didMove(toParent: self)

        return newOptionView
        
    }
    
    func itinerariesFromOptionsBlockIndex(_ blockIndex: Int) -> [Itinerary] {
        guard let block = itinerary.schedule[blockIndex] as? OptionBlock else { return [] }
        var destinationOptions : [[Destination]]!
        if block is OneOfBlock {
            destinationOptions = block.placeGroup.places.map( { [Destination(place: $0, timing: block.timing)] } )
        } else if let asManyOf = block as? AsManyOfBlock{
            destinationOptions = asManyOf.scheduledOptions!
        }
        var itineraries = [Itinerary]()
        let dispatchGroup = DispatchGroup()
        
        for o in destinationOptions {

            dispatchGroup.enter()
            var newItineraryBlocks: [ScheduleBlock] = o.map({ SingleBlock(timing: $0.timing, place: $0.place) })
            if blockIndex > 0 {
                let prevDest = itinerary.schedule[blockIndex - 1].destinations!.last!
                newItineraryBlocks.insert(SingleBlock(timing: prevDest.timing, place: prevDest.place), at: 0)
            }
            if blockIndex < itinerary.schedule.count - 1 {
                let nextDest = itinerary.schedule[blockIndex + 1].destinations!.first!
                newItineraryBlocks.append(SingleBlock(timing: nextDest.timing, place: nextDest.place))
            }
            scheduler.reschedule(blocks: newItineraryBlocks) { schedule, route in
                let itinerary = Itinerary()
                if var schedule = schedule {
                    if blockIndex > 0 {
                        schedule.removeFirst()
                    }
                    if blockIndex < itinerary.schedule.count - 1 {
                        schedule.removeLast()
                    }
                    print("SCHEDULED")
                    itinerary.schedule = schedule
                    print(itinerary.destinations)
                }
                if let route = route { itinerary.route = route }
                itineraries.append(itinerary)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.wait()
        print("all")
        print(itineraries.map( {$0.destinations} ))
        return itineraries
        
    }

}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        guard let block = blockFromObject(object) else { return }
        var editingBlocks = itinerary.schedule
        var index : Int?
        
        if draggableContentViewController is ItineraryViewController {
            editingBlocks.remove(at: indexPath.item)
            index = indexPath.item
        }
        
        editingSession = ItineraryEditingSession(scheduler: scheduler, movingBlock: block, withIndex: index, inBlocks: editingBlocks, travelMode: itinerary.travelMode, callback: didEditItinerary)
        collectionView.reloadData()
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionView)
        
        if !collectionView.bounds.contains(location) {
            if previousTouchHour != nil {
                editingSession.removeBlock()
                previousTouchHour = nil
            }
            return
        }
        
        let y = gesture.location(in: view).y
        let hour = timelineController.roundedHourInTimeline(forY: y)
        print(hour)
        if hour != previousTouchHour {
            editingSession.moveBlock(toTime: TimeInterval.from(hours: hour))
            previousTouchHour = hour
        }
        
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        editingSession = nil
        previousTouchHour = nil
        collectionView.reloadData()
        
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
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
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

// MARK:- Drag Data Delegate
extension ItineraryViewController: DragDataDelegate {
    
    func objectFor(draggable: UIView) -> Any? {
        guard let draggable = draggable as? UICollectionViewCell,
              let indexPath = collectionView.indexPath(for: draggable),
              let obj = eventFor(indexPath: indexPath) else { return nil }
        
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
              let indexPath = collectionView.indexPath(for: draggable) else { return nil}
        
        return indexPath
    }
    
    // this is bad i think?? lol TODO make not bad!
    func blockOfDestination(at index: Int) -> ScheduleBlock? {
        
        if let blockIndex = indexOfBlockContainingDestination(at: index) {
            return itinerary.schedule[blockIndex]
        }
        return nil
        
    }
    
    func indexOfBlockContainingDestination(at index: Int) -> Int? {
        var count = 0
        
        for (i, block) in itinerary.schedule.enumerated() {
            
            if let destinations = block.destinations {
                count += destinations.count
            }
            
            if count > index {
                return i
            }

        }
        
        return nil
    }
    
}


// MARK: - Layout Delegate
extension ItineraryViewController : ItineraryLayoutDelegate {
    
    func timelineSidebarWidth(of collectionView: UICollectionView) -> CGFloat {
        return timelineController.timelineView.sidebarWidth
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return timelineController.hourHeight
    }
    
    func collectionView(_ collectionView:UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
        if indexPath.section < 3 {
            guard let event = eventFor(indexPath: indexPath) else { return Timing() }
            return event.timing
        } else { // HOURS OF OPERATION!!!
            guard shouldShowHoursOfOperation() else { return Timing() }
            let indexOfDest = indexPath.item / 2 // integer division
            guard let hours = editingSession!.movingBlock.destinations![indexOfDest].place.openHours else { return Timing() }
            
            if indexPath.item % 2 == 0 {
                return Timing(start: TimeInterval.from(hours: 0), end: hours.start)
            } else {
                return Timing(start: hours.end, end: TimeInterval.from(hours: 24.5))
            }
        }
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

//MARK:- Timeline Delegate
// Reload collection when there are changes to the timeline (timeline panning, timeline pinching)
extension ItineraryViewController: TimelineViewDelegate {

    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeightBy delta: CGFloat) {
        collectionView.reloadData()
        if let ov = optionView {
            ov.removeFromSuperview()
            optionView = setupOptionViewForBlockIndex(ov.tag)!
            collectionView.addSubview(optionView!)
        }
    }
    
}

//MARK:- OptionsView Delegate
extension ItineraryViewController: OptionsViewControllerDelegate {
    
    func shouldDismissOptionsViewController(_ optionsViewController: OptionsViewController) {

        optionsViewController.willMove(toParent: nil)
        optionsViewController.view.removeFromSuperview()
        optionsViewController.removeFromParent()
        
        optionsViewController.itineraries = nil
        optionsViewController.blockIndex = nil
        optionsViewController.selectedOption = nil
        
        optionView?.removeFromSuperview()
        optionView = nil
    }
    
    func optionsViewController(_ optionsViewController: OptionsViewController, didSelectOptionIndex index: Int) {
        let blockIndex = optionsViewController.blockIndex
        scheduler.scheduleOptionChange(of: blockIndex!, toOption: index, in: itinerary.schedule, callback: didEditItinerary)
        
    }
    
}

//MARK:- Group Cell Buttons Delegate
extension ItineraryViewController: GroupButtonsDelegate {
    
    func didPressLockOnGroupCell(_ cell: GroupCell) {
        let blockIndex = cell.tag
        var optionBlock = itinerary.schedule[blockIndex] as! OptionBlock
        optionBlock.isFixed = !optionBlock.isFixed
        cell.lockButton.isSelected = optionBlock.isFixed
    }
    
    func didPressOptionsOnGroupCell(_ cell: GroupCell) {
        let blockIndex = cell.tag
        guard let newView = setupOptionViewForBlockIndex(blockIndex) else { return }
        collectionView.addSubview(newView)
        optionView = newView
    }
    
    func didPressNextOnGroupCell(_ cell: GroupCell) {
        let blockIndex = cell.tag
        let block = itinerary.schedule[blockIndex] as! OptionBlock
        let oldIndex = block.selectedOption!
        let newIndex = (oldIndex + 1) % block.options.count
        scheduler.scheduleOptionChange(of: blockIndex, toOption: newIndex, in: itinerary.schedule, callback: didEditItinerary)
    }
    
}


// MARK: - Self Delegate Protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}

extension Notification.Name {
    static let didTapDestination = Notification.Name("didTapDestination")
}
