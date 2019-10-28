//
//  AsManyOfCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import FontAwesome_swift

class GroupCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setup() {
        
        lockButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15.0, style: .solid)
        lockButton.setTitle(String.fontAwesomeIcon(name: .lockOpen), for: .normal)
        lockButton.setTitle(String.fontAwesomeIcon(name: .lock), for: .selected)
        
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
