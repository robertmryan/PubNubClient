//
//  MessageAction.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/28/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation
import PubNub

enum MessageActionType: String, Codable {
    case receipt
    case reaction
}

enum MessageActionValue: String, Codable {
    case read = "messageRead"
    case delivered = "messageDelivered"
}

struct MessageReceipt: Codable {
    let value: MessageActionValue
    let userId: UserId
    let messageIdStart: Int?
    let messageIdEnd: Int

    enum CodingKeys: String, CodingKey {
        case value
        case userId = "user_id"
        case messageIdStart = "message_id_start"
        case messageIdEnd = "message_id_end"
    }

    init(type: MessageActionType = .receipt, value: MessageActionValue = .read, userId: UserId, messageIdStart: Int? = nil, messageIdEnd: Int) {
        self.value = value
        self.userId = userId
        self.messageIdStart = messageIdStart
        self.messageIdEnd = messageIdEnd
    }
}

extension MessageReceipt: JSONCodable {
    var codableValue: AnyJSON {
        [
            CodingKeys.value.stringValue: value,
            CodingKeys.userId.stringValue: userId,
            CodingKeys.messageIdStart.stringValue: messageIdStart,
            CodingKeys.messageIdEnd.stringValue: messageIdEnd,
        ]
    }
}

