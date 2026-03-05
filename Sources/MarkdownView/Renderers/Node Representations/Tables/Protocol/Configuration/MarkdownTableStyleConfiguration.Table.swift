//
//  MarkdownTableStyleConfiguration.Row.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/4/21.
//

import SwiftUI
import Markdown

extension MarkdownTableStyleConfiguration {
    /// A type-erased view of a table.
    ///
    /// This view uses `Grid` on supported platforms, or `AdaptiveGrid` otherwise.
    ///
    /// Access `header`, `rows`, and `fallback` properties for further customization.
    @preconcurrency
    @MainActor
    public struct Table {
        public let header: MarkdownTableStyleConfiguration.Table.Header
        public let rows: [MarkdownTableStyleConfiguration.Table.Row]
        public let fallback: Fallback

        init(table: Markdown.Table) {
            let headerRow = MarkdownTableRowModel(rowIndex: 0, cells: Array(table.head.cells))
            let bodyRows = table.body.rows.enumerated().map {
                MarkdownTableRowModel(rowIndex: $0.offset + 1, cells: Array($0.element.cells))
            }

            header = MarkdownTableStyleConfiguration.Table.Header(row: headerRow)
            rows = bodyRows.map(MarkdownTableStyleConfiguration.Table.Row.init)
            fallback = Fallback(header: headerRow, rows: bodyRows)
        }

        /// The header row of a table.
    }
}

extension MarkdownTableStyleConfiguration.Table: View {
    @_documentation(visibility: internal)
    public var body: some View {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                header
                ForEach(rows, id: \.rowID) { row in
                    row
                }
            }
        } else {
            fallback
        }
    }
}
