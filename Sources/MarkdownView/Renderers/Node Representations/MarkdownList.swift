import SwiftUI
import Markdown

struct MarkdownList<List: ListItemContainer>: View {
    private let rows: [MarkdownListRowData]
    private let depth: Int
    private let isOrderedList: Bool

    @Environment(\.markdownRendererConfiguration) private var configuration

    init(listItemsContainer: List) {
        rows = Array(listItemsContainer.listItems.enumerated()).map(MarkdownListRowData.init)
        depth = listItemsContainer.listDepth

        if listItemsContainer is UnorderedList {
            isOrderedList = false
        } else if listItemsContainer is OrderedList {
            isOrderedList = true
        } else {
            fatalError("Marker Protocol not implemented for \(type(of: listItemsContainer)).")
        }
    }

    var body: some View {
        let listConfiguration = configuration.listConfiguration
        let marker = MarkdownListMarker(
            unorderedMarker: isOrderedList ? nil : listConfiguration.unorderedListMarker,
            orderedMarker: isOrderedList ? listConfiguration.orderedListMarker : nil
        )

        VStack(alignment: .leading, spacing: configuration.componentSpacing) {
            ForEach(rows) { row in
                MarkdownListRow(
                    row: row,
                    depth: depth,
                    leadingIndentation: listConfiguration.leadingIndentation,
                    marker: marker,
                    configuration: configuration
                )
            }
        }
    }
}

struct MarkdownListItem: View {
    private let children: [any Markup]
    @Environment(\.markdownRendererConfiguration) private var configuration

    init(listItem: ListItem) {
        children = Array(listItem.children)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: configuration.componentSpacing) {
            ForEach(Array(children.enumerated()), id: \.offset) { (_, child) in
                CmarkNodeVisitor(configuration: configuration)
                    .makeBody(for: child)
            }
        }
    }
}

// MARK: - Auxiliary

private struct MarkdownListRowData: Identifiable {
    let index: Int
    let listItem: ListItem

    init(_ row: EnumeratedSequence<[ListItem]>.Element) {
        index = row.offset
        listItem = row.element
    }

    var id: Int { index }
}

private struct MarkdownListMarker {
    let unorderedMarker: AnyUnorderedListMarkerProtocol?
    let orderedMarker: AnyOrderedListMarkerProtocol?
}

private struct MarkdownListRow: View {
    let row: MarkdownListRowData
    let depth: Int
    let leadingIndentation: CGFloat
    let marker: MarkdownListMarker
    let configuration: MarkdownRendererConfiguration

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            MarkdownListRowMarker(row: row, depth: depth, marker: marker)
                .padding(.leading, depth == 0 ? leadingIndentation : 0)
            CmarkNodeVisitor(configuration: configuration)
                .makeBody(for: row.listItem)
        }
    }
}

private struct MarkdownListRowMarker: View {
    let row: MarkdownListRowData
    let depth: Int
    let marker: MarkdownListMarker

    var body: some View {
        if let checkBox = row.listItem.checkbox {
            MarkdownCheckbox(checkbox: checkBox)
        } else if let unorderedMarker = marker.unorderedMarker {
            SwiftUI.Text(unorderedMarker.marker(listDepth: depth))
                .backdeployedMonospaced(unorderedMarker.monospaced)
        } else if let orderedMarker = marker.orderedMarker {
            SwiftUI.Text(orderedMarker.marker(at: row.index, listDepth: depth))
                .backdeployedMonospaced(orderedMarker.monospaced)
        }
    }
}

private struct MarkdownCheckbox: View {
    let checkbox: Checkbox

    var body: some View {
        switch checkbox {
        case .checked:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
        case .unchecked:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        }
    }
}

fileprivate extension SwiftUI.Text {
    func backdeployedMonospaced(_ isActive: Bool = true) -> SwiftUI.Text {
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            return monospaced(isActive)
        } else {
            @Environment(\.font) var font
            return self.font(font?.monospaced())
        }
    }
}
