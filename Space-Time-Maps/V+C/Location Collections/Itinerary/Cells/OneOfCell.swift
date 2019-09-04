//
//  OneOfCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 03/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class OneOfCell: UICollectionViewCell, Draggable {
    var dragHandle : UIView = UIView()
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var optionControl: UIPageControl!
    
    
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
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = true;
        
        optionControl.transform = (CGAffineTransform(scaleX: 0.5, y: 0.5))
        
        dragHandle.frame = contentView.frame
        dragHandle.backgroundColor = .clear
        dragHandle.layer.zPosition = 1000
        self.addSubview(dragHandle)
    }

}
