//
//  NoteTableViewCell.swift
//  NoteConcept
//
//  Created by Nadiya on 10/26/18.
//  Copyright © 2018 Nadiya. All rights reserved.
//

import UIKit

class NoteTableViewCell: UITableViewCell {

    @IBOutlet weak var getCurrentTimeLabel: UILabel!
    @IBOutlet weak var newNoteLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
