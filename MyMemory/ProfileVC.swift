//
//  ProfileVC.swift
//  MyMemory
//
//  Created by 꼼꼼한재은님 on 2020/05/02.
//  Copyright © 2020 꼼꼼한재은님. All rights reserved.
//

import UIKit
import Alamofire
import LocalAuthentication

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // API 호출 상태값을 관리할 변수
    var isCalling = false
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    let uinfo = UserInfoManager() // 개인 정보 관리 매니저
    let profileImage = UIImageView() // 프로필 사진 이미지
    let tv = UITableView() // 프로필 목록
    
    override func viewDidLoad() {
        self.navigationItem.title = "프로필"
        // 뒤로 가기 버튼 처리
        let backBtn = UIBarButtonItem(title: "닫기", style: .plain, target: self, action: #selector(close(_:)))
        self.navigationItem.leftBarButtonItem = backBtn
        
        // 배경 이미지 설정
        let bg = UIImage(named: "profile-bg")
        let bgImg = UIImageView(image: bg)
        bgImg.frame.size = CGSize(width: bgImg.frame.size.width, height: bgImg.frame.size.height)
        bgImg.center = CGPoint(x: self.view.frame.width / 2, y: 40)
        bgImg.layer.cornerRadius = bgImg.frame.size.width / 2
        bgImg.layer.borderWidth = 0
        bgImg.layer.masksToBounds = true
        
        self.view.addSubview(bgImg)
        
        // ① 프로필 사진에 들어갈 기본 이미지
        // let image = UIImage(named: "account.jpg")
        let image = self.uinfo.profile
        
        // ② 프로필 이미지 처리
        self.profileImage.image = image
        self.profileImage.frame.size = CGSize(width: 100, height: 100)
        self.profileImage.center = CGPoint(x: self.view.frame.width / 2, y: 270)
        
        // ③ 프로필 이미지 둥글게 만들기
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.layer.borderWidth = 0
        self.profileImage.layer.masksToBounds = true
        
        // ④ 루트 뷰에 추가
        self.view.addSubview(self.profileImage)
        
        // 테이블 뷰
        self.tv.frame = CGRect(x: 0,
                               y: self.profileImage.frame.origin.y + self.profileImage.frame.size.height + 20,
                               width: self.view.frame.width,
                               height: 100)
        self.tv.dataSource = self
        self.tv.delegate = self
        self.view.addSubview(self.tv)
        
        // 내비게이션 바 숨김 처리
        self.navigationController?.navigationBar.isHidden = true
        
        // 최초 화면 로딩 시 로그인 상태에 따라 적절히 로그인/로그아웃 버튼을 출력한다.
        self.drawBtn()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(profile(_:)))
        self.profileImage.addGestureRecognizer(tap)
        self.profileImage.isUserInteractionEnabled = true
        
        self.view.bringSubviewToFront(self.indicatorView) // 인디케이터 뷰를 화면 맨 앞으로
        
        // 키 체인 저장 여부 확인을 위한 임시 코드
        let tk = TokenUtils()
        if let accessToken = tk.load("kr.co.rubypaper.MyMemory", account: "accessToken") {
            print("accessToken = \(accessToken)")
        } else {
            print("accessToken is nil")
        }
        if let refreshToken = tk.load("kr.co.rubypaper.MyMemory", account: "refreshToken") {
            print("refreshToken = \(refreshToken)")
        } else {
            print("refreshToken is nil")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 토큰 인증 여부 체크
        self.tokenValidate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.accessoryType = .disclosureIndicator
        
        switch indexPath.row {
        case 0 :
            cell.textLabel?.text = "이름"
            //cell.detailTextLabel?.text = "꼼꼼한재은 씨"
            cell.detailTextLabel?.text = self.uinfo.name ?? "Login please"
        case 1 :
            cell.textLabel?.text = "계정"
            //cell.detailTextLabel?.text = "sqlpro@naver.com"
            cell.detailTextLabel?.text = self.uinfo.account ?? "Login please"
        default :
            ()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.uinfo.isLogin == false {
            // 로그인되어 있지 않다면 로그인 창을 띄워 준다.
            self.doLogin(self.tv)
        }
    }
    
    @objc func close(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
    
    @objc func doLogin(_ sender: Any) {
        if self.isCalling == true {
            self.alert("응답을 기다리는 중입니다. \n잠시만 기다려 주세요.")
            return
        } else {
            self.isCalling = true
        }
        
        let loginAlert = UIAlertController(title: "LOGIN", message: nil, preferredStyle: .alert)
        
        // 알림창에 들어갈 입력폼 추가
        loginAlert.addTextField() { (tf) in
            tf.placeholder = "Your Account"
        }
        loginAlert.addTextField() { (tf) in
            tf.placeholder = "Password"
            tf.isSecureTextEntry = true
        }
        
        // 알림창 버튼 추가
        loginAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.isCalling = false
        })
        
        loginAlert.addAction(UIAlertAction(title: "Login", style: .destructive) { (_) in
            
            // 인디케이터 실행
            self.indicatorView.startAnimating()
            
            let account = loginAlert.textFields?[0].text ?? "" // 첫 번째 필드 : 계정
            let passwd = loginAlert.textFields?[1].text ?? "" // 두 번째 필드 : 비밀번호
            
            self.uinfo.login(account: account, passwd: passwd, success: {
                // 인디케이터 종료
                self.indicatorView.stopAnimating()
                self.isCalling = false
                
                self.tv.reloadData() // 테이블 뷰를 갱신한다.
                self.profileImage.image = self.uinfo.profile // 이미지 프로필을 갱신한다.
                self.drawBtn()
                
                // 서버와 데이터 동기화
                let sync = DataSync()
                DispatchQueue.global(qos: .background).async {
                    sync.downloadBackupData() // 서버에 저장된 데이터가 있으면 내려받는다.
                }
                DispatchQueue.global(qos: .background).async {
                    sync.uploadData(self.indicatorView) // 서버에 저장해야 할 데이터가 있으면 업로드한다.
                }
                
            }, fail: { msg in
                // 인디케이터 종료
                self.indicatorView.stopAnimating()
                self.isCalling = false // 추가
                
                self.alert(msg)
            })
        })
        self.present(loginAlert, animated: false)
    }
    
    @objc func doLogout(_ sender: Any) {
        let msg = "로그아웃하시겠습니까?"
        
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { (_) in
            // 인디케이터 실행
            self.indicatorView.startAnimating()
            
            self.uinfo.logout() {
                // Logout API 호출과 logout() 실행이 모두 끝나면 인디케이터도 중지
                self.indicatorView.stopAnimating()
                
                self.tv.reloadData() // 테이블 뷰를 갱신한다.
                self.profileImage.image = self.uinfo.profile // 이미지 프로필을 갱신한다.
                self.drawBtn() // 로그인 상태에 따라 적절히 로그인/로그아웃 버튼을 출력한다.
            }
        })
        self.present(alert, animated: false)
    }
    
    func drawBtn() {
        // 버튼을 감쌀 뷰를 정의한다.
        let v = UIView()
        v.frame.size.width = self.view.frame.width
        v.frame.size.height = 40
        v.frame.origin.x = 0
        v.frame.origin.y = self.tv.frame.origin.y + self.tv.frame.height
        v.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        
        self.view.addSubview(v)
        
        // 버튼을 정의한다.
        let btn = UIButton(type: .system)
        btn.frame.size.width = 100
        btn.frame.size.height = 30
        btn.center.x = v.frame.size.width / 2
        btn.center.y = v.frame.size.height / 2
        
        // 로그인 상태일 때는 로그아웃 버튼을, 로그아웃 상태일 때에는 로그인 버튼을 만들어 준다.
        if self.uinfo.isLogin == true {
            btn.setTitle("로그아웃", for: .normal)
            btn.addTarget(self, action: #selector(doLogout(_:)), for: .touchUpInside)
        } else {
            btn.setTitle("로그인", for: .normal)
            btn.addTarget(self, action: #selector(doLogin(_:)), for: .touchUpInside)
        }
        v.addSubview(btn)
    }
    
    func imgPicker( _ source : UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true)
    }
    
    // 프로필 사진의 소스 타입을 선택하는 액션 메소드
    @objc func profile(_ sender : UIButton) {
        // 로그인되어 있지 않을 경우에는 프로필 이미지 등록을 막고 대신 로그인 창을 띄워 준다.
        guard self.uinfo.account != nil else {
            self.doLogin(self)
            return
        }
        let alert = UIAlertController(title: nil,
                                      message: "사진을 가져올 곳을 선택해 주세요",
                                      preferredStyle: .actionSheet)
        // 카메라를 사용할 수 있으면
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "카메라", style: .default) { (_) in
                self.imgPicker(.camera)
            })
        }
        // 저장된 앨범을 사용할 수 있으면
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            alert.addAction(UIAlertAction(title: "저장된 앨범", style: .default) { (_) in
                self.imgPicker(.savedPhotosAlbum)
            })
        }
        // 포토 라이브러리를 사용할 수 있으면
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "포토 라이브러리", style: .default) { (_) in
                self.imgPicker(.photoLibrary)
            })
        }
        // 취소 버튼 추가
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        // 액션 시트 창 실행
        self.present(alert, animated: true)
    }
    
    // 이미지를 선택하면 이 메소드가 자동으로 호출된다.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 인디케이터 실행
        self.indicatorView.startAnimating()
        
        if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.uinfo.newProfile(img, success: {
                // 인디케이터 종료
                self.indicatorView.stopAnimating()
                self.profileImage.image = img
            }, fail: { msg in
                // 인디케이터 종료
                self.indicatorView.stopAnimating()
                self.alert(msg)
            })
        }
        picker.dismiss(animated: true)
    }
    
    @IBAction func backProfileVC(_ segue: UIStoryboardSegue) {
        // 단지 프로필 화면으로 되돌아오기 위한 표식 역할만 할 뿐이므로
        // 아무 내용도 작성하지 않음
    }
}

