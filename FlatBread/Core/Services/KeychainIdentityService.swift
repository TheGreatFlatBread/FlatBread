//
//  KeychainIdentityService.swift
//  FlatBread
//
//  Created by Gemini on 12/3/25.
//

import Foundation
import Security
import CommonCrypto

// MARK: - Identity Service Protocol
/// MPC(MultipeerConnectivity) 통신에 사용할 암호화된 신원(Identity)을 제공하는 기능에 대한 추상화 프로토콜.
protocol IdentityServiceProvider {
    /// 통신에 사용할 `SecIdentity`와 인증서 배열을 반환.
    /// - Returns: `SecIdentity`와 `SecCertificate`를 포함하는 배열, 또는 생성/로드 실패 시 `nil`.
    func getIdentity() -> [Any]?
}


// MARK: - Keychain Identity Service Implementation
/// `IdentityServiceProvider`의 구현체.
/// `Security` 프레임워크를 사용하여 키체인에서 신원을 로드하거나, 없을 경우 새로 생성하여 저장.
final class KeychainIdentityService: IdentityServiceProvider {

    // NOTE: Capability에서 'Keychain Sharing'을 추가해야 함.
    private let keychainIdentityTag = "com.flatbread.identity"

    /// 키체인에서 영구적인 `SecIdentity`를 로드하거나, 없을 경우 새로 생성하여 반환.
    func getIdentity() -> [Any]? {
        let tag = keychainIdentityTag.data(using: .utf8)!

        // 1. 키체인에서 기존 Identity 검색
        let query: [String: Any] = [
            // kSecClass: 검색할 항목의 종류. kSecClassIdentity는 개인키와 인증서가 쌍으로 이루어진 신원 객체를 의미.
            kSecClass as String: kSecClassIdentity,
            // kSecAttrApplicationTag: 앱 내에서 데이터를 고유하게 식별하기 위한 이름표.
            kSecAttrApplicationTag as String: tag,
            // kSecReturnRef: 검색 결과를 실제 객체 참조(Reference)로 반환하도록 요청.
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        
        // SecItemCopyMatching: query 딕셔너리에 정의된 조건으로 키체인에서 항목을 검색하는 C언어 함수.
        // &item: C언어 스타일의 'in-out' 파라미터입니다. Swift의 'inout' 키워드와 유사한 개념으로,
        //        함수가 실행된 후 이 변수에 검색 결과(SecIdentity 객체)가 채워져서 나옴.
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess {
            print("기존 인증서 로드 성공")
            let identity = item as! SecIdentity
            
            var certificate: SecCertificate?
            // SecIdentityCopyCertificate: SecIdentity 객체에서 인증서(SecCertificate) 부분만 추출하는 C 함수.
            SecIdentityCopyCertificate(identity, &certificate)
            
            if let cert = certificate {
                // MPC는 신원 객체와 인증서 객체를 배열로 전달받아야 함.
                return [identity, cert]
            }
        }
        
        // errSecItemNotFound: 키체인에서 항목을 찾지 못했을 때 반환되는 정상적인 에러 코드.
        guard status == errSecItemNotFound else {
            print("키체인 에러: \(status)")
            return nil
        }
        
        print("기존 인증서 없음, 새로 생성함")

        // 2. 새 키 쌍 생성
        let keyGenQuery: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA, // 키 종류: RSA
            kSecAttrKeySizeInBits as String: 2048,         // 키 길이: 2048 비트
            // kSecPrivateKeyAttrs: 생성될 개인키에 대한 추가 속성
            kSecPrivateKeyAttrs as String: [
                // kSecAttrIsPermanent: 이 키를 키체인에 영구적으로 저장할지 여부.
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag
            ]
        ]
        
        var error: Unmanaged<CFError>?
        // SecKeyCreateRandomKey: 위 조건에 맞는 새로운 개인키/공개키 쌍을 생성하는 C 함수.
        // &error: 함수 실행 중 에러가 발생하면 여기에 에러 정보가 담김.
        guard let privateKey = SecKeyCreateRandomKey(keyGenQuery as CFDictionary, &error) else {
            // .takeRetainedValue(): C언어 객체의 소유권을 Swift로 가져오면서 메모리 관리를 Swift가 맡게 됨.
            print("키 생성 실패: \(error!.takeRetainedValue())")
            return nil
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            print("공개키 생성 실패")
            return nil
        }

        // 3. 자체 서명 인증서 생성 및 저장
        guard let certificate = createSelfSignedCertificate(privateKey: privateKey, publicKey: publicKey) else {
            return nil
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate, // 저장할 항목 종류: 인증서
            kSecValueRef as String: certificate, // 저장할 실제 객체
            kSecAttrApplicationTag as String: tag
        ]

        // SecItemAdd: 키체인에 새 항목을 추가하는 C 함수.
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        if addStatus != errSecSuccess && addStatus != errSecDuplicateItem {
            print("인증서 저장 실패: \(addStatus)")
            return nil
        }

        print("새 인증서 생성 및 저장 성공")
        
        // 생성된 Identity 다시 로드하여 반환 (이 때에는 키체인에 새 Identity가 저장되어 이를 반환하게 됨.)
        // 재귀 호출로 방금 저장된 Identity를 로드.
        return getIdentity()
    }
    
