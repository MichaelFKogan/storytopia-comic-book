import SwiftUI
import UIKit

private extension NSAttributedString.Key {
    static let notebookBold = NSAttributedString.Key("StorytopiaNotebookBold")
    static let notebookItalic = NSAttributedString.Key("StorytopiaNotebookItalic")
    static let notebookTextStyle = NSAttributedString.Key("StorytopiaNotebookTextStyle")
}

enum NotebookTextFormattingCommand: Equatable {
    case bold
    case italic
    case underline
    case strikethrough
    case bulletList
    case textStyle(NotebookTextRunStyle)
}

enum NotebookTextRunStyle: String, Codable, Equatable, CaseIterable {
    case body
    case heading1
    case heading2
    case heading3
    case heading4
    case heading5
    case heading6

    var fontScale: CGFloat {
        switch self {
        case .body:
            1
        case .heading1:
            1.86
        case .heading2:
            1.66
        case .heading3:
            1.48
        case .heading4:
            1.32
        case .heading5:
            1.18
        case .heading6:
            1.08
        }
    }

    var usesHeadingWeight: Bool {
        self != .body
    }
}

struct NotebookTextFormattingRun: Codable, Equatable {
    var location: Int
    var length: Int
    var isBold: Bool
    var isItalic: Bool
    var isUnderlined: Bool
    var isStrikethrough: Bool
    var textStyleRawValue: String?

    init(
        location: Int,
        length: Int,
        isBold: Bool,
        isItalic: Bool,
        isUnderlined: Bool,
        isStrikethrough: Bool,
        textStyleRawValue: String? = nil
    ) {
        self.location = location
        self.length = length
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
        self.isStrikethrough = isStrikethrough
        self.textStyleRawValue = textStyleRawValue
    }
}

struct NotebookRichTextDocument: Codable, Equatable {
    var text: String
    var formattingRuns: [NotebookTextFormattingRun]

    init(text: String, formattingRuns: [NotebookTextFormattingRun] = []) {
        self.text = text
        self.formattingRuns = formattingRuns
    }

    init(attributedString: NSAttributedString) {
        text = attributedString.string
        var runs: [NotebookTextFormattingRun] = []

        attributedString.enumerateAttributes(
            in: NSRange(location: 0, length: attributedString.length)
        ) { attributes, range, _ in
            let font = attributes[.font] as? UIFont
            let traits = font?.fontDescriptor.symbolicTraits ?? []
            let isBold = (attributes[.notebookBold] as? Bool) ?? false
            let isItalic = (attributes[.notebookItalic] as? Bool) ?? traits.contains(.traitItalic)
            let isUnderlined = (attributes[.underlineStyle] as? Int ?? 0) != 0
            let isStrikethrough = (attributes[.strikethroughStyle] as? Int ?? 0) != 0
            let textStyleRawValue = attributes[.notebookTextStyle] as? String
            let run = NotebookTextFormattingRun(
                location: range.location,
                length: range.length,
                isBold: isBold,
                isItalic: isItalic,
                isUnderlined: isUnderlined,
                isStrikethrough: isStrikethrough,
                textStyleRawValue: textStyleRawValue
            )

            if run.hasFormatting {
                runs.append(run)
            }
        }

        formattingRuns = runs
    }

    func normalized(for plainText: String) -> NotebookRichTextDocument {
        text == plainText ? self : NotebookRichTextDocument(text: plainText)
    }

    func trimmingCharacters(in characterSet: CharacterSet) -> NotebookRichTextDocument {
        let nsText = text as NSString
        var lowerBound = 0
        var upperBound = nsText.length

        while lowerBound < upperBound,
              let scalar = UnicodeScalar(Int(nsText.character(at: lowerBound))),
              characterSet.contains(scalar) {
            lowerBound += 1
        }

        while upperBound > lowerBound,
              let scalar = UnicodeScalar(Int(nsText.character(at: upperBound - 1))),
              characterSet.contains(scalar) {
            upperBound -= 1
        }

        let keptRange = NSRange(location: lowerBound, length: upperBound - lowerBound)
        let trimmedText = nsText.substring(with: keptRange)
        let trimmedRuns = formattingRuns.compactMap { run -> NotebookTextFormattingRun? in
            let runRange = NSRange(location: run.location, length: run.length)
            let intersection = NSIntersectionRange(runRange, keptRange)
            guard intersection.length > 0 else {
                return nil
            }

            return NotebookTextFormattingRun(
                location: intersection.location - lowerBound,
                length: intersection.length,
                isBold: run.isBold,
                isItalic: run.isItalic,
                isUnderlined: run.isUnderlined,
                isStrikethrough: run.isStrikethrough,
                textStyleRawValue: run.textStyleRawValue
            )
        }

        return NotebookRichTextDocument(text: trimmedText, formattingRuns: trimmedRuns)
    }

