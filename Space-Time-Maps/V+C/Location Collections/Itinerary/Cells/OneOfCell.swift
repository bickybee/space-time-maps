//
//  OneOfCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 03/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class OneOfCell: UICollectionViewCell, Draggable {
    
    @IBOutlet weak var containerView: UIView!
    
    // Data rendering
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var optionControl: UIPageControl!
    var optionColor : UIColor!
    
    // Interactive
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    var dragHandle : UIView! = UIView()
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dragHandle.frame = containerView.frame
    }
    
    private func setup() {
        containerView.layer.cornerRadius = 5;
        containerView.layer.masksToBounds = true;
        
        optionControl.transform = (CGAffineTransform(scaleX: 0.5, y: 0.5))
        optionControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        optionControl.currentPageIndicatorTintColor = UIColor.white
        
        dragHandle = UIView(frame: containerView.frame)
        dragHandle.backgroundColor = .clear
        dragHandle.layer.zPosition = 100
        dragHandle.layer.cornerRadius = 5;
        dragHandle.layer.masksToBounds = true;
        self.addSubview(dragHandle)
    }
    
    func configureWith(_ oneOf: OneOfGroup) {
        
        configureLabelsWith(oneOf)
        configureOptionControlWith(oneOf)
        
    }
    
    private func configureLabelsWith(_ oneOf: OneOfGroup) {
        
        groupLabel.text = oneOf.name
        destinationLabel.text = oneOf.selectedDestination?.place.name ?? "No destination selected"
        durationLabel.text = Utils.secondsToString(seconds: oneOf.timing.duration)
        
    }
    
    private func configureOptionControlWith(_ oneOf: OneOfGroup) {
        
        optionControl.numberOfPages = oneOf.places.count
        
        if let option = oneOf.selectedIndex {
            optionControl.currentPageIndicatorTintColor = UIColor.white
            optionControl.currentPage = option
            optionControl.updateCurrentPageDisplay()
        } else {
            optionControl.currentPageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
            optionControl.updateCurrentPageDisplay()
        }
        
    }

}
