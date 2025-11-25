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
    
    func makeUIViewController(context: Context) -> UIViewController {
        let view = IamportPaymentViewController()
        return view
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

final class IamportPaymentViewController: UIViewController {
    
    private var didRequest = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didRequest else { return }
        didRequest = true
        requestIamportPayment()
    }
    
    // 아임포트 SDK 결제 요청
    func requestIamportPayment() {
        let userCode = "imp14511373" // iamport 에서 부여받은 가맹점 식별코드
        let payment = createPaymentData()
        
        Iamport.shared.payment(viewController: self,
                               userCode: userCode, payment: payment) { [weak self] response in
            print("결과 : \(response)")
        }
    }
    
    // 아임포트 결제 데이터 생성
    func createPaymentData() -> IamportPayment {
        return IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"), //PG사: KG이니시스
            merchant_uid: "swiftui_ios_\(Int(Date().timeIntervalSince1970))", //고유한 주문 번호
            amount: "100").then { //결제 금액
                $0.pay_method = PayMethod.card.rawValue //결제 수단
                $0.name = "SwiftUI 에서 주문입니다" //결제할 상품명
                $0.buyer_name = "SwiftUI" //주문자 이름
                $0.app_scheme = "iamporttest" // 결제 후 돌아올 앱스킴
            }
    }
}
