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
    
    private var scheduler : Scheduler!
    private var timeTickService : TimeTickService!
    private let hourHeight = 50.0
    
    // Child views
    @IBOutlet weak var collectionView: UICollectionView!
    var timelineController: TimelineViewController!
    var timeQuerySidebar: UIView!
    var timeQueryLine: UIView?
    var optionView : UIView?
    var optionsVC = OptionsViewController()


    // Itinerary editing
    var editingSession : ItineraryEditingSession?
    var previousTouchHour : Double?
    var defaultDuration = TimeInterval.from(hours: 1.0)

    // Delegate (subscribes to itinerary updates)
    weak var delegate : ItineraryViewControllerDelegate?
    weak var timeQueryDelegate : TimeQueryDelegate?
    
    // Collection view data source!
    var itinerary = Itinerary()
    var dragging = false
    
    // MARK: - Setup
    override func viewDidLoad() {
        // self
        super.viewDidLoad()
        self.dragDelegate = self as DragDelegate
        self.dragDataDelegate = self as DragDataDelegate
//        NotificationCenter.default.addObserver(self, selector: #selector(self.scrollToPlaceWithName), name: .didTapMarker, object: nil)
        
        setupServices()
        setupCollectionView()
        setupTimeline()
        setupTimeQuerySidebar()
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // default start time
        collectionView.setContentOffset(CGPoint(x: 0, y: 380.0), animated: false)
    }
    
    func setupServices() {
        let qs = QueryService()
        scheduler = Scheduler(qs)
        timeTickService = TimeTickService(qs)
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
    
    func setupTimeline() {
        
        timelineController = TimelineViewController()
        self.addChild(timelineController)
        timelineController.didMove(toParent: self)
        timelineController.delegate = self
        
    }
    
    func setupTimeQuerySidebar() {
        
        let timeSidebarFrame = CGRect(x: 0, y: 0, width: timelineController.sidebarWidth, height: collectionView.frame.height)
        timeQuerySidebar = UIView(frame: timeSidebarFrame)
        timeQuerySidebar.backgroundColor = .clear
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(queryTime))
        longPress.minimumPressDuration = 0.0
        timeQuerySidebar.addGestureRecognizer(longPress)
        view.addSubview(timeQuerySidebar)
    }
    
// MARK:- Updates & Interaction
    
    @objc func queryTime(_ gesture: UILongPressGestureRecognizer) {
        
        let y = gesture.location(in: timeQuerySidebar).y
        let time = timelineController.hourInTimeline(forY: y)
        let roundedTime = timelineController.roundedHourInTimeline(forY: y)
        let roundedY = timelineController.yFromTime(TimeInterval.from(hours:roundedTime))
        let schedulable = itinerary.intersectsWithTime(TimeInterval.from(hours: roundedTime))
        
        switch gesture.state {
        case .began:
            print(roundedY)
            let frame = CGRect(x: 0, y: y - 2, width: view.frame.width, height: 4)
            timeQueryLine = UIView(frame: frame)
            timeQueryLine!.backgroundColor = UIColor.darkGray.withAlphaComponent(0.25)
            view.addSubview(timeQueryLine!)
            timeQueryDelegate?.didMakeTimeQuery(time: TimeInterval.from(hours: roundedTime), schedulable: schedulable)
        case .changed:
            timeQueryLine!.frame = CGRect(x: 0, y: y - 2, width: view.frame.width, height: 4)
            timeQueryDelegate?.didMakeTimeQuery(time: TimeInterval.from(hours: roundedTime), schedulable: schedulable)
        default:
            timeQueryLine!.removeFromSuperview()
            timeQueryLine = nil
            timeQueryDelegate?.didEndTimeQuery()
        }
        
    }
    
    func computeRoute() {
        // This is called when the mode of transport changes, but needs to be fixed because it won't update asManyOf blocks if they change to no longer fit their dests...
        // picking an arbitrary movingIndex to avoid conflicts / enforce block pushing!
        scheduler.reschedule(blocks: itinerary.schedule, movingIndex:0, callback: didEditItinerary)
        
    }
    
    func updateScheduler(_ places: [Place], _ callback: (() -> ())?) {
        scheduler.updateTimeDict(places, callback)
    }
    
    func updateSchedulerWithPlace(_ place: Place, in places: [Place]) {
        scheduler.updateTimeDictWithPlace(place, in: places)
    }
    
    func updateScheduler(_ travelMode: TravelMode) {
        scheduler.travelMode = travelMode
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
    
    func editBlockTiming(_ timing: Timing) {
        guard let editingSession = editingSession else { return }
        editingSession.changeBlockTiming(timing)
    }
    
    func updateBlockPlaceDuration(_ placeIndex: Int, _ duration: TimeInterval) {
        guard let editingSession = editingSession else { return }
        editingSession.changeBlockPlaceDuration(placeIndex, duration)
    }
    
    // not being used
    @objc func didTapDestination(_ sender: UITapGestureRecognizer) {
        print("tap")
        let index = sender.view!.tag
        let block = itinerary.schedule[index] // only works for dests rn
        NotificationCenter.default.post(name: .didTapDestination, object: (block, index))
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
        return false//editingSession != nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        timelineController.offset = collectionView.contentOffset.y
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var obj : Any!
        
        if indexPath.section == 0 {
            let blockIndex = indexOfBlockContainingDestination(at: indexPath.item)!
            let block = itinerary.schedule[blockIndex]
            if block is SingleBlock {
                obj = (block, blockIndex)
            } else {
                let dest = itinerary.destinations[indexPath.item]
                let placeIndex = block.places.firstIndex(where: {$0.name == dest.place.name})!
                obj = (dest, placeIndex)
            }
            startEditingSession(withBlockAtIndex: blockIndex)
        } else if indexPath.section == 2 {
            obj = (itinerary.schedule[indexPath.item], indexPath.item)
            startEditingSession(withBlockAtIndex: indexPath.item)
        }
        NotificationCenter.default.post(name: .didTapDestination, object: obj)
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
            return 1
        case 4:
            return shouldShowHoursOfOperation() ? editingSession!.movingBlock.places.count * 2 : 0
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
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: timelineReuseIdentifier, for: indexPath)
            if !cell.contentView.subviews.contains(timelineController.view) {
                cell.contentView.addSubview(timelineController.view)
                timelineController.view.frame = cell.contentView.frame
                timelineController.view.setNeedsDisplay()
            }
            cell.isUserInteractionEnabled = false
        case 4:
            cell = setupHoursCell(with: indexPath)
        default:
            cell = UICollectionViewCell()
        }
        
        return cell
    }
    
    
