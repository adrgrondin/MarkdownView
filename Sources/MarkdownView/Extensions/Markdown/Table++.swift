//
//  Table++.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2025/4/17.
//

import Markdown
import SwiftUI

extension Markdown.Table.Cell {
    var cellAlignment: CellAlignment {
        guard parent is any TableCellContainer else { return .leading }
        
        let columnIdx = self.indexInParent
        var currentElement = parent
        while currentElement != nil {
            if currentElement is Markdown.Table {
                let alignment = (currentElement as! Markdown.Table).columnAlignments[columnIdx]
                switch alignment {
                case .center: return .center
                case .left: return .leading
                case .right: return .trailing
                case .none: return .leading
                }
            }
            
            currentElement = currentElement?.parent
        }
        
        return .leading
    }
    
    var horizontalAlignment: HorizontalAlignment {
        cellAlignment.horizontalAlignment
    }
    
    var textAlignment: TextAlignment {
        cellAlignment.textAlignment
    }
    
    enum CellAlignment {
        case leading
        case center
        case trailing
        
        var textAlignment: TextAlignment {
            switch self {
            case .leading: .leading
            case .center: .center
            case .trailing: .trailing
            }
        }
        
        var horizontalAlignment: HorizontalAlignment {
            switch self {
            case .leading: .leading
            case .center: .center
            case .trailing: .trailing
            }
        }
    }

}
