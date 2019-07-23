//
//  PlacePaletteViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

private let reuseIdentifier = "locationCell"

class PlacePaletteViewController: UICollectionViewController {
    
    var placeManager : PlaceManager!
    
    private let cellHeight : CGFloat = 100.0
    private let sectionInsets = UIEdgeInsets(top: 20.0, left: 10.0, bottom: 20.0, right: 10.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.dragInteractionEnabled = true
        self.collectionView?.dragDelegate = self
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placeManager.numPlaces()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        let index = indexPath.item
        cell.backgroundColor = .yellow
        cell.nameLabel.text = self.placeName(for: indexPath)
        cell.nameLabel.backgroundColor = .white
        cell.nameLabel.sizeToFit()
        cell.nameLabel.center = cell.contentView.center
        return cell
    }
    
    func place(for indexPath: IndexPath) -> Place? {
        let allPlaces = placeManager.getPlaces()
        let index = indexPath.item
        return allPlaces.indices.contains(index) ? allPlaces[index] : nil
    }
    
    func placeName(for indexPath: IndexPath) -> String? {
        let place = self.place(for: indexPath)
        return place?.name
    }

}

extension PlacePaletteViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = view.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }
}

// MARK: - UICollectionViewDragDelegate
extension PlacePaletteViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        if let place = self.place(for: indexPath) {
            let item = NSItemProvider(object: place as NSItemProviderWriting)
            let dragItem = UIDragItem(itemProvider: item)
            return [dragItem]
        } else {
            return []
        }
    }
}
