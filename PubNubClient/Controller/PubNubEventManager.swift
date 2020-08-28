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

    var onReceiveMessage: ((Message) -> Void)?
    var onReceiveSignal: ((Signal) -> Void)?
    var onTypingOn: ((Int) -> Void)?
    var onTypingOff: ((Int) -> Void)?

    // MARK: - Private properties

    private let userId: Int
    private let channel: String

    private let listener = SubscriptionListener()

    private let pubnub: PubNub = {
        var configuration = PubNubConfiguration(
            publishKey: PubNubCredentials.publishKey,    // note these keys are not included in this repo, so use your own keys here
            subscribeKey: PubNubCredentials.subscribeKey
        )

        configuration.uuid = UUID().uuidString
        return PubNub(configuration: configuration)
    }()

    // MARK: - Object lifecycle

    init(userId: Int, channel: String) {
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

    func publish(_ event: Event<Message>) {
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
        let typingOn = Signal(userId: userId, type: .typingOn)
        signal(typingOn)
    }

    /// Send signal to PubNub indicating that the user is no longer typing.

    func signalStopTyping() {
        let typingOff = Signal(userId: userId, type: .typingOff)
        signal(typingOff)
    }
}

// MARK: - Private implementation

private extension PubNubEventManager {
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
    /// - Parameter event: The inbound `MessageEvent`

    func handle(messageEvent event: MessageEvent) {
        guard
            let payload = event.payload.dictionaryOptional,
            let string = payload["type"] as? String,
            let type = EventType(rawValue: string)
        else {
            print("whoops")
            return
        }

        switch type {
        case .message:
            guard let message = try? event.payload.decode(Event<Message>.self) else { return }
            let payload = message.data
            onReceiveMessage?(payload)

        case .action:
            print("action")

        case .receipt:
            print("receipt")
        }

        print(event)
    }

    /// Handle inbound signal
    ///
    /// Examples of signals include typing indicators.
    ///
    /// - Parameter event: The inbound `MessageEvent`.

    func handle(signalEvent event: MessageEvent) {
        let signal: Signal
        do {
            signal = try event.payload.decode(Signal.self)
        } catch {
            print(error)
            return
        }

        guard signal.userId != userId else { return }
        
        switch signal.type {
        case .typingOff:
            onTypingOff?(signal.userId)

        case .typingOn:
            onTypingOn?(signal.userId)
        }

        print(event)
    }

}