// MARK: - Cell setup
    func setupHoursCell(with indexPath: IndexPath) -> UICollectionViewCell {
        let movingBlock = editingSession!.movingBlock
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: hoursReuseIdentifier, for: indexPath) as! HoursCell
        cell.configureWith(movingBlock.places[indexPath.item / 2])
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
//            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDestination))
//            tapGesture.numberOfTapsRequired = 1
//            tapGesture.delegate = self
//            cell.addGestureRecognizer(tapGesture)
            let dragRecognizer = addDragRecognizerTo(draggable: cell)
            
        }
        cell.tag = index
        cell.configureWith(destination, currentlyDragging)
        return cell
        
    }
    
    @objc func didSwipeDestination(_ gesture: UISwipeGestureRecognizer) {
        print("swipe!")
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
        let enteringLeg = itinerary.route.legEndingAt(block.destinations[0].place)
        let exitingLeg = itinerary.route.legStartingAt(block.destinations.last!.place)
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
                let prevDest = itinerary.schedule[blockIndex - 1].destinations.last!
                newItineraryBlocks.insert(SingleBlock(timing: prevDest.timing, place: prevDest.place), at: 0)
            }
            if blockIndex < itinerary.schedule.count - 1 {
                let nextDest = itinerary.schedule[blockIndex + 1].destinations.first!
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
                    itinerary.schedule = schedule
                }
                if let route = route { itinerary.route = route }
                itineraries.append(itinerary)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.wait()
        return itineraries
        
    }

}

// MARK: - PlacePalette Drag Delegate
// Coordinates dragging/dropping from the place palette to the itinerary
extension ItineraryViewController : DragDelegate {
    
