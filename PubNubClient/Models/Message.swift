//
//  Message.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/30/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation

struct Message {
    let messageId: Int
    let userId: UserId
    var text: String
    let timestamp: Date             // In 2020-08-28T00:21:32.024Z ISO 8601 format?
    var readPoint: [UserId]

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case userId = "user_id"
        case text
        case timestamp
        case readPoint = "read_point"
    }

    init(messageId: Int? = nil, userId: UserId, text: String, timestamp: Date = Date(), readPoint: [UserId] = []) {
        self.messageId = messageId ?? .random(in: 1...1_000_000)
        self.userId = userId
        self.text = text
        self.timestamp = timestamp
        self.readPoint = readPoint
    }
}
