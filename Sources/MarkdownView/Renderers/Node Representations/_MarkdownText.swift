//
//  _MarkdownText.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/10/20.
//

import SwiftUI

/// A view that displays parsed HTML asynchronously.
///
/// Convert HTML into  `AttributedString` asynchronously to avoid `AttributeGraph` crash.
struct _MarkdownText: View {
    private let text: AttributedString
    private let containsHTML: Bool

    init(_ text: AttributedString) {
        self.text = text
        containsHTML = text.runs.contains { $0.isHTML ?? false }
    }

    var body: some View {
        if containsHTML {
            HTMLMarkdownText(text: text)
        } else {
            Text(text)
        }
    }
}

private struct HTMLMarkdownText: View {
    let text: AttributedString
    @State private var attributedString: AttributedString?

    var body: some View {
        Group {
            if let attributedString {
                Text(attributedString)
            } else {
                Text(text)
            }
        }
        .task(id: text) {
            var attributedString = text
            for run in text.runs.reversed() where (run.isHTML ?? false) {
                let range = run.range

                if let htmlAttrString = try? AttributedString(
                    NSAttributedString(
                        data: Data(String(text.characters[range]).utf8),
                        options: [
                            .documentType: NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    )
                ) {
                    attributedString.replaceSubrange(range, with: htmlAttrString)
                }
            }
            self.attributedString = attributedString
        }
    }
}
