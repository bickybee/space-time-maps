//
//  PassThroughCollectionView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 19/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PassThroughCollectionView: UICollectionView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.contains(where: {
            !$0.isHidden && $0.point(inside: self.convert(point, to: $0), with: event)
        })
    }

}