extension ProfileVC {
    // 토큰 인증 메소드
    func tokenValidate() {
        // 0. 응답 캐시를 사용하지 않도록
        URLCache.shared.removeAllCachedResponses()
        
        // 1. 키 체인에 액세스 토큰이 없을 경우 유효성 검증을 진행하지 않음
        let tk = TokenUtils()
        guard let header = tk.getAuthorizationHeader() else {
            return
        }
        
        // 로딩 인디케이터 시작
        self.indicatorView.startAnimating()
        
        // 2. tokenValidate API를 호출한다.
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/tokenValidate"
        let validate = AF.request(url, method: .post, encoding: JSONEncoding.default, headers: header)
        validate.responseJSON { res in
            self.indicatorView.stopAnimating()
            
            let responseBody = try! res.result.get()
            print(responseBody) // 2-1. 응답 결과를 확인하기 위해 메시지 본문 전체를 출력
            guard let jsonObject = responseBody as? NSDictionary else {
                self.alert("잘못된 응답입니다.")
                return
            }
            // 3. 응답 결과 처리
            let resultCode = jsonObject["result_code"] as! Int //
            if resultCode != 0 { // 3-1. 응답 결과가 실패일 때, 즉 토큰이 만료되었을 때
                // 로컬 인증 실행
                self.touchID()
            }
        } // end of response closure
    } // end of func tokenValidate()
    
