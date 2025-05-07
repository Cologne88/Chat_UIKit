//
//  LabelDelegate.swift
//  Nantes
//
//  Created by Chris Hansen on 5/8/19.
//  Copyright © 2019 Instacart. All rights reserved.
//

import UIKit

public protocol TUIAttributedLabelDelegate: AnyObject {
    func attributedLabel(_ label: TUIAttributedLabel, didSelectAddress addressComponents: [NSTextCheckingKey: String])
    func attributedLabel(_ label: TUIAttributedLabel, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval)
    func attributedLabel(_ label: TUIAttributedLabel, didSelectLink link: URL)
    func attributedLabel(_ label: TUIAttributedLabel, didSelectPhoneNumber phoneNumber: String)
    func attributedLabel(_ label: TUIAttributedLabel, didSelectTextCheckingResult result: NSTextCheckingResult)
    func attributedLabel(_ label: TUIAttributedLabel, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String])
}

public extension TUIAttributedLabelDelegate {
    func attributedLabel(_ label: TUIAttributedLabel, didSelectAddress addressComponents: [NSTextCheckingKey: String]) {}
    func attributedLabel(_ label: TUIAttributedLabel, didSelectDate date: Date, timeZone: TimeZone, duration: TimeInterval) {}
    func attributedLabel(_ label: TUIAttributedLabel, didSelectLink link: URL) {}
    func attributedLabel(_ label: TUIAttributedLabel, didSelectPhoneNumber phoneNumber: String) {}
    func attributedLabel(_ label: TUIAttributedLabel, didSelectTextCheckingResult result: NSTextCheckingResult) {}
    func attributedLabel(_ label: TUIAttributedLabel, didSelectTransitInfo transitInfo: [NSTextCheckingKey: String]) {}
}
