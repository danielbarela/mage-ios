//
//  ObservationListCard.swift
//  MAGE
//
//  Created by Daniel Barela on 1/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCCard;
import Persistence

@objc class ObservationListCardCell: UITableViewCell {
    
    private var constructed = false;
    private var didSetUpConstraints = false;
    private var observation: Observation?;
    private weak var actionsDelegate: ObservationActionsDelegate?;
    
    private lazy var card: MDCCard = {
        let card = MDCCard(forAutoLayout: ());
        card.enableRippleBehavior = true
        card.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
        return card;
    }()
    
    private lazy var compactView: ObservationCompactView = {
        let view = ObservationCompactView(cornerRadius: self.card.cornerRadius, includeAttachments: true);
        return view;
    }()
    
    @objc public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        construct()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.backgroundColor = scheme.colorScheme.backgroundColor;
        card.applyTheme(withScheme: scheme);
        compactView.applyTheme(withScheme: scheme);
    }
    
    @objc func tap(_ card: MDCCard) {
        if let observation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewObservation?(observation);
            }
        }
    }

    // The card's own ripple triggers automatically for taps it receives directly (see `tap(_:)`
    // above). A tap on the attachment carousel never reaches the card's touch handling at all,
    // so it needs to be played manually at the right point before navigating.
    private func rippleAndViewObservation(at pointInCard: CGPoint) {
        guard let observation = observation else { return }
        card.rippleView.beginRippleTouchDown(at: pointInCard, animated: true, completion: nil);
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.card.rippleView.beginRippleTouchUp(animated: true, completion: nil);
            self.actionsDelegate?.viewObservation?(observation);
        }
    }
    
    public func configure(observation: Observation, scheme: MDCContainerScheming?, actionsDelegate: ObservationActionsDelegate?, attachmentSelectionDelegate: AttachmentSelectionDelegate?) {
        self.observation = observation;
        card.accessibilityLabel = "observation card \(observation.objectID.uriRepresentation().absoluteString)"
        self.actionsDelegate = actionsDelegate;
        
        compactView.configure(observation: observation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);
        
        applyTheme(withScheme: scheme);
    }
    
    override func prepareForReuse() {
        compactView.prepareForReuse()
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            card.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8));
            compactView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func construct() {
        if (!constructed) {
            self.contentView.addSubview(card);
            card.addSubview(compactView);
            compactView.onAttachmentAreaTapped = { [weak self] pointInCompactView in
                guard let self = self else { return }
                self.rippleAndViewObservation(at: self.card.convert(pointInCompactView, from: self.compactView));
            }
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
    
}
