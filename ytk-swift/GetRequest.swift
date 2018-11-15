//
//  GetRequest.swift
//  YTKNetwork-Swift
//
//  Created by liuhongnian on 9/19/17.
//  Copyright © 2017 liuhongnian. All rights reserved.
//

import UIKit

class GetRequest: YTKRequest {
    
    override init() {
//        YTKNetworkConfig.sharedConfig.baseUrl = "http://www.weather.com.cn/data/sk/101190408.html"
    }
    
    override func requestUrl() -> String {
        return "http://www.weather.com.cn/data/sk/101190408.html"
    }
    
    override func requestMethod() -> YTKBaseRequest.YTKRequestMethod {
        return .GET
    }
    
    override var ignoreCache: Bool {
        return false
    }
    
    override func cacheTimeInSeconds() -> Int? {
        return 24 * 60 * 60
    }
    
}
