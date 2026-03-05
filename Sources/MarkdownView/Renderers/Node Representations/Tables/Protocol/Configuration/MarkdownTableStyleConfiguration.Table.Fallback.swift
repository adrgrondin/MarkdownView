//
//  MarkdownTableStyleConfiguration.Table.Fallback.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/4/21.
//

import SwiftUI
import Markdown

extension MarkdownTableStyleConfiguration.Table {
    /// A type-erased fallback table that uses `AdaptiveGrid` for rendering table on older platforms.
    public struct Fallback: View {
        private let header: MarkdownTableRowModel
        private let rows: [MarkdownTableRowModel]
        @Environment(\.markdownRendererConfiguration) private var configuration
        @Environment(\.markdownFontGroup.tableHeader) private var headerFont
        @Environment(\.markdownFontGroup.tableBody) private var bodyFont
        @Environment(\.markdownTableCellPadding) private var padding
        private var showsRowSeparators: Bool = false
        private var horizontalSpacing: CGFloat = 0
        private var verticalSpacing: CGFloat = 0

        init(header: MarkdownTableRowModel, rows: [MarkdownTableRowModel]) {
            self.header = header
            self.rows = rows
        }

        @_documentation(visibility: internal)
        public var body: some View {
            AdaptiveGrid(
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                showDivider: showsRowSeparators
            ) {
                GridRowContainer(index: header.rowIndex) {
                    for cell in header.cells {
                        GridCellContainer(alignment: cell.horizontalAlignment) {
                            CmarkNodeVisitor(configuration: configuration)
                                .makeBody(for: cell.cell)
                                .font(headerFont)
                                .multilineTextAlignment(cell.textAlignment)
                                ._markdownCellPadding(padding)
                        }
                    }
                }
                for row in rows {
                    GridRowContainer(index: row.rowIndex) {
                        for cell in row.cells {
                            GridCellContainer(alignment: cell.horizontalAlignment) {
                                CmarkNodeVisitor(configuration: configuration)
                                    .makeBody(for: cell.cell)
                                    .font(bodyFont)
                                    .multilineTextAlignment(cell.textAlignment)
                                    ._markdownCellPadding(padding)
                            }
                        }
                    }
                }
            }
        }
        
        /// Sets the visibilities of row separators.
        public func showsRowSeparators(_ show: Bool = true) -> MarkdownTableStyleConfiguration.Table.Fallback {
            var fallback = self
            fallback.showsRowSeparators = show
            return fallback
        }
        
        /// Sets the amount of space for two rows.
        public func verticalSpacing(_ spacing: CGFloat) -> MarkdownTableStyleConfiguration.Table.Fallback {
            var fallback = self
            fallback.verticalSpacing = spacing
            return fallback
        }
        
        /// Sets the amount of space for two columns.
        public func horizontalSpacing(_ spacing: CGFloat) -> MarkdownTableStyleConfiguration.Table.Fallback {
            var fallback = self
            fallback.horizontalSpacing = spacing
            return fallback
        }
    }
}
