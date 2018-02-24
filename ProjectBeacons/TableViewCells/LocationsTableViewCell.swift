//
//  LocationsTableViewCell.swift
//  ProjectBeacons
//
//  Created by Maria Syed on 06/02/2018.
//  Copyright © 2018 Maria Syed. All rights reserved.
//

import UIKit

class LocationsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
