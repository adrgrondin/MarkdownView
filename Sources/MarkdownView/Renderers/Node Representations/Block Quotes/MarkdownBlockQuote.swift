//
//  MarkdownBlockQuote.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/2/22.
//

import SwiftUI
import Markdown

struct MarkdownBlockQuote: View {
    private let configuration: BlockQuoteStyleConfiguration
    @Environment(\.blockQuoteStyle) private var blockQuoteStyle

    init(blockQuote: BlockQuote) {
        configuration = BlockQuoteStyleConfiguration(
            content: BlockQuoteStyleConfiguration.Content(blockQuote: blockQuote)
        )
    }

    var body: some View {
        blockQuoteStyle
            .makeBody(configuration: configuration)
            .erasedToAnyView()
    }
}
