//
//  DestCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class DestCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    override var isHighlighted: Bool {
        didSet {
            containerView.backgroundColor = isHighlighted ? containerView.backgroundColor?.withAlphaComponent(0.5) : containerView.backgroundColor?.withAlphaComponent(1.0)
        }
    }

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
    }
    
    private func setup() {
        containerView.layer.cornerRadius = 5;
        containerView.layer.masksToBounds = true;
    }
    
    func configureWith(_ destination: Destination, _ isCurrentlyDragging: Bool) {
        
        nameLabel.text = destination.place.name
        durationLabel.text = Utils.secondsToString(seconds: destination.timing.duration)
        containerView.backgroundColor = destination.place.color
        isUserInteractionEnabled = false
        if isCurrentlyDragging {
            addShadow()
        }
    }
    
    override func prepareForReuse() {
         removeShadow()
    }

}
