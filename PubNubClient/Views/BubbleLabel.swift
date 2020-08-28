//
//  BubbleLabel.swift
//  ChatMVPKit
//
//  Created by Robert Ryan on 5/27/18.
//
// swiftlint:disable colon
// swiftlint:disable opening_brace
// swiftlint:disable function_body_length

import UIKit

/// Protocol used by internal `UILabel` subclass within the `BubbleLabel`.
///
/// Informs `BubbleLabel` of changes of frame (esp those which can result from
/// intrinsic constraints, which aren't captured by traditional techniques such
/// as `frame` KVO or `layoutSubviews`.

private protocol _BubbleLabelLabelDelegate: class {
    func bubbleLabel(_ bubbleLabel: _BubbleLabelLabel, didUpdateFrame: CGRect)
}

/// `UILabel` subclass that supports delegate of `_BubbleLabelLabelDelegate`.

private class _BubbleLabelLabel: UILabel {
    weak var bubbleDelegate: _BubbleLabelLabelDelegate?

    override func layoutSubviews() {
        super.layoutSubviews()

        bubbleDelegate?.bubbleLabel(self, didUpdateFrame: frame)
    }
}

// MARK: -

/// A wrapper around `UILabel` subcontrol that draws a chat-style bubble around the label,
/// insetting the `UILabel` appropriately.

@IBDesignable
public class BubbleLabel: UIView {

    // MARK: Inspectable properties

    /// Border color of bubble itself, not the `bounds` of the broader view.

    @IBInspectable public var borderColor: UIColor = .clear     { didSet { bubbleLayer.borderColor = borderColor.cgColor        } }

    /// Fill color of the bubble, itself, not the `background` color of the broader view

    @IBInspectable public var fillColor:   UIColor = UIColor(red: 0xf2 / 255, green: 0xf2 / 255, blue: 0xf5 / 255, alpha: 1) { didSet { bubbleLayer.fillColor = fillColor.cgColor            } }

    /// Color of the text in the `UILabel` subview

    @IBInspectable public var textColor:   UIColor = .black     { didSet { label.textColor = textColor                          } }

    /// Width of the path outlining the bubble.

    @IBInspectable public var lineWidth:   CGFloat = 0          { didSet { bubbleLayer.lineWidth = lineWidth; configureBubble() } }

    /// Boolean to indicate whether the bubble's callout is on the left or the right.
    ///
    /// I know it's strange to use boolean rather than enumeration, but you cannot yet
    /// use `@IBInspectable` enumerations (not even `@objc` ones).

    @IBInspectable public var isOnLeft: Bool = true {
        didSet {
            updateConstraints()
            configureBubble()
        }
    }

    @IBInspectable public var isSameAuthor: Bool = false {
        didSet {
            updateConstraints()
            configureBubble()
        }
    }
    
    /// Inset of the label within the bubble.

    @IBInspectable public var inset: CGFloat = 5 {
        didSet {
            updateConstraints()
            configureBubble()
        }
    }

    /// Rounding of bubble path.

    @IBInspectable public var rounding: CGFloat = 10 {
        didSet {
            updateConstraints()
            configureBubble()
        }
    }

    /// Rounding of bubble path.
    ///
    /// If zero, no callout rounding, but rather simple square corner.

    @IBInspectable public var calloutRounding: CGFloat = 15 {
        didSet {
            updateConstraints()
            configureBubble()
        }
    }

    // MARK: - UILabel properties

    /// Computed property for the `font` of the underlying label

    public var font: UIFont? {
        get { return label.font }
        set { label.font = newValue }
    }

    /// Computed property for the `text` of the underlying label.

    public var text: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    /// Computed property for attributedText of underlying label.

    public var attributedText: NSAttributedString? {
        get { return label.attributedText }
        set { label.attributedText = newValue }
    }

    // MARK: - Private properties

    /// The `UILabel` that actually shows the text.
    ///
    /// - Note: This is actually `_BubbleLabelLabel`, so that we can be notified of
    ///         changes resulting from intrinsic constraints, but other than that, it's
    ///         standard `UILabel`.

    private lazy var label: _BubbleLabelLabel = {
        let textLabel = _BubbleLabelLabel()
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.setContentHuggingPriority(.required, for: .horizontal)
        textLabel.textColor = textColor
        textLabel.adjustsFontSizeToFitWidth = false
        textLabel.bubbleDelegate = self
        return textLabel
    }()

    /// The `CAShapeLayer` of the path of the actual bubble part of this control.

    private lazy var bubbleLayer: CAShapeLayer = {
        let bubbleLayer = CAShapeLayer()
        bubbleLayer.fillColor   = fillColor.cgColor
        bubbleLayer.strokeColor = borderColor.cgColor
        bubbleLayer.lineJoin    = .round
        bubbleLayer.lineWidth   = 1
        return bubbleLayer
    }()

    /// Constraints used when the bubble is on the left side

    private var leftConstraints: [NSLayoutConstraint]!

    /// Array of constraints when the bubble is on the right side

    private var rightConstraints: [NSLayoutConstraint]!

    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!

    // MARK: - Initialization

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    // MARK: - Various `UIView` lifecycle methods

    // Some text so we can see it when rendered in IB

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        text = "This is a test"
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        configureBubble()
    }

}

// MARK: Configuration methods

extension BubbleLabel {

    /// Add constraints for the `UILabel` within this broader `BubbleLabel`.
    ///
    /// This defaults to left alignment of the bubble, which the caller