    // 터치 아이디 인증 메소드
    func touchID() {
        // 1. LAContext 인스턴스 생성
        let context = LAContext()
        
        // 2. 로컬 인증에 사용할 변수 정의
        var error: NSError?
        let msg = "인증이 필요합니다."
        let deviceAuth = LAPolicy.deviceOwnerAuthenticationWithBiometrics // 인증 정책
        
        // 3. 로컬 인증이 사용 가능한지 여부 확인
        if context.canEvaluatePolicy(deviceAuth, error: &error) {
            // 4. 터치 아이디 인증창 실행
            context.evaluatePolicy(deviceAuth, localizedReason: msg) { (success, e) in
                if success { // 5. 인증 성공 : 토큰 갱신 로직
                    // 5-1. 토큰 갱신 로직 실행
                    self.refresh()
                } else { // 6. 인증 실패
                    print((e?.localizedDescription)!)
                    switch (e!._code) {
                    case LAError.systemCancel.rawValue:
                        self.alert("시스템에 의해 인증이 취소되었습니다.")
                    case LAError.userCancel.rawValue:
                        self.alert("사용자에 의해 인증이 취소되었습니다.") {
                            self.commonLogout(true)
                        }
                    case LAError.userFallback.rawValue:
                        OperationQueue.main.addOperation() {
                            self.commonLogout(true)
                        }
                    default:
                        OperationQueue.main.addOperation() {
                            self.commonLogout(true)
                        }
                    }
                }
            }
        } else { // 7. 인증창이 실행되지 못한 경우
            print(error!.localizedDescription)
            switch (error!.code) {
            case LAError.biometryNotEnrolled.rawValue:
                print("터치 아이디가 등록되어 있지 않습니다.")
            case LAError.passcodeNotSet.rawValue:
                print("패스 코드가 설정되어 있지 않습니다.")
            default: // LAError.touchIDNotAvailable 포함
                print("터치 아이디를 사용할 수 없습니다.")
            }
            OperationQueue.main.addOperation() {
                self.commonLogout(true)
            }
        }
    }
    
