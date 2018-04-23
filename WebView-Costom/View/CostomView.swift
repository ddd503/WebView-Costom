//
//  CostomView.swift
//  WebView-Costom
//
//  Created by kawaharadai on 2018/04/22.
//  Copyright © 2018年 kawaharadai. All rights reserved.
//

import UIKit
import WebKit

enum LoadingStatus {
    case start
    case finish
    case error(error: Error)
}

protocol CostomViewDelegate: class {
    func webViewAction(status: LoadingStatus)
}

class CostomView: UIView {
    
    var webView: WKWebView?
    var headerView: UIView?
    weak var delegate: CostomViewDelegate?
    private let headerViewHight: CGFloat = 50
    
    // MARK: - Init Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupWebView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupWebView()
    }

    // MARK: - Setup Methods

    private func setupWebView() {
        self.webView = WKWebView(frame: .zero, configuration: setupConfiguration())
        self.webView?.navigationDelegate = self
        self.webView?.uiDelegate = self
        self.webView?.allowsBackForwardNavigationGestures = true
        self.addSubview(webView ?? WKWebView())
        self.setupConstain(webView: self.webView)
        // ヘッダービューをスクロール内に追加（遷移時のスクロール位置に関しては考慮していない）
        setHeaderView()
    }
    
    /// configに設定を加える場合はここで行う
    private func setupConfiguration() -> WKWebViewConfiguration {
        return WKWebViewConfiguration()
    }
    
    /// autolayoutを設定（4辺共に0）
    private func setupConstain(webView: WKWebView?) {
        webView?.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v0]|",
                                                           options: NSLayoutFormatOptions(),
                                                           metrics: nil,
                                                           views: ["v0": webView ?? WKWebView()]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v0]|",
                                                           options: NSLayoutFormatOptions(),
                                                           metrics: nil,
                                                           views: ["v0": webView ?? WKWebView()]))
    }
    
    func setHeaderView() {
        self.headerView?.removeFromSuperview()
        // 画面外に作成
        self.headerView = UIView(frame: CGRect(x: 0, y: -headerViewHight, width: self.frame.width, height: headerViewHight))
        self.headerView?.backgroundColor = UIColor.red
        // スクロール領域の拡張
        self.webView?.scrollView.contentInset = UIEdgeInsetsMake(headerViewHight, 0, 0, 0)
        self.webView?.scrollView.addSubview(self.headerView ?? UIView())
        // スクロール開始位置を変更
        self.webView?.scrollView.setContentOffset(CGPoint(x: 0, y: -headerViewHight), animated: false)
    }
    
    // MARK: - Private Methods
    
    func isBack() -> Bool {
        return self.webView?.canGoBack ?? false
    }
    
    func isForword() -> Bool {
        return self.webView?.canGoForward ?? false
    }
    
    
}

// MARK: - WKNavigationDelegate Methods

extension CostomView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("読み込み開始")
        self.delegate?.webViewAction(status: .start)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("読み込み完了")
        self.delegate?.webViewAction(status: .finish)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("読み込み中エラー")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("通信中のエラー")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // 読み込みを許可
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate Methods

extension CostomView: WKUIDelegate {
    /// _blank挙動対応
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        guard let url = navigationAction.request.url else {
            return nil
        }
        
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            webView.load(URLRequest(url: url))
            return nil
        }
        return nil
    }
    
    /// プレビュー表示の許可
    func webView(_ webView: WKWebView,
                 shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        
        return true
    }
    
}
