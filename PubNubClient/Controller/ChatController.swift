//
//  ChatController.swift
//  PubNubClient
//
//  This is a controller associated with the Chat view controller, encapsulating
//  all non-UI related business logic.
//
//  Created by Robert Ryan on 8/27/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation
import PubNub

class ChatController {
    private var messages: [Message] = []
    private let eventManager: PubNubEventManager
    var onNewMessage: ((Int) -> Void)?
    var onUpdateMessage: ((Int) -> Void)?
    var onDeleteMessage: ((Int) -> Void)?
    var onIsTyping: (() -> Void)?
    var onStopTyping: (() -> Void)?
    private var wasTyping = false
    var isTyping = false { didSet { updateTyping(isTyping) } }
    private var typers: Set<Int> = []

    private var typingTimer: Timer?

    /// Mock of Mydas userid
    private let userId = Int.random(in: 1000..<10000)

    init() {
        eventManager = PubNubEventManager(userId: userId, channel: "conv-1")
        addEventManagerObservers()
    }

}

// MARK: - Public Interface

extension ChatController {
    func send(_ text: String) {
        let message = Message(userId: userId, text: text)
        let event = Event(type: .message, data: message)
        debugPrintJSON(for: event)
        eventManager.publish(event)
    }

    func update(row: Int, with text: String) {
        messages[row].text = text
        messages[row].type = .update
        let event = Event(type: .message, data: messages[row])
        eventManager.publish(event)
    }

    func delete(row: Int) {
        messages[row].type = .delete

        let event = Event(type: .message, data: messages[row])
        eventManager.publish(event)
    }

    var messageCount: Int { messages.count }

    func text(for row: Int) -> String {
        messages[row].text
    }

    func isMine(for row: Int) -> Bool {
        messages[row].userId == userId
    }
}

// MARK: - Private Implementation

private extension ChatController {

    func debugPrintJSON<T: Encodable>(for object: T) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601)
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(object)
        print(String(data: data, encoding: .utf8)!)
    }

    func addEventManagerObservers() {
        eventManager.onReceiveMessage = { [weak self] message in
            self?.process(message)
        }

        eventManager.onTypingOn = { [weak self] userId in
            guard let self = self else { return }

            let didNotHaveTypers = self.typers.isEmpty
            self.typers.insert(userId)
            if didNotHaveTypers {
                self.onIsTyping?()
            }
        }

        eventManager.onTypingOff = { [weak self] userId in
            guard let self = self else { return }

            let hadTypers = !self.typers.isEmpty
            self.typers.remove(userId)
            let nowHasNoTypers = self.typers.isEmpty
            if hadTypers, nowHasNoTypers {
                self.onStopTyping?()
            }
        }
    }

    func process(_ message: Message) {
        switch message.type {
        case .new:
            let row = messages.count
            messages.append(message)
            onNewMessage?(row)

        case .update:
            guard let row = messageId(for: message) else { return }
            messages[row].text = message.text
            onUpdateMessage?(row)

        case .delete:
            guard let row = messageId(for: message) else { return }
            messages.remove(at: row)
            onDeleteMessage?(row)
        }
    }

    func messageId(for messagePayload: Message) -> Int? {
        messages.firstIndex { $0.messageId == messagePayload.messageId }
    }

    func updateTyping(_ isTyping: Bool) {
        switch isTyping {
        case true:
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                self?.wasTyping = false
                self?.eventManager.signalStopTyping()
            }

            if !wasTyping {
                eventManager.signalStartTyping()
                wasTyping = true
            }

        case false:
            if wasTyping {
                eventManager.signalStopTyping()
                wasTyping = false
            }
        }
    }

}
