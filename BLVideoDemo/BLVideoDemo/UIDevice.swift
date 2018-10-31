//
//  UIDevice.swift
//  FXChat
//
//  Created by Kinglin on 2018/1/24.
//  Copyright © 2018年 PengZhihao. All rights reserved.
//

import Foundation

extension UIDevice {
    //                  W       H
    // iphone XS Max:  414.0, 896.0
    // iphone XR    :  414.0, 896.0
    // iphone XS    :  375.0, 812.0
    // iphone X     :  375.0, 812.0
    @objc static func iPhoneX() -> Bool {
        let maxVaule:CGFloat = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        return maxVaule >= 812
    }
    
    static func isiPhone5_SE() -> Bool {
        if UIScreen.main.bounds.width == 320 || UIScreen.main.bounds.height == 568{
            return true 
        }
        return false
    }
    
    static func isiPhoneXOriPhoneXS() -> Bool {
        if UIScreen.main.bounds.width == 375 || UIScreen.main.bounds.height == 812{
            return true
        }
        return false
    }
    
    static func isiPhoneXROriPhoneXSMax() -> Bool {
        if UIScreen.main.bounds.width == 414 || UIScreen.main.bounds.height == 896{
            return true
        }
        return false
    }
    
    /// 返回屏幕像素大小 如 640*960
    static func ScreenImageSizePixel() -> String {
        var result = "320*480"
        let width = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let height = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        switch (width, height) {
        case (320, 480):
            result = "640*960"
        case (320, 568):
            result = "640*1136"
        case (375, 667):
            result = "750*1334"
        case (414, 736):
            result = "1242*2208"
        case (375, 812):
            result = "1125*2436"
        case (414, 896):
            result = "1242*2688"
        default:
            break
        }
        return result
    }
    
    /// 获取APP version
    static func currentAppVersion() -> String{
        if let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String {
            return currentVersion
        }
        return ""
    }
    
    static func deviceName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1":                               return "iPhone 7 (CDMA)"
        case "iPhone9,3":                               return "iPhone 7 (GSM)"
        case "iPhone9,2":                               return "iPhone 7 Plus (CDMA)"
        case "iPhone9,4":                               return "iPhone 7 Plus (GSM)"
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}
