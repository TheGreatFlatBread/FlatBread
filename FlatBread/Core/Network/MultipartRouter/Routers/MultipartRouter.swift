//
//  MultipartRouter.swift
//  FlatBread
//
//  Created by hwan on 11/5/25.
//

import Foundation
import Alamofire

enum MultipartRouter: MultipartAPIRouter {
    case updateProfile(request: UserProfileUpdateDTO)
    case uploadImages(request: ImageUploadRequestDTO)
    case uploadVideos(request: VideoUploadRequestDTO)
    
    var baseURL: URL {
        switch self {
        case .updateProfile:
            guard let url = URL(string: APIConfig.baseURL + "/users/") else {
                assert(false, "is not valid User URL")
            }
            return url
        case .uploadImages, .uploadVideos:
            guard let url = URL(string: APIConfig.baseURL + "/posts/") else {
                assert(false, "is not valid Posts URL")
            }
            return url
        }
    }

    var method: HTTPMethod {
        switch self {
        case .updateProfile:
            return .put
        case .uploadImages, .uploadVideos:
            return .post
        }
    }

    var headers: HTTPHeaders {
        switch self {
        case .updateProfile, .uploadImages, .uploadVideos:
            let headerTypes: [APIHeader] = [.multipartForm, .apiKey, .productID, .accessToken]
            return HTTPHeaders(headerTypes.map(\.httpHeader))
        }
    }

    var path: String {
        return switch self {
        case .updateProfile: "me/profile"
        case .uploadImages: "files"
        case .uploadVideos: "files"
        }
    }

    var multipartFormData: MultipartFormData {
        switch self {
        case .updateProfile(let request):
            let formData = MultipartFormData()
            if let nick = request.nick {
                formData.append(Data(nick.utf8), withName: "nick")
            }
            if let phoneNum = request.phoneNum {
                formData.append(Data(phoneNum.utf8), withName: "phoneNum")
            }
            if let birthDay = request.birthDay {
                formData.append(Data(birthDay.utf8), withName: "birthDay")
            }
            if let profileData = request.profile {
                formData.append(profileData, withName: "profile", fileName: "profile.jpg", mimeType: "image/jpeg")
            }
            if let gender = request.gender {
                formData.append(Data(gender.utf8), withName: "gender")
            }
            if let info1 = request.info1 {
                formData.append(Data(info1.utf8), withName: "info1")
            }
            if let info2 = request.info2 {
                formData.append(Data(info2.utf8), withName: "info2")
            }
            if let info3 = request.info3 {
                formData.append(Data(info3.utf8), withName: "info3")
            }
            if let info4 = request.info4 {
                formData.append(Data(info4.utf8), withName: "info4")
            }
            if let info5 = request.info5 {
                formData.append(Data(info5.utf8), withName: "info5")
            }
            return formData
            
        case .uploadImages(let request):
            let formData = MultipartFormData()
            request.files.forEach { file in
                formData.append(
                    file.data,
                    withName: "files",
                    fileName: file.fileName,
                    mimeType: file.mimeType
                )
            }
            return formData

        case .uploadVideos(let request):
            let formData = MultipartFormData()
            request.files.forEach { file in
                formData.append(
                    file.data,
                    withName: "files",
                    fileName: file.fileName,
                    mimeType: file.mimeType
                )
            }
            return formData
        }
    }

    func asURLRequest() throws -> URLRequest {
        guard let url = URL(string: self.baseURL.appendingPathComponent(self.path).absoluteString) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.method = self.method
        request.headers = self.headers
        return request
    }
}
