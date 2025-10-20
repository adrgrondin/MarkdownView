//
//  MathParser.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/2/24.
//

import SwiftUI
#if canImport(LaTeXSwiftUI)
import LaTeXSwiftUI
import MathJaxSwift
#endif

/*
 Credits to colinc86/LaTeXSwiftUI
 */
@_spi(MarkdownMath)
public struct MathParser {
    public var text: any StringProtocol
    
    public init(text: some StringProtocol) {
        self.text = text
    }
    
    public var mathRepresentations: [MathRepresentation] {
        var stack = [MathRepresentation.Kind]()
        var index = text.startIndex
        var startIndex = index
        var endIndex = index
        var representations: [MathRepresentation] = []
        
        inputLoop: while index < text.endIndex {
            let remaining = text[index...]
            
            if !stack.isEmpty {
                for type in MathRepresentation.Kind.allCases {
                    let end = type.rightTerminator
                    if remaining.hasPrefix(end) {
                        if index > text.startIndex && text[text.index(before: index)] == "\\" {
                            index = text.index(index, offsetBy: end.count)
                            continue inputLoop
                        }
                        
                        endIndex = text.index(index, offsetBy: end.count)
                        
                        if stack.last == type {
                            stack.removeLast()
                            
                            if stack.isEmpty {
                                // Validate the potential math expression before adding it
                                if isValidMathExpression(
                                    kind: type,
                                    range: startIndex..<endIndex
                                ) {
                                    representations.append(
                                        MathRepresentation(
                                            kind: type,
                                            range: startIndex..<endIndex
                                        )
                                    )
                                }
                            }
                        }
                        index = endIndex
                        continue inputLoop
                    }
                }
            }
            
            for type in MathRepresentation.Kind.allCases {
                let start = type.leftTerminator
                if remaining.hasPrefix(start) {
                    if index > text.startIndex && text[text.index(before: index)] == "\\" {
                        index = text.index(index, offsetBy: start.count)
                        continue inputLoop
                    }
                    
                    if stack.isEmpty {
                        startIndex = index
                    }
                    
                    stack.append(type)
                    index = text.index(index, offsetBy: start.count)
                    continue inputLoop
                }
            }
            
            index = text.index(after: index)
        }
        
        return representations
    }
    
    /// Validates if the given range contains a valid math expression.
    /// This helps prevent false positives like currency amounts being treated as math.
    private func isValidMathExpression(
        kind: MathRepresentation.Kind,
        range: Range<String.Index>
    ) -> Bool {
        let content = text[range]
        let delimiter = kind.leftTerminator
        
        // Extract the inner content (without delimiters)
        let innerStartIndex = text.index(range.lowerBound, offsetBy: delimiter.count)
        let innerEndIndex = text.index(range.upperBound, offsetBy: -delimiter.count)
        
        guard innerStartIndex < innerEndIndex else {
            return false // Empty content
        }
        
        let innerContent = text[innerStartIndex..<innerEndIndex]
        
        // For single $ inline equations, apply stricter validation
        if kind == .inlineEquation {
            // Check if it starts or ends with whitespace (common in currency like "$ 100" or "100 $")
            if innerContent.first?.isWhitespace == true || innerContent.last?.isWhitespace == true {
                return false
            }
            
            // Check if this looks like a currency amount
            // Currency patterns typically have: $<number><optional decimal><optional unit/word>
            // Example: $3.9, $3.9 trillion, $4
            if isCurrencyPattern(innerContent) {
                return false
            }
        }
        
        // Check if the content contains typical LaTeX/math syntax
        if containsMathSyntax(innerContent) {
            return true
        }
        
        // For non-inline equations ($$, \[, etc.), be more lenient
        if !kind.inline {
            return true
        }
        
        // For inline equations, require at least some indication of math
        // Allow if content has: backslashes, braces, typical math symbols, or superscript/subscript
        return innerContent.contains { char in
            char == "\\" || char == "{" || char == "}" || 
            char == "^" || char == "_" || char == "=" ||
            char == "+" || char == "-" || char == "*" || char == "/" ||
            char == "(" || char == ")" || char == "[" || char == "]"
        }
    }
    
