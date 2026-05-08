//
//  MarkdownRendererConfiguration.Math.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/4/16.
//

import Foundation

extension MarkdownRendererConfiguration {
    struct Math: Sendable, Hashable {
        var shouldRender: Bool {
            get { displayMathStorage != nil }
            set(enabled) {
                if enabled {
                    displayMathStorage = [:]
                } else {
                    displayMathStorage = nil
                }
            }
        }
        var displayMathStorage: [UUID : String]? = nil
        
        mutating func appendDisplayMath(_ displayMath: some StringProtocol) -> UUID {
            appendDisplayMath(displayMath, id: UUID())
        }
        
        mutating func appendDisplayMath(_ displayMath: some StringProtocol, id: UUID) -> UUID {
            if displayMathStorage == nil {
                displayMathStorage = [:]
            }
            
            displayMathStorage![id] = String(displayMath)
            return id
        }
    }
}
