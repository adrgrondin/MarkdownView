//
//  MarkdownTableStyleConfiguration.Table.Header.swift
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
    public struct Header: View {
        private let row: MarkdownTableRowModel
        @Environment(\.markdownFontGroup.tableHeader) private var font

        init(row: MarkdownTableRowModel) {
            self.row = row
        }

        @_documentation(visibility: internal)
        public var body: some View {
            MarkdownTableRow(row: row)
            .font(font)
        }
    }
}
