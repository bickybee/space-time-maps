//
//  OptionsViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 23/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {
    
    weak var collectionView: UICollectionView!
    var optionBlock: OptionBlock?
    var hourHeight: CGFloat?
    

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
        
        self.collectionView.backgroundColor = .white
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.register(MiniTimelineCell.self, forCellWithReuseIdentifier: "MiniTimelineCell")
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
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let optionBlock = optionBlock else { return 0 }
        if isMainCollectionView(collectionView) {
            return optionBlock.options.count
        } else {
            let whichOption = collectionView.tag
            print(optionBlock.options[whichOption].count)
            return optionBlock.options[whichOption].count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isMainCollectionView(collectionView) {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniTimelineCell", for: indexPath) as! MiniTimelineCell
            cell.timelineView.delegate = self
            cell.timelineView.dataSource = self
            let layout = cell.timelineView!.collectionViewLayout as! ItineraryLayout
            layout.delegate = self
            cell.timelineView.reloadData()
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyCell", for: indexPath)
            cell.backgroundColor = ColorUtils.randomColor()
            return cell
            
        }
        
    }
    
}

extension OptionsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width * 0.5, height: collectionView.frame.height)
    }
    
}

extension OptionsViewController: ItineraryLayoutDelegate {
    func timelineStartHour(of collectionView: UICollectionView) -> CGFloat {
        return CGFloat(optionBlock!.timing.start.inHours())
    }
    
    func hourHeight(of collectionView: UICollectionView) -> CGFloat {
        return hourHeight ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, timingForEventAtIndexPath indexPath: IndexPath) -> Timing {
        
        guard let optionBlock = optionBlock else { return Timing(start: 0, duration: 0) }
        
        let optionIndex = collectionView.tag
        if let asManyOf = optionBlock as? AsManyOfBlock {
            let event = asManyOf.scheduledOptions![optionIndex][indexPath.item]
            return event.timing
        } else {
            return optionBlock.timing
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
        self.contentView.backgroundColor = .lightGray
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
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MyCell")
        collectionView.backgroundColor = .red
        timelineView = collectionView
        
    }

}


