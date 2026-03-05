//
//  MarkdownTableStyleConfiguration.Table.Row.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/4/21.
//

import SwiftUI
import Markdown

extension MarkdownTableStyleConfiguration.Table {
    /// A type-erased header row of a table.
    ///
    /// On platforms that does not supports `Grid`, it would be `EmptyView`.
    public struct Row: View {
        private let row: MarkdownTableRowModel
        let rowID: Int
        @Environment(\.markdownFontGroup.tableBody) private var font

        init(_ row: MarkdownTableRowModel) {
            self.row = row
            rowID = row.id
        }

        @_documentation(visibility: internal)
        public var body: some View {
            MarkdownTableRow(row: row)
                .font(font)
        }
    }
}
