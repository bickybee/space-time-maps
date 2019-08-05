//
//  ItineraryViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

private let reuseIdentifier = "locationCell"

class ItineraryViewController: UICollectionViewController {
    
    var itineraryManager: ItineraryManager!
    
    private let cellHeight : CGFloat = 50.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itineraryManager.getPlaceManager().numPlaces()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        let index = indexPath.item
        
        
        if let place = itineraryManager.getPlaceManager().getPlace(at: index) {
            var text = ""
            
            // If there's an existing route and the cell is odd, return a route cell
            if let route = itineraryManager.getRoute() {
                let legs = route.getLegs()
                if index > 0 && index <= legs.count {
                    let timeInSeconds = route.getLeg(at: index - 1).duration
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.hour, .minute]
                    formatter.unitsStyle = .full
                    let formattedString = formatter.string(from: TimeInterval(timeInSeconds))!
                    text += formattedString + " -> "
                }
            }
            
            // Else, return a location cell
            if index == 0 {
                cell.backgroundColor = .green
            } else if index == self.itineraryManager.getPlaceManager().numPlaces() - 1 {
                cell.backgroundColor = .red
            } else {
                cell.backgroundColor = .yellow
            }
            text += place.name
            cell.nameLabel.text = text
            cell.nameLabel.backgroundColor = .white
            cell.nameLabel.sizeToFit()
            cell.nameLabel.center = cell.contentView.center
        }
        
        return cell
    }

}

extension ItineraryViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }
}