    /// Checks if the content matches common currency patterns
    private func isCurrencyPattern(_ content: any StringProtocol) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        
        // Check if it starts with a digit (like "3.9 trillion")
        guard let firstChar = trimmed.first else { return false }
        
        if firstChar.isNumber {
            // This looks like a currency amount if it contains only:
            // - numbers, dots, commas (for formatting)
            // - optional spaces and common currency-related words
            let contentStr = String(trimmed)
            let mathFreeContent = contentStr.replacingOccurrences(of: #"\d"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            // If after removing numbers and punctuation, we only have common currency words or nothing
            let currencyWords = ["trillion", "billion", "million", "thousand", "k", "m", "b", "t"]
            let words = mathFreeContent.lowercased().split(separator: " ")
            
            // If it has no words left, or only currency-related words, treat as currency
            if mathFreeContent.isEmpty || words.allSatisfy({ currencyWords.contains(String($0)) }) {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if the content contains typical LaTeX/math syntax
    private func containsMathSyntax(_ content: any StringProtocol) -> Bool {
        let mathCommands = ["\\frac", "\\sqrt", "\\sum", "\\int", "\\prod", "\\lim", 
                           "\\alpha", "\\beta", "\\gamma", "\\delta", "\\theta",
                           "\\left", "\\right", "\\begin", "\\end", "\\text",
                           "\\mu", "\\nu", "\\sigma", "\\pi", "\\mathbf"]
        
        let contentStr = String(content)
        return mathCommands.contains { contentStr.contains($0) }
    }
}

extension MathParser {
    public struct MathRepresentation: Sendable, Hashable {
        public var kind: Kind
        public var range: Range<String.Index>
    }
}

extension MathParser.MathRepresentation {
    public enum Kind: Hashable, Sendable, CaseIterable {
        /// An inline equation component.
        ///
        /// - Example: `$x^2$`
        case inlineEquation
        
        /// An inline equation component.
        ///
        /// - Example: `\(x^2\)`
        case inlineParenthesesEquation
        
        /// A TeX-style block equation.
        ///
        /// - Example: `$$x^2$$`.
        case texEquation
        
        /// A block equation.
        ///
        /// - Example: `\[x^2\]`
        case blockEquation
        
        /// A named equation component.
        ///
        /// - Example: `\begin{equation}x^2\end{equation}`
        case namedEquation
        
        /// A named equation component.
        ///
        /// - Example: `\begin{equation*}x^2\end{equation*}`
        case namedNoNumberEquation
        
        /// The component's left terminator.
        var leftTerminator: String {
            switch self {
            case .inlineEquation: return "$"
            case .inlineParenthesesEquation: return "\\("
            case .texEquation: return "$$"
            case .blockEquation: return "\\["
            case .namedEquation: return "\\begin{equation}"
            case .namedNoNumberEquation: return "\\begin{equation*}"
            }
        }
        
        /// The component's right terminator.
        var rightTerminator: String {
            switch self {
            case .inlineEquation: return "$"
            case .inlineParenthesesEquation: return "\\)"
            case .texEquation: return "$$"
            case .blockEquation: return "\\]"
            case .namedEquation: return "\\end{equation}"
            case .namedNoNumberEquation: return "\\end{equation*}"
            }
        }
        
        /// Whether or not this component is inline.
        var inline: Bool {
            switch self {
            case .inlineEquation, .inlineParenthesesEquation: return true
            default: return false
            }
        }
        
        public static let allCases: [Kind] = [
            .namedNoNumberEquation,
            .namedEquation,
            .blockEquation,
            .texEquation,
            .inlineEquation,
            .inlineParenthesesEquation,
        ]
    }
}
