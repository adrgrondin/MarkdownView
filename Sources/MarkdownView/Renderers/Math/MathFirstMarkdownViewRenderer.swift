//
//  MathFirstMarkdownViewRenderer.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/4/12.
//

import SwiftUI
import Markdown

struct MathFirstMarkdownViewRenderer: MarkdownViewRenderer {
    func makeBody(
        content: MarkdownContent,
        configuration: MarkdownRendererConfiguration
    ) -> some View {
        var configuration = configuration
        var rawText = content.raw.text
        
        var extractor = ParsingRangesExtractor()
        extractor.visit(content.parse(options: ParseOptions().union(.parseBlockDirectives)))
        for range in extractor.parsableRanges(in: rawText).reversed() {
            let segment = rawText[range]
            let segmentParser = MathParser(text: segment)
            for math in segmentParser.mathRepresentations.reversed() where !math.kind.inline {
                let displayMath = rawText[math.range]
                let stableIdentifier = Self.displayMathIdentifier(
                    for: displayMath,
                    in: math.range,
                    rawText: rawText
                )
                let mathIdentifier = configuration.math.appendDisplayMath(
                    displayMath,
                    id: stableIdentifier
                )
                rawText.replaceSubrange(
                    math.range,
                    with: "@math(uuid:\(mathIdentifier))"
                )
            }
        }
        
        let _content = MarkdownContent(raw: .plainText(rawText))
        return CmarkFirstMarkdownViewRenderer()
            .makeBody(content: _content, configuration: configuration)
    }
}

private extension MathFirstMarkdownViewRenderer {
    static func displayMathIdentifier(
        for displayMath: some StringProtocol,
        in range: Range<String.Index>,
        rawText: String
    ) -> UUID {
        let startOffset = rawText.utf8.distance(
            from: rawText.utf8.startIndex,
            to: range.lowerBound.samePosition(in: rawText.utf8) ?? rawText.utf8.startIndex
        )
        let endOffset = rawText.utf8.distance(
            from: rawText.utf8.startIndex,
            to: range.upperBound.samePosition(in: rawText.utf8) ?? rawText.utf8.startIndex
        )
        let seed = "\(startOffset):\(endOffset):\(displayMath)"
        let bytes = deterministicBytes(for: seed)
        
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
    
    static func deterministicBytes(for value: String) -> [UInt8] {
        let bytes = Array(value.utf8)
        var firstHash: UInt64 = 0xcbf29ce484222325
        var secondHash: UInt64 = 0x84222325cbf29ce4
        
        for byte in bytes {
            firstHash ^= UInt64(byte)
            firstHash &*= 0x100000001b3
            
            secondHash ^= UInt64(byte) &+ 0x9e3779b97f4a7c15
            secondHash &*= 0x100000001b3
        }
        
        var output = [UInt8]()
        for shift in stride(from: 56, through: 0, by: -8) {
            output.append(UInt8((firstHash >> UInt64(shift)) & 0xff))
        }
        for shift in stride(from: 56, through: 0, by: -8) {
            output.append(UInt8((secondHash >> UInt64(shift)) & 0xff))
        }
        
        output[6] = (output[6] & 0x0f) | 0x40
        output[8] = (output[8] & 0x3f) | 0x80
        
        return output
    }
}
