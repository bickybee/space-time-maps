//
//  PlannerViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class OldItineraryViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var timelineCollectionView: UICollectionView!
    @IBOutlet weak var listCollectionView: UICollectionView!
    
    private let cellHeight : CGFloat = 100.0
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    private let reuseIdentifier = "locationCell"
    
    var savedPlaces : PlaceManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        timelineCollectionView.dataSource = self as? UICollectionViewDataSource
        timelineCollectionView.delegate = self as? UICollectionViewDelegateFlowLayout
        listCollectionView.dataSource = self as? UICollectionViewDataSource
        listCollectionView.delegate = self as? UICollectionViewDelegateFlowLayout

        timelineCollectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        listCollectionView.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.savedPlaces.getPlaces().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        cell.backgroundColor = .yellow
        cell.nameLabel.text = self.placeName(for: indexPath)
        
        return cell
    }
    
    func place(for indexPath: IndexPath) -> Place? {
        let allPlaces = savedPlaces.getPlaces()
        let index = indexPath.item
        return allPlaces.indices.contains(index) ? allPlaces[index] : nil
    }
    
    func placeName(for indexPath: IndexPath) -> String? {
        let place = self.place(for: indexPath)
        return place?.name
    }

}

//MARK: - UICollectionViewDelegateFlowLayout
extension OldItineraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = collectionView.bounds.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }
    
}
