//
//  Typer.swift
//  PubNubClient
//
//  Created by Robert Ryan on 9/7/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import Foundation

typealias TyperExpirationHandler = (UserId) -> Void

class Typer {
    let userId: UserId
    var expirationHandler: TyperExpirationHandler?

    private var timestamp = Date()
    private weak var timer: Timer?

    init(userId: UserId, expirationHandler: @escaping TyperExpirationHandler) {
        self.userId = userId
        self.expirationHandler = expirationHandler
        updateTimer()
    }

    func renew() {
        updateTimer()
    }
}

private extension Typer {
    
    func updateTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            let savedHandler = self?.expirationHandler

            guard let self = self else { return }
            savedHandler?(self.userId)
            self.expirationHandler = nil
        }
    }
}
