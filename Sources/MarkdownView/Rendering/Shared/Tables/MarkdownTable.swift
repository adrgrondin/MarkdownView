import SwiftUI
import Markdown

struct MarkdownTable: View {
    var table: MarkdownTableStyleConfiguration.Table
    @Environment(\.markdownTableStyle) private var tableStyle
    @Environment(\.markdownHorizontalScrollViewTransform) private var horizontalScrollViewTransform
    @State private var viewportWidth: CGFloat = 0

    init(table: MarkdownTableStyleConfiguration.Table) {
        self.table = table
    }
    
    var body: some View {
        let configuration = MarkdownTableStyleConfiguration(
            table: table
        )
        horizontalScrollViewTransform(
            ScrollView(.horizontal) {
                tableStyle
                    .makeBody(configuration: configuration)
                    .erasedToAnyView()
                    .environment(
                        \.markdownTableMinimumWidth,
                        max(0, viewportWidth - MarkdownTableLayout.outerPadding * 2)
                    )
                    .fixedSize(horizontal: true, vertical: true)
                    .markdownTableCellStyleApplied()
                    .padding(MarkdownTableLayout.outerPadding)
                    .coordinateSpace(name: MarkdownTable.CoordinateSpaceName)
            }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .onWidthChange { viewportWidth = $0 }
    }
}

extension MarkdownTable {
    static let CoordinateSpaceName: String = "markdownview-table"
}

enum MarkdownTableLayout {
    static let outerPadding: CGFloat = 1
    static let maximumColumnWidth: CGFloat = 280
}

struct MarkdownTableMinimumWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var markdownTableMinimumWidth: CGFloat {
        get { self[MarkdownTableMinimumWidthEnvironmentKey.self] }
        set { self[MarkdownTableMinimumWidthEnvironmentKey.self] = newValue }
    }
}

private struct MarkdownTableColumnWidthLimitLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let subview = subviews.first else { return .zero }

        let idealSize = subview.sizeThatFits(.unspecified)
        let width = min(idealSize.width, MarkdownTableLayout.maximumColumnWidth)
        let constrainedSize = subview.sizeThatFits(
            ProposedViewSize(width: width, height: proposal.height)
        )

        return CGSize(width: width, height: constrainedSize.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard let subview = subviews.first else { return }

        subview.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: nil)
        )
    }
}

// MARK: - Auxiliary

fileprivate extension View {
    nonisolated func markdownTableCellStyleApplied() -> some View {
        modifier(MarkdownTableCellStylingViewModifier())
    }
}

fileprivate struct MarkdownTableCellStylingViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .backgroundPreferenceValue(
                MarkdownTableRowStyleCollectionPreference.self
            ) { styleCollection in
                if styleCollection.values.contains(where: { $0.backgroundStyle != nil }) {
                    ZStack(alignment: .topLeading) {
                        ForEach(styleCollection.rows) { row in
                            if let backgroundStyle = row.backgroundStyle {
                                resolveShape(row.backgroundShape, style: backgroundStyle)
                                    .offset(styleCollection.offset(for: row.position))
                                    .frame(height: styleCollection.heights[row.position.row])
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .backgroundPreferenceValue(
                MarkdownTableCellStyleCollectionPreference.self
            ) { styleCollection in
                if styleCollection.cells.contains(where: { $0.backgroundStyle != nil }) {
                    ZStack(alignment: .topLeading) {
                        ForEach(styleCollection.cells) { cell in
                            if let backgroundStyle = cell.backgroundStyle {
                                resolveShape(cell.backgroundShape, style: backgroundStyle)
                                    .offset(styleCollection.offset(for: cell.position))
                                    .frame(
                                        width: styleCollection.widths[cell.position.column],
                                        height: styleCollection.heights[cell.position.row]
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .overlayPreferenceValue(
                MarkdownTableCellStyleCollectionPreference.self
            ) { styleCollection in
                if styleCollection.cells.contains(where: { $0.overlayContent != nil }) {
                    ZStack(alignment: .topLeading) {
                        ForEach(styleCollection.cells) { cell in
                            if let overlayContent = cell.overlayContent {
                                overlayContent
                                    .offset(styleCollection.offset(for: cell.position))
                                    .frame(
                                        width: styleCollection.widths[cell.position.column],
                                        height: styleCollection.heights[cell.position.row]
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
    }
    
    func resolveShape(_ shape: any Shape, style: some ShapeStyle) -> AnyView {
        func cast(_ shape: some Shape) -> AnyView {
            AnyView(shape.fill(style))
        }
        return _openExistential(shape, do: cast(_:))
    }
}

extension View {
    nonisolated func _markdownTableColumnWidthLimited() -> some View {
        MarkdownTableColumnWidthLimitLayout {
            self
        }
    }

    nonisolated func _markdownTableStylesIgnored(_ ignored: Bool = true) -> some View {
        transformEnvironment(\.self) { environmentValues in
            if ignored {
                environmentValues.markdownTableCellPadding = .zero
                environmentValues.markdownTableCellBackgroundStyle = nil
                environmentValues.markdownTableCellOverlayContent = nil
                environmentValues.markdownTableRowBackgroundStyle = nil
            }
        }
    }
}
