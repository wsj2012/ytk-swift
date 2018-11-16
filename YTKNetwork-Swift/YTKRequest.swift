//
//  YTKRequest.swift
//  YZTAILawyer
//
//  Created by 王树军(金融壹账通客户端研发团队) on 2018/11/14.
//  Copyright © 2018 yzt. All rights reserved.
//

import UIKit


let YTKRequestCacheErrorDomain = "com.yuantiku.request.caching"
let YTKRequestCacheErrorExpired = -1
let YTKRequestCacheErrorVersionMismatch = -2
let YTKRequestCacheErrorSensitiveDataMismatch = -3
let YTKRequestCacheErrorAppVersionMismatch = -4
let YTKRequestCacheErrorInvalidCacheTime = -5
let YTKRequestCacheErrorInvalidMetadata = -6
let YTKRequestCacheErrorInvalidCacheData = -7


public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    public class func once(token: String, block:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

class YTKCacheMetadata:NSObject, NSSecureCoding {
    
    var version: String?
    var sensitiveDataString: String?
    var stringEncoding: CFStringEncoding
    var creationDate: Date?
    var appVersionString: String?
    
    static var supportsSecureCoding: Bool {
        get {
            return true
        }
    }
    
    override init() {
        self.stringEncoding = CFStringBuiltInEncodings.UTF8.rawValue
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.version, forKey: "version")
        aCoder.encode(self.sensitiveDataString, forKey: "sensitiveDataString")
        aCoder.encode(self.stringEncoding, forKey: "stringEncoding")
        aCoder.encode(self.creationDate, forKey: "creationDate")
        aCoder.encode(self.appVersionString, forKey: "appVersionString")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.version = aDecoder.decodeObject(forKey: "version") as? String
        self.sensitiveDataString = aDecoder.decodeObject(forKey: "sensitiveDataString") as? String
        self.stringEncoding = (aDecoder.decodeObject(forKey: "stringEncoding") as? CFStringEncoding)!
        self.creationDate = aDecoder.decodeObject(forKey: "creationDate") as? Date
        self.appVersionString = aDecoder.decodeObject(forKey: "appVersionString") as? String
        super.init()
    }
    
}

class YTKRequest: YTKBaseRequest {
    
    var cacheData: Data?
    var cacheString: String?
    var cacheJSON: AnyObject?
    var cacheXML: XMLParser?
    var cacheMetadata: YTKCacheMetadata?
    var dataFromCache: Bool = false
    
    override func start() {
        //是否忽略缓存
        
        //有未完成的下载文件吗
        
        //尝试加载缓存
        if self.ignoreCache {
            self.startWithoutCache()
            return
        }
        
        if self.loadCacheWithError(error: nil) == false {
            self.startWithoutCache()
            return
        }
        
        super.start()
        
        dataFromCache = true
        
    }
    
    override func requestCompletePreprocessor() {
        super.requestCompletePreprocessor()
        if self.writeCacheAsynchronously()! {
            DispatchQueue.once(token: "com.yuantiku.ytkrequest.caching") {
                self.saveResponseDataToCacheFile(data: super.responseData)
            }
        }else {
            self.saveResponseDataToCacheFile(data: super.responseData)
        }
    }
    
    override func loadCache() {
        if self.ignoreCache == false && self.loadCacheWithError(error: nil) == true{
            DispatchQueue.main.async {
                let strongSelf: YTKRequest = self
                if let block = strongSelf.successCompletionBlock {
                    block(strongSelf)
                }
            }
        }
    }
    
    //MARK: -
    
    func isDataFromCache() -> Bool? {
        return self.dataFromCache
    }
    
    func responseData() -> Data? {
        if let cacheData = self.cacheData {
            return cacheData
        }
        return super.responseData
    }
    
    func responseString() -> String? {
        if let cacheString = self.cacheString {
            return cacheString
        }
        return super.responseString
    }
    
    func responseObject() -> Any? {
        if let cacheJson = self.cacheJSON {
//            ChangeValue.changeResponseObject(cacheJson, forRequest: self)
            return cacheJson
        }
        if let cacheXML = self.cacheXML {
//            ChangeValue.changeResponseObject(cacheXML, forRequest: self)
            return cacheXML
        }
        if let cacheData = self.cacheData {
//            ChangeValue.changeResponseObject(cacheData as AnyObject, forRequest: self)
            return cacheData
        }
        return super.responseObject
    }
    
