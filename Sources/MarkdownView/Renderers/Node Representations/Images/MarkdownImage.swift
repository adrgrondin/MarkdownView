//
//  MarkdownImage.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/2/22.
//

import Markdown
import SwiftUI

struct MarkdownImage: View {
    private let url: URL?
    private let alternativeText: String?
    private let fallbackText: String

    @Environment(\.markdownRendererConfiguration.preferredBaseURL) private var baseURL
    @Environment(\.markdownRendererConfiguration.allowedImageRenderers) private var allowedRenderer

    init(image: Markdown.Image) {
        url = image.source.flatMap(URL.init(string:))
        fallbackText = image.plainText

        if image.parent is Markdown.Link {
            alternativeText = nil
        } else if let title = image.title, !title.isEmpty {
            alternativeText = title
        } else {
            alternativeText = image.plainText.isEmpty ? nil : image.plainText
        }
    }

    var body: some View {
        if let url {
            let configuration = MarkdownImageRendererConfiguration(
                url: url,
                alternativeText: alternativeText
            )
            if let scheme = url.scheme, allowedRenderer.contains(scheme),
               let renderer = MarkdownImageRenders.named(scheme) {
                renderer
                    .makeBody(configuration: configuration)
                    .erasedToAnyView()
            } else if let baseURL {
                RelativePathMarkdownImageRenderer(baseURL: baseURL)
                    .makeBody(configuration: configuration)
                    .erasedToAnyView()
            } else {
                fallbackView
            }
        } else {
            fallbackView
        }
    }
    
    private var fallbackView: some View {
        MarkdownNodeView(fallbackText)
    }
}
