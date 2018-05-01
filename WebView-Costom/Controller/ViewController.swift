//
//  ViewController.swift
//  WebView-Costom
//
//  Created by kawaharadai on 2018/04/22.
//  Copyright © 2018年 kawaharadai. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var baseView: CostomView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwordButton: UIBarButtonItem!
    @IBOutlet weak var indicetor: UIActivityIndicatorView!
    
    // MARK: - LifeCycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - Setup Methods
    
    private func setup() {
        self.baseView.delegate = self
        load(urlString: "https://qiita.com/d-kawahara")
    }
    
    // MARK: - Private Methods
    
    private func load(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("URLが不正")
            return
        }
        let request = URLRequest(url: url)
        self.baseView.webView?.load(request)
    }
    
    private func toolbarStatus() {
        self.backButton.isEnabled = self.baseView.isBack()
        self.forwordButton.isEnabled = self.baseView.isForword()
    }
    
    // MARK: - Action Methods
    
    @IBAction func back(_ sender: Any) {
        self.baseView.webView?.goBack()
    }
    
    @IBAction func forword(_ sender: Any) {
        self.baseView.webView?.goForward()
    }
    
    @IBAction func reload(_ sender: Any) {
        self.baseView.webView?.reload()
    }
}

// MARK: - CostomViewDelegate Methods

extension ViewController: CostomViewDelegate {
    
    /// webView側のデリゲートを受ける
    func webViewAction(status: LoadingStatus) {
        switch status {
        case .finish:
            self.toolbarStatus()
            self.indicetor.stopAnimating()
        case .start:
            self.indicetor.startAnimating()
        case .error(let error):
            self.indicetor.stopAnimating()
            print("エラー：\(error.localizedDescription)")
        }
    }
}
