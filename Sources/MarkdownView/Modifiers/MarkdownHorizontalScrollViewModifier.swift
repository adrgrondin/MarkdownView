import SwiftUI

extension View {
    /// Applies a value-based modifier to horizontal scroll views created by MarkdownView.
    ///
    /// Prefer this overload for unchanged content in frequently updating parents.
    /// Equal modifier values preserve the environment value, avoiding unnecessary
    /// descendant rendering and layout. Include every behavior-affecting input in
    /// the modifier's equality; do not ignore changing captured state.
    ///
    /// The modifier applies to fenced code blocks, tables, and overflowing math.
    @MainActor
    public func markdownHorizontalScrollViewModifier<Modifier: ViewModifier & Equatable>(
        _ modifier: Modifier
    ) -> some View {
        environment(\.markdownHorizontalScrollViewTransform,
                    MarkdownHorizontalScrollViewTransform(modifier: modifier))
    }

    /// Applies a transform to horizontal scroll views created by MarkdownView.
    ///
    /// The transform applies to fenced code blocks, tables, and overflowing math.
    /// Closures have no reliable equality, so reconstructing this environment
    /// value can invalidate descendants. Prefer the Equatable ViewModifier
    /// overload for stable wrappers in animated or frequently updating parents.
    /// This overload always propagates replacements, including changed captures.
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
        environment(\.markdownHorizontalScrollViewTransform,
                    MarkdownHorizontalScrollViewTransform(transform))
    }
}

// Erasure uses methods, not stored forwarding closures. The value-based path
// contains only the caller's Equatable modifier. Legacy replacements receive a
// new reference identity: ignoring closure changes would freeze captured inputs.
struct MarkdownHorizontalScrollViewTransform: Equatable {
    private let implementation: any MarkdownScrollViewTransforming

    nonisolated init() { implementation = IdentityScrollViewTransform() }

    nonisolated init<Modifier: ViewModifier & Equatable>(modifier: Modifier) {
        implementation = ModifiedScrollViewTransform(modifier: modifier)
    }

    nonisolated init<ModifiedContent: View>(
        @ViewBuilder _ transform: @MainActor @escaping (AnyView) -> ModifiedContent
    ) {
        implementation = ClosureScrollViewTransform(transform: transform)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.implementation.isEqual(to: rhs.implementation)
    }

    @MainActor
    func callAsFunction<Content: View>(_ content: Content) -> AnyView {
        implementation.apply(to: AnyView(content))
    }
}

private protocol MarkdownScrollViewTransforming {
    @MainActor func apply(to content: AnyView) -> AnyView
    func isEqual(to other: any MarkdownScrollViewTransforming) -> Bool
}

private struct IdentityScrollViewTransform: MarkdownScrollViewTransforming {
    @MainActor func apply(to content: AnyView) -> AnyView { content }
    func isEqual(to other: any MarkdownScrollViewTransforming) -> Bool {
        other is Self
    }
}

private struct ModifiedScrollViewTransform<Modifier: ViewModifier & Equatable>: MarkdownScrollViewTransforming {
    var modifier: Modifier
    @MainActor func apply(to content: AnyView) -> AnyView { AnyView(content.modifier(modifier)) }
    func isEqual(to other: any MarkdownScrollViewTransforming) -> Bool {
        guard let other = other as? Self else { return false }
        return modifier == other.modifier
    }
}

private final class ClosureScrollViewTransform<ModifiedContent: View>: MarkdownScrollViewTransforming {
    let transform: @MainActor (AnyView) -> ModifiedContent
    init(transform: @MainActor @escaping (AnyView) -> ModifiedContent) { self.transform = transform }
    @MainActor func apply(to content: AnyView) -> AnyView { AnyView(transform(content)) }
    func isEqual(to other: any MarkdownScrollViewTransforming) -> Bool {
        guard let other = other as? Self else { return false }
        return self === other
    }
}

extension EnvironmentValues {
    @Entry var markdownHorizontalScrollViewTransform = MarkdownHorizontalScrollViewTransform()
}
