//
//  IamportPaymentView.swift
//  FlatBread
//
//  Created by andev on 11/25/25.
//

import SwiftUI
import iamport_ios
import Then

struct IamportPaymentView: UIViewControllerRepresentable {
    let input: IamportPaymentInput
    var onCompleted: ((IamportResponse?) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIViewController {
        let view = IamportPaymentViewController(input: input, onCompleted: onCompleted)
        return view
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

final class IamportPaymentViewController: UIViewController {
    
    private var didRequest = false
    private let input: IamportPaymentInput
    private let onCompleted: ((IamportResponse?) -> Void)?
    private let networkService: AsyncNetworkService = NetworkServiceFactory.shared.makeNetworkService()
    
    init(input: IamportPaymentInput, onCompleted: ((IamportResponse?) -> Void)? = nil) {
        self.input = input
        self.onCompleted = onCompleted
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[IMP] viewDidAppear - didRequest: \(didRequest)")
        guard !didRequest else { return }
        didRequest = true
        requestIamportPayment()
    }
    
    // 아임포트 SDK 결제 요청
    func requestIamportPayment() {
        print("[IMP] requestIamportPayment - start")
        let userCode = "imp14511373" // iamport 에서 부여받은 가맹점 식별코드
        print("[IMP] userCode: imp14511373")
        let payment = createPaymentData()
        
        Iamport.shared.payment(viewController: self,
                               userCode: userCode, payment: payment) { [weak self] response in
            if let response {
                print("[IMP] payment callback - success: \(response.success == true), imp_uid: \(response.imp_uid ?? "nil"), merchant_uid: \(response.merchant_uid ?? "nil"), error_msg: \(response.error_msg ?? "nil")")
                if response.success == true, let imp = response.imp_uid {
                    Task { [weak self] in
                        await self?.validatePayment(impUID: imp, postID: self?.input.postId ?? "")
                    }
                }
            } else {
                print("[IMP] payment callback - response is nil")
            }
            self?.onCompleted?(response)
            // 결제 화면 닫기
            self?.dismiss(animated: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self else { return }
            if self.didRequest {
                print("[IMP] Timeout: payment callback not received within 10s. If no result printed above, check URL Scheme / PG settings.")
            }
        }
    }
    
    // 아임포트 결제 데이터 생성
    func createPaymentData() -> IamportPayment {
        let timestamp = Int(Date().timeIntervalSince1970)
        let merchantUID = "\(input.postId)_\(timestamp)"
        print("[IMP] createPaymentData - merchant_uid: \(merchantUID), amount: \(input.price), name: \(input.title), buyer: \(input.buyerName)")
        return IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"), //PG사: KG이니시스
            merchant_uid: merchantUID, //고유한 주문 번호
            amount: String(input.price)
        ).then { //결제 금액
            $0.pay_method = PayMethod.card.rawValue //결제 수단
            $0.name = input.title //결제할 상품명
            $0.buyer_name = input.buyerName //주문자 이름
            $0.app_scheme = "FlatBread" // 결제 후 돌아올 앱스킴
        }
    }
    
    private func validatePayment(impUID: String, postID: String) async {
        let body = PaymentValidationRequestDTO(imp_uid: impUID, post_id: postID)
        do {
            let result = try await networkService.request(
                PaymentRouter.validatePayment(request: body),
                responseType: PaymentValidationResponseDTO.self
            )
            print("[IMP] validation 200: buyer_id=\(result.buyer_id ?? "nil"), post_id=\(result.post_id ?? "nil"), merchant_uid=\(result.merchant_uid ?? "nil"), productName=\(result.productName ?? "nil"), price=\(String(describing: result.price)), paidAt=\(result.paidAt ?? "nil")")
        } catch {
            // Try to decode error body if available
            print("[IMP] validation failed: \(error)")
        }
    }
}
