//
//  SignalPayload.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/27/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation
import PubNub

enum SignalType: Int, Codable {
    case typingOff = 0
    case typingOn = 1
}

struct Signal: Codable {
    var userId: Int
    var type: SignalType
}

extension Signal: JSONCodable {
    var codableValue: AnyJSON {
        [
            CodingKeys.userId.stringValue: userId,
            CodingKeys.type.stringValue: type.rawValue
        ]
    }
}
