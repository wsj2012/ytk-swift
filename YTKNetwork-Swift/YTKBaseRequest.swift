//
//  YTKBaseRequest.swift
//  YZTAILawyer
//
//  Created by 王树军(金融壹账通客户端研发团队) on 2018/11/14.
//  Copyright © 2018 yzt. All rights reserved.
//

import UIKit

typealias YTKRequestCompletionBlock = (YTKBaseRequest) -> ()

open class YTKBaseRequest: NSObject {
    
    enum YTKRequestSerializerType: NSInteger {
        case HTTP = 0
        case JSON
    }
    
    enum YTKResponseSerializerType: NSInteger {
        case HTTP
        case JSON
        case XMLParser
    }
    
    public enum YTKRequestMethod {
        case GET
        case POST
        case HEAD
        case PUT
        case DELETE
        case PATCH
    }
    
    enum YTKRequestPriority {
        case YTKRequestPriorityLow
        case YTKRequestPriorityDefault
        case YTKRequestPriorityHight
    }
    var requestPriority: YTKRequestPriority = .YTKRequestPriorityDefault
    
    var requestTask: URLSessionTask?
    
    public var currentRequest: URLRequest{
        get{
            return requestTask!.currentRequest!
        }
    }
    public var originalRequest: URLRequest{
        get{
            return requestTask!.originalRequest!
        }
    }
    
    fileprivate var _response: HTTPURLResponse?
    public var response: HTTPURLResponse {
        get{
            return _response!
        }
    }
    fileprivate var _responseData: Data?
    public var responseData: Data {
        get{
            return _responseData!
        }
    }
    
    fileprivate var _responseString: String?
    public var responseString: String {
        get{
            return _responseString!
        }
    }
    
    fileprivate var _responseObject: AnyObject?
    public var responseObject: AnyObject{
        get{
            return _responseObject!
        }
    }
    
    fileprivate var _error: NSError?
    public var error: NSError{
        get{
            return _error!
        }
    }
    
    var successCompletionBlock: ((YTKBaseRequest) -> ())?
    var failureCompletionBlock: ((YTKBaseRequest) -> ())?
    
    /************************************************************************/
    open var ignoreCache: Bool {
        get {
            return true
        }
    }
    
    /************************************************************************/
    
    public override init() {
        successCompletionBlock = {_ in }
        failureCompletionBlock = {_ in }
        
        self.requestTask = nil
        self._response = nil
        self._responseData = nil
        self._responseString = nil
        self._responseObject = nil
        self._error = nil
        super.init()
    }
    
    func clearCompletionBlock() {
        self.successCompletionBlock = nil
        self.failureCompletionBlock = nil
    }
    
    func start() {
        //通知外部请求即将开始
        YTKNetworkAgent.sharedAgent.add(request: self)
    }
    
    func stop() {
        YTKNetworkAgent.sharedAgent.cancelAllRequests()
    }
    
    func loadCache() {
        
    }
    
    public func startWithCompletionBlockWithSuccess(success: @escaping (YTKBaseRequest) -> (),
                                                    failure: @escaping (YTKBaseRequest) -> ())
    {
        
        self.successCompletionBlock = success
        self.failureCompletionBlock = failure
        
        self.start()
        
    }
    
    public func loadCacheWithSuccess(success: @escaping (YTKBaseRequest) -> ()) {
        self.successCompletionBlock = success
        self.loadCache()
    }
    
    //MARK: Subclass Override
    func requestCompletePreprocessor() {
        
    }
    
    func requestCompleteFilter() {
        
    }
    
    //MARK: - 子类复写方法
    
    ///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseUrl`.
    open func requestUrl() -> String {
        return ""
    }
    
    ///  Optional CDN URL for request.
    open func cndUrl() -> String {
        return ""
    }
    ///  Requset timeout interval. Default is 60s.
    
    open func requestTimeoutInterval() -> TimeInterval {
        return 60
    }
    
    open func requestArgument() -> [String :Any]? {
        return nil
    }
    
    func cacheFileNameFilterForRequest(argument: Any) -> Any {
        return argument
    }
    
    open func requestMethod() -> YTKRequestMethod {
        return YTKRequestMethod.GET
    }
    
    func requestHeaderFieldDictionary() -> Dictionary<String, String>? {
        return nil
    }
    
    /*****************************************************************/
    
    func requestSerializerType() -> YTKRequestSerializerType {
        return .HTTP
    }
    
    func responseSerializerType() -> YTKResponseSerializerType {
        return .JSON
    }
    
    func requestAuthorizationHeaderFieldArray() -> Array<String>? {
        return nil
    }
    
    func requestHeaderFieldValueDictionary() -> [String: String]? {
        return nil
    }
    
    func buildCustomUrlRequest() -> URLRequest? {
        return nil
    }
    
    func useCDN() -> Bool {
        return false
    }
    
    func allowsCellularAccess() -> Bool {
        return true
    }
    
    /*****************************************************************/

    func jsonValidator() -> Any? {
        return nil
    }
}

class ChangeValue {
    
    class func changeResponse(_ response: HTTPURLResponse, forRequest: YTKBaseRequest) {
        forRequest._response = response
    }
    
    class func changeResponseData(_ data: Data, forRequest: YTKBaseRequest) {
        forRequest._responseData = data
    }
    
    class func changeResponseString(_ str: String, forRequest: YTKBaseRequest) {
        
        forRequest._responseString = str
    }
    
    class func changeResponseObject(_ obj: AnyObject, forRequest: YTKBaseRequest) {
        forRequest._responseObject = obj
    }
}
