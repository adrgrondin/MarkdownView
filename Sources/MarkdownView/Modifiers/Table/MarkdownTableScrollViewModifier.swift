import SwiftUI

extension View {
    /// Applies a transform to the horizontal scroll view used by markdown tables.
    ///
    /// Use this modifier when an app-specific modifier needs to act directly on
    /// each table scroll view rather than on the surrounding ``MarkdownView``.
    ///
    /// ```swift
    /// MarkdownView(markdown)
    ///     .markdownTableScrollViewModifier { scrollView in
    ///         scrollView.excludeSideDrawerGesture()
    ///     }
    /// ```
    @MainActor
    public func markdownTableScrollViewModifier<ModifiedContent: View>(
        @ViewBuilder _ transform: @MainActor @escaping (AnyView) -> ModifiedContent
    ) -> some View {
        environment(
            \.markdownTableScrollViewTransform,
            MarkdownTableScrollViewTransform(transform)
        )
    }
}

struct MarkdownTableScrollViewTransform {
    private let transform: @MainActor (AnyView) -> AnyView

    nonisolated init() {
        transform = { $0 }
    }

    nonisolated init<ModifiedContent: View>(
        @ViewBuilder _ transform: @MainActor @escaping (AnyView) -> ModifiedContent
    ) {
        self.transform = { AnyView(transform($0)) }
    }

    @MainActor
    func callAsFunction<Content: View>(_ content: Content) -> AnyView {
        transform(AnyView(content))
    }
}

extension EnvironmentValues {
    @Entry var markdownTableScrollViewTransform = MarkdownTableScrollViewTransform()
}
