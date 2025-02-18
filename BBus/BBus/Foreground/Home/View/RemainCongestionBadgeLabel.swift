//
//  RemainCongestionBadgeLabel.swift
//  BBus
//
//  Created by 김태훈 on 2021/11/07.
//

import UIKit

final class RemainCongestionBadgeLabel: UILabel {

    let padding = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)

    override func drawText(in rect: CGRect) {
        let paddingRect = rect.inset(by: padding)
        super.drawText(in: paddingRect)
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += padding.top + padding.bottom
        contentSize.width += padding.left + padding.right
        return contentSize
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureUI()
    }

    convenience init() {
        self.init(frame: CGRect())
    }

    private func configureUI() {
        self.layer.borderColor = BBusColor.bbusLightGray?.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = 3
        self.font = UIFont.systemFont(ofSize: 11)
        self.textColor = BBusColor.bbusGray
        self.textAlignment = .center
    }

    func configure(remaining: String?, congestion: String?) {
        if remaining == nil && congestion == nil {
            self.isHidden = true
        }
        else {
            let remaining = remaining ?? ""
            let congestion = congestion ?? ""
            let description = remaining + " " + congestion
            let redRange = (description as NSString).range(of: congestion)
            let attributedString = NSMutableAttributedString(string: description)
            attributedString.addAttribute(.foregroundColor,
                                          value: BBusColor.bbusCongestionRed as Any,
                                          range: redRange)
            self.attributedText = attributedString
            self.isHidden = false
        }
        self.sizeToFit()
    }
}
