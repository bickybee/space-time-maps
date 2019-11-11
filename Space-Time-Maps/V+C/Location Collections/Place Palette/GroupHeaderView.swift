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
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup() {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: -1)
        self.layer.shadowRadius = 0;
        self.layer.shadowOpacity = 0.5;
        
        editBtn.titleLabel?.font = UIFont.fontAwesome(ofSize: 15.0, style: .solid)
        editBtn.setTitle(String.fontAwesomeIcon(name: .edit), for: .normal)
        
        deleteBtn.titleLabel?.font = UIFont.fontAwesome(ofSize: 15.0, style: .solid)
        deleteBtn.setTitle(String.fontAwesomeIcon(name: .trash), for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let newHeight = self.frame.size.height
    }
    
}
