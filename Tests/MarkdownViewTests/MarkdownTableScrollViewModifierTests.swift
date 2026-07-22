import SwiftUI
import Testing

@testable import MarkdownView

@Suite("Markdown Table Scroll View Modifier")
struct MarkdownTableScrollViewModifierTests {
    @Test("Accepts an app-specific View extension")
    @MainActor
    func acceptsAppSpecificViewExtension() {
        _ = EmptyView()
            .markdownTableScrollViewModifier { scrollView in
                scrollView.excludeSideDrawerGesture()
            }
    }

    @Test("Applies the configured scroll view transform")
    @MainActor
    func appliesConfiguredScrollViewTransform() {
        var didApplyTransform = false
        let transform = MarkdownTableScrollViewTransform { content in
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
