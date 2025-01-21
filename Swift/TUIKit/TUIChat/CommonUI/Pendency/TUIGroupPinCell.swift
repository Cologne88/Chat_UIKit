import ImSDK_Plus
import TIMCommon
import UIKit

class TUIGroupPinCellView: UIView {
    var onClickRemove: ((V2TIMMessage) -> Void)?
    var onClickCellView: ((V2TIMMessage) -> Void)?
    var cellData: TUIMessageCellData?
    var isFirstPage: Bool = false

    private lazy var leftIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_group_pin_left_color", defaultColor: "#D9D9D9")
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.tuiChatDynamicColor("chat_pop_group_pin_title_color", defaultColor: "#141516")
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()

    private lazy var content: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.tuiChatDynamicColor("chat_pop_group_pin_subtitle_color", defaultColor: "#000000").withAlphaComponent(0.6)
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()

    lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: TUISwift.tuiChatImagePath("chat_group_del_icon")), for: .normal)
        button.addTarget(self, action: #selector(removeCurrentGroupPin), for: .touchUpInside)
        return button
    }()

    private lazy var multiAnimationView: UIView = {
        let view = UIView(frame: .zero)
        view.alpha = 0
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        view.addGestureRecognizer(tap)

        let arrowBackgroundView = UIView(frame: .zero)
        arrowBackgroundView.backgroundColor = .clear
        arrowBackgroundView.layer.cornerRadius = 5
        view.addSubview(arrowBackgroundView)

        let arrow = UIImageView(frame: .zero)
        arrow.image = TUISwift.tuiChatBundleThemeImage("chat_pop_group_pin_down_arrow_img", defaultImage: "chat_down_arrow_icon")
        arrowBackgroundView.addSubview(arrow)

        let bottomLine = UIView()
        bottomLine.backgroundColor = .gray
        arrowBackgroundView.addSubview(bottomLine)

        arrowBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false
        bottomLine.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            arrowBackgroundView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowBackgroundView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            arrowBackgroundView.widthAnchor.constraint(equalToConstant: 20),
            arrowBackgroundView.heightAnchor.constraint(equalToConstant: 20),

            arrow.centerXAnchor.constraint(equalTo: arrowBackgroundView.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: arrowBackgroundView.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 20),
            arrow.heightAnchor.constraint(equalToConstant: 20),

            bottomLine.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
            bottomLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fill(withData cellData: TUIMessageCellData) {
        self.cellData = cellData
        titleLabel.text = TUIMessageDataProvider.getShowName(cellData.innerMessage)
        content.text = TUIMessageDataProvider.getDisplayString(cellData.innerMessage)

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        leftIcon.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.centerY.equalTo(self)
            make.width.equalTo(6)
            make.top.bottom.equalTo(self)
        }

        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(leftIcon.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(removeButton.snp.leading)
            make.width.equalTo(titleLabel.frame.size.width)
            make.height.equalTo(titleLabel.frame.size.height)
            make.top.equalTo(self).offset(9)
        }

        content.sizeToFit()
        content.snp.remakeConstraints { make in
            make.leading.equalTo(leftIcon.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(removeButton.snp.leading)
            make.width.equalTo(content.frame.size.width)
            make.height.equalTo(content.frame.size.height)
            make.bottom.equalTo(self).offset(-9)
        }

        removeButton.snp.remakeConstraints { make in
            make.trailing.equalTo(-10)
            make.centerY.equalTo(self)
            make.width.height.equalTo(30)
        }

        removeButton.imageView?.snp.remakeConstraints { make in
            make.center.equalTo(removeButton)
            make.width.height.equalTo(14)
        }

        multiAnimationView.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(20)
            make.top.equalTo(self.snp.bottom)
        }

        bottomLine.snp.remakeConstraints { make in
            make.width.equalTo(self)
            make.height.equalTo(0.5)
            make.centerX.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let newP = convert(point, to: multiAnimationView)
        if multiAnimationView.point(inside: newP, with: event) {
            return multiAnimationView
        }
        return super.hitTest(point, with: event)
    }

    private func setupView() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_group_pin_back_color", defaultColor: "#F9F9F9")
        addSubview(leftIcon)
        addSubview(titleLabel)
        addSubview(content)
        addSubview(removeButton)
        addSubview(multiAnimationView)
        addSubview(bottomLine)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        guard let cellData = cellData else { return }
        onClickCellView?(cellData.innerMessage)
    }

    @objc private func removeCurrentGroupPin() {
        if let message = cellData?.innerMessage {
            onClickRemove?(message)
        }
    }

    func hideMultiAnimation() {
        multiAnimationView.backgroundColor = UIColor.white.withAlphaComponent(0)
        multiAnimationView.alpha = 0
        bottomLine.alpha = 1
    }

    func showMultiAnimation() {
        multiAnimationView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_group_pin_back_color", defaultColor: "#F9F9F9")
        multiAnimationView.alpha = 1
        bottomLine.alpha = 0
    }
}

class TUIGroupPinCell: UITableViewCell {
    lazy var cellView: TUIGroupPinCellView = {
        let view = TUIGroupPinCellView()
        view.isFirstPage = false
        return view
    }()

    private lazy var seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_group_pin_line_color", defaultColor: "#DDDDDD")
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(cellView)
        contentView.addSubview(seperatorView)
    }

    func fill(withData cellData: TUIMessageCellData?) {
        guard let cellData = cellData else { return }
        cellView.fill(withData: cellData)
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        cellView.snp.remakeConstraints { make in
            make.leading.trailing.top.bottom.equalTo(self)
        }

        seperatorView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(6)
            make.trailing.bottom.equalTo(contentView)
            make.height.equalTo(0.5)
        }
    }
}
