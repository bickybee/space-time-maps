//
//  PlaceGroupHeaderView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupHeaderView: UICollectionReusableView, Draggable {
        
    @IBOutlet weak var label: UILabel!
    var dragHandle: UIView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupHandle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupHandle()
    }
    
    private func setupHandle() {
        dragHandle.frame = self.frame
        dragHandle.backgroundColor = .red
        dragHandle.layer.zPosition = 1000
        self.addSubview(dragHandle)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let newHeight = self.frame.size.width
        dragHandle.frame.size.height = newHeight
    }
    
}