    func attributedString(
        textStyle: NotebookTextStyle,
        usesTexturedPaperEffect: Bool = false
    ) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: NotebookMetrics.typingAttributes(
                for: textStyle,
                usesTexturedPaperEffect: usesTexturedPaperEffect
            )
        )
        let fullRange = NSRange(location: 0, length: attributedText.length)

        for run in formattingRuns {
            let range = NSRange(location: run.location, length: run.length)
            let safeRange = NSIntersectionRange(range, fullRange)
            guard safeRange.length > 0 else {
                continue
            }

            if let runStyle = run.textRunStyle {
                attributedText.setNotebookTextRunStyle(
                    runStyle,
                    textStyle: textStyle,
                    in: safeRange
                )
            }

            if run.isBold {
                attributedText.setNotebookFontStyle(
                    isBold: true,
                    isItalic: run.isItalic,
                    textStyle: textStyle,
                    in: safeRange
                )
            } else if run.isItalic {
                attributedText.setNotebookFontStyle(
                    isBold: false,
                    isItalic: true,
                    textStyle: textStyle,
                    in: safeRange
                )
            }

            if run.isUnderlined {
                attributedText.addAttribute(
                    .underlineStyle,
                    value: NSUnderlineStyle.single.rawValue,
                    range: safeRange
                )
            }

            if run.isStrikethrough {
                attributedText.addAttribute(
                    .strikethroughStyle,
                    value: NSUnderlineStyle.single.rawValue,
                    range: safeRange
                )
            }
        }

        return attributedText
    }
}

private extension NotebookTextFormattingRun {
    var textRunStyle: NotebookTextRunStyle? {
        textStyleRawValue.flatMap(NotebookTextRunStyle.init(rawValue:))
    }

    var hasFormatting: Bool {
        isBold || isItalic || isUnderlined || isStrikethrough || textStyleRawValue != nil
    }
}

struct NotebookTextFormattingRequest: Equatable {
    let id: Int
    let command: NotebookTextFormattingCommand
}

enum NotebookMetrics {
    static let ruleSpacing: CGFloat = 35
    static let bodyFontSize: CGFloat = 16
    static let titleFontSize: CGFloat = 20
    static let marginLeading: CGFloat = 54
    static let textLeadingInset: CGFloat = 5

    static var titleFont: UIFont {
        UIFont.systemFont(ofSize: titleFontSize, weight: .bold)
    }

    static var bodyFont: UIFont {
        UIFont.systemFont(ofSize: bodyFontSize, weight: .medium)
    }

    static var ruleUIColor: UIColor {
        UIColor(red: 0.45, green: 0.58, blue: 0.78, alpha: 0.24)
    }

    static var bodyTextUIColor: UIColor {
        UIColor(red: 0.08, green: 0.07, blue: 0.22, alpha: 0.78)
    }

    static var typingParagraphStyle: NSParagraphStyle {
        typingParagraphStyle(alignment: .natural)
    }

    static func typingParagraphStyle(alignment: NSTextAlignment) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = ruleSpacing
        style.maximumLineHeight = ruleSpacing
        style.lineSpacing = 0
        style.paragraphSpacing = 0
        style.lineBreakMode = .byWordWrapping
        style.alignment = alignment
        return style
    }

    static var typingAttributes: [NSAttributedString.Key: Any] {
        typingAttributes(for: .default)
    }

    static func titleFont(for style: NotebookTextStyle) -> Font {
        if let customFontName = style.customFontName {
            return VariableFont.font(
                name: style.customFontBoldName ?? customFontName,
                size: style.titleFontSize,
                weight: style.customFontBoldWeight,
                usesWeightAxis: style.customFontUsesVariableWeight,
                wghtOverride: style.customFontBoldWght ?? style.customFontWght.map { max($0, 700) }
            )
        }

        return .system(size: style.titleFontSize, weight: .bold, design: style.swiftUIDesign)
    }

    static func bodyPlaceholderFont(for style: NotebookTextStyle) -> Font {
        if let customFontName = style.customFontName {
            return VariableFont.font(
                name: customFontName,
                size: style.scaledBodyFontSize,
                weight: style.customFontWeight,
                usesWeightAxis: style.customFontUsesVariableWeight,
                wghtOverride: style.customFontWght
            )
        }

        return .system(size: style.bodyFontSize, weight: .regular, design: style.swiftUIDesign)
    }

    static func uiBodyFont(for style: NotebookTextStyle) -> UIFont {
        uiBodyFont(for: style, isBold: false, isItalic: false)
    }

    static func uiBodyFont(
        for style: NotebookTextStyle,
        isBold: Bool,
        isItalic: Bool
    ) -> UIFont {
        if let customFontName = style.customFontName,
           let customFont = VariableFont.uiFont(
               name: isBold ? style.customFontBoldName ?? customFontName : customFontName,
               size: style.scaledBodyFontSize,
               weight: isBold ? style.customFontBoldWeight : style.customFontWeight,
               usesWeightAxis: style.customFontUsesVariableWeight,
               wghtOverride: isBold ? style.customFontBoldWght : style.customFontWght
           ) {
            return resolvedItalicFont(customFont, isItalic: isItalic)
        }

        let baseFont = UIFont.systemFont(
            ofSize: style.bodyFontSize,
            weight: isBold ? .bold : .regular
        )
        guard var descriptor = baseFont.fontDescriptor.withDesign(style.uiKitDesign) else {
            return baseFont
        }

        var traits = descriptor.symbolicTraits
        if isBold {
            traits.insert(.traitBold)
        } else {
            traits.remove(.traitBold)
        }

        if isItalic {
            traits.insert(.traitItalic)
        } else {
            traits.remove(.traitItalic)
        }

        if let styledDescriptor = descriptor.withSymbolicTraits(traits) {
            descriptor = styledDescriptor
        }

        return UIFont(descriptor: descriptor, size: style.bodyFontSize)
    }

    static func typingAttributes(
        for style: NotebookTextStyle,
        usesTexturedPaperEffect: Bool = false,
        isBold: Bool = false,
        isItalic: Bool = false
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: uiBodyFont(for: style, isBold: isBold, isItalic: isItalic),
            .foregroundColor: usesTexturedPaperEffect ? UIColor.clear : style.uiColor,
            .paragraphStyle: typingParagraphStyle
        ]

        if isBold {
            attributes[.notebookBold] = true

            if shouldUseSyntheticBold(for: style) {
                attributes[.strokeWidth] = -2
            }
        }

        if isItalic {
            attributes[.notebookItalic] = true
        }

        return attributes
    }

    static func shouldUseSyntheticBold(for style: NotebookTextStyle) -> Bool {
        style.customFontName != nil &&
            !style.customFontUsesVariableWeight &&
            style.customFontBoldName == nil &&
            style.customFontAllowsSyntheticBold
    }

    private static func resolvedItalicFont(_ font: UIFont, isItalic: Bool) -> UIFont {
        guard isItalic else {
            return font
        }

        var traits = font.fontDescriptor.symbolicTraits
        traits.insert(.traitItalic)

        guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else {
            return font
        }

        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    /// Vertical inset so placeholder text matches the text view's first-line position.
    static var firstLineTextTopInset: CGFloat {
        max(0, (ruleSpacing - bodyFont.lineHeight) / 2 + 8)
    }

    static var bodyCaretHeight: CGFloat {
        min(ruleSpacing, titleFont.lineHeight + 4)
    }

    static var bodyCaretYOffset: CGFloat {
        (bodyCaretHeight - bodyFont.lineHeight) / 2 + 6
    }

    static var titleLineTextTopInset: CGFloat {
        max(0, (ruleSpacing - titleFont.lineHeight) / 2)
    }

    static let contentTopPadding: CGFloat = 14
    static let contentBottomPadding: CGFloat = 18

    static var firstNotebookRuleY: CGFloat {
        contentTopPadding + ruleSpacing
    }

    static func bodyAreaMinHeight(forPageHeight pageHeight: CGFloat) -> CGFloat {
        let availableHeight = pageHeight - contentTopPadding - contentBottomPadding - ruleSpacing
        return max(ruleSpacing * 3, availableHeight)
    }

    static var ruleColor: Color {
        Color(red: 0.45, green: 0.58, blue: 0.78).opacity(0.24)
    }

    static var minimumBodyHeight: CGFloat {
        ruleSpacing * 8
    }
}

