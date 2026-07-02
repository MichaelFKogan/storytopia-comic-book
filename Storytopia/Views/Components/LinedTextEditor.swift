import SwiftUI
import UIKit

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
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = ruleSpacing
        style.maximumLineHeight = ruleSpacing
        style.lineSpacing = 0
        style.paragraphSpacing = 0
        style.lineBreakMode = .byWordWrapping
        return style
    }

    static var typingAttributes: [NSAttributedString.Key: Any] {
        typingAttributes(for: .default)
    }

    static func titleFont(for style: NotebookTextStyle) -> Font {
        .system(size: style.titleFontSize, weight: .bold, design: style.swiftUIDesign)
    }

    static func bodyPlaceholderFont(for style: NotebookTextStyle) -> Font {
        .system(size: style.bodyFontSize, weight: .regular, design: style.swiftUIDesign)
    }

    static func uiBodyFont(for style: NotebookTextStyle) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: style.bodyFontSize, weight: .medium)
        guard
            let descriptor = baseFont.fontDescriptor.withDesign(style.uiKitDesign)
        else {
            return baseFont
        }

        return UIFont(descriptor: descriptor, size: style.bodyFontSize)
    }

    static func typingAttributes(for style: NotebookTextStyle) -> [NSAttributedString.Key: Any] {
        [
            .font: uiBodyFont(for: style),
            .foregroundColor: style.uiColor,
            .paragraphStyle: typingParagraphStyle
        ]
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
    var bodyFontSize: CGFloat = NotebookMetrics.bodyFontSize
    var color: Color = Color(NotebookMetrics.bodyTextUIColor)
    var uiColor: UIColor = NotebookMetrics.bodyTextUIColor

    static let `default` = NotebookTextStyle()

    var titleFontSize: CGFloat {
        bodyFontSize + 4
    }
}

final class LinedTextView: UITextView {
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
        let attributes = NotebookMetrics.typingAttributes(for: notebookTextStyle)
        typingAttributes = attributes
        font = NotebookMetrics.uiBodyFont(for: notebookTextStyle)
        textColor = notebookTextStyle.uiColor

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
        let attributes = NotebookMetrics.typingAttributes(for: notebookTextStyle)

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
        let attributes = NotebookMetrics.typingAttributes(for: notebookTextStyle)
        attributedText = NSAttributedString(string: text, attributes: attributes)
        self.selectedRange = selectedRange
        typingAttributes = attributes
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
    var scrollsInternally: Bool = true
    var drawsRuledLines: Bool? = nil
    var minimumHeight: CGFloat = NotebookMetrics.minimumBodyHeight
    var tintUIColor: UIColor = .systemBlue
    var textStyle: NotebookTextStyle = .default
    var textLeadingInset = NotebookMetrics.textLeadingInset

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

        func textViewDidEndEditing(_ textView: UITextView) {
            if let linedTextView = textView as? LinedTextView, textView.markedTextRange == nil {
                linedTextView.normalizeAttributesPreservingSelection()
            }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollView.setNeedsDisplay()
        }
    }
}

struct NotebookEditorContent: View {
    @Binding var storyTitle: String
    @Binding var entryText: String
    @FocusState.Binding var isTitleFocused: Bool
    var editorFocusRequestID: Int
    var editorBlurRequestID: Int = 0
    var bodyPlaceholder: String
    var scrollsInternally: Bool = true
    var pageHeight: CGFloat?
    var textStyle: NotebookTextStyle = .default
    var showsTitleRule = true
    var leadingContentPadding = NotebookMetrics.marginLeading
    var leadingTextPadding = NotebookMetrics.textLeadingInset
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
                scrollsInternally: scrollsInternally,
                drawsRuledLines: false,
                minimumHeight: bodyMinHeight,
                textStyle: textStyle,
                textLeadingInset: leadingTextPadding
            )
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
