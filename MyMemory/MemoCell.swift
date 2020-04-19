import UIKit

class MemoCell: UITableViewCell {

    @IBOutlet weak var subject: UILabel! // 메모 제목
    @IBOutlet weak var contents: UILabel! // 메모 내용
    @IBOutlet weak var regdate: UILabel! // 등록 일자
    @IBOutlet weak var img: UIImageView! // 이미지
}
