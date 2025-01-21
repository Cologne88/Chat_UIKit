// TUIContactActionCell_Minimalist.swift
// TXIMSDK_TUIKit_iOS

import UIKit
import TIMCommon

class TUIContactActionCell_Minimalist: TUICommonTableViewCell {

    let titleLabel = UILabel()
    let unRead = TUIUnReadView()
    var actionData: TUIContactActionCellData_Minimalist?
    var line: UIView?
    var readNumObservation: NSKeyValueObservation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.frame = .zero
        contentView.addSubview(titleLabel)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        titleLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        
        contentView.addSubview(unRead)
        
        line = UIView()
        contentView.addSubview(line!)
        line!.backgroundColor = UIColor.white
        backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        contentView.backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        selectionStyle = .none
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        readNumObservation = nil
    }

    override func fill(with actionData: TUICommonCellData) {
        guard let actionData = actionData as? TUIContactActionCellData_Minimalist else { return }

        super.fill(with: actionData)
        self.actionData = actionData
        titleLabel.text = actionData.title

        readNumObservation = self.actionData?.observe(\.readNum, options: [.new, .initial]) { [weak self] (_, change) in
            guard let self = self, let newNum = change.newValue else { return }
            self.unRead.setNum(newNum)
        }
        
        line?.isHidden = !(actionData.needBottomLine)
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        
        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(contentView.snp.leading).offset(TUISwift.kScale390(16))
            make.width.equalTo(titleLabel.frame.size.width)
            make.height.equalTo(titleLabel.frame.size.height)
        }
        
        unRead.unReadLabel.sizeToFit()
        unRead.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.trailing.equalTo(contentView.snp.trailing).offset(-5)
            make.width.height.equalTo(TUISwift.kScale375(20))
        }
        
        unRead.unReadLabel.snp.remakeConstraints { make in
            make.center.equalTo(unRead)
            make.size.equalTo(unRead.unReadLabel)
        }
        
        unRead.layer.cornerRadius = TUISwift.kScale375(10)
        unRead.layer.masksToBounds = true
        
        line?.snp.remakeConstraints { make in
            make.bottom.equalTo(contentView.snp.bottom).offset(-1)
            make.width.equalTo(contentView)
            make.height.equalTo(1)
            make.leading.equalTo(contentView.snp.leading)
        }
    }
}
