//
//  LocationHistoryTableViewCell.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 17/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit

class LocationHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastVisitedLabel: UILabel!
    @IBOutlet weak var timesVisitedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        profileImage.layer.masksToBounds = false
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