    //MARK: -
    
    func loadCacheWithError(error: NSError?) -> Bool? {
        
        var ptr = unsafeBitCast(error, to: NSError.self)
        if self.cacheTimeInSeconds()! < 0 {
            if error != nil {
                ptr = NSError(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorInvalidCacheTime, userInfo: [NSLocalizedDescriptionKey : "Invalid cache time"])
            }
            return false
        }
        
        if self.loadCacheMetadata()! == false {
            if error != nil {
                ptr = NSError(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorInvalidMetadata, userInfo: [NSLocalizedDescriptionKey: "Invalid metadata. Cache may not exist"])
            }
            return false
        }
        
        if self.validateCache(with: error)! == false {
            return false
        }
        
        if self.loadCacheData()! == false {
            if error != nil {
                ptr = NSError(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorInvalidCacheData, userInfo: [NSLocalizedDescriptionKey: "Invalid cache data"])
            }
            return false
        }
        else {
            ChangeValue.changeResponseData(self.responseData()!, forRequest: self)
            ChangeValue.changeResponseString(self.responseString()!, forRequest: self)
            ChangeValue.changeResponseObject(self.responseObject()! as AnyObject, forRequest: self)
        }
        
        return true
    }
    
    private func validateCache(with error: NSError?) -> Bool? {
        let creationDate: Date? = self.cacheMetadata?.creationDate
        let duration = -(creationDate?.timeIntervalSinceNow)!
        
        var ptr = unsafeBitCast(error, to: NSError.self)
        
        if duration < 0 || duration > Double(self.cacheTimeInSeconds()!) {
            if error != nil {
                ptr = NSError(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorExpired, userInfo: [NSLocalizedDescriptionKey: "Cache expired"])
            }
            return false
        }
        
        let cacheVersionFileContent = self.cacheMetadata?.version
        if cacheVersionFileContent != self.cacheVersion() {
            if error != nil {
                ptr = NSError.init(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorVersionMismatch, userInfo: [NSLocalizedDescriptionKey: "Cache version mismatch"])
            }
            return false
        }
        
        let sensitiveDataString: String? = self.cacheMetadata?.sensitiveDataString
        let currentSensitiveDataString: String? = ((self.cacheSensitiveData() ?? "") as! NSObject).description
        if sensitiveDataString != nil && currentSensitiveDataString != nil {
            if sensitiveDataString?.count != currentSensitiveDataString?.count || sensitiveDataString != currentSensitiveDataString {
                if error != nil {
                    ptr = NSError(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorSensitiveDataMismatch, userInfo: [NSLocalizedDescriptionKey: "Cache sensitive data mismatch"])
                }
                return false
            }
        }
        let appVersionString: String? = self.cacheMetadata?.appVersionString
        let currentAppVersionString: String? = YTKNetworkUtils.appVersionString()
        if appVersionString != nil || currentAppVersionString != nil {
            if appVersionString?.count != currentAppVersionString?.count || appVersionString?.caseInsensitiveCompare(currentAppVersionString!).rawValue != 0 {
                if error != nil {
                    ptr = NSError(domain: YTKRequestCacheErrorDomain, code: YTKRequestCacheErrorAppVersionMismatch, userInfo: [NSLocalizedDescriptionKey: "App version mismatch"])
                }
                return false
            }
        }
        
        return true
    }
    
    func startWithoutCache() {
        self.clearCacheVars()
        
        super.start()
    }
    
    func saveResponseDataToCacheFile(data: Data?) {
        if self.cacheTimeInSeconds()! > 0 && self.isDataFromCache() == false {
            if data != nil {
                do {
                    try data?.write(to: URL(fileURLWithPath: self.cacheFilePath()!))
                }catch let error as NSError {
                    print("write failed: \(error)")
                    return
                }
                
                let metadata = YTKCacheMetadata.init()
                metadata.version = self.cacheVersion()
                metadata.sensitiveDataString = ((self.cacheSensitiveData() ?? "") as! NSObject).description
                metadata.stringEncoding = YTKNetworkUtils.stringEncodingWithRequest(request: self)
                metadata.creationDate = Date()
                metadata.appVersionString = YTKNetworkUtils.appVersionString()
                NSKeyedArchiver.archiveRootObject(metadata as Any, toFile: self.cacheMetadataFilePath()!)
            }
        }
    }
    
