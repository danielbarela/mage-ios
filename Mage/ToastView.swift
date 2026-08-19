//
//  ToastView.swift
//  Mage
//
//

import UIKit
import PureLayout

class ToastView: UIView {

    private lazy var label: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(message: String) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        label.text = message
        self.addSubview(label)
        label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
    }

    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height / 2
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowRadius = 4
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    static func show(message: String, in view: UIView, duration: TimeInterval = 3.0) {
        let toast = ToastView(message: message)
        view.addSubview(toast)
        toast.autoAlignAxis(.vertical, toSameAxisOf: view)
        toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32).isActive = true
        toast.autoMatch(.width, to: .width, of: view, withMultiplier: 1.0, relation: .lessThanOrEqual)
        toast.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }, completion: { _ in
                    toast.removeFromSuperview()
                })
            }
        })
    }
}
