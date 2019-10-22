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
    var destContainer: UIView!
    
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
        optionControl.transform = (CGAffineTransform(scaleX: 0.75, y: 0.75))
        optionControl.pageIndicatorTintColor = optionTint
        optionControl.currentPageIndicatorTintColor = currentOptionTint
        
    }
    
    func configureWith(_ block: OptionBlock) {
        
        configureDestinationsWith(block)
        configureLabelsWith(block)
        configureOptionControlWith(block)
        
    }
    
    func configureDestinationsWith(_ block: OptionBlock){
        guard let destinations = block.destinations else { return }
        destContainer = UIView(frame: containerView.frame)
        containerView.addSubview(destContainer)
        
        for dest in destinations {
            let frame = rectForDestination(dest, from: block)
            let destView = PaddedDestinationView(frame: frame)
            destView.destinationView.nameLabel.text = dest.place.name
            destView.destinationView.durationLabel.text = Utils.secondsToString(seconds:dest.timing.duration)
            destView.destinationView.backgroundColor = dest.place.color
            destContainer.addSubview(destView)
        }
        
    }
    
    func rectForDestination(_ dest: Destination, from block: OptionBlock) -> CGRect {
        
        let height : CGFloat = CGFloat((dest.timing.duration / block.timing.duration)) * self.frame.height
        let width : CGFloat = self.frame.width
        let x : CGFloat = 0.0
        let y : CGFloat = CGFloat((dest.timing.start - block.timing.start) / block.timing.duration) * self.frame.height
        let frame = CGRect(x: x, y: y, width: width, height: height)
        return frame
        
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
        print(containerView.subviews.count)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        destContainer.subviews.forEach({ $0.removeFromSuperview() }) // this gets things done
        destContainer.removeFromSuperview()
    }
    
}
