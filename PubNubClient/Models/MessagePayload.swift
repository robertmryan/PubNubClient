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

struct MessagePayload: Codable {
    let type: MessagePayloadAction             // pubnub uses "type" to indicate whether update or not in its chat API, so let's follow that convention
    let messageId: Int
    let userId: UserId
    let text: String
    let timestamp: Date                        // In 2020-08-28T00:21:32.024Z ISO 8601 format?

    enum CodingKeys: String, CodingKey {
        case type
        case messageId = "message_id"
        case userId = "user_id"
        case text
        case timestamp
    }
    
    init(type: MessagePayloadAction = .new, messageId: Int = .random(in: 1...1_000_000), userId: UserId, text: String, timestamp: Date = Date()) {
        self.type = type
        self.messageId = messageId
        self.userId = userId
        self.text = text
        self.timestamp = timestamp
    }
}

extension MessagePayload {
    var message: Message { Message(messageId: messageId, userId: userId, text: text, timestamp: timestamp)}
}

extension MessagePayload: JSONCodable {
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
