//
//  PubNubEventManager.swift
//  PubNubClient
//
//  Note, while the PubNub listeners and the sending of the signals might be interesting
//  for client developers, the sending of the messages via pubnub will be handled by the server.
//  The publishing of messages is here simply for purposes of demonstrating the propagation
//  of messages through the PubNub system, but in the final implementation, our backend will
//  be doing the sending, not the client.
//
//  Created by Robert Ryan on 8/29/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation
import PubNub

class PubNubEventManager {
    // MARK: - Event handler closures

    var onReceiveMessage: ((MessagePayload) -> Void)?
    var onReceiveReceipt: ((MessageReceipt) -> Void)?
    var onReceiveSignal: ((Signal) -> Void)?
    var onTypingOn: ((Int) -> Void)?
    var onTypingOff: ((Int) -> Void)?

    // MARK: - Private properties

    private let userId: UserId
    private let channel: String

    private let listener = SubscriptionListener()

    static let pubnub: PubNub = {
        var configuration = PubNubConfiguration(
            publishKey: PubNubCredentials.publishKey,    // note these keys are not included in this repo, so use your own keys here
            subscribeKey: PubNubCredentials.subscribeKey
        )

        configuration.uuid = UUID().uuidString
        return PubNub(configuration: configuration)
    }()

    lazy var pubnub = Self.pubnub

    // MARK: - Object lifecycle

    init(userId: UserId, channel: String) {
        self.userId = userId
        self.channel = channel

        configurePubNub()
    }
}

// MARK: - Public interface

extension PubNubEventManager {
    /// Publish a message to be sent via PubNub.
    ///
    /// - Parameter event: The `Message` wrapped in an `Event`.

    func send(_ message: Message) {
        let message = MessagePayload(userId: message.userId, text: message.text)
        publish(message)
    }

    func update(_ message: Message) {
        let message = MessagePayload(type: .update, messageId: message.messageId, userId: message.userId, text: message.text)
        publish(message)
    }

    func delete(_ message: Message) {
        let message = MessagePayload(type: .delete, messageId: message.messageId, userId: message.userId, text: message.text)
        publish(message)
    }

    func publishReadReceipt(for messageId: Int) {
        let receipt = MessageReceipt(userId: userId, messageIdEnd: messageId)
        let event = Event(type: .receipt, data: receipt)
//        debugPrintJSON(for: event)

        pubnub.publish(channel: channel, message: event) { result in
            switch result {
            case let .success(response):
                print("Successful Publish Response: \(response)")

            case let .failure(error):
                print("Failed Publish Response: \(error.localizedDescription)")
            }
        }
    }

    /// Send signal to PubNub indicating that the user is typing.

    func signalStartTyping() {
        let typingOn = Signal(id: userId, type: .typingOn)
        signal(typingOn)
    }

    /// Send signal to PubNub indicating that the user is no longer typing.

    func signalStopTyping() {
        let typingOff = Signal(id: userId, type: .typingOff)
        signal(typingOff)
    }
}

// MARK: - Private implementation

private extension PubNubEventManager {

    func publish(_ message: MessagePayload) {
        let event = Event(type: .message, data: message)
//        debugPrintJSON(for: event)

        pubnub.publish(channel: channel, message: event) { result in
            switch result {
            case let .success(response):
                print("Successful Publish Response: \(response)")

            case let .failure(error):
                print("Failed Publish Response: \(error.localizedDescription)")
            }
        }
    }

    func debugPrintJSON<T: Encodable>(for object: T) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601)
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(object)
        print(String(data: data, encoding: .utf8)!)
    }

    func configurePubNub() {
        // Add listener event callbacks
        listener.didReceiveSubscription = { [weak self] event in
            switch event {
            case let .messageReceived(message):
                self?.handle(messageEvent: message)

            case let .connectionStatusChanged(status):
                print("Status Received: \(status)")

            case let .presenceChanged(presence):
                print("Presence Received: \(presence)")

            case let .subscribeError(error):
                print("Subscription Error \(error)")

            case let .signalReceived(signal):
                self?.handle(signalEvent: signal)

            default:
                break
            }
        }

        pubnub.add(listener)
        pubnub.subscribe(to: [channel])
    }

    /// Send PubNub signal
    ///
    /// Used to send `typingOn` and `typingOff` signals.
    ///
    /// In PubNub, “signals” are smaller (max of 30 bytes!) than “messages”, but are less expensive.
    /// See [Messages vs Signals](https://www.pubnub.com/docs/platform/messages/publish#messages-vs-signals).
    ///
    /// - Parameter event: The receied `Signal` object.

    func signal(_ event: Signal) {
        pubnub.signal(channel: channel, message: event) { result in
            switch result {
            case let .success(response):
                print("Successful Signal Response: \(response)")

            case let .failure(error):
                print("Failed Signal Response: \(error.localizedDescription)")
            }
        }
    }

    /// Handle inbound message
    ///
    /// - Parameter event: The inbound `PubNubMessage`.

    func handle(messageEvent event: PubNubMessage) {
        guard
            let payload = event.payload.codableValue.dictionaryOptional,
            let string = payload["type"] as? String,
            let type = EventType(rawValue: string)
        else {
            print("whoops")
            return
        }

        switch type {
        case .message:
            guard let message = try? event.payload.codableValue.decode(Event<MessagePayload>.self) else { return }
            let payload = message.data
            onReceiveMessage?(payload)
            publishReadReceipt(for: payload.messageId)

        case .action:
            print("action")

        case .receipt:
            guard let receipt = try? event.payload.codableValue.decode(Event<MessageReceipt>.self) else { return }
            let payload = receipt.data
            onReceiveReceipt?(payload)
        }

        print(event)
    }

    /// Handle inbound signal
    ///
    /// Examples of signals include typing indicators.
    ///
    /// - Parameter event: The inbound `MessageEvent`.

    func handle(signalEvent event: PubNubMessage) {
        let signal: Signal
        do {
            signal = try event.payload.codableValue.decode(Signal.self)
        } catch {
            print(error)
            return
        }

        guard signal.id != userId else { return }
        
        switch signal.type {
        case .typingOff:
            onTypingOff?(signal.id)

        case .typingOn:
            onTypingOn?(signal.id)
        }

        print(event)
    }

}
