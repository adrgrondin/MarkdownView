import SwiftUI
import Markdown

struct MarkdownTable: View {
    private let configuration: MarkdownTableStyleConfiguration
    @Environment(\.markdownTableStyle) private var tableStyle

    init(table: Markdown.Table) {
        configuration = MarkdownTableStyleConfiguration(
            table: MarkdownTableStyleConfiguration.Table(table: table)
        )
    }

    var body: some View {
        tableStyle
            .makeBody(configuration: configuration)
            .erasedToAnyView()
            .markdownTableCellStyleApplied()
            .coordinateSpace(name: MarkdownTable.CoordinateSpaceName)
    }
}

extension MarkdownTable {
    static let CoordinateSpaceName: String = "markdownview-table"
}

struct MarkdownTableBody: View {
    private let rows: [MarkdownTableRowModel]
    @Environment(\.markdownRendererConfiguration) private var configuration
    @Environment(\.markdownFontGroup.tableBody) private var font

    init(tableBody: Markdown.Table.Body) {
        rows = tableBody.rows.enumerated().map {
            MarkdownTableRowModel(rowIndex: $0.offset + 1, cells: Array($0.element.cells))
        }
    }

    var body: some View {
        ForEach(rows) { row in
            MarkdownTableRow(row: row)
                .font(font)
        }
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
    nonisolated package func _markdownTableStylesIgnored(_ ignored: Bool = true) -> some View {
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
