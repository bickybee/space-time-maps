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
    @IBOutlet weak var nextButton: UIButton!
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
        nextButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15.0, style: .solid)
        nextButton.setTitle(String.fontAwesomeIcon(name: .arrowRight), for: .normal)
        
        optionsButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15.0, style: .solid)
        optionsButton.setTitle(String.fontAwesomeIcon(name: .ellipsisH), for: .normal)
        
        lockButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 15.0, style: .solid)
        lockButton.setTitle(String.fontAwesomeIcon(name: .lockOpen), for: .normal)
        lockButton.setTitle(String.fontAwesomeIcon(name: .lock), for: .selected)
    }

    @IBAction func didPressLock(_ sender: Any) {
        delegate?.didPressLockOnGroupCell(self)
    }
    
    @IBAction func didPressNext(_ sender: Any) {
        delegate?.didPressNextOnGroupCell(self)
    }
    
    @IBAction func didPressOptions(_ sender: Any) {
        delegate?.didPressOptionsOnGroupCell(self)
    }
    
}

protocol GroupButtonsDelegate: AnyObject {
    
    func didPressNextOnGroupCell(_ cell: GroupCell)
    func didPressOptionsOnGroupCell(_ cell: GroupCell)
    func didPressLockOnGroupCell(_ cell: GroupCell)
    
}
