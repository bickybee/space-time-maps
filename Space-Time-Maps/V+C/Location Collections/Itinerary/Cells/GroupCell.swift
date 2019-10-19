//
//  AsManyOfCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var optionControl: UIPageControl!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    private let optionTint = UIColor.white.withAlphaComponent(0.5)
    private let currentOptionTint = UIColor.white
    
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
        
        containerView.layer.cornerRadius = 5
        
        optionControl.transform = (CGAffineTransform(scaleX: 0.5, y: 0.5))
        optionControl.pageIndicatorTintColor = optionTint
        optionControl.currentPageIndicatorTintColor = currentOptionTint
        
    }
    
    func configureWith(_ block: OptionBlock) {
        
        configureLabelsWith(block)
        configureOptionControlWith(block)
        
    }
    
    private func configureLabelsWith(_ block: OptionBlock) {
        
        nameLabel.text = block.name
        
    }
    
    private func configureOptionControlWith(_ block: OptionBlock) {
        
        optionControl.numberOfPages = block.options.count
        
        if let option = block.selectedOption {
            optionControl.currentPageIndicatorTintColor = UIColor.white
            optionControl.currentPage = option
            optionControl.updateCurrentPageDisplay()
        } else {
            optionControl.currentPageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
            optionControl.updateCurrentPageDisplay()
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
