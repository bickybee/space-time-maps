//
//  ItineraryCollectionViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 24/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// should set up consts w reuse identifiers and sections
private let destReuseIdentifier = "destinationCell"
private let travelTimeReuseIdentifier = "travelTimeCell"
private let routeLineReuseIdentifier = "routeLineCell"
private let groupReuseIdentifier = "groupCell"
private let nilReuseIdentifier = "nilCell"


class ItineraryCollectionViewController: UICollectionViewController {
    
    var itinerary: Itinerary
    var hourHeight: CGFloat = 50.0
    
    init(with itinerary: Itinerary, layout: ItineraryLayout) {
        self.itinerary = itinerary
        super.init(collectionViewLayout: layout)
        
        layout.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Should never happen")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell classes
        let destNib = UINib(nibName: "DestCell", bundle: nil)
        let groupNib = UINib(nibName: "GroupCell", bundle: nil)
        let travelTimeNib = UINib(nibName: "TravelTimeCell", bundle: nil)
        let routeLineNib = UINib(nibName: "RouteLineCell", bundle: nil)
        self.collectionView!.register(destNib, forCellWithReuseIdentifier: destReuseIdentifier)
        self.collectionView!.register(travelTimeNib, forCellWithReuseIdentifier: travelTimeReuseIdentifier)
        self.collectionView!.register(routeLineNib, forCellWithReuseIdentifier: routeLineReuseIdentifier)
        self.collectionView!.register(groupNib, forCellWithReuseIdentifier: groupReuseIdentifier)
        self.collectionView!.register(NilCell.self, forCellWithReuseIdentifier: nilReuseIdentifier)

    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 4
        
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return itinerary.destinations.count
        case 1,
             2:
            return itinerary.route.count
        case 3:
            return itinerary.schedule.count
        default:
            return 0
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let section = indexPath.section
        switch section {
        case 0:
            return setupDestinationCell(with: indexPath)
        case 1:
            return setupTravelTimingCell(with: indexPath)
        case 2:
            return setupRouteLineCell(with: indexPath)
        case 3:
            return setupBlockCell(with: indexPath)
        default:
            return UICollectionViewCell()
        }
        
    }
    
    func eventFor(indexPath: IndexPath) -> Schedulable? {
        
        let section = indexPath.section
        let item = indexPath.item
        
        switch section {
        case 0:
            return itinerary.destinations[safe: item]
        case 1,
             2:
            return itinerary.route.legs[safe: item]
        case 3:
            return itinerary.schedule[safe: item]
        default:
            return nil
        }
        
    }
    
    public func hourInTimeline(forY y: CGFloat) -> Double {
        
        let relativeHour = y / hourHeight
        let absoluteHour = relativeHour //+ startHour
        
        return Double(absoluteHour)
    }
    
    public func roundedHourInCollection(forY y: CGFloat) -> Double {
        
        let hour = hourInTimeline(forY: y)
        let roundedHour = Utils.ceilHour(hour)
        
        return roundedHour
    }
    
    public func yFromTime(_ seconds: TimeInterval) -> CGFloat {
        let hour = CGFloat(seconds.inHours())
//        let y = (hour - startHour) * hourHeight
        let y = hour * hourHeight
        return y
    }

}

// MARK:- Setup for the various cells

extension ItineraryCollectionViewController {
    
    func setupDestinationCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get data
        let index = indexPath.item
        let destination = itinerary.destinations[index]
        
        // Configure cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: destReuseIdentifier, for: indexPath) as! DestCell
        cell.configureWith(destination)
        
        return cell
        
    }
    
    func setupTravelTimingCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get data
        let index = indexPath.item
        let leg = itinerary.route.legs[index]
        
        // Configure cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: travelTimeReuseIdentifier, for: indexPath) as! TravelTimeCell
        cell.configureWith(leg)
        
        return cell
    }
    
    func setupRouteLineCell(with indexPath: IndexPath) -> UICollectionViewCell {

        return collectionView.dequeueReusableCell(withReuseIdentifier: routeLineReuseIdentifier, for: indexPath)
        
    }
    
    func setupBlockCell(with indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get data
        let index = indexPath.item
        
        // Is there an option block here?
        guard itinerary.schedule[index] is OptionBlock else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
        }
        
        // Configure cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: groupReuseIdentifier, for: indexPath) as! GroupCell
        cell.button.tag = index
        
        return cell
    }
    
}

// MARK:- Layout delegate

extension ItineraryCollectionViewController: ItineraryLayoutDelegate {
    
    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat {
        return 0
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return hourHeight
    }
    
    func collectionView(_ collectionView:UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
        let section = indexPath.section
        let item = indexPath.item
        
        switch section {
        case 0:
            return itinerary.destinations[item].timing
        case 1:
            return itinerary.route.legs[item].travelTiming
        case 2:
            return itinerary.route.legs[item].timing
        case 3:
            return itinerary.schedule[item].timing
        default:
            return Timing()
        }
    }

    
}
