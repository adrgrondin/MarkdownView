//
//  CmarkFirstMarkdownViewRenderer.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/4/12.
//

import SwiftUI
import Markdown

struct CmarkFirstMarkdownViewRenderer: MarkdownViewRenderer {    
    func makeBody(
        content: MarkdownContent,
        configuration: MarkdownRendererConfiguration
    ) -> some View {
        CmarkRenderedMarkdownView(
            content: content,
            configuration: configuration
        )
    }
}

extension CmarkFirstMarkdownViewRenderer {
    struct Cache: Cacheable {
        var markdownContent: MarkdownContent
        var configuration: MarkdownRendererConfiguration
        var renderedView: any View
        
        var cacheKey: some Hashable { markdownContent }
    }
}

private struct CmarkRenderedMarkdownView: View {
    var content: MarkdownContent
    var configuration: MarkdownRendererConfiguration
    
    @State private var loaded: LoadedRenderedView?
    
    private var renderKey: RenderKey {
        RenderKey(content: content, configuration: configuration)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let loaded, loaded.key == renderKey {
                loaded.renderedView
            } else if let cached = cachedRenderedView {
                AnyView(cached.renderedView)
            } else {
                ProgressView()
                    .hidden()
                    .accessibilityHidden(true)
            }
        }
        .task(id: renderKey) {
            await renderIfNeeded(for: renderKey)
        }
    }
    
    @MainActor
    private func renderIfNeeded(for key: RenderKey) async {
        if let cached = cachedRenderedView {
            loaded = LoadedRenderedView(
                key: key,
                renderedView: AnyView(cached.renderedView)
            )
            return
        }
        
        loaded = nil
        
        let document = await content.parseAsynchronously(options: parseOptions)
        guard !Task.isCancelled else { return }
        
        let renderedView = CmarkNodeVisitor(configuration: configuration)
            .makeBody(for: document)
            .erasedToAnyView()
        
        CacheStorage.shared.addCache(
            CmarkFirstMarkdownViewRenderer.Cache(
                markdownContent: content,
                configuration: configuration,
                renderedView: renderedView
            )
        )
        
        loaded = LoadedRenderedView(key: key, renderedView: renderedView)
    }
    
    private var cachedRenderedView: CmarkFirstMarkdownViewRenderer.Cache? {
        guard let cached = CacheStorage.shared.withCacheIfAvailable(
            content,
            type: CmarkFirstMarkdownViewRenderer.Cache.self
        ), cached.configuration == configuration else {
            return nil
        }
        
        return cached
    }
    
    private var parseOptions: ParseOptions {
        var parseOptions = ParseOptions()
        if !configuration.allowedBlockDirectiveRenderers.isEmpty {
            parseOptions.insert(.parseBlockDirectives)
        }
        return parseOptions
    }
}

private extension CmarkRenderedMarkdownView {
    struct RenderKey: Equatable {
        var content: MarkdownContent
        var configuration: MarkdownRendererConfiguration
    }
    
    struct LoadedRenderedView {
        var key: RenderKey
        var renderedView: AnyView
    }
}
