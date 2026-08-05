//
//  ObservationCompactView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/28/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Persistence

class ObservationCompactView: UIView {
    private var constructed = false;
    private var didSetUpConstraints = false;
    private var observation: Observation?;
    private weak var actionsDelegate: ObservationActionsDelegate?;
    private var scheme: MDCContainerScheming?;
    private var cornerRadius:CGFloat = 0.0;
    private var includeAttachments: Bool = false;
    private var totalAttachmentCount = 0;

    // Set by the containing cell/view so it can play its own tap feedback (e.g. a card's ripple)
    // at the right location before navigating - falls back to navigating directly if unset.
    var onAttachmentAreaTapped: ((CGPoint) -> Void)?

    private lazy var stackView: PassThroughStackView = {
        let stackView = PassThroughStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()

    public lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: self.cornerRadius);
        return importantView;
    }()

    private lazy var observationSummaryView: ObservationSummaryView = {
        let summary = ObservationSummaryView();
        summary.isUserInteractionEnabled = false;
        return summary;
    }()

    private lazy var observationActionsView: ObservationListActionsView = {
        let actions = ObservationListActionsView(observation: self.observation, observationActionsDelegate: actionsDelegate, scheme: nil);
        return actions;
    }();

    // Introducing label for failed attachments
    private lazy var failedAttachmentLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        return label
    }()

    // Adding failed label to the observation badge
    private lazy var failedAttachmentBadge: UIView = {
        let badge = UIView.newAutoLayout()
        badge.addSubview(failedAttachmentLabel)
        failedAttachmentLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 2, left: 8, bottom:2, right: 8))
        badge.clipsToBounds = true
        return badge
    }()

    // Adding number of attachments
    private lazy var attachmentCountLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        return label
    }()

    private lazy var attachmentCountBadge: UIView = {
        let badge = UIView.newAutoLayout()
        badge.addSubview(attachmentCountLabel)
        attachmentCountLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        return badge
    }()

    private lazy var attachmentSlideshow: AttachmentSlideShow = {
        let actions = AttachmentSlideShow();
        actions.isUserInteractionEnabled = true;
        return actions;
    }();

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self { return nil }
        return result
    }

    init(cornerRadius: CGFloat, includeAttachments: Bool = false, actionsDelegate: ObservationActionsDelegate? = nil, scheme: MDCContainerScheming? = nil) {
        super.init(frame: CGRect.zero);
        translatesAutoresizingMaskIntoConstraints = false;
        self.cornerRadius = cornerRadius;
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        self.includeAttachments = includeAttachments;
        construct()
    }

    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        importantView.applyTheme(withScheme: scheme);
        observationSummaryView.applyTheme(withScheme: scheme);
        observationActionsView.applyTheme(withScheme: scheme);
        attachmentSlideshow.applyTheme(withScheme: scheme);

        let errorScheme = MAGEErrorScheme.scheme()
        failedAttachmentBadge.backgroundColor = errorScheme.colorScheme.primaryColor.withAlphaComponent(0.12)
        failedAttachmentLabel.textColor = errorScheme.colorScheme.primaryColor

        // Neutral color - non-error
        attachmentCountBadge.backgroundColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.85)
        attachmentCountLabel.textColor = .white
    }

    public func configure(observation: Observation, scheme: MDCContainerScheming?, actionsDelegate: ObservationActionsDelegate?, attachmentSelectionDelegate: AttachmentSelectionDelegate?) {
        self.observation = observation;
        self.actionsDelegate = actionsDelegate;
        if (observation.isImportant) {
            importantView.populate(observation: observation);
            importantView.isHidden = false;
        } else {
            importantView.isHidden = true;
        }
        observationSummaryView.populate(observation: observation);
        observationActionsView.populate(observation: observation, delegate: actionsDelegate);
        attachmentSlideshow.applyTheme(withScheme: scheme)

        let failedCount = failedAttachmentCount(observation: observation)
        let hasRealAttachment = includeAttachments && (observation.attachments?.filter { $0.url != nil }.count ?? 0) > 0
        let hasAnyAttachment = includeAttachments && (observation.attachments?.count ?? 0) > 0
        if hasAnyAttachment {
            // No delegate here on purpose - tapping an attachment thumbnail in this list/card
            // context should open the observation, same as tapping anywhere else on the card,
            // not jump straight to the attachment viewer.
            attachmentSlideshow.populate(observation: observation, attachmentSelectionDelegate: nil);
        }
        // Keep the slideshow's frame alive (even with nothing to populate) whenever there's a
        // failed badge to show, since the badge overlays on top of it and relies on its geometry.
        attachmentSlideshow.isHidden = !(hasRealAttachment || failedCount > 0 || (observation.attachments?.count ?? 0) > 1);

        applyTheme(withScheme: scheme);

        if failedCount > 0 {
            failedAttachmentLabel.text = failedCount > 1 ? "Attachments Failed - \(failedCount)" : "Attachment Failed"
            failedAttachmentBadge.isHidden = false
        } else {
            failedAttachmentBadge.isHidden = true
        }

        totalAttachmentCount = observation.attachments?.count ?? 0
        if totalAttachmentCount > 1 {
            attachmentCountLabel.text = "1 of \(totalAttachmentCount)"
            attachmentCountBadge.isHidden = false
        } else {
            attachmentCountBadge.isHidden = true
        }
    }

    func prepareForReuse() {
        attachmentSlideshow.clear()
    }

    // Counter function for failed attachments
    func failedAttachmentCount(observation: Observation) -> Int {
        return observation.attachments?.filter { $0.processingStatus == "rejected" || $0.processingStatus == "error" }.count ?? 0
    }

    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges();
            failedAttachmentBadge.layer.cornerRadius = 12
            failedAttachmentBadge.autoPinEdge(.top, to: .top, of: attachmentSlideshow, withOffset: 8)
            failedAttachmentBadge.autoPinEdge(.leading, to: .leading, of: attachmentSlideshow, withOffset: 8)
            attachmentCountBadge.layer.cornerRadius = 12
            attachmentCountBadge.autoPinEdge(.bottom, to: .bottom, of: attachmentSlideshow, withOffset: -8)
            attachmentCountBadge.autoPinEdge(.trailing, to: .trailing, of: attachmentSlideshow, withOffset: -8)
            attachmentCountBadge.layer.shadowColor = UIColor.black.cgColor
            attachmentCountBadge.layer.shadowOpacity = 0.25
            attachmentCountBadge.layer.shadowRadius = 4
            attachmentCountBadge.layer.shadowOffset = CGSize(width: 0, height: 2)
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }

    func construct() {
        if (!constructed) {
            self.addSubview(stackView)
            self.stackView.addArrangedSubview(importantView);
            self.stackView.addArrangedSubview(observationSummaryView);
            self.stackView.addArrangedSubview(attachmentSlideshow);
            self.attachmentSlideshow.addSubview(failedAttachmentBadge);
            self.attachmentSlideshow.addSubview(attachmentCountBadge);
            self.stackView.addArrangedSubview(observationActionsView);
            // Explicit gesture rather than relying on the tap falling through the view
            // hierarchy to the card - AttachmentSlideShow and its internal scroll/stack views
            // don't participate in this view's pass-through hitTest overrides, so a tap here
            // would otherwise dead-end instead of reaching the card's own tap handler.
            let attachmentSlideshowTap = UITapGestureRecognizer(target: self, action: #selector(attachmentSlideshowTapped(_:)));
            self.attachmentSlideshow.addGestureRecognizer(attachmentSlideshowTap);
            self.attachmentSlideshow.onPageChanged = { [weak self] page in
                guard let self = self else { return }
                self.attachmentCountLabel.text = "\(page + 1) of \(self.totalAttachmentCount)"
            }
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }

    @objc func attachmentSlideshowTapped(_ gesture: UITapGestureRecognizer) {
        guard let observation = observation else { return }
        if let onAttachmentAreaTapped = onAttachmentAreaTapped {
            onAttachmentAreaTapped(gesture.location(in: self));
        } else {
            actionsDelegate?.viewObservation?(observation);
        }
    }
}