struct NotebookTextStyle: Equatable {
    var swiftUIDesign: Font.Design = .serif
    var uiKitDesign: UIFontDescriptor.SystemDesign = .serif
    var customFontName: String?
    var customFontBoldName: String?
    var customFontWeight: Font.Weight = .regular
    var customFontWght: CGFloat?
    var customFontBoldWeight: Font.Weight = .bold
    var customFontBoldWght: CGFloat?
    var customFontUsesVariableWeight: Bool = false
    var customFontAllowsSyntheticBold: Bool = true
    var customFontSizeScale: CGFloat = 1
    var bodyFontSize: CGFloat = NotebookMetrics.bodyFontSize
    var color: Color = Color(NotebookMetrics.bodyTextUIColor)
    var uiColor: UIColor = NotebookMetrics.bodyTextUIColor

    static let `default` = NotebookTextStyle()

    var scaledBodyFontSize: CGFloat {
        bodyFontSize * customFontSizeScale
    }

    var titleFontSize: CGFloat {
        scaledBodyFontSize + 4
    }
}

enum TexturedPaperTextEffect {
    static func shouldMultiplyBlend(_ color: UIColor) -> Bool {
        relativeLuminance(of: color) < 0.55
    }

    static func inkShadow(for color: UIColor) -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 0, height: -0.45)
        shadow.shadowBlurRadius = 0.45
        shadow.shadowColor = UIColor.black.withAlphaComponent(shouldMultiplyBlend(color) ? 0.16 : 0.1)
        return shadow
    }

    static func titleShadowColor(for color: UIColor) -> Color {
        Color.black.opacity(shouldMultiplyBlend(color) ? 0.16 : 0.1)
    }

    static func bodyShadowColor(for color: UIColor) -> UIColor {
        UIColor.black.withAlphaComponent(shouldMultiplyBlend(color) ? 0.28 : 0.18)
    }

    static func bodyHighlightColor(for color: UIColor) -> UIColor {
        UIColor.white.withAlphaComponent(shouldMultiplyBlend(color) ? 0.24 : 0.16)
    }

    private static func relativeLuminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0
        }

        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    private static func linearized(_ component: CGFloat) -> CGFloat {
        component <= 0.03928
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }
}

final class LinedTextView: UITextView {
    private static let bulletPrefix = "• "

