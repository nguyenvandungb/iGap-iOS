/*
 * This is the source code of iGap for iOS
 * It is licensed under GNU AGPL v3.0
 * You should have received a copy of the license in this archive (see LICENSE).
 * Copyright © 2017 , iGap - www.iGap.net
 * iGap Messenger | Free, Fast and Secure instant messaging application
 * The idea of the RooyeKhat Media Company - www.RooyeKhat.co
 * All rights reserved.
 */

import UIKit
import SwiftyRSA
import CryptoSwift

enum IGCipherMethod {
    case AES
}

class IGSecurityManager: NSObject {
    static let sharedManager = IGSecurityManager()
    
    private var symmetricKey                = ""
    private var encryptedSymmetricKeyData   = Data()
    private var publicKey             : String    = ""
    private var symmetricIVSize       : Int       = 0
    private var encryptoinKeySize     : Int       = 128
    private var encryptoinBlockMode   : BlockMode = .CBC
    private var encryptoinPaddingType : Padding   = PKCS7()
    
    private override init() {
        super.init()
    }
    
    func setConnecitonPublicKey(_ publicKey :String) {
        self.publicKey = removeSpecialCharacters(pemString: publicKey)
    }
    
    func generateEncryptedSymmetricKeyData(length :Int) -> Data {
        symmetricKey = IGGlobal.randomString(length: length)
        print("symmetricKey: \(symmetricKey)")
        do {
            let symmetricKeyData = symmetricKey.data(using: .utf8)
            encryptedSymmetricKeyData = try encrypt(rawData: symmetricKeyData!) //SwiftyRSA.encryptData(symmetricKeyData!, publicKeyPEM: publicKey)
        } catch  {
            print(error)
        }
        return encryptedSymmetricKeyData
    }
    
    func setSymmetricIVSize(_ size: Int) {
        symmetricIVSize = size
    }
    
    func setEncryptionMethod(_ method: String) {
        var methodSections = method.components(separatedBy: "-")
        //AES-128-CBC
        encryptoinKeySize = Int(methodSections[1])!
        let blockMode : String = methodSections[2]
        switch blockMode {
        case "ECB":
            encryptoinBlockMode = .ECB
        case ".CBC":
            encryptoinBlockMode = .CBC
        case "PCBC":
            encryptoinBlockMode = .PCBC
        case "CFB":
            encryptoinBlockMode = .CFB
        case "OFB":
            encryptoinBlockMode = .OFB
        case "CTR":
            encryptoinBlockMode = .CTR
        default:
            encryptoinBlockMode = .CBC
        }
    }
    
    func encryptAndAddIV(payload :Data) -> Data {
        var encryptedData :Data
        var IVBytes :Data
        var encryptedPayload : Data
        do {
            IVBytes = generateIV()
            encryptedPayload = try encrypt(rawData: payload, iv: IVBytes)
        } catch  {
            return Data()
        }
        encryptedData = IVBytes
        encryptedData.append(encryptedPayload)
            
        return encryptedData
    }
    
    func decrypt(encryptedData :Data) -> Data {
        var decryptedData = Data()
        do {
            decryptedData = try decryptUsingAES(encryptedData: encryptedData)
            return decryptedData
        } catch  {
            
        }
        return Data()
    }
    
    //MARK: private functions
    
    
    private func removeSpecialCharacters(pemString : String) -> String {
        return pemString.replacingOccurrences(of: "\r", with: "")
    }
    
    private func encrypt(rawData :Data) throws -> Data {
        return try SwiftyRSA.encryptData(rawData, publicKeyPEM: publicKey)
    }
    
    private func encrypt(rawData :Data, iv: Data) throws -> Data {
        let keyData = symmetricKey.data(using: .utf8)!
        let aes = try AES(key: [UInt8](keyData), iv: [UInt8](iv), blockMode: encryptoinBlockMode, padding: encryptoinPaddingType)
        let ciphered = try aes.encrypt(rawData)
        return Data(bytes: ciphered)
    }
    
    private func generateIV() -> Data {
        let IVData = IGGlobal.randomString(length: symmetricIVSize).data(using: .utf8)!
        return IVData
    }
    
    private func decryptUsingAES(encryptedData :Data) throws -> Data {
        let convertedData = NSData(data: encryptedData)
        let iv =  convertedData.subdata(with: NSMakeRange(0, symmetricIVSize))
        let encryptedPayload = convertedData.subdata(with: NSMakeRange(symmetricIVSize, convertedData.length-symmetricIVSize))
        
        let keyData = symmetricKey.data(using: .utf8)!
        let aes = try AES(key: [UInt8](keyData), iv: [UInt8](iv), blockMode: encryptoinBlockMode, padding: encryptoinPaddingType)
        
        let deciphered = try aes.decrypt(encryptedPayload)
        return Data(bytes: deciphered)
    }
}

extension String {
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
}
