import SwiftUI
import Testing

@testable import MarkdownView

@Suite("Markdown Horizontal Scroll View Modifier")
struct MarkdownHorizontalScrollViewModifierTests {
    @Test("Accepts an app-specific View extension")
    @MainActor
    func acceptsAppSpecificViewExtension() {
        _ = EmptyView()
            .markdownHorizontalScrollViewModifier { scrollView in
                scrollView.excludeSideDrawerGesture()
            }
    }

    @Test("Applies the configured transform")
    @MainActor
    func appliesConfiguredTransform() {
        var didApplyTransform = false
        let transform = MarkdownHorizontalScrollViewTransform { content in
            didApplyTransform = true
            return content
        }

        _ = transform(EmptyView())

        #expect(didApplyTransform)
    }
}

private extension View {
    func excludeSideDrawerGesture() -> some View {
        self
    }
}
