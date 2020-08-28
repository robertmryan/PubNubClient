//
//  MessagePayload.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/27/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation
import PubNub

enum MessagePayloadAction: String, Codable {
    case new
    case update                                // pubnub uses "type" of "update" for updates to a chat message, so let's follow that convention
    case delete
}

struct Message: Codable {
    var type: MessagePayloadAction = .new        // pubnub uses "type" to indicate whether update or not in its chat API, so let's follow that convention
    var messageId: Int = .random(in: 1...1_000_000)
    var userId: Int
    var text: String
    var timestamp: Date = Date()               // In 2020-08-28T00:21:32.024Z ISO 8601 format?

    enum CodingKeys: String, CodingKey {
        case timestamp, type, text
        case messageId = "message_id"
        case userId = "user_id"
    }
}

extension Message: JSONCodable {
    var codableValue: AnyJSON {
        [
            CodingKeys.userId.stringValue: userId,
            CodingKeys.messageId.stringValue: messageId,
            CodingKeys.text.stringValue: text,
            CodingKeys.type.stringValue: type,
            CodingKeys.timestamp.stringValue: DateFormatter.iso8601.string(for: timestamp) // this is Pubnub's formatter; alternative might be `timestamp.timeIntervalSince1970 * 1000`
        ]
    }
}
