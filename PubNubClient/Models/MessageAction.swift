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
    case read = "message_read"
    case delivered = "message_delivered"
}

struct MessageReceipt {
    let type: MessageActionType = .receipt
    let value: MessageActionValue = .read
    let userId: Int
    let messageIdStart: String?
    let messageIdEnd: String

    enum CodingKeys: String, CodingKey {
        case type, value
        case userId = "user_id"
        case messageIdStart = "message_id_start"
        case messageIdEnd = "message_id_end"
    }
}

extension MessageReceipt: JSONCodable {
    var codableValue: AnyJSON {
        [
            CodingKeys.userId.stringValue: userId,
            CodingKeys.messageIdStart.stringValue: messageIdStart,
            CodingKeys.messageIdEnd.stringValue: messageIdEnd,
            CodingKeys.type.stringValue: type
        ]
    }
}

