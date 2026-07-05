import SwiftUI
import UIKit

enum NotebookTextFormattingCommand: Equatable {
    case bold
    case italic
    case underline
    case strikethrough
    case bulletList
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
                name: customFontName,
                size: style.titleFontSize,
                weight: .bold,
                usesWeightAxis: style.customFontUsesVariableWeight,
                wghtOverride: style.customFontWght.map { max($0, 700) }
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
        if let customFontName = style.customFontName,
           let customFont = VariableFont.uiFont(
               name: customFontName,
               size: style.scaledBodyFontSize,
               weight: style.customFontWeight,
               usesWeightAxis: style.customFontUsesVariableWeight,
               wghtOverride: style.customFontWght
           ) {
            return customFont
        }

        let baseFont = UIFont.systemFont(ofSize: style.bodyFontSize, weight: .medium)
        guard
            let descriptor = baseFont.fontDescriptor.withDesign(style.uiKitDesign)
        else {
            return baseFont
        }

        return UIFont(descriptor: descriptor, size: style.bodyFontSize)
    }

    static func typingAttributes(
        for style: NotebookTextStyle,
        usesTexturedPaperEffect: Bool = false
    ) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: uiBodyFont(for: style),
            .foregroundColor: usesTexturedPaperEffect ? UIColor.clear : style.uiColor,
            .paragraphStyle: typingParagraphStyle
        ]

        return attributes
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
    var customFontWeight: Font.Weight = .regular
    var customFontWght: CGFloat?
    var customFontUsesVariableWeight: Bool = false
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
        let attributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
        typingAttributes = attributes
        font = NotebookMetrics.uiBodyFont(for: notebookTextStyle)
        textColor = usesTexturedPaperEffect ? .clear : notebookTextStyle.uiColor
        layer.compositingFilter = nil

        guard let text, !text.isEmpty else {
            setNeedsDisplay()
            return
        }

        let selectedRange = selectedRange
        attributedText = NSAttributedString(string: text, attributes: attributes)
        self.selectedRange = selectedRange
        typingAttributes = attributes
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

    func setNotebookText(_ string: String) {
        let attributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )

        if string.isEmpty {
            text = ""
            typingAttributes = attributes
            setNeedsDisplay()
            return
        }

        let selectedRange = selectedRange
        attributedText = NSAttributedString(string: string, attributes: attributes)
        self.selectedRange = selectedRange
        typingAttributes = attributes
        setNeedsDisplay()
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
        self.selectedRange = selectedRange
        typingAttributes = attributes
    }

    func applyFormattingCommand(_ command: NotebookTextFormattingCommand) {
        if command == .bulletList {
            applyBulletToCurrentLine()
            return
        }

        let range = selectedRange
        guard range.length > 0, range.location != NSNotFound else {
            return
        }

        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let fullRange = NSRange(location: 0, length: mutableText.length)
        guard NSIntersectionRange(range, fullRange).length == range.length else {
            return
        }

        switch command {
        case .bold:
            mutableText.toggleFontTrait(.traitBold, in: range)
        case .italic:
            mutableText.toggleFontTrait(.traitItalic, in: range)
        case .underline:
            mutableText.toggleIntegerStyle(.underlineStyle, in: range)
        case .strikethrough:
            mutableText.toggleIntegerStyle(.strikethroughStyle, in: range)
        case .bulletList:
            break
        }

        attributedText = mutableText
        selectedRange = range
        typingAttributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
        setNeedsDisplay()
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
        let attributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        mutableText.insert(
            NSAttributedString(string: Self.bulletPrefix, attributes: attributes),
            at: lineRange.location
        )

        attributedText = mutableText
        selectedRange = NSRange(
            location: cursor >= lineRange.location ? cursor + Self.bulletPrefix.count : cursor,
            length: 0
        )
        typingAttributes = attributes
        notifyTextDidChange()
        setNeedsDisplay()
    }

    private func removeBulletFromLine(at lineRange: NSRange, cursor: Int) {
        let attributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
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

        let attributes = NotebookMetrics.typingAttributes(
            for: notebookTextStyle,
            usesTexturedPaperEffect: usesTexturedPaperEffect
        )
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
            selectedRange = NSRange(location: insertLocation + 1, length: 0)
        } else {
            let insertString = "\n" + Self.bulletPrefix
            mutableText.replaceCharacters(
                in: range,
                with: NSAttributedString(string: insertString, attributes: attributes)
            )
            attributedText = mutableText
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
        textView.setNotebookText(text)
        context.coordinator.onTextChange = { newText in
            text = newText
        }
        return textView
    }

    func updateUIView(_ textView: LinedTextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onTextChange = { newText in
            text = newText
        }

        if textView.scrollsInternally != scrollsInternally {
            textView.scrollsInternally = scrollsInternally
        }

        if textView.drawsRuledLines != shouldDrawRuledLines {
            textView.drawsRuledLines = shouldDrawRuledLines
        }

        if textView.notebookTextStyle != textStyle {
            textView.notebookTextStyle = textStyle
        }

        if textView.textLeadingInset != textLeadingInset {
            textView.textLeadingInset = textLeadingInset
        }

        if textView.usesTexturedPaperEffect != usesTexturedPaperEffect {
            textView.usesTexturedPaperEffect = usesTexturedPaperEffect
        }

        if !coordinator.isUpdatingFromTextView, textView.text != text {
            textView.setNotebookText(text)
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
        var onTextChange: ((String) -> Void)?

        func textViewDidChange(_ textView: UITextView) {
            isUpdatingFromTextView = true
            onTextChange?(textView.text)

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
    func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, in range: NSRange) {
        let shouldAddTrait = !containsFontTrait(trait, in: range)

        enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? UIFont) ?? NotebookMetrics.bodyFont
            var traits = font.fontDescriptor.symbolicTraits

            if shouldAddTrait {
                traits.insert(trait)
            } else {
                traits.remove(trait)
            }

            guard let descriptor = font.fontDescriptor.withSymbolicTraits(traits) else {
                return
            }

            addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: subrange)
        }
    }

    func toggleIntegerStyle(_ key: NSAttributedString.Key, in range: NSRange) {
        if containsAttribute(key, in: range) {
            removeAttribute(key, range: range)
        } else {
            addAttribute(key, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    private func containsFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, in range: NSRange) -> Bool {
        var containsTrait = true

        enumerateAttribute(.font, in: range) { value, _, stop in
            let font = (value as? UIFont) ?? NotebookMetrics.bodyFont
            if !font.fontDescriptor.symbolicTraits.contains(trait) {
                containsTrait = false
                stop.pointee = true
            }
        }

        return containsTrait
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
}

private final class TexturedPaperBodyTextView: UIView {
    var text = "" {
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
        let attributes = NotebookMetrics.typingAttributes(for: textStyle)
        textStorage.setAttributedString(NSAttributedString(string: text, attributes: attributes))
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
    let textStyle: NotebookTextStyle
    let textLeadingInset: CGFloat

    func makeUIView(context: Context) -> TexturedPaperBodyTextView {
        let view = TexturedPaperBodyTextView()
        view.text = text
        view.textStyle = textStyle
        view.textLeadingInset = textLeadingInset
        return view
    }

    func updateUIView(_ view: TexturedPaperBodyTextView, context: Context) {
        if view.text != text {
            view.text = text
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
