//
//  OptionsViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 23/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

private let locationReuseIdentifier = "locationCell"
private let legReuseIdentifier = "legCell"
private let nilReuseIdentifier = "nilCell"

class OptionsViewController: UIViewController {
    
    var blockIndex: Int!
    weak var delegate: OptionsViewControllerDelegate!
    weak var collectionView: UICollectionView!
    weak var dismissButton: UIButton!
    var hourHeight: CGFloat?
    var itineraries: [Itinerary]? {
        didSet {
            collectionView.reloadData()
        }
    }
    

    override func loadView() {
        super.loadView()
        setupCollectionView()
        setupDismissButton()
    }
    
    func setupCollectionView() {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            ])
        collectionView.tag = -1
        self.collectionView = collectionView
        
    }
    
    func setupDismissButton() {
        
        let button = UIButton()
        button.backgroundColor = .darkGray
        button.layer.zPosition = 10
        self.view.insertSubview(button, aboveSubview: collectionView)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 20.0),
            button.heightAnchor.constraint(equalToConstant: 20.0),
            button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            button.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        button.addTarget(self, action: #selector(didPressDismiss), for: .touchUpInside)
        self.dismissButton = button
        
    }
    
    @objc func didPressDismiss(_ sender: UIButton) {
        let index = collectionView.getCenterCellIndex()! - 1
        delegate.optionsViewController(self, shouldDismissWithSelectedOptionIndex: index)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.register(MiniTimelineCell.self, forCellWithReuseIdentifier: "MiniTimelineCell")
        self.collectionView.register(NilCell.self, forCellWithReuseIdentifier: nilReuseIdentifier)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}

extension OptionsViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.row + 1)
    }
    
}

extension OptionsViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.collectionView.scrollToNearestVisibleCollectionViewCell()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.collectionView.scrollToNearestVisibleCollectionViewCell()
        }
    }
    
}

extension OptionsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if isMainCollectionView(collectionView) {
            return 1
        } else {
            return 2
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let itineraries = itineraries else { return 0 }
        
        if isMainCollectionView(collectionView) {
            return itineraries.count + 2
        } else {
            let whichOption = collectionView.tag
            if section == 0 { // dests
                return itineraries[whichOption].schedule.count
            } else { // legs! TODO!
                print(itineraries[whichOption].route)
                return itineraries[whichOption].route.count
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isMainCollectionView(collectionView) {
            if ((indexPath.item == 0) || (indexPath.item == itineraries!.count + 1)) {
                return collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniTimelineCell", for: indexPath) as! MiniTimelineCell
            cell.timelineView.delegate = self
            cell.timelineView.dataSource = self
            cell.timelineView.tag = indexPath.item - 1 // Because of nil cell to start
            
            let layout = cell.timelineView!.collectionViewLayout as! ItineraryLayout
            layout.delegate = self
            
            cell.timelineView.reloadData()
            return cell
            
        } else {
            
            let section = indexPath.section
            if section == 0 {
                return setupDestinationCell(with: indexPath, for: collectionView)
            } else {
                return setupLegCell(with: indexPath, for: collectionView)
            }
            
        }
        
    }
    
    func setupDestinationCell(with indexPath: IndexPath, for cv: UICollectionView) -> UICollectionViewCell {
        
        let index = indexPath.item
        let destination = itineraries![cv.tag].destinations[index]
        let cell = cv.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
        cell.configureWith(destination)
        cell.isUserInteractionEnabled = false
        return cell
        
    }
    
    func setupLegCell(with indexPath: IndexPath, for cv: UICollectionView) -> UICollectionViewCell {
        
        let index = indexPath.item
        let leg = itineraries![cv.tag].route.legs[index]
        let cell = cv.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! RouteCell
        let gradient = [leg.startPlace.color, leg.endPlace.color]
        
        cell.configureWith(timing: leg.timing, duration: leg.travelTiming.duration, hourHeight: hourHeight!, gradient: gradient)
        return cell
    }
    
}

extension OptionsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if ((indexPath.item == 0) || (indexPath.item == itineraries!.count + 1)) {
            return CGSize(width: collectionView.frame.width * 0.25, height: collectionView.frame.height)
        }
        return CGSize(width: collectionView.frame.width * 0.5, height: collectionView.frame.height)
    }
    
}

extension OptionsViewController: ItineraryLayoutDelegate {
    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat {
        guard let itineraries = itineraries else { return 0 }
        
        let firstDest = itineraries[0].schedule[0]
        if let enteringLeg = itineraries[0].route.legs.first {
            return CGFloat(min(firstDest.timing.start.inHours(), enteringLeg.timing.start.inHours()))
        } else {
            return CGFloat(firstDest.timing.start.inHours())
        }
        
        
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return hourHeight ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
        
        let optionIndex = collectionView.tag
        if indexPath.section == 0 {
            return itineraries![optionIndex].schedule[indexPath.item].timing
        } else {
            return itineraries![optionIndex].route.legs[indexPath.item].timing
        }
        
    }
    
}

extension OptionsViewController {
    
    func isMainCollectionView(_ collectionView: UICollectionView) -> Bool {
        if collectionView.tag < 0 {
            return true
        }
        
        return false
    }
    
}

class MiniTimelineCell: UICollectionViewCell {
    
    var timelineView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = .clear
        setupTimelineView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        fatalError("Interface Builder is not supported!")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        fatalError("Interface Builder is not supported!")
    }
    
    func setupTimelineView() {
        
        let layout = ItineraryLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        let destNib = UINib(nibName: "DestCell", bundle: nil)
        let routeNib = UINib(nibName: "RouteCell", bundle: nil)
        collectionView.register(routeNib, forCellWithReuseIdentifier: legReuseIdentifier)
        collectionView.register(destNib, forCellWithReuseIdentifier: locationReuseIdentifier)
        collectionView.backgroundColor = .clear
        timelineView = collectionView
        
    }

}

protocol OptionsViewControllerDelegate: AnyObject {
    
    func optionsViewController(_ optionsViewController: OptionsViewController, shouldDismissWithSelectedOptionIndex index: Int)
    
}