    private func addLabelConstraints() {
        leftConstraints = [
            label.leftAnchor.constraint(equalTo: leftAnchor),
            label.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor)
        ]
        NSLayoutConstraint.activate(leftConstraints)

        rightConstraints = [
            label.leftAnchor.constraint(greaterThanOrEqualTo: leftAnchor),
            label.rightAnchor.constraint(equalTo: rightAnchor)
        ]

        topConstraint = label.topAnchor.constraint(equalTo: topAnchor)
        bottomConstraint = label.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomConstraint.priority = UILayoutPriority.init(rawValue: 999)

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.75),
            topConstraint,
            bottomConstraint
        ])

        updateLabelConstraints()
    }

    // this should not need to be exposed; when you change the `inset` and `rounding` properties,
    // their respective `didSet` should call this, but it's not.

    public func updateLabelConstraints() {
        leftConstraints[0].constant = inset + calloutRounding
        leftConstraints[1].constant = -inset
        rightConstraints[0].constant = inset
        rightConstraints[1].constant = -(inset + calloutRounding)
        topConstraint.constant = inset
        bottomConstraint.constant = -inset
    }

    /// Called when the view is first instantiated

    private func configure() {
        layer.addSublayer(bubbleLayer)

        addSubview(label)
        addLabelConstraints()
    }

    /// This configures the `CAShapeLayer` of the actual bubble.
    ///
    /// Also updates left vs. right constraints

    private func configureBubble() {
        if isOnLeft {
            NSLayoutConstraint.deactivate(rightConstraints)
            NSLayoutConstraint.activate(leftConstraints)
        } else {
            NSLayoutConstraint.deactivate(leftConstraints)
            NSLayoutConstraint.activate(rightConstraints)
        }

        // frame of main bubble, not including callout handle

        let bubbleRect = label.frame.insetBy(dx: -inset + lineWidth / 2, dy: -inset + lineWidth / 2)

        bubbleLayer.path = buildPath(in: bubbleRect).cgPath
    }

    private func buildPath(in bubbleRect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        
        // top
        
        path.move(to: CGPoint(x: bubbleRect.minX + rounding, y: bubbleRect.minY))
        path.addLine(to: CGPoint(x: bubbleRect.maxX - rounding, y: bubbleRect.minY))
        
        // top right corner
        
        if !isOnLeft && isSameAuthor {
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY))
        } else {
            path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY + rounding),
                              controlPoint: CGPoint(x: bubbleRect.maxX, y: bubbleRect.minY))
        }
        
        // right
        
        if isOnLeft {
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - rounding))
        } else {
            path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY - calloutRounding))
        }
        
        // bottom right corner
        
        if isOnLeft {
            path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX - rounding, y: bubbleRect.maxY),
                              controlPoint: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY))
        } else {
            if calloutRounding <= 0 {
                path.addLine(to: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY))
            } else {
                path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX + calloutRounding, y: bubbleRect.maxY),
                                  controlPoint: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY))
                path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX - rounding + cos(.pi / 4) * rounding,
                                              y: bubbleRect.maxY - rounding + cos(.pi / 4) * rounding),
                                  controlPoint: CGPoint(x: bubbleRect.maxX, y: bubbleRect.maxY))
                path.addQuadCurve(to: CGPoint(x: bubbleRect.maxX - rounding, y: bubbleRect.maxY),
                                  controlPoint: CGPoint(x: bubbleRect.maxX - rounding + rounding * tan(.pi / 8), y: bubbleRect.maxY))
            }
        }
        
        // bottom
        
        path.addLine(to: CGPoint(x: bubbleRect.minX + rounding, y: bubbleRect.maxY))
        
        // bottom left corner
        
        if isOnLeft {
            if calloutRounding <= 0 {
                path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY))
            } else {
                path.addQuadCurve(to: CGPoint(x: bubbleRect.minX + rounding - cos(.pi / 4) * rounding,
                                              y: bubbleRect.maxY - rounding + cos(.pi / 4) * rounding),
                                  controlPoint: CGPoint(x: bubbleRect.minX + rounding - rounding * tan(.pi / 8), y: bubbleRect.maxY))
                path.addQuadCurve(to: CGPoint(x: bubbleRect.minX - calloutRounding, y: bubbleRect.maxY),
                                  controlPoint: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY))
                path.addQuadCurve(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY - calloutRounding),
                                  controlPoint: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY))
            }
        } else {
            path.addQuadCurve(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY - rounding),
                              controlPoint: CGPoint(x: bubbleRect.minX, y: bubbleRect.maxY))
        }
        
        // left
        
        path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY + rounding))
        
        // top left corner
        
        if isOnLeft && isSameAuthor {
            path.addLine(to: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY))
        } else {
            path.addQuadCurve(to: CGPoint(x: bubbleRect.minX + rounding, y: bubbleRect.minY),
                              controlPoint: CGPoint(x: bubbleRect.minX, y: bubbleRect.minY))
        }
        
        path.close()

        return path
    }
}

extension BubbleLabel: _BubbleLabelLabelDelegate {

    /// Delegate method used by label within broader `BubbleLabel` to indicate size changes.
    ///
    /// This is more reliable than observing `frame` changes via KVO or using `layoutSubviews`
    /// (because we have to detect changes triggered by intrinsic constraints of subview).
    ///
    /// - Parameters:
    ///   - bubbleLabel: The internal `_BubbleLabelLabel`.
    ///   - didUpdateFrame: The new `frame`.

    fileprivate func bubbleLabel(_ bubbleLabel: _BubbleLabelLabel, didUpdateFrame: CGRect) {
        configureBubble()
    }
}
