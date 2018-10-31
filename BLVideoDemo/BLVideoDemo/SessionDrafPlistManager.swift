//
//  FxPlistManager.swift
//  FXChat
//
//  Created by BaiLun on 2018/10/16.
//  Copyright © 2018 PengZhihao. All rights reserved.
//

import UIKit

@objcMembers class SessionDrafPlistManager: NSObject {
    
    static let shared = SessionDrafPlistManager()
    let plistSuffix = "plist"
    lazy var plistFolderPath: String = {
        if let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            return documentPath
        }
        return ""
    }()
    fileprivate var plistName: String!
}

// MARK: - plist文件操作
extension SessionDrafPlistManager {
    
    /// 创建一个plist文件
    ///
    /// - Parameters:
    ///   - plistName: plist文件名, xxx.plist
    ///   - isRemoved: 是否删除旧的Plist文件
    @objc func createPlist(name plistName: String, removeOld isRemoved: Bool = false) {
        // 删除存在的plist
        if  isRemoved {
            self.removePlist(name: plistName)
        }
        // 如果plist不存在，则新建
        let isPlistExist = plistExist(name: plistName)
        if !isPlistExist {
            let strs = plistName.components(separatedBy: ".")
            if let suffix = strs.last, suffix == plistSuffix {
                if let plistFilePath = self.getPlistFullPath(name: plistName) {
                    FileManager.default.createFile(atPath: plistFilePath, contents: nil, attributes: nil)
                } else {
                    print("创建文件路径失败")
                }
                
            } else {
                print("无效的plist后缀:", strs.last ?? " nil")
            }
        }
    }
    
    /// 删除一个plist文件
    ///
    /// - Parameter plistName: plist文件名
    @objc func removePlist(name plistName: String) {
        if let plistFilePath = self.getPlistFullPath(name: plistName) {
            let isPlistExist = plistExist(name: plistName)
            if isPlistExist {
                try? FileManager.default.removeItem(atPath: plistFilePath)
            }
        }
    }
    
    /// 判断plist文件是否存在
    ///
    /// - Parameter plistName: plist文件名
    /// - Returns: 是否存在
    @objc func plistExist(name plistName: String) -> Bool {
        if let filePath = self.getPlistFullPath(name: plistName)  {
            return FileManager.default.fileExists(atPath: filePath)
        }
        return false
    }
    
}

// MARK: - Plist内容操作： 增、删、查、改
extension SessionDrafPlistManager {
    
    /// 向plist文件中新增一个键值对
    ///
    /// - Parameters:
    ///   - plistName: plist文件名, xxx.plist
    ///   - value: 值
    ///   - key: 键
    func addValue(to plistName: String, value: Any, key: String) {
        if let plistFilePath = self.getPlistFullPath(name: plistName) {
            let storedDict = self.plistContentToDict(name: plistName)
            storedDict.setValue(value, forKey: key)
            let isPlistExist = self.plistExist(name: plistName)
            if isPlistExist {
                storedDict.write(toFile: plistFilePath, atomically: true)
            } else {
                self.createPlist(name: plistName)
            }
        }
    }
    
    /// 从plist中移除一个值
    ///
    /// - Parameters:
    ///   - plistName: plist文件名， xxx.plist
    ///   - key: 键
    func removeValue(from plistName: String, key: String) {
        if let plistFilePath = self.getPlistFullPath(name: plistName) {
            let storedDict = self.plistContentToDict(name: plistName)
            if storedDict.value(forKey: key) != nil {
                storedDict.removeObject(forKey: key)
                storedDict.write(toFile: plistFilePath, atomically: true)
            }
        }
    }
    
    /// 查询plist中的值
    ///
    /// - Parameters:
    ///   - plistName: plist文件名， xxx.plist
    ///   - key: 键
    func queryValue(from plistName: String, key: String) -> Any? {
        let storedDict = self.plistContentToDict(name: plistName)
        return storedDict.value(forKey: key)
    }
    
    /// 更新plist中的值
    ///
    /// - Parameters:
    ///   - plistName: plist文件名
    ///   - newValue: 新值
    ///   - key: 键
    func updateValue(to plistName: String, newValue: Any,  key: String) {
        self.addValue(to: plistName, value: newValue, key: key)
    }
}

// MARK: - 私有方法
fileprivate extension SessionDrafPlistManager {
    
    /// 获取plist的全路径
    ///
    /// - Parameter plistName: plist文件名， xxx.plist
    /// - Returns: plist全路径或nil
    func getPlistFullPath(name plistName: String) -> String? {
        guard plistName.count > 0 else {
            return nil
        }
        return String(format: "%@/%@", self.plistFolderPath, plistName)
    }
    
    /// 将plist转成字典
    ///
    /// - Parameter plistName: plist名称
    /// - Returns: 可变字典
    func plistContentToDict(name plistName: String) -> NSMutableDictionary {
        var dict = NSMutableDictionary()
        if let plistFilePath = self.getPlistFullPath(name: plistName) {
            let storedDict = NSMutableDictionary(contentsOfFile: plistFilePath)
            if nil != storedDict {
                dict = storedDict!
            }
        }
        return dict
    }
    
    
}
