#if os(macOS) || os(iOS)
import SwiftUI
import Testing
#if os(macOS)
import AppKit
#else
import UIKit
#endif
@testable import MarkdownView

@Suite("Markdown Table Viewport", .serialized)
struct MarkdownTableViewportTests {
    @Test("Short tables fit the inner viewport as padding and width change",
          arguments: TableStyle.allCases, [false, true])
    @MainActor
    func shortTablesFitViewport(style: TableStyle, valueModifier: Bool) async throws {
        try await checkViewport(style: style, valueModifier: valueModifier, wide: false)
    }

    @Test("Wide tables remain wider than the viewport",
          arguments: TableStyle.allCases, [false, true])
    @MainActor
    func wideTablesStillOverflow(style: TableStyle, valueModifier: Bool) async throws {
        try await checkViewport(style: style, valueModifier: valueModifier, wide: true)
    }

    @MainActor
    private func checkViewport(style: TableStyle, valueModifier: Bool, wide: Bool) async throws {
        let measurements = Measurements()
        func root(width: CGFloat, padding: CGFloat) -> TableHost {
            TableHost(width: width, padding: padding, style: style,
                      valueModifier: valueModifier, wide: wide, measurements: measurements)
        }
        #if os(macOS)
        _ = NSApplication.shared
        let host = NSHostingView(rootView: root(width: 400, padding: 0))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 160),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        window.alphaValue = 0
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        #else
        let host = UIHostingController(rootView: root(width: 400, padding: 0))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 160))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        #endif

        // Keep the same hosted view alive: wrapper updates must not leave a stale minimum width.
        for (width, padding): (CGFloat, CGFloat) in [(400, 0), (400, 20), (320, 20), (320, 8)] {
            host.rootView = root(width: width, padding: padding)
            let expectedViewport = width - 2 * padding
            try await MarkdownViewTestSupport.waitUntil {
                abs(measurements.viewport - expectedViewport) < 1 &&
                (wide ? measurements.content > expectedViewport :
                    abs(measurements.content + 2 * MarkdownTableLayout.outerPadding - expectedViewport) < 1)
            }
            #expect(abs(measurements.viewport - expectedViewport) < 1)
            if wide {
                #expect(measurements.content > measurements.viewport)
            } else {
                #expect(abs(measurements.content + 2 * MarkdownTableLayout.outerPadding - measurements.viewport) < 1)
            }
        }
    }

    enum TableStyle: CaseIterable, Sendable {
        case standard, github, grid
    }
}

@MainActor
private final class Measurements {
    var viewport: CGFloat = 0
    var content: CGFloat = 0
}

private struct TableHost: View {
    var width: CGFloat
    var padding: CGFloat
    var style: MarkdownTableViewportTests.TableStyle
    var valueModifier: Bool
    var wide: Bool
    var measurements: Measurements

    private var table: some View {
        MarkdownTable(table: .init(headerCells: (0..<(wide ? 4 : 1)).map { _ in
            .init(horizontalAlignment: .leading, textAlignment: .leading, colspan: 1,
                  content: Text(wide ? String(repeating: "Wide content ", count: 12) : "Short"))
        }, bodyRows: []))
        .markdownTableStyle(MeasuredStyle(style: style, measurements: measurements))
    }

    var body: some View {
        Group {
            if valueModifier {
                table.markdownHorizontalScrollViewModifier(
                    MeasuredScrollPadding(padding: padding, measurements: measurements)
                )
            } else {
                table.markdownHorizontalScrollViewModifier { scroll in
                    scroll.onWidthChange { measurements.viewport = $0 }
                        .padding(.horizontal, padding)
                }
            }
        }
        .frame(width: width, height: 160)
    }
}

private struct MeasuredScrollPadding: ViewModifier, Equatable {
    var padding: CGFloat
    var measurements: Measurements

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.padding == rhs.padding && lhs.measurements === rhs.measurements
    }

    func body(content: Content) -> some View {
        content.onWidthChange { measurements.viewport = $0 }
            .padding(.horizontal, padding)
    }
}

private struct MeasuredStyle: MarkdownTableStyle {
    var style: MarkdownTableViewportTests.TableStyle
    var measurements: Measurements

    func makeBody(configuration: Configuration) -> some View {
        styledTable(configuration: configuration)
            .onWidthChange { measurements.content = $0 }
    }

    @ViewBuilder
    private func styledTable(configuration: Configuration) -> some View {
        switch style {
        case .standard: DefaultMarkdownTableStyle().makeBody(configuration: configuration)
        case .github: GithubMarkdownTableStyle().makeBody(configuration: configuration)
        case .grid: GridMarkdownTableStyle().makeBody(configuration: configuration)
        }
    }
}
#endif
