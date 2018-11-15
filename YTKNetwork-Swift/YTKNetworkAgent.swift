//
//  YTKNetworkAgent.swift
//  YZTAILawyer
//
//  Created by 王树军(金融壹账通客户端研发团队) on 2018/11/14.
//  Copyright © 2018 yzt. All rights reserved.
//

import UIKit
import Alamofire

class YTKNetworkAgent: NSObject {
    // 单例
    class var sharedAgent: YTKNetworkAgent {
        get {
            struct SingletonWrapper {
                static let singleton = YTKNetworkAgent()
            }
            return SingletonWrapper.singleton
        }
    }
    
    private var manager: SessionManager
    private var requestsRecord: [NSNumber : YTKBaseRequest]
    private let requestRecordQueue: DispatchQueue
    private override init() {
        
        manager = SessionManager.default
        self.requestsRecord = Dictionary()
        requestRecordQueue = DispatchQueue(label:"com.yuantiku.record_request.queue", attributes: .concurrent)
        
        super.init()
    }
    
    func add(request: YTKBaseRequest) {
        
        //生成sessionTask
        let task = self.sessionTaskFor(request: request)
        request.requestTask = task;
        
        //设置优先级
        if ((request.requestTask?.priority) != nil) {
            switch request.requestPriority {
            case .YTKRequestPriorityHight:
                request.requestTask?.priority = URLSessionTask.highPriority
            case .YTKRequestPriorityLow:
                request.requestTask?.priority = URLSessionTask.lowPriority
            default:
                request.requestTask?.priority = URLSessionTask.defaultPriority
            }
        }
        
        //保存task
        self.recordRequest(request)
    }
    
    func cancelAllRequests() {
        objc_sync_enter(self)
        let allkeys: Dictionary.Keys? = requestsRecord.keys
        objc_sync_exit(self)
        if allkeys != nil && allkeys!.count > 0 {
            let copiedKeys = allkeys
            for key in copiedKeys! {
                objc_sync_enter(self)
                let request = requestsRecord[key]
                objc_sync_exit(self)
                request?.stop()
            }
        }
    }
    
    func remove(request: YTKBaseRequest) {
        
    }
    
    private func sessionTaskFor(request: YTKBaseRequest) -> URLSessionTask {
        
        let method = request.requestMethod()
        let url = request.requestUrl()
        let param = request.requestArgument()
        let headers = request.requestHeaderFieldDictionary()
        let af_request = self.requestFor(url,
                                         method: method,
                                         httpHeaders: headers,
                                         parameters: param)
        
        return af_request.task!
        
    }
    
    private func requestFor(_ url: String,
                            method: YTKBaseRequest.YTKRequestMethod,
                            httpHeaders: Dictionary<String, String>?,
                            parameters: [String :Any]?) -> Request
    {
        var request: Request? = nil
        
        switch method {
        case .GET:
            //下载文件get
            //普通get
            request = manager.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: httpHeaders).responseData(completionHandler: { [weak self] (responseData) in
                self?.handlerRequest(request!, responseData: responseData)
            })
        case .POST:
            return manager.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: nil)
        case .HEAD:
            print()
        case .DELETE:
            print()
        case .PATCH:
            print()
        case .PUT:
            print()
        }
    
        return request!
    }
    
    private func recordRequest(_ request: YTKBaseRequest) {
        
        requestRecordQueue.async(flags: .barrier) {
            self.requestsRecord[NSNumber.init(value: (request.requestTask?.taskIdentifier)!)] = request
        }
    }
    
    private func queryRequest(_ request: Request) -> YTKBaseRequest? {
        var baseRequest = YTKBaseRequest()
        
        requestRecordQueue.sync {
            baseRequest = self.requestsRecord[NSNumber.init(value: (request.task?.taskIdentifier)!)]!
            
        }
        return baseRequest
    }
    
    private func handlerRequest(_ request: Request, responseData: DataResponse<Data>) {
        
        let window = UIApplication.shared.keyWindow
        if (responseData.error != nil) {
            //处理异常
//            ZVProgressHUD.showError(with: "网络请求异常")
            window?.rootViewController?.view.makeToast("网络请求异常")
            return
        }
        //验证数据准确性
        if responseData.response == nil {
//            HYBProgressHUD.show(status: "请求返回数据为空")
            window?.rootViewController?.view.makeToast("请求返回数据为空")
            return
        }
        
        //成功后的处理
        if self.queryRequest(request) != nil {
            let baseRequest: YTKBaseRequest = self.queryRequest(request)!
            ChangeValue.changeResponse(responseData.response ?? HTTPURLResponse(coder: NSCoder.init())!, forRequest: baseRequest)
            
            ChangeValue.changeResponseData(responseData.data!, forRequest: baseRequest)
            //data to json or xml string
            let resString = String.init(data: responseData.data!, encoding: .utf8)
            ChangeValue.changeResponseString(resString!, forRequest: baseRequest)
            
            do {
                let json = try JSONSerialization.jsonObject(with: responseData.data!, options: [])
                ChangeValue.changeResponseObject(json as AnyObject, forRequest: baseRequest)
                
            } catch let error as NSError {
                print("解析数据失败, \(error)")
            }
            
            //成功回调
            self.requestDidSuccessWithRequest(baseRequest)
        }
        
    }
    
    private func requestDidSuccessWithRequest(_ request: YTKBaseRequest) {
        //尝试缓存请求结果
        request.requestCompletePreprocessor()
        //主线程回调
        DispatchQueue.main.async {
            request.successCompletionBlock!(request)
        }
        
    }
}
