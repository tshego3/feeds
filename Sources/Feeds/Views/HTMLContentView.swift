#if canImport(WebKit)
import SwiftUI
import WebKit

/// Renders HTML content in a self-sizing WKWebView styled to match the app's dark theme.
/// Used by ArticleReadingView for feeds that return HTML descriptions.
#if os(iOS)
struct HTMLContentView: UIViewRepresentable {
    let html: String
    let fontScale: Double
    @Binding var contentHeight: CGFloat
    @Environment(\.themeColors) var theme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrappedHTML, baseURL: nil)
    }
}
#elseif os(macOS)
struct HTMLContentView: NSViewRepresentable {
    let html: String
    let fontScale: Double
    @Binding var contentHeight: CGFloat
    @Environment(\.themeColors) var theme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(wrappedHTML, baseURL: nil)
    }
}
#endif

extension HTMLContentView {

    private var wrappedHTML: String {
        let baseFontSize = 18.0 * fontScale
        let isDark = theme.isDark
        let textColor = isDark ? "#E5E2E1" : "#1C1C1E"
        let linkColor = isDark ? "#FFFFFF" : "#000000"
        let headingColor = isDark ? "#FFFFFF" : "#000000"
        let quoteColor = isDark ? "#C4C7C8" : "#636366"
        let quoteBorder = isDark ? "#444748" : "#D1D1D6"
        let codeBg = isDark ? "#1C1B1B" : "#F5F5F7"
        let ruleBorder = isDark ? "#444748" : "#D1D1D6"
        let tableBorder = isDark ? "#444748" : "#D1D1D6"
        let tableHeaderBg = isDark ? "#1C1B1B" : "#F5F5F7"
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: Georgia, 'Times New Roman', serif;
                font-size: \(baseFontSize)px;
                line-height: 1.8;
                color: \(textColor);
                background: transparent;
                word-wrap: break-word;
                -webkit-text-size-adjust: none;
            }
            p { margin-bottom: 1em; }
            a { color: \(linkColor); text-decoration: underline; }
            img {
                max-width: 100%;
                height: auto;
                border-radius: 8px;
                margin: 12px 0;
            }
            blockquote {
                border-left: 3px solid \(quoteBorder);
                padding-left: 16px;
                margin: 16px 0;
                color: \(quoteColor);
                font-style: italic;
            }
            h1, h2, h3, h4, h5, h6 {
                color: \(headingColor);
                margin: 20px 0 8px 0;
                line-height: 1.3;
            }
            ul, ol { padding-left: 24px; margin-bottom: 1em; }
            li { margin-bottom: 4px; }
            pre, code {
                background: \(codeBg);
                border-radius: 4px;
                padding: 2px 6px;
                font-size: 0.9em;
            }
            pre { padding: 12px; overflow-x: auto; margin-bottom: 1em; }
            hr { border: none; border-top: 1px solid \(ruleBorder); margin: 24px 0; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 1em; }
            td, th { border: 1px solid \(tableBorder); padding: 8px; }
            th { background: \(tableHeaderBg); }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: HTMLContentView

        init(_ parent: HTMLContentView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let height = result as? CGFloat else { return }
                DispatchQueue.main.async {
                    self?.parent.contentHeight = height
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                return .allow
            }
            #if os(iOS)
            await UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
            return .cancel
        }
    }
}
#endif
