//
//  Event.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/28/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation
import PubNub

enum EventType: String, Codable {
    case message
    case action
    case receipt
}

struct Event<T: Codable>: Codable {
    let type: EventType
    let data: T
}

extension Event: JSONCodable where T: JSONCodable {
    var codableValue: AnyJSON {
        [
            CodingKeys.type.stringValue: type,
            CodingKeys.data.stringValue: data.codableValue
        ]
    }
}