    func clearCacheVars() {
        cacheData = nil
        cacheXML = nil
        cacheJSON = nil
        cacheString = nil
        cacheMetadata = nil
        dataFromCache = false
    }
    
    private func loadCacheMetadata() -> Bool? {
        let path: String = self.cacheMetadataFilePath()!
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path, isDirectory: nil) {
            cacheMetadata = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? YTKCacheMetadata
            return true
        }
        return false
    }
    
    private func loadCacheData() -> Bool? {
        let path = self.cacheFilePath()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path!, isDirectory: nil) {
            
            var data = Data.init()
            do {
                try data = Data(contentsOf: URL(fileURLWithPath: path!))
            }catch let error as NSError{
                print("error : \(error)")
                return false
            }
            cacheData = data
            cacheString = String(data: cacheData!, encoding: String.Encoding(rawValue: UInt((self.cacheMetadata?.stringEncoding)!)))
            switch self.responseSerializerType() {
            case .HTTP: return true
            case .JSON:
                do {
                    try
                        cacheJSON = JSONSerialization.jsonObject(with: cacheData!, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as AnyObject
                    return true
                }catch let error as NSError{
                    print("error: \(error)")
                    return false
                }
            case .XMLParser:
                cacheXML = XMLParser.init(data: cacheData!)

            return true
            }
        }
        return false
    }
    
    
    //MARK: - Subclass Override
    func cacheTimeInSeconds() -> Int? {
        return -1
    }
    
    func cacheVersion() -> String {
        return "0"
    }
    
    func cacheSensitiveData() -> Any? {
        return nil
    }
    
    func writeCacheAsynchronously() -> Bool? {
        return true
    }
    
    //MARK: -
    func createDirectoryIfNeeded(path: String) {
        let fileManager = FileManager.default
        var isdir: ObjCBool = ObjCBool(false)
        if fileManager.fileExists(atPath: path, isDirectory: &isdir) == false {
           try! self.createBaseDirectoryAtPath(path: path)
        }else {
            if isdir.boolValue == false {
                try! fileManager.removeItem(atPath: path)
                try! self.createBaseDirectoryAtPath(path: path)
            }
        }
    }
    
    private func createBaseDirectoryAtPath(path: String) throws {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }catch let errors as NSError {
            print("create cache directory failed, error = \(errors)")
            return
        }
        
        YTKNetworkUtils.addDoNotBackupAttribute(path: path)
    }
    
    func cacheBasePath() -> String {
        let pathOfLibrary: String = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        var path = pathOfLibrary.appending("/LazyRequestCache")
        let filters:[YTKCacheDirPathFilterProtocol] = YTKNetworkConfig.sharedConfig.cacheDirPathFilters
        if filters.count > 0 {
            for f:YTKCacheDirPathFilterProtocol in filters {
                path = f.filterCacheDirPath(originPath: path, request: self)!
            }
        }
        self.createDirectoryIfNeeded(path: path)
        return path
    }
    
    func cacheFileName() -> String {
        let requestUrl = self.requestUrl()
        let baseUrl = YTKNetworkConfig.sharedConfig.baseUrl
        let argument = self.cacheFileNameFilterForRequest(argument: self.requestArgument() ?? [])
        let requestInfo = "Method:\(self.requestMethod()) Host:\(String(describing: baseUrl)) Url:\(requestUrl) Argument:\(argument)"
        let cacheFileName = YTKNetworkUtils.md5StringFromString(string: requestInfo)
        return cacheFileName!
    }
    
    func cacheFilePath() -> String? {
        let cacheFileName = self.cacheFileName()
        var path:String = self.cacheBasePath()
        path = path + "/" + cacheFileName
        return path
    }
    
    func cacheMetadataFilePath() -> String? {
        let cacheMetadataFileName: String = "\(String(describing: self.cacheFileName())).metadata"
        var path = self.cacheBasePath()
        path = path + "/" + cacheMetadataFileName
        return path
    }

}
