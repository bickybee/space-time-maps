//
//  AsManyOfCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 04/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
//import FontAwesome_swift

class GroupCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    weak var delegate: GroupButtonsDelegate?
    
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
        optionsButton.setImage(UIImage.init(named:"ellipsis-h"), for: .normal);
        optionsButton.tintColor = UIColor.white;
        lockButton.setImage(UIImage.init(named:"lock-open"), for: .normal);
        lockButton.setImage(UIImage.init(named:"lock"), for: .selected);
        lockButton.tintColor = UIColor.white;
    }
    
    func configureWith(_ block: OptionBlock, _ isCurrentlyDragging: Bool) {
        lockButton.isSelected = block.isFixed
        if isCurrentlyDragging {
            addShadow()
        }
    }

    @IBAction func didPressLock(_ sender: Any) {
        delegate?.didPressLockOnGroupCell(self)
    }
    
    @IBAction func didPressOptions(_ sender: Any) {
        delegate?.didPressOptionsOnGroupCell(self)
    }
    
    override func prepareForReuse() {
        removeShadow()
    }
    
}

protocol GroupButtonsDelegate: AnyObject {
    
    func didPressNextOnGroupCell(_ cell: GroupCell)
    func didPressOptionsOnGroupCell(_ cell: GroupCell)
    func didPressLockOnGroupCell(_ cell: GroupCell)
    
}
