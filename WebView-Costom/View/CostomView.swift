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
    var refreshControl: UIRefreshControl?
    weak var delegate: CostomViewDelegate?
    private var scrollingToTop = false
    private let headerViewHight: CGFloat = 50
    var isRefreshing = false
    private var updatingContentOffsetY = false
    private var isOverTheContentSizeHeight = false
    private var isUnderTheStartingPosition = false
    
    // MARK: - Init Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupWebView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupWebView()
    }
    
    // デリゲートを解放
    deinit {
        self.webView?.uiDelegate = nil
        self.webView?.navigationDelegate = nil
        self.webView?.scrollView.delegate = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // headerViewをscrollView内に追加
        setHeaderView()
        webView?.scrollView.delegate = self
    }
    
    // MARK: - Setup Methods
    
    private func setupWebView() {
        self.webView = WKWebView(frame: .zero, configuration: setupConfiguration())
        self.webView?.navigationDelegate = self
        self.webView?.uiDelegate = self
        self.webView?.allowsBackForwardNavigationGestures = true
        self.addSubview(webView ?? WKWebView())
        self.setupConstain(webView: self.webView)
        setPulltoRefresh()
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
    
    private func setHeaderView() {
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
    
    private func setPulltoRefresh() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "引っ張って更新")
        self.refreshControl?.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
        self.webView?.scrollView.addSubview(self.refreshControl ?? UIRefreshControl())
    }
    
    // MARK: - Private Methods
    
    func isBack() -> Bool {
        return self.webView?.canGoBack ?? false
    }
    
    func isForword() -> Bool {
        return self.webView?.canGoForward ?? false
    }
    
    @objc func pullToRefreshAction() {
        self.isRefreshing = true
        self.webView?.reload()
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
        self.delegate?.webViewAction(status: .error(error: error))
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("通信中のエラー")
        self.delegate?.webViewAction(status: .error(error: error))
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
        
        // URL型は必要ない？
        //        guard let url = navigationAction.request.url else {
        //            return nil
        //        }
        
        guard
            let targetFrame = navigationAction.targetFrame,
            targetFrame.isMainFrame else {
                webView.load(navigationAction.request)
                return nil
        }
        return nil
    }
    
    /// プレビュー表示の許可
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView,
                 shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        
        return true
    }
    
}

// MARK: - UIScrollViewDelegate

extension CostomView: UIScrollViewDelegate {
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollingToTop = true
        return true
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollingToTop = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.frame.height + scrollView.contentOffset.y > scrollView.contentSize.height {
            // bouncing
            isOverTheContentSizeHeight = true
        }
        
        if scrollView.contentOffset.y < -headerViewHight {
            // bouncing
            isUnderTheStartingPosition = true
        }
        
        // 以下の全てを満たす場合、webView.scrollViewのContentOffsetYを更新する
        // - scrollView内部のドラッグをしていない
        // - ステータスバータップによる一番上へのスクロールをしていない
        // - webView.scrollViewのContentOffsetY更新中でない
        // - scrollviewの一番下より下にいない (not bouncing)
        // - scrollviewの一番上より上にいない (not bouncing)
        let isUpdateableContentOffsetY = !scrollView.isDragging
            && !scrollingToTop
            && !updatingContentOffsetY
            && !isOverTheContentSizeHeight
            && !isUnderTheStartingPosition
        
        if isUpdateableContentOffsetY {
            
            updatingContentOffsetY = true
            
            // iOS9以下ではScrollViewによる強制的なoffsetの変更はなし
            if #available(iOS 10.0, *) {
                var newContentOffsetY: CGFloat
                if scrollView.contentOffset.y < 0 {
                    newContentOffsetY = -headerViewHight
                } else {
                    newContentOffsetY = scrollView.contentOffset.y - headerViewHight
                }
                print("newContentOffsetY: \(newContentOffsetY)")
                webView?.scrollView.setContentOffset(CGPoint(x: 0, y: newContentOffsetY), animated: false)
            }
            
            updatingContentOffsetY = false
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isOverTheContentSizeHeight = false
        isUnderTheStartingPosition = false
    }
}
