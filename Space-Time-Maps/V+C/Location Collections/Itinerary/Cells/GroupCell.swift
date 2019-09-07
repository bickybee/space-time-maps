//
//  AsManyOfCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupCell: UICollectionViewCell, Draggable {

    var dragHandle : UIView! = UIView()
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var optionControl: UIPageControl!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    private let optionTint = UIColor.white.withAlphaComponent(0.5)
    private let currentOptionTint = UIColor.white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
    }

    func setup() {
        
        
        tabView.layer.cornerRadius = 5
        tabView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        containerView.layer.cornerRadius = 5
        containerView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        
        optionControl.transform = (CGAffineTransform(scaleX: 0.5, y: 0.5))
        optionControl.pageIndicatorTintColor = optionTint
        optionControl.currentPageIndicatorTintColor = currentOptionTint
        
        dragHandle = UIView(frame: containerView.frame)
        dragHandle.backgroundColor = .clear
        dragHandle.layer.cornerRadius = 5;
        dragHandle.layer.masksToBounds = true;
        self.addSubview(dragHandle)
        
    }
    
    func configureWith(_ block: OptionBlock) {
        
        configureLabelsWith(block)
        configureOptionControlWith(block)
        
    }
    
    private func configureLabelsWith(_ block: OptionBlock) {
        
        nameLabel.text = block.name
        
    }
    
    private func configureOptionControlWith(_ block: OptionBlock) {
        
        optionControl.numberOfPages = block.optionCount
        
        if let option = block.optionIndex {
            optionControl.currentPageIndicatorTintColor = UIColor.white
            optionControl.currentPage = option
            optionControl.updateCurrentPageDisplay()
        } else {
            optionControl.currentPageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
            optionControl.updateCurrentPageDisplay()
        }
        
    }
    
}
