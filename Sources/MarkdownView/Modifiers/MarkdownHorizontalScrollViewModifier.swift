import SwiftUI

extension View {
    /// Applies a transform to horizontal scroll views created by MarkdownView.
    ///
    /// The transform applies to fenced code blocks, tables, and overflowing
    /// inline or display math.
    ///
    /// ```swift
    /// MarkdownView(markdown)
    ///     .markdownHorizontalScrollViewModifier { scrollView in
    ///         scrollView.excludeSideDrawerGesture()
    ///     }
    /// ```
    @MainActor
    public func markdownHorizontalScrollViewModifier<ModifiedContent: View>(
        @ViewBuilder _ transform: @MainActor @escaping (AnyView) -> ModifiedContent
    ) -> some View {
        environment(
            \.markdownHorizontalScrollViewTransform,
            MarkdownHorizontalScrollViewTransform(transform)
        )
    }
}

struct MarkdownHorizontalScrollViewTransform {
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
    @Entry var markdownHorizontalScrollViewTransform = MarkdownHorizontalScrollViewTransform()
}