    // 토큰 갱신 메소드
    func refresh() {
        self.indicatorView.startAnimating() // 로딩 시작
        
        // 1. 인증 헤더
        let tk = TokenUtils()
        let header = tk.getAuthorizationHeader()
        // 2. 리프레시 토큰 전달 준비
        let refreshToken = tk.load("kr.co.rubypaper.MyMemory", account: "refreshToken")
        let param: Parameters = ["refresh_token": refreshToken!]
        // 3. 호출 및 응답
        let url = "http://swiftapi.rubypaper.co.kr:2029/userAccount/refresh"
        let refresh = AF.request(url, method: .post, parameters: param,
                                        encoding: JSONEncoding.default, headers: header)
        refresh.responseJSON { res in
            self.indicatorView.stopAnimating() // 로딩 중지
            guard let jsonObject = try! res.result.get() as? NSDictionary else {
                self.alert("잘못된 응답입니다.")
                return
            }
            // 4. 응답 결과 처리
            let resultCode = jsonObject["result_code"] as! Int
            if resultCode == 0 { // 성공 : 액세스 토큰이 갱신되었다는 의미
                // 4-1. 키 체인에 저장된 액세스 토큰 교체
                let accessToken = jsonObject["access_token"] as! String
                tk.save("kr.co.rubypaper.MyMemory", account: "accessToken", value: accessToken)
            } else { // 실패 : 액세스 토큰 만료
                self.alert("인증이 만료되었으므로 다시 로그인해야 합니다.") {
                    OperationQueue.main.addOperation() {
                        self.commonLogout(true)
                    }
                }
            }
        } // end of responseJSON closure
    }
    
    func commonLogout(_ isLogin: Bool = false) {
        // 1. 저장된 기존 개인 정보 & 키 체인 데이터를 삭제하여 로그아웃 상태로 전환
        let userInfo = UserInfoManager()
        userInfo.deviceLogout()
        
        // 2. 현재의 화면이 프로필 화면이라면 바로 UI를 갱신한다.
        self.tv.reloadData() // 추가) 테이블 뷰를 갱신한다.
        self.profileImage.image = userInfo.profile // 추가) 이미지 프로필을 갱신한다.
        self.drawBtn()
        
        // 3. 기본 로그인 창 실행 여부
        if isLogin {
            self.doLogin(self)
        }
    }
}
