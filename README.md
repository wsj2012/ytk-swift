# ytk-swift
### ytknetwork of swift verion，Combined with Alarmofire usage，Implementing network requests



## Basic Examples

* pod 'ytk-swift'
* Create new class extends from YTKRequest

```
import UIKit

class GetRequest: YTKRequest {
    
    override func requestUrl() -> String {
        return "http://www.weather.com.cn/data/sk/101190408.html"
    }
    
    override func requestMethod() -> YTKBaseRequest.YTKRequestMethod {
        return .GET
    }
    
    //不要缓存的话下面两个方法可不用重写
    override var ignoreCache: Bool {
        return false
    }
    
    override func cacheTimeInSeconds() -> Int? {
        return 24 * 60 * 60
    }
    
}

```

* Test

```
import UIKit

class ViewController: UIViewController {
    
    lazy var actionBtn: UIButton = {
        let btn = UIButton.init(type: .roundedRect)
        btn.frame = CGRect(x: 0, y: 0, width: 150, height: 60)
        btn.center = view.center
        btn.backgroundColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Send Request", for: .normal)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview(actionBtn)
        actionBtn.addTarget(self, action: #selector(loadData), for: .touchUpInside)
    }


    //network  demo
    @objc func loadData() {
        
        view.makeToastActivity(.center)
        DispatchQueue.main.asyncAfter(deadline: .now()+2, execute:
            {
            	// loadCache
//                let request: GetRequest = GetRequest()
//                request.loadCacheWithSuccess(success: { (request) in
//                    print("\(request.responseString)")
//                    self.view.hideToastActivity()
//                })
                // loadData from network
                let request: GetRequest = GetRequest()
                request.startWithCompletionBlockWithSuccess(success: { (request) in
                    print("\(request.responseString)")
                    self.view.hideToastActivity()
                }) { (request) in
                    self.view.hideToastActivity()
                    self.view.makeToast("网络异常或返回数据异常")
                }
        })

    }
    

}
```