    private func createSelfSignedCertificate(privateKey: SecKey, publicKey: SecKey) -> SecCertificate? {
        let oidSHA256WithRSA = "1.2.840.113549.1.1.11"
        let oidCommonName = "2.5.4.3"

        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data else {
            print("공개키 데이터 변환 실패")
            return nil
        }
        
        let subjectOrIssuer: [ASN1Node] = [
            .sequence(nodes: [ .set(nodes: [ .sequence(nodes: [ .objectIdentifier(oid: oidCommonName), .utf8String(string: "FlatBread User") ]) ]) ])
        ]
        
        let validity: [ASN1Node] = [ .utcTime(date: Date()), .utcTime(date: Date().addingTimeInterval(365 * 24 * 60 * 60)) ]

        let tbsCertificate: [ASN1Node] = [
            .version(2), .integer(1), .sequence(nodes: [.objectIdentifier(oid: oidSHA256WithRSA)]),
            .sequence(nodes: subjectOrIssuer), .sequence(nodes: validity), .sequence(nodes: subjectOrIssuer),
            .node(from: publicKeyData)
        ]
        
        guard let tbsData = try? ASN1Encoder.encode(nodes: [.sequence(nodes: tbsCertificate)]) else {
            print("TBS 데이터 인코딩 실패"); return nil
        }
        
        var tbsHash = [UInt8](repeating: 0, count: 32)
        // CC_SHA256, CC_LONG: C언어로 작성된 CommonCrypto 라이브러리의 함수들입니다.
        // tbsData의 바이트 주소와 길이를 받아 SHA256 해시를 계산하고 결과를 tbsHash 변수에 채웁니다.
        tbsData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(tbsData.count), &tbsHash)
        }
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, Data(tbsHash) as CFData, &error) as? Data else {
            print("TBS 데이터 서명 실패: \(error!.takeRetainedValue())"); return nil
        }

        let finalCertificate: [ASN1Node] = [
            .sequence(nodes: tbsCertificate), .sequence(nodes: [.objectIdentifier(oid: oidSHA256WithRSA)]), .bitString(data: signature, trailingBits: 0)
        ]

        guard let finalCertData = try? ASN1Encoder.encode(nodes: [.sequence(nodes: finalCertificate)]) else {
            print("최종 인증서 데이터 인코딩 실패"); return nil
        }
        
        guard let certificate = SecCertificateCreateWithData(nil, finalCertData as CFData) else {
            print("DER 데이터로 SecCertificate 객체 생성 실패"); return nil
        }
        
        return certificate
    }
}


// MARK: - ASN.1/DER Encoding Helper
// 자체 서명 인증서를 생성하기 위해 필요한 ASN.1 구조를 만들고 DER로 인코딩하는 헬퍼.
fileprivate enum ASN1Error: Error { case encodingFailed }
fileprivate enum ASN1Node {
    case sequence(nodes: [ASN1Node]); case set(nodes: [ASN1Node]); case integer(Int); case bitString(data: Data, trailingBits: Int)
    case objectIdentifier(oid: String); case utf8String(string: String); case utcTime(date: Date); case version(Int); case node(from: Data)

    var tag: UInt8 {
        switch self {
        case .sequence: return 0x30; case .set: return 0x31; case .integer: return 0x02; case .bitString: return 0x03
        case .objectIdentifier: return 0x06; case .utf8String: return 0x0C; case .utcTime: return 0x17; case .version: return 0xA0
        case .node: return 0x00
        }
    }
}
fileprivate class ASN1Encoder {
    static func encode(nodes: [ASN1Node]) throws -> Data {
        var data = Data(); for node in nodes { data.append(try encode(node: node)) }; return data
    }

    private static func encode(node: ASN1Node) throws -> Data {
        switch node {
        case .sequence(let n): return try encode(tag: node.tag, nodes: n)
        case .set(let n): return try encode(tag: node.tag, nodes: n)
        case .integer(let v):
            var int = v, data = Data()
            while int > 0 { data.insert(UInt8(int & 0xFF), at: 0); int >>= 8 }
            if (data.first ?? 0x00) & 0x80 != 0 { data.insert(0x00, at: 0) }
            if data.isEmpty { data.append(0) }; return try encodeLength(data.count, into: Data([node.tag])) + data
        case .bitString(let d, let t): var data = Data([UInt8(t)]); data.append(d); return try encodeLength(data.count, into: Data([node.tag])) + data
        case .objectIdentifier(let o):
            let parts = o.split(separator: ".").map { Int($0)! }; var data = Data(); data.append(UInt8(parts[0] * 40 + parts[1]))
            for i in 2..<parts.count {
                var val = parts[i], buffer = [UInt8](); buffer.insert(UInt8(val & 0x7F), at: 0); val >>= 7
                while val > 0 { buffer.insert(UInt8(val & 0x7F | 0x80), at: 0); val >>= 7 }
                data.append(contentsOf: buffer)
            }
            return try encodeLength(data.count, into: Data([node.tag])) + data
        case .utf8String(let s): let data = s.data(using: .utf8)!; return try encodeLength(data.count, into: Data([node.tag])) + data
        case .utcTime(let d):
            let f = DateFormatter(); f.dateFormat = "yyMMddHHmmss'Z'"; f.timeZone = TimeZone(secondsFromGMT: 0)
            let data = f.string(from: d).data(using: .ascii)!; return try encodeLength(data.count, into: Data([node.tag])) + data
        case .version(let v): let d = try encode(node: .integer(v)); return try encodeLength(d.count, into: Data([node.tag])) + d
        case .node(let d): return d
        }
    }
    
    private static func encode(tag: UInt8, nodes: [ASN1Node]) throws -> Data {
        let content = try encode(nodes: nodes); return try encodeLength(content.count, into: Data([tag])) + content
    }

    private static func encodeLength(_ length: Int, into data: Data) throws -> Data {
        var data = data
        if length < 128 { data.append(UInt8(length)) } 
        else {
            let lengthData = withUnsafeBytes(of: length.bigEndian) { Data($0) }.drop { $0 == 0 }
            data.append(UInt8(lengthData.count | 0x80)); data.append(contentsOf: lengthData)
        }
        return data
    }
}