    var ruleSpacing: CGFloat = NotebookMetrics.ruleSpacing
    var notebookTextStyle: NotebookTextStyle = .default {
        didSet {
            applyTextStyle()
        }
    }
    var textLeadingInset = NotebookMetrics.textLeadingInset {
        didSet {
            applyTextContainerInset()
        }
    }
    var drawsRuledLines = true
    var scrollsInternally = true {
        didSet {
            applyScrollBehavior()
        }
    }
    var usesTexturedPaperEffect = false {
        didSet {
            applyTextStyle()
        }
    }
    private var isTypingBold = false
    private var isTypingItalic = false
    private var storedRichTextDocument = NotebookRichTextDocument(text: "")

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configureNotebookAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureNotebookAppearance()
    }

    private func configureNotebookAppearance() {
        backgroundColor = .clear
        applyTextContainerInset()
        textContainer.lineFragmentPadding = 0
        applyTextStyle()
        returnKeyType = .default
        showsHorizontalScrollIndicator = false
        keyboardDismissMode = .interactive
        applyScrollBehavior()
    }

    private func applyTextContainerInset() {
        textContainerInset = UIEdgeInsets(
            top: 0,
            left: textLeadingInset,
            bottom: 0,
            right: 0
        )
    }

    private func applyTextStyle() {
        let document = storedRichTextDocument.normalized(for: text ?? "")
        storedRichTextDocument = document
        let selectedRange = selectedRange
        font = NotebookMetrics.uiBodyFont(for: notebookTextStyle)
        textColor = usesTexturedPaperEffect ? .clear : notebookTextStyle.uiColor
        attributedText = document.attributedString(
            textStyle: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
        self.selectedRange = selectedRange
        refreshTypingAttributes()
        layer.compositingFilter = nil
        setNeedsDisplay()
    }

    private func applyScrollBehavior() {
        isScrollEnabled = scrollsInternally
        alwaysBounceVertical = scrollsInternally
        showsVerticalScrollIndicator = scrollsInternally
    }

    override var intrinsicContentSize: CGSize {
        guard !scrollsInternally else {
            return super.intrinsicContentSize
        }

        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        return sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        let rect = super.caretRect(for: position)
        let height = NotebookMetrics.bodyCaretHeight

        return CGRect(
            x: rect.minX,
            y: rect.minY + NotebookMetrics.bodyCaretYOffset,
            width: rect.width,
            height: height
        )
    }

    func refreshLayoutAfterContentChange() {
        setNeedsDisplay()
        guard !scrollsInternally else {
            return
        }

        invalidateIntrinsicContentSize()
    }

    func setNotebookText(_ string: String, richText: NotebookRichTextDocument? = nil) {
        let document = richText?.normalized(for: string) ?? NotebookRichTextDocument(text: string)
        storedRichTextDocument = document

        if string.isEmpty {
            text = ""
            refreshTypingAttributes()
            refreshLayoutAfterContentChange()
            return
        }

        let selectedRange = selectedRange
        attributedText = document.attributedString(
            textStyle: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
        self.selectedRange = selectedRange
        refreshTypingAttributes()
        refreshLayoutAfterContentChange()
    }

    func normalizeAttributesPreservingSelection() {
        guard let text, !text.isEmpty else {
            return
        }

        let selectedRange = selectedRange
        let attributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
        attributedText = NSAttributedString(string: text, attributes: attributes)
        updateStoredRichTextDocument()
        self.selectedRange = selectedRange
        refreshTypingAttributes()
    }

    func applyFormattingCommand(_ command: NotebookTextFormattingCommand) {
        if command == .bulletList {
            applyBulletToCurrentLine()
            return
        }

        let range = selectedRange
        guard range.length > 0, range.location != NSNotFound else {
            toggleTypingFormatting(command)
            return
        }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: mutableText.length)
        guard NSIntersectionRange(range, fullRange).length == range.length else {
            return
        }

        switch command {
        case .bold:
            let shouldAddBold = !mutableText.containsNotebookStyle(.notebookBold, in: range)
            mutableText.setNotebookFontStyle(
                isBold: shouldAddBold,
                isItalic: nil,
                textStyle: notebookTextStyle,
                in: range
            )
            isTypingBold = shouldAddBold
        case .italic:
            let shouldAddItalic = !mutableText.containsNotebookStyle(.notebookItalic, in: range)
            mutableText.setNotebookFontStyle(
                isBold: nil,
                isItalic: shouldAddItalic,
                textStyle: notebookTextStyle,
                in: range
            )
            isTypingItalic = shouldAddItalic
        case .underline:
            mutableText.toggleIntegerStyle(.underlineStyle, in: range)
        case .strikethrough:
            mutableText.toggleIntegerStyle(.strikethroughStyle, in: range)
        case .bulletList:
            break
        case .textStyle(let textRunStyle):
            mutableText.setNotebookTextRunStyle(
                textRunStyle,
                textStyle: notebookTextStyle,
                in: range
            )
        }

        attributedText = mutableText
        updateStoredRichTextDocument()
        selectedRange = range
        refreshTypingAttributes()
        notifyTextDidChange()
        setNeedsDisplay()
    }

    func richTextDocument() -> NotebookRichTextDocument {
        storedRichTextDocument.normalized(for: text ?? "")
    }

    private func applyBulletToCurrentLine() {
        let cursor = selectedRange.location
        guard cursor != NSNotFound else {
            return
        }

        let plain = text ?? ""
        let nsPlain = plain as NSString
        let lineRange = nsPlain.lineRange(for: NSRange(location: cursor, length: 0))
        let lineText = nsPlain
            .substring(with: lineRange)
            .trimmingCharacters(in: .newlines)

        if lineText.hasPrefix(Self.bulletPrefix) {
            removeBulletFromLine(at: lineRange, cursor: cursor)
        } else {
            addBulletToLine(at: lineRange, cursor: cursor)
        }
    }

    private func addBulletToLine(at lineRange: NSRange, cursor: Int) {
        let attributes = currentTypingAttributes()
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        mutableText.insert(
            NSAttributedString(string: Self.bulletPrefix, attributes: attributes),
            at: lineRange.location
        )

        attributedText = mutableText
        updateStoredRichTextDocument()
        selectedRange = NSRange(
            location: cursor >= lineRange.location ? cursor + Self.bulletPrefix.count : cursor,
            length: 0
        )
        typingAttributes = attributes
        notifyTextDidChange()
        setNeedsDisplay()
    }

    private func removeBulletFromLine(at lineRange: NSRange, cursor: Int) {
        let attributes = currentTypingAttributes()
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        mutableText.deleteCharacters(in: NSRange(location: lineRange.location, length: Self.bulletPrefix.count))

        let newCursor: Int
        if cursor >= lineRange.location + Self.bulletPrefix.count {
            newCursor = cursor - Self.bulletPrefix.count
        } else if cursor > lineRange.location {
            newCursor = lineRange.location
        } else {
            newCursor = cursor
        }

        attributedText = mutableText
        updateStoredRichTextDocument()
        selectedRange = NSRange(location: newCursor, length: 0)
        typingAttributes = attributes
        notifyTextDidChange()
        setNeedsDisplay()
    }

    func handleReturnKey(in range: NSRange) -> Bool {
        guard range.location != NSNotFound else {
            return true
        }

        let plain = text ?? ""
        let nsPlain = plain as NSString
        let lineRange = nsPlain.lineRange(for: NSRange(location: range.location, length: 0))
        let lineText = nsPlain
            .substring(with: lineRange)
            .trimmingCharacters(in: .newlines)

        guard lineText.hasPrefix(Self.bulletPrefix) else {
            return true
        }

        let attributes = currentTypingAttributes()
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let contentAfterBullet = String(lineText.dropFirst(Self.bulletPrefix.count))

        if contentAfterBullet.trimmingCharacters(in: .whitespaces).isEmpty {
            mutableText.deleteCharacters(in: NSRange(location: lineRange.location, length: Self.bulletPrefix.count))

            var insertLocation = range.location
            if insertLocation >= lineRange.location + Self.bulletPrefix.count {
                insertLocation -= Self.bulletPrefix.count
            } else if insertLocation > lineRange.location {
                insertLocation = lineRange.location
            }

            mutableText.replaceCharacters(
                in: NSRange(location: insertLocation, length: 0),
                with: NSAttributedString(string: "\n", attributes: attributes)
            )
            attributedText = mutableText
            updateStoredRichTextDocument()
            selectedRange = NSRange(location: insertLocation + 1, length: 0)
        } else {
            let insertString = "\n" + Self.bulletPrefix
            mutableText.replaceCharacters(
                in: range,
                with: NSAttributedString(string: insertString, attributes: attributes)
            )
            attributedText = mutableText
            updateStoredRichTextDocument()
            selectedRange = NSRange(location: range.location + insertString.count, length: 0)
        }

        typingAttributes = attributes
        notifyTextDidChange()
        setNeedsDisplay()
        return false
    }

    private func notifyTextDidChange() {
        delegate?.textViewDidChange?(self)
    }

    func refreshStoredRichTextDocumentFromTextStorage() {
        updateStoredRichTextDocument()
    }

    private func updateStoredRichTextDocument() {
        storedRichTextDocument = NotebookRichTextDocument(
            attributedString: attributedText ?? NSAttributedString(string: text ?? "")
        )
    }

    private func toggleTypingFormatting(_ command: NotebookTextFormattingCommand) {
        switch command {
        case .bold:
            isTypingBold.toggle()
        case .italic:
            isTypingItalic.toggle()
        case .underline, .strikethrough, .bulletList, .textStyle:
            return
        }

        refreshTypingAttributes()
    }

    private func currentTypingAttributes() -> [NSAttributedString.Key: Any] {
        NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect,
            isBold: isTypingBold,
            isItalic: isTypingItalic
        )
    }

    private func refreshTypingAttributes() {
        typingAttributes = currentTypingAttributes()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        if drawsRuledLines {
            drawRuledLines(in: rect)
        }
        super.draw(rect)
    }

    private func drawRuledLines(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.saveGState()
        context.translateBy(x: 0, y: -contentOffset.y)
        context.setStrokeColor(NotebookMetrics.ruleUIColor.cgColor)
        context.setLineWidth(1)

        let width = bounds.width
        var y = ruleSpacing
        let maxY = max(contentSize.height, bounds.height + contentOffset.y)

        while y <= maxY {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: width, y: y))
            y += ruleSpacing
        }

        context.strokePath()
        context.restoreGState()
    }
}

