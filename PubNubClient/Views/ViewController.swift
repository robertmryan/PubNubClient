//
//  ViewController.swift
//  PubNubClient
//
//  Created by Robert Ryan on 8/26/20.
//  Copyright © 2020 Robert Ryan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var typingContainerView: UIStackView!
    @IBOutlet private weak var typingIndicatorView: UIActivityIndicatorView!

    private let chatController = ChatController()

    private var showObserver: NSObjectProtocol?
    private var hideObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }

    @IBAction func didTapSend(_ sender: Any) {
        guard let text = textField.text else { return }
        textField.text = nil
        textField.resignFirstResponder()

        // in our app, the server will be doing this, but this is a mock of what it will be doing
        chatController.send(text)
    }

    @IBAction func didTapInfo(_ sender: Any) {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let deviceToken = appDelegate.deviceToken
        else {
            presentMessage(title: "Channels", deviceToken: nil, message: "Couldn't get device token")
            return
        }

        chatController.info(for: deviceToken) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.presentMessage(title: "Channels", deviceToken: deviceToken, message: error.localizedDescription)

            case .success(let conversations):
                self?.presentMessage(title: "Channels", deviceToken: deviceToken, message: conversations)
            }
        }
    }
}

// MARK: - Private utility methods

private extension ViewController {

    func configure() {
        showTypingIndicator(false)
        addControllerCallbacks()
        addKeyboardObservers()
    }

    func addControllerCallbacks() {
        chatController.onNewMessage = { [weak self] row in
            self?.tableView?.insertRows(at: [IndexPath(row: row, section: 0)], with: .top)
        }

        chatController.onUpdateMessage = { [weak self] row in
            self?.tableView?.reloadRows(at: [IndexPath(row: row, section: 0)], with: .fade)
        }

        chatController.onDeleteMessage = { [weak self] row in
            self?.tableView?.deleteRows(at: [IndexPath(row: row, section: 0)], with: .top)
        }

        chatController.onIsTyping = { [weak self] in
            self?.showTypingIndicator(true)
        }

        chatController.onStopTyping = { [weak self] in
            self?.showTypingIndicator(false)
        }
    }

    func showTypingIndicator(_ isTyping: Bool) {
        typingContainerView.isHidden = !isTyping

        if isTyping, !typingIndicatorView.isAnimating {
            typingIndicatorView.startAnimating()
        } else if !isTyping, typingIndicatorView.isAnimating {
            typingIndicatorView.stopAnimating()
        }
    }

    func addKeyboardObservers() {
        showObserver = NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            guard
                let self = self,
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                let rect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            else {
                return
            }

            UIView.animate(withDuration: duration, delay: 0, options: .init(rawValue: curve), animations: {
                self.bottomConstraint.constant = -rect.height
                self.view.layoutIfNeeded()
            }, completion: nil)
        }

        hideObserver = NotificationCenter.default.addObserver(forName: UIApplication.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
            guard
                let self = self,
                let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            else {
                return
            }

            UIView.animate(withDuration: duration, delay: 0, options: .init(rawValue: curve), animations: {
                self.bottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func presentMessage(title: String? = nil, deviceToken: Data?, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let deviceToken = deviceToken {
                alert.addTextField { textfield in
                    textfield.text = deviceToken.hexEncodedString
                }
            }
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatController.messageCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell

        cell.delegate = self
        let text = chatController.text(for: indexPath.row)
        let isMine = chatController.isMine(for: indexPath.row)
        cell.configure(for: text, isMine: isMine)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row

        guard chatController.isMine(for: row) else { return }

        edit(row)
    }

    func edit(_ row: Int) {
        let alert = UIAlertController(title: nil, message: "Edit Message", preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            textField.text = self?.chatController.text(for: row)
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.chatController.update(row: row, with: alert.textFields?.first?.text ?? "")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let row = indexPath.row

        guard chatController.isMine(for: row) else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, result in
            let alert = UIAlertController(title: nil, message: "Delete this message?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.chatController.delete(row: row)
                result(true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in result(false) })
            self.present(alert, animated: true)
        }

        let connect = UIContextualAction(style: .normal, title: "Edit") { [weak self] action, view, result in
            self?.edit(row)
            result(true)
        }

        return UISwipeActionsConfiguration(actions: [connect, delete])
    }

}

// MARK: - MessageCellDelegate

extension ViewController: MessageCellDelegate {
    func cell(_ cell: UITableViewCell, didChangeText text: String) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        chatController.update(row: indexPath.row, with: text)
    }
}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        didTapSend(self)
        chatController.isTyping = false
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldText = textField.text ?? ""
        guard let range = Range(range, in: oldText) else { return true }

        let result = (textField.text ?? "").replacingCharacters(in: range, with: string)
        chatController.isTyping = !result.isEmpty

        return true
    }
}
