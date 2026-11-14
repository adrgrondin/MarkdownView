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

    @Test("Equal value modifiers are stable and changed inputs propagate")
    @MainActor
    func valueModifiersPreserveRelevantInputs() {
        let first = MarkdownHorizontalScrollViewTransform(modifier: TestScrollModifier(padding: 8))
        let equal = MarkdownHorizontalScrollViewTransform(modifier: TestScrollModifier(padding: 8))
        let changed = MarkdownHorizontalScrollViewTransform(modifier: TestScrollModifier(padding: 16))
        #expect(first == equal)
        #expect(first != changed)
        #expect(MarkdownHorizontalScrollViewTransform() == MarkdownHorizontalScrollViewTransform())
        #expect(first != MarkdownHorizontalScrollViewTransform())
        _ = EmptyView().markdownHorizontalScrollViewModifier(TestScrollModifier(padding: 8))
    }

    @Test("Closure replacements propagate captures without violating reflexive equality")
    @MainActor
    func closureReplacementPreservesCapturedValues() {
        var observed = 0
        let first = MarkdownHorizontalScrollViewTransform { content in
            observed = 8
            return content
        }
        let replacement = MarkdownHorizontalScrollViewTransform { content in
            observed = 16
            return content
        }
        #expect(first == first)
        #expect(first != replacement)
        _ = first(EmptyView())
        #expect(observed == 8)
        _ = replacement(EmptyView())
        #expect(observed == 16)
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

private struct TestScrollModifier: ViewModifier, Equatable {
    var padding: CGFloat
    func body(content: Content) -> some View { content.padding(padding) }
}

private extension View {
    func excludeSideDrawerGesture() -> some View {
        self
    }
}