struct LinedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var richText: Binding<NotebookRichTextDocument?>? = nil
    var focusRequestID: Int = 0
    var blurRequestID: Int = 0
    var formattingRequest: NotebookTextFormattingRequest? = nil
    var scrollsInternally: Bool = true
    var drawsRuledLines: Bool? = nil
    var minimumHeight: CGFloat = NotebookMetrics.minimumBodyHeight
    var tintUIColor: UIColor = .systemBlue
    var textStyle: NotebookTextStyle = .default
    var textLeadingInset = NotebookMetrics.textLeadingInset
    var usesTexturedPaperEffect = false

    private var shouldDrawRuledLines: Bool {
        drawsRuledLines ?? scrollsInternally
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LinedTextView {
        let textView = LinedTextView()
        textView.scrollsInternally = scrollsInternally
        textView.drawsRuledLines = shouldDrawRuledLines
        textView.delegate = context.coordinator
        textView.tintColor = tintUIColor
        textView.notebookTextStyle = textStyle
        textView.textLeadingInset = textLeadingInset
        textView.usesTexturedPaperEffect = usesTexturedPaperEffect
        textView.setNotebookText(text, richText: richText?.wrappedValue)
        context.coordinator.currentRichTextDocument = textView.richTextDocument()
        context.coordinator.onTextChange = { newText in
            text = newText
        }
        context.coordinator.onRichTextChange = { newRichText in
            context.coordinator.currentRichTextDocument = newRichText
            context.coordinator.isWaitingForRichTextBindingSync = true
            richText?.wrappedValue = newRichText
        }
        return textView
    }

    func updateUIView(_ textView: LinedTextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onTextChange = { newText in
            text = newText
        }
        coordinator.onRichTextChange = { newRichText in
            coordinator.currentRichTextDocument = newRichText
            coordinator.isWaitingForRichTextBindingSync = true
            richText?.wrappedValue = newRichText
        }

        if richText?.wrappedValue?.normalized(for: text) == coordinator.currentRichTextDocument {
            coordinator.isWaitingForRichTextBindingSync = false
        }

        if textView.scrollsInternally != scrollsInternally {
            textView.scrollsInternally = scrollsInternally
        }

        if textView.drawsRuledLines != shouldDrawRuledLines {
            textView.drawsRuledLines = shouldDrawRuledLines
        }

        let didChangeTextStyle = textView.notebookTextStyle != textStyle
        if didChangeTextStyle {
            textView.notebookTextStyle = textStyle
        }

        if textView.textLeadingInset != textLeadingInset {
            textView.textLeadingInset = textLeadingInset
        }

        let didChangeTexturedPaperEffect = textView.usesTexturedPaperEffect != usesTexturedPaperEffect
        if didChangeTexturedPaperEffect {
            textView.usesTexturedPaperEffect = usesTexturedPaperEffect
        }

        if !coordinator.isUpdatingFromTextView {
            if textView.text != text {
                textView.setNotebookText(text, richText: richText?.wrappedValue)
                coordinator.currentRichTextDocument = textView.richTextDocument()
            } else if !didChangeTextStyle,
                      !didChangeTexturedPaperEffect,
                      let richText = richText?.wrappedValue,
                      !coordinator.isWaitingForRichTextBindingSync,
                      richText.normalized(for: text) != textView.richTextDocument() {
                textView.setNotebookText(text, richText: richText)
                coordinator.currentRichTextDocument = textView.richTextDocument()
            }
        }

        if didChangeTextStyle || didChangeTexturedPaperEffect {
            let refreshedRichText = textView.richTextDocument()
            coordinator.currentRichTextDocument = refreshedRichText
            coordinator.isWaitingForRichTextBindingSync = true
            DispatchQueue.main.async {
                richText?.wrappedValue = refreshedRichText
            }
        }

        if focusRequestID != coordinator.handledFocusRequestID {
            coordinator.handledFocusRequestID = focusRequestID
            DispatchQueue.main.async {
                textView.becomeFirstResponder()
            }
        }

        if blurRequestID != coordinator.handledBlurRequestID {
            coordinator.handledBlurRequestID = blurRequestID
            DispatchQueue.main.async {
                textView.resignFirstResponder()
            }
        }

        if let formattingRequest,
           formattingRequest.id != coordinator.handledFormattingRequestID {
            coordinator.handledFormattingRequestID = formattingRequest.id
            DispatchQueue.main.async {
                textView.applyFormattingCommand(formattingRequest.command)
            }
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LinedTextView, context: Context) -> CGSize? {
        guard !scrollsInternally else {
            return nil
        }

        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else {
            return nil
        }

        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(
            width: width,
            height: max(fitted.height, minimumHeight)
        )
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var isUpdatingFromTextView = false
        var handledFocusRequestID = 0
        var handledBlurRequestID = 0
        var handledFormattingRequestID = 0
        var currentRichTextDocument: NotebookRichTextDocument?
        var isWaitingForRichTextBindingSync = false
        var onTextChange: ((String) -> Void)?
        var onRichTextChange: ((NotebookRichTextDocument) -> Void)?

        func textViewDidChange(_ textView: UITextView) {
            isUpdatingFromTextView = true
            onTextChange?(textView.text)
            if let linedTextView = textView as? LinedTextView {
                linedTextView.refreshStoredRichTextDocumentFromTextStorage()
                onRichTextChange?(linedTextView.richTextDocument())
            }

            if let linedTextView = textView as? LinedTextView {
                linedTextView.refreshLayoutAfterContentChange()
            }

            DispatchQueue.main.async {
                self.isUpdatingFromTextView = false
            }
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            guard text == "\n", let linedTextView = textView as? LinedTextView else {
                return true
            }

            return linedTextView.handleReturnKey(in: range)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollView.setNeedsDisplay()
        }
    }
}

private extension NSMutableAttributedString {
    func setNotebookTextRunStyle(
        _ runStyle: NotebookTextRunStyle,
        textStyle: NotebookTextStyle,
        in range: NSRange
    ) {
        enumerateAttributes(in: range) { attributes, subrange, _ in
            let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            let isBold = (attributes[.notebookBold] as? Bool) ?? false
            let isItalic = (attributes[.notebookItalic] as? Bool) ?? traits.contains(.traitItalic)
            let font = notebookFont(
                textStyle: textStyle,
                runStyle: runStyle,
                isBold: isBold,
                isItalic: isItalic
            )

            addAttribute(.font, value: font, range: subrange)

            if runStyle == .body {
                removeAttribute(.notebookTextStyle, range: subrange)
            } else {
                addAttribute(.notebookTextStyle, value: runStyle.rawValue, range: subrange)
            }

            applySyntheticBoldIfNeeded(isBold: isBold || runStyle.usesHeadingWeight, textStyle: textStyle, range: subrange)
        }
    }

    func setNotebookFontStyle(
        isBold: Bool?,
        isItalic: Bool?,
        textStyle: NotebookTextStyle,
        in range: NSRange
    ) {
        enumerateAttributes(in: range) { attributes, subrange, _ in
            let traits = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            let resolvedBold = isBold ?? ((attributes[.notebookBold] as? Bool) ?? false)
            let resolvedItalic = isItalic ?? ((attributes[.notebookItalic] as? Bool) ?? traits.contains(.traitItalic))
            let runStyle = (attributes[.notebookTextStyle] as? String)
                .flatMap(NotebookTextRunStyle.init(rawValue:)) ?? .body
            let font = notebookFont(
                textStyle: textStyle,
                runStyle: runStyle,
                isBold: resolvedBold,
                isItalic: resolvedItalic
            )

            addAttribute(.font, value: font, range: subrange)
            setBooleanAttribute(.notebookBold, isEnabled: resolvedBold, range: subrange)
            setBooleanAttribute(.notebookItalic, isEnabled: resolvedItalic, range: subrange)
            applySyntheticBoldIfNeeded(isBold: resolvedBold || runStyle.usesHeadingWeight, textStyle: textStyle, range: subrange)
        }
    }

    private func notebookFont(
        textStyle: NotebookTextStyle,
        runStyle: NotebookTextRunStyle,
        isBold: Bool,
        isItalic: Bool
    ) -> UIFont {
        var adjustedStyle = textStyle
        adjustedStyle.bodyFontSize = textStyle.bodyFontSize * runStyle.fontScale

        return NotebookMetrics.uiBodyFont(
            for: adjustedStyle,
            isBold: isBold || runStyle.usesHeadingWeight,
            isItalic: isItalic
        )
    }

    func toggleIntegerStyle(_ key: NSAttributedString.Key, in range: NSRange) {
        if containsAttribute(key, in: range) {
            removeAttribute(key, range: range)
        } else {
            addAttribute(key, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    func containsNotebookStyle(_ key: NSAttributedString.Key, in range: NSRange) -> Bool {
        var containsStyle = true

        enumerateAttributes(in: range) { attributes, _, stop in
            let explicitValue = attributes[key] as? Bool
            let hasFallbackTrait: Bool
            if explicitValue == nil, let font = attributes[.font] as? UIFont {
                if key == .notebookBold {
                    hasFallbackTrait = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                } else if key == .notebookItalic {
                    hasFallbackTrait = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
                } else {
                    hasFallbackTrait = false
                }
            } else {
                hasFallbackTrait = false
            }

            if explicitValue != true && !hasFallbackTrait {
                containsStyle = false
                stop.pointee = true
            }
        }

        return containsStyle
    }

    private func containsAttribute(_ key: NSAttributedString.Key, in range: NSRange) -> Bool {
        var containsStyle = true

        enumerateAttribute(key, in: range) { value, _, stop in
            if value == nil {
                containsStyle = false
                stop.pointee = true
            }
        }

        return containsStyle
    }

    private func setBooleanAttribute(
        _ key: NSAttributedString.Key,
        isEnabled: Bool,
        range: NSRange
    ) {
        if isEnabled {
            addAttribute(key, value: true, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    private func applySyntheticBoldIfNeeded(
        isBold: Bool,
        textStyle: NotebookTextStyle,
        range: NSRange
    ) {
        guard isBold else {
            removeAttribute(.strokeWidth, range: range)
            return
        }

        addAttribute(.strokeWidth, value: -2, range: range)
    }
}

private final class TexturedPaperBodyTextView: UIView {
    var text = "" {
        didSet {
            updateTextStorage()
        }
    }
    var richText: NotebookRichTextDocument? {
        didSet {
            updateTextStorage()
        }
    }
    var textStyle: NotebookTextStyle = .default {
        didSet {
            updateTextStorage()
        }
    }
    var textLeadingInset = NotebookMetrics.textLeadingInset {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    private let textStorage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer(size: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureTextSystem()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextSystem()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = CGSize(
            width: max(0, bounds.width - textLeadingInset),
            height: .greatestFiniteMagnitude
        )
    }

    override func draw(_ rect: CGRect) {
        guard !text.isEmpty, let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        guard glyphRange.length > 0 else {
            return
        }

        let inkColor = textStyle.uiColor.withAlphaComponent(0.9)
        let darkEdge = TexturedPaperTextEffect.bodyShadowColor(for: textStyle.uiColor)
        let lightEdge = TexturedPaperTextEffect.bodyHighlightColor(for: textStyle.uiColor)

        context.saveGState()
        drawGlyphs(glyphRange, color: darkEdge, offset: CGSize(width: -0.7, height: -0.2))
        drawGlyphs(glyphRange, color: darkEdge, offset: CGSize(width: 0, height: -1.1))
        drawGlyphs(glyphRange, color: lightEdge, offset: CGSize(width: 0.8, height: 0.25))
        drawGlyphs(glyphRange, color: lightEdge, offset: CGSize(width: 0, height: 1.15))
        drawGlyphs(glyphRange, color: inkColor, offset: .zero)
        context.restoreGState()
    }

    private func configureTextSystem() {
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        textContainer.lineFragmentPadding = 0
        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
    }

    private func updateTextStorage() {
        let attributedText = richText?
            .normalized(for: text)
            .attributedString(textStyle: textStyle)
            ?? NSAttributedString(
                string: text,
                attributes: NotebookMetrics.typingAttributes(for: textStyle)
            )
        textStorage.setAttributedString(attributedText)
        setNeedsLayout()
        setNeedsDisplay()
    }

    private func drawGlyphs(_ glyphRange: NSRange, color: UIColor, offset: CGSize) {
        let characterRange = layoutManager.characterRange(
            forGlyphRange: glyphRange,
            actualGlyphRange: nil
        )

        textStorage.addAttribute(.foregroundColor, value: color, range: characterRange)
        layoutManager.drawGlyphs(
            forGlyphRange: glyphRange,
            at: CGPoint(
                x: textLeadingInset + offset.width,
                y: offset.height
            )
        )
    }
}

private struct TexturedPaperBodyTextOverlay: UIViewRepresentable {
    let text: String
    let richText: NotebookRichTextDocument?
    let textStyle: NotebookTextStyle
    let textLeadingInset: CGFloat

    func makeUIView(context: Context) -> TexturedPaperBodyTextView {
        let view = TexturedPaperBodyTextView()
        view.text = text
        view.richText = richText
        view.textStyle = textStyle
        view.textLeadingInset = textLeadingInset
        return view
    }

    func updateUIView(_ view: TexturedPaperBodyTextView, context: Context) {
        if view.text != text {
            view.text = text
        }

        if view.richText != richText {
            view.richText = richText
        }

        if view.textStyle != textStyle {
            view.textStyle = textStyle
        }

        if view.textLeadingInset != textLeadingInset {
            view.textLeadingInset = textLeadingInset
        }
    }
}

struct NotebookEditorContent: View {
    @Binding var storyTitle: String
    @Binding var entryText: String
    var entryRichText: Binding<NotebookRichTextDocument?>? = nil
    @FocusState.Binding var isTitleFocused: Bool
    var editorFocusRequestID: Int
    var editorBlurRequestID: Int = 0
    var formattingRequest: NotebookTextFormattingRequest? = nil
    var bodyPlaceholder: String
    var scrollsInternally: Bool = true
    var pageHeight: CGFloat?
    var textStyle: NotebookTextStyle = .default
    var showsTitleRule = true
    var leadingContentPadding = NotebookMetrics.marginLeading
    var leadingTextPadding = NotebookMetrics.textLeadingInset
    var usesTexturedPaperEffect = false
    var onBodyTap: (() -> Void)? = nil
    var onTitleSubmit: () -> Void

    private var bodyMinHeight: CGFloat {
        guard let pageHeight else {
            return NotebookMetrics.minimumBodyHeight
        }

        return NotebookMetrics.bodyAreaMinHeight(forPageHeight: pageHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
            bodyEditor
        }
        .padding(.leading, leadingContentPadding)
        .padding(.trailing, 18)
        .padding(.top, NotebookMetrics.contentTopPadding)
        .padding(.bottom, NotebookMetrics.contentBottomPadding)
    }

    private var titleRow: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                if showsTitleRule {
                    Rectangle()
                        .fill(NotebookMetrics.ruleColor)
                        .frame(height: 1)
                }
            }

            TextField(
                "",
                text: $storyTitle,
                prompt: Text("Title")
                    .foregroundColor(Color.storyGray.opacity(0.46))
            )
            .font(NotebookMetrics.titleFont(for: textStyle))
            .foregroundStyle(textStyle.color)
            .shadow(
                color: usesTexturedPaperEffect ? TexturedPaperTextEffect.titleShadowColor(for: textStyle.uiColor) : .clear,
                radius: usesTexturedPaperEffect ? 0.45 : 0,
                x: 0,
                y: usesTexturedPaperEffect ? -0.45 : 0
            )
            .blendMode(
                usesTexturedPaperEffect && TexturedPaperTextEffect.shouldMultiplyBlend(textStyle.uiColor)
                    ? .multiply
                    : .normal
            )
            .focused($isTitleFocused)
            .textFieldStyle(.plain)
            .submitLabel(.next)
            .padding(.leading, leadingTextPadding)
            .padding(.top, NotebookMetrics.titleLineTextTopInset)
            .onSubmit(onTitleSubmit)
        }
        .frame(height: NotebookMetrics.ruleSpacing)
    }

    @ViewBuilder
    private var bodyEditor: some View {
        let editor = ZStack(alignment: .topLeading) {
            LinedTextEditor(
                text: $entryText,
                richText: entryRichText,
                focusRequestID: editorFocusRequestID,
                blurRequestID: editorBlurRequestID,
                formattingRequest: formattingRequest,
                scrollsInternally: scrollsInternally,
                drawsRuledLines: false,
                minimumHeight: bodyMinHeight,
                textStyle: textStyle,
                textLeadingInset: leadingTextPadding,
                usesTexturedPaperEffect: usesTexturedPaperEffect
            )
            .overlay(alignment: .topLeading) {
                if usesTexturedPaperEffect && !entryText.isEmpty {
                    TexturedPaperBodyTextOverlay(
                        text: entryText,
                        richText: entryRichText?.wrappedValue,
                        textStyle: textStyle,
                        textLeadingInset: leadingTextPadding
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
                }
            }
            .padding(.bottom, 28)

            if entryText.isEmpty {
                Text(bodyPlaceholder)
                    .font(NotebookMetrics.bodyPlaceholderFont(for: textStyle))
                    .foregroundStyle(Color.storyGray.opacity(0.46))
                    .padding(.leading, leadingTextPadding)
                    .padding(.top, NotebookMetrics.firstLineTextTopInset)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)

        if scrollsInternally {
            editor.frame(maxHeight: .infinity)
        } else if let onBodyTap {
            editor
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        onBodyTap()
                    }
                )
        } else {
            editor
        }
    }
}

struct NotebookPageChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                HStack {
                    Rectangle()
                        .fill(Color.storyBorder.opacity(0.72))
                        .frame(width: 1)

                    Spacer()

                    Rectangle()
                        .fill(Color.storyBorder.opacity(0.72))
                        .frame(width: 1)
                }
            )
    }
}

extension View {
    func notebookPageChrome() -> some View {
        modifier(NotebookPageChrome())
    }
}
