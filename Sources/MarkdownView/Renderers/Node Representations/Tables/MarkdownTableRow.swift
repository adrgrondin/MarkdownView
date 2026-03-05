//
//  MarkdownTableHeader.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/4/21.
//

import SwiftUI
import Markdown

struct MarkdownTableRow: View {
    private let row: MarkdownTableRowModel
    @Environment(\.markdownRendererConfiguration) private var configuration
    @Environment(\.markdownTableCellPadding) private var padding

    init(rowIndex: Int, cells: [Markdown.Table.Cell]) {
        row = MarkdownTableRowModel(rowIndex: rowIndex, cells: cells)
    }

    init(row: MarkdownTableRowModel) {
        self.row = row
    }

    var body: some View {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            GridRow {
                ForEach(row.cells) { cell in
                    CmarkNodeVisitor(configuration: configuration)
                        .makeBody(for: cell.cell)
                        .multilineTextAlignment(cell.textAlignment)
                        .gridColumnAlignment(cell.horizontalAlignment)
                        .gridCellColumns(cell.columnSpan)
                        ._markdownCellPadding(padding)
                        .modifier(
                            MarkdownTableStylePreferenceSynchronizer(
                                row: row.rowIndex,
                                column: cell.columnIndex
                            )
                        )
                }
            }
        }
    }
}

struct MarkdownTableRowModel: Identifiable {
    let rowIndex: Int
    let cells: [MarkdownTableCellModel]

    init(rowIndex: Int, cells: [Markdown.Table.Cell]) {
        self.rowIndex = rowIndex
        self.cells = cells.map(MarkdownTableCellModel.init)
    }

    var id: Int { rowIndex }
}

struct MarkdownTableCellModel: Identifiable {
    let columnIndex: Int
    let cell: Markdown.Table.Cell
    let textAlignment: TextAlignment
    let horizontalAlignment: HorizontalAlignment
    let columnSpan: Int

    init(cell: Markdown.Table.Cell) {
        let alignment = cell.cellAlignment
        columnIndex = cell.indexInParent
        self.cell = cell
        textAlignment = alignment.textAlignment
        horizontalAlignment = alignment.horizontalAlignment
        columnSpan = Int(cell.colspan)
    }

    var id: Int { columnIndex }
}
