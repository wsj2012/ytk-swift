//
//  YTKNetworkConfig.swift
//  YZTAILawyer
//
//  Created by 王树军(金融壹账通客户端研发团队) on 2018/11/8.
//  Copyright © 2018 yzt. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

protocol YTKUrlFilterProtocol {
    func filterUrl(originUrl: String, request: YTKBaseRequest) -> String?
}

protocol YTKCacheDirPathFilterProtocol {
    func filterCacheDirPath(originPath: String, request: YTKBaseRequest) -> String?
}

class YTKNetworkConfig: NSObject {
    
    var baseUrl: String?
    var cdnUrl: String?
    
    var _urlFilters: [YTKUrlFilterProtocol]
    
    var urlFilters: [YTKUrlFilterProtocol] {
        get {
            return _urlFilters
        }
    }
    var _cacheDirPathFilters:[YTKCacheDirPathFilterProtocol]
    var cacheDirPathFilters: [YTKCacheDirPathFilterProtocol] {
        get {
            return _cacheDirPathFilters
        }
    }
    
//    var securityPolicy: AFSecurityPolicy?
    var debugLogEnabled: Bool?
    var sessionConfiguration: URLSessionConfiguration?
    
    // 单例
    class var sharedConfig: YTKNetworkConfig {
        get {
            struct SingletonWrapper {
                static let singleton = YTKNetworkConfig()
            }
            return SingletonWrapper.singleton
        }
    }
    
    override init() {
        baseUrl = ""
        cdnUrl = ""
        _urlFilters = Array()
        _cacheDirPathFilters = Array()
//        securityPolicy = AFSecurityPolicy.default;
        debugLogEnabled = false
    }
    
    func addUrlFilter(filter: YTKUrlFilterProtocol) {
        _urlFilters.append(filter)
    }
    
    func clearUrlFilter() {
        _urlFilters.removeAll()
    }
    
    func addCacheDirPathFilter(filter: YTKCacheDirPathFilterProtocol) {
        _cacheDirPathFilters.append(filter)
    }
    
    func clearCacheDirPathFilter() {
        _cacheDirPathFilters.removeAll()
    }
    
    //MARK: - NSObject
    override var description: String {
        get {
            return "<\(NSStringFromClass(self.classForCoder)) : \(self)> { baseURL: \(String(describing: self.baseUrl))} { cdnURL: \(String(describing: self.cdnUrl)) }"
        }
    }
}
