//
//  YTKNetworkPrivate.swift
//  YZTAILawyer
//
//  Created by 王树军(金融壹账通客户端研发团队) on 2018/11/8.
//  Copyright © 2018 yzt. All rights reserved.
//

import Foundation
import Alamofire
import CommonCrypto

class YTKNetworkUtils: NSObject {
    
    class func validateJSON(json: AnyObject, jsonValidator: AnyObject) -> Bool? {
        if json is [String: Any] && jsonValidator is [String: Any] {
            var dic: [String: Any] = json as! Dictionary
            var validator: [String: Any]  = jsonValidator as! [String : Any]
            var result: Bool? = true
            let enumerator = validator.keys
            
            for key in enumerator {
                let value = dic[key]
                let format: AnyObject = validator[key] as AnyObject
                if value is [String: Any] || value is [Any] {
                    result =  self.validateJSON(json: value as AnyObject, jsonValidator: format as AnyObject)
                    if result == nil {
                        break;
                    }
                }
            }
            return result
        }else if json is [AnyObject] && jsonValidator is Array<Any> {
            let validatorArray:[AnyObject] = jsonValidator as! Array
            if validatorArray.count > 0 {
                let array: [AnyObject] = json as! [AnyObject]
                let validator = (jsonValidator as! Array<Any>)[0]
                for item in array {
                    let result: Bool? = self.validateJSON(json: item, jsonValidator: validator as AnyObject)
                    if result == false {
                        return false
                    }
                }
            }
            return true
        }else if json.isKind!(of: jsonValidator as! AnyClass) {
            return true
        }else {
            return false
        }
    }
    
    class func addDoNotBackupAttribute(path: String) {
        var url: URL = URL.init(fileURLWithPath: path)
        url.setTemporaryResourceValue(NSNumber.init(value: true), forKey: .isExcludedFromBackupKey)
    }
    
    class func md5StringFromString(string: String) -> String? {
        let str = string.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(string.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        free(result)
        return String(format: hash as String)
    }
    
    class func appVersionString() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    class func stringEncodingWithRequest(request: YTKBaseRequest) -> CFStringEncoding {
        var stringEncoding = String.Encoding.utf8
        if let name = request.response.textEncodingName {
            let encoding: CFStringEncoding = CFStringConvertIANACharSetNameToEncoding(name as CFString)
            if encoding != kCFStringEncodingInvalidId {
                stringEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
            }
        }
        return CFStringEncoding(stringEncoding.rawValue)
    }
    
    class func validateResumeData(data: Data?) -> Bool? {
        guard data != nil && (data?.count)! >= 1 else {
            return false
        }
        
        do {
            let resumeDictionary: [String: AnyObject]? = try PropertyListSerialization.propertyList(from: data!, options: .init(), format: nil) as? Dictionary
            if resumeDictionary == nil {
                return false
            }
        } catch let errors as NSError{
            print("failed, error = \(errors)")
            return false
        }
        
        return true
    }
}
