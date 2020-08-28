//
//  MessageCell.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/27/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import UIKit

protocol MessageCellDelegate: class {
    func cell(_ cell: UITableViewCell, didChangeText text: String)
}

class MessageCell: UITableViewCell {
    weak var delegate: MessageCellDelegate?

    @IBOutlet weak var bubbleLabel: BubbleLabel!

    func configure(for text: String, isMine: Bool) {
        bubbleLabel.text = text
        bubbleLabel.fillColor = isMine ? .blue : .lightGray
        bubbleLabel.textColor = isMine ? .white : .black
        bubbleLabel.isOnLeft = !isMine
    }
}
