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
    
    weak var delegate: OptionsViewControllerDelegate!
    weak var collectionView: UICollectionView!
    var hourHeight: CGFloat?
    var timelineOffset: TimeInterval = 0.0
    
    var blockIndex: Int!
    var selectedOption: Int!
    var itineraries: [(Itinerary, Int)]? {
        didSet {
            collectionView.reloadData()
        }
    }
    

    override func loadView() {
        super.loadView()
        setupCollectionView()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.register(MiniTimelineCell.self, forCellWithReuseIdentifier: "MiniTimelineCell")
        self.collectionView.register(NilCell.self, forCellWithReuseIdentifier: nilReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.scrollToItem(at: IndexPath(item: selectedOption + 1, section: 0), at: .centeredHorizontally, animated: false)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    func isPaddingCell(indexPath: IndexPath) -> Bool {
        return ((indexPath.item == 0) || (indexPath.item == itineraries!.count + 1))
    }
    
    func setSelectedOption(_ index: Int) {
        selectedOption = itineraries!.firstIndex(where: {$0.1 == index})
    }

}

extension OptionsViewController: UICollectionViewDelegate {
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isPaddingCell(indexPath: indexPath) else { return }
        
        let centerIndex = collectionView.getCenterCellIndex()!
        if indexPath.item == centerIndex {
             // due to padding cells
            delegate.shouldDismissOptionsViewController(self)
        } else {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func selectOptionIndex(_ index: Int) {
        
        selectedOption = index
        delegate.optionsViewController(self, didSelectOptionIndex: index)
        
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
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let centerIndex = collectionView.getCenterCellIndex()!
        let optionForIndex = itineraries![centerIndex - 1].1
        selectOptionIndex(optionForIndex)
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
                return itineraries[whichOption].0.schedule.count
            } else { // legs! TODO!
                return itineraries[whichOption].0.route.count
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isMainCollectionView(collectionView) {
            if (isPaddingCell(indexPath: indexPath)) {
                return collectionView.dequeueReusableCell(withReuseIdentifier: nilReuseIdentifier, for: indexPath) as! NilCell
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniTimelineCell", for: indexPath) as! MiniTimelineCell
            cell.timelineView.delegate = self
            cell.timelineView.dataSource = self
            cell.timelineView.tag = indexPath.item - 1 // Because of nil cell to start
            cell.timelineView.isUserInteractionEnabled = false
            
            let travelTime = itineraries![indexPath.item - 1].0.route.travelTime
            cell.timeLabel.text = " " + Utils.secondsToRelativeTimeString(seconds: travelTime)
            
            if (indexPath.item == 0) {
                cell.setColor(.flatLime())
            } else {
                if travelTime == itineraries![0].0.route.travelTime {
                    cell.setColor(.flatLime())
                } else {
                    cell.setColor(.darkGray)
                }
            }
            
            let layout = cell.timelineView!.collectionViewLayout as! ItineraryLayout
            layout.delegate = self
            layout.shouldPadCells = false

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
        let destination = itineraries![cv.tag].0.destinations[index]
        let cell = cv.dequeueReusableCell(withReuseIdentifier: locationReuseIdentifier, for: indexPath) as! DestCell
        cell.configureWith(destination, false)
        cell.isUserInteractionEnabled = false
        return cell
        
    }
    
    func setupLegCell(with indexPath: IndexPath, for cv: UICollectionView) -> UICollectionViewCell {
        
        let index = indexPath.item
        let leg = itineraries![cv.tag].0.route.legs[index]
        let cell = cv.dequeueReusableCell(withReuseIdentifier: legReuseIdentifier, for: indexPath) as! RouteCell
        let gradient = [leg.startPlace.color, leg.endPlace.color]
        
        cell.configureWith(timing: leg.timing, duration: leg.travelTiming.duration, hourHeight: hourHeight!, gradient: gradient)
        return cell
    }
    
}

extension OptionsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if (isPaddingCell(indexPath: indexPath)) {
            return CGSize(width: collectionView.frame.width * 0.25, height: collectionView.frame.height)
        }
        return CGSize(width: collectionView.frame.width * 0.5, height: collectionView.frame.height)
    }
    
}

extension OptionsViewController: ItineraryLayoutDelegate {
    func timelineSidebarWidth(of collectionView: UICollectionView) -> CGFloat {
        return 0.0
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return hourHeight ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
        
        let optionIndex = collectionView.tag
        if indexPath.section == 0 {
            return itineraries![optionIndex].0.schedule[indexPath.item].timing.offsetBy(timelineOffset)
        } else {
            return itineraries![optionIndex].0.route.legs[indexPath.item].timing.offsetBy(timelineOffset)
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
    var timeLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.backgroundColor = .clear
        layer.cornerRadius = 3
        setupTimelineView()
        setupTimelineOutline()
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
    
    func setupTimelineOutline() {
        // HIGHLIGHTING EXPERIMENTING
        layer.borderWidth = 2
        layer.borderColor = UIColor.lightGray.cgColor
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = UIColor.lightGray
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.heightAnchor.constraint(equalToConstant: 20.0)
        ])
        label.layer.cornerRadius = 3
        timeLabel = label
    }
    
    func setColor(_ color: UIColor) {
        layer.borderColor = color.cgColor
        timeLabel.backgroundColor = color
    }

}

protocol OptionsViewControllerDelegate: AnyObject {
    
    func shouldDismissOptionsViewController(_ optionsViewController: OptionsViewController)
    func optionsViewController(_ optionsViewController: OptionsViewController, didSelectOptionIndex index: Int)
}