    func startEditingSession(withNewBlock block: ScheduleBlock) {
        let editingBlocks = itinerary.schedule
        editingSession = ItineraryEditingSession(scheduler: scheduler, movingBlock: block, withIndex: nil, inBlocks: editingBlocks, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    func startEditingSession(withBlockAtIndex index: Int) {
        let block = itinerary.schedule[index]
        var editingBlocks = itinerary.schedule
        editingBlocks.remove(at: index)
        editingSession = ItineraryEditingSession(scheduler: scheduler, movingBlock: block, withIndex: index, inBlocks: editingBlocks, travelMode: itinerary.travelMode, callback: didEditItinerary)
    }
    
    func endEditingSession() {
        editingSession = nil
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, shouldScrollInDirection direction: Int) {
        print("boop")
    }
    
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didBeginDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        guard let block = blockFromObject(object) else { return }

        if draggableContentViewController is ItineraryViewController {
            startEditingSession(withBlockAtIndex: indexPath.item)
        } else {
            startEditingSession(withNewBlock: block)
        }
        
        let snapshotFrame = CGRect(x: 0, y: collectionView.contentOffset.y, width: collectionView.frame.width, height: collectionView.frame.height)
        timelineController.addShadowView(from: UIColor.init(patternImage: collectionView.snapshot(of: snapshotFrame, afterScreenUpdates: true)), withFrame: snapshotFrame)
        collectionView.reloadData()
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didContinueDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer, andDiff diff: CGPoint) {

        // Get place for corresponding time of touch
        guard let editingSession = editingSession else { return }
        let location = gesture.location(in: collectionView)
        
        // Either remove cell
        if !collectionView.bounds.contains(location) {
            if previousTouchHour != nil {
                editingSession.removeBlock()
                previousTouchHour = nil
            }

        } else {
            // Or move cell
            let y = gesture.location(in: view).y
            let dy = y + diff.y
            let hour = timelineController.roundedHourInTimeline(forY: dy)
            if hour != previousTouchHour {
                editingSession.moveBlock(toTime: TimeInterval.from(hours: hour))
                previousTouchHour = hour
            }
        }
        // Resize if cells go off screen
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        var totalNumCells = 0
        // Excluding hours of op cells...
        for i in 0..<collectionView.numberOfSections - 1 {
            totalNumCells += collectionView.numberOfItems(inSection: i)
        }
        var visibleCells = collectionView.indexPathsForVisibleItems.filter{ $0.section != 4}
        if visibleCells.count < totalNumCells {
            print("should zoom")
        }
    }
    
    func draggableContentViewController(_ draggableContentViewController: DraggableContentViewController, didEndDragging object: Any, at indexPath: IndexPath, withGesture gesture: UILongPressGestureRecognizer) {
        
        timelineController.removeShadow()
        timelineController.view.layoutIfNeeded()
        previousTouchHour = nil
        collectionView.reloadData()
        
        print("end press")

        endEditingSession()
        
      // lol testing time tick isochrone stuff
        for leg in itinerary.route.legs {
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                  return
                }
              // get ticks
              self.timeTickService.getTimeTicksForLeg(leg) { ticks in
                  leg.ticks = ticks
                    DispatchQueue.main.async { [weak self] in
                      guard let self = self else {
                        return
                      }
                      self.delegate?.itineraryViewController(self, didUpdateItinerary: self.itinerary)
                        print("done")
                    }
                  
              }
            }
      }
            
        
    }
    
    func cellForIndex(_ indexPath: IndexPath) -> UIView? {
        
        return collectionView.cellForItem(at: indexPath)
        
    }
    
    func updatePlaceGroups(_ groups:[PlaceGroup]) {

        for group in groups {
            if let i = itinerary.schedule.firstIndex(where: {
                if let ob = $0 as? OptionBlock {
                    return ob.placeGroup.id == group.id
                }
                return false
            }) {
                if let oob = itinerary.schedule[i] as? OneOfBlock {
                    itinerary.schedule[i] = OneOfBlock(placeGroup: group, timing: oob.timing)
                } else if let a = itinerary.schedule[i] as? AsManyOfBlock {
                    itinerary.schedule[i] = AsManyOfBlock(placeGroup: group, timing: a.timing, timeDict: scheduler.timeDict, travelMode: scheduler.travelMode)
                }
            }
        }
        scheduler.reschedule(blocks: itinerary.schedule, movingIndex: 0, callback: didEditItinerary(blocks:route:))
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
                    return AsManyOfBlock(placeGroup: group, timing: Timing(start: 0, duration: TimeInterval.from(hours: 2.5)), timeDict: scheduler.timeDict, travelMode: scheduler.travelMode)
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
              var indexPath = collectionView.indexPath(for: draggable),
              let obj = eventFor(indexPath: indexPath) else { return nil }
        
        if indexPath.section == 0 {
            return IndexPath(item: indexOfBlockContainingDestination(at: indexPath.item)!, section: indexPath.section)
        }
        
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
            
            count += block.destinations.count
            
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
            guard let hours = editingSession!.movingBlock.places[indexOfDest].openHours else { return Timing() }
            
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
        if optionView != nil {
            shouldDismissOptionsViewController(optionsVC)
        }
        guard let newView = setupOptionViewForBlockIndex(blockIndex) else { return }
        collectionView.addSubview(newView)
        optionView = newView
    }
    
    func didPressNextOnGroupCell(_ cell: GroupCell) {
        let blockIndex = cell.tag
        let block = itinerary.schedule[blockIndex] as! OptionBlock
        let oldIndex = block.selectedOption!
        let newIndex = (oldIndex + 1) % block.optionCount
        scheduler.scheduleOptionChange(of: blockIndex, toOption: newIndex, in: itinerary.schedule, callback: didEditItinerary)
    }
    
}

// MARK: - Self Delegate Protocol
protocol ItineraryViewControllerDelegate : AnyObject {
    
    func itineraryViewController(_ itineraryViewController: ItineraryViewController, didUpdateItinerary: Itinerary)
    
}

// MARK: - Time Query Delegate Protocol
protocol TimeQueryDelegate : AnyObject {
    func didMakeTimeQuery(time: TimeInterval, schedulable: Schedulable?)
    func didEndTimeQuery()
}

extension Notification.Name {
    static let didTapDestination = Notification.Name("didTapDestination")
    static let didMakeTimeQuery = Notification.Name("didMakeTimeQuery")
    static let didEndTimeQuery = Notification.Name("didEndTimeQuery")
}
