//
//  TimelineViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

private let reuseIdentifier = "locationCell"

class TimelineViewController: UICollectionViewController {
    
    var itinerary = [Place]()
    
    private let cellHeight : CGFloat = 100.0
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.register(LocationCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.dragInteractionEnabled = true
        self.collectionView?.dropDelegate = self
        self.collectionView?.dragDelegate = self
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itinerary.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        let index = indexPath.item
        if index == 0 {
            cell.backgroundColor = .green
        } else if index == self.itinerary.count - 1 {
            cell.backgroundColor = .red
        } else {
            cell.backgroundColor = .yellow
        }
        cell.nameLabel.text = self.itinerary[index].name
        cell.nameLabel.backgroundColor = .white
        cell.nameLabel.sizeToFit()
        cell.nameLabel.center = cell.contentView.center
        return cell
    }

}

extension TimelineViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = collectionView.frame.size
        size.width -= (sectionInsets.left + sectionInsets.right)
        return CGSize(width:size.width, height:self.cellHeight)
    }
}

// MARK: - UICollectionViewDropDelegate
extension TimelineViewController: UICollectionViewDropDelegate {
    
    // Enable dropping
    func collectionView(_ collectionView: UICollectionView,
                        canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    // What to do when a drop is performed?
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        var destinationIndexPath : IndexPath
        if let givenIndexPath = coordinator.destinationIndexPath {
            destinationIndexPath = givenIndexPath
        } else {
            destinationIndexPath = IndexPath(item: 0, section: 0)
        }
    
        coordinator.items.forEach { dropItem in
            dropItem.dragItem.itemProvider.loadObject(ofClass: Place.self, completionHandler: {(newPlace, error) in
                DispatchQueue.main.sync {
                    if let place = newPlace as? Place {
                        if let sourceIndexPath = dropItem.sourceIndexPath {
                            self.itinerary.remove(at: sourceIndexPath.item)
                            collectionView.deleteItems(at: [sourceIndexPath])
                        }
                        self.itinerary.insert(place, at: destinationIndexPath.item)
                        collectionView.insertItems(at: [destinationIndexPath])
                        coordinator.drop(dropItem.dragItem,
                                         toItemAt: destinationIndexPath)
                        print(self.itinerary)
                        UIView.performWithoutAnimation {
                            collectionView.reloadSections(IndexSet([0]))
                        }

                    }
                }
            })
        }

    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal {
            return UICollectionViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath)
    }
    
}

// MARK: - UICollectionViewDragDelegate
extension TimelineViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        let place = self.itinerary[indexPath.item]
        let item = NSItemProvider(object: place as NSItemProviderWriting)
        let dragItem = UIDragItem(itemProvider: item)
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        print(session)
    }
}
