//
//  PlaceGroupHeaderView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupHeaderView: UICollectionReusableView {
        
    @IBOutlet weak var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: -1)
        self.layer.shadowRadius = 0;
        self.layer.shadowOpacity = 0.5;
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let newHeight = self.frame.size.height
    }
    
}
