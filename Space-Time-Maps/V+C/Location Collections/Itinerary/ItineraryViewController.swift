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
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action:#selector(pinch)))
        collectionView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action:#selector(scroll)));
    }
    
    @objc func scroll(_ sender: UIPanGestureRecognizer) {
        timelineController.panTime(gesture: sender)
    }
    
    @objc func pinch (_ sender: UIPinchGestureRecognizer) {
    
        if editingSession != nil {
            pinchLocationCell(gesture: sender)
        } else {
            timelineController.pinchTime(sender)
        }
    
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
        var cell : UICollectionViewCell!
        switch section {
        case 0:
            cell = setupDestinationCell(with: indexPath)
        case 1:
            cell = setupLegCell(with: indexPath)
        case 2:
            cell = setupBlockCell(with: indexPath)
        default:
            cell = UICollectionViewCell()
        }
        
        return cell
    }
    
    func setupDestinationCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        let index = indexPath.item
        let destination = itinerary.destinations[index]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
        cell.configureWith(destination)
        cell.isUserInteractionEnabled = false
        cell.removeShadow()
        if let editingSession = editingSession, let movingBlockIndex = editingSession.lastPosition  {
            if indexOfBlockContainingDestination(at: index)! == movingBlockIndex {
                cell.addShadow()
            }
        }
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
            blockCell.lockButton.isSelected = block.isFixed
            cell = blockCell
            
            cell.removeShadow()
            if let editingSession = editingSession, let movingBlockIndex = editingSession.lastPosition  {
                if index == movingBlockIndex {
                    cell.addShadow()
                }
            }
            
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
        }
        
        if (cell.gestureRecognizers == nil || cell.gestureRecognizers?.count == 0) {
            addDragRecognizerTo(draggable: cell)
        }
        
        return cell
    }
    
    func setupOptionViewForBlockIndex(_ blockIndex: Int) -> UIView? {
        
        guard let block = itinerary.schedule[blockIndex] as? OptionBlock else { return nil }
        let enteringLeg = itinerary.route.legEndingAt(block.destinations![0].place)
        let exitingLeg = itinerary.route.legStartingAt(block.destinations!.last!.place)
        let startTime = enteringLeg != nil ? enteringLeg!.timing.start : block.timing.start
        let endTime = exitingLeg != nil ? exitingLeg!.timing.end : block.timing.end
        
        let minY = timelineController.yFromTime(startTime)
        let maxY = timelineController.yFromTime(endTime)
        let frame = CGRect(x: 0, y: minY, width: collectionView.frame.width, height: maxY - minY)
        
        let newOptionView = UIView(frame: frame)
        newOptionView.tag = blockIndex
        let bgSnapshotFrame = collectionView.convert(newOptionView.frame, to: timelineController.view)
        newOptionView.backgroundColor = UIColor.init(patternImage: timelineController.view.snapshot(of: bgSnapshotFrame, afterScreenUpdates: false))
        
        addChild(optionsVC)
        optionsVC.view.frame = CGRect(x: 0, y: 0, width: newOptionView.frame.width, height: newOptionView.frame.height)
        newOptionView.addSubview(optionsVC.view)
        optionsVC.didMove(toParent: self)
        optionsVC.delegate = self
        optionsVC.blockIndex = blockIndex
        optionsVC.selectedOption = block.selectedOption!
        optionsVC.hourHeight = timelineController.hourHeight
        optionsVC.view.backgroundColor = .clear //UIColor.lightGray.withAlphaComponent(0.5)
        
        if optionsVC.itineraries == nil {
            // Create itineraries from options!!!
            let itineraries = itinerariesFromOptionsBlockIndex(blockIndex)
            optionsVC.itineraries = itineraries
        }

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
            print("option")
            print(o)
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
        
        if !collectionView.frame.contains(location) {
            if previousTouchHour != nil {
                editingSession.removeBlock()
                previousTouchHour = nil
            }
            return
        }
        
        let y = gesture.location(in: view).y
        let hour = timelineController.roundedHourInTimeline(forY: y)
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
        if let ov = optionView {
            ov.removeFromSuperview()
            optionView = setupOptionViewForBlockIndex(ov.tag)!
            collectionView.addSubview(optionView!)
        }
    }
    
    func timelineViewController(_ timelineViewController: TimelineViewController, didUpdateHourHeight: CGFloat) {
        collectionView.reloadData()
        if let ov = optionView {
            ov.removeFromSuperview()
            optionView = setupOptionViewForBlockIndex(ov.tag)!
            collectionView.addSubview(optionView!)
        }
    }
    
}

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


// MARK: - Self delegate protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}
