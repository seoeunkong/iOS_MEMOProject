//
//  MemoData.swift
//  MyMemory
//
//  Created by 꼼꼼한재은님 on 2020/04/19.
//  Copyright © 2020 꼼꼼한재은님. All rights reserved.
//

import UIKit
import CoreData

class MemoData {
    var memoIdx: Int? // 데이터 식별값
    var title: String? // 메모 제목
    var contents: String? // 메모 내용
    var image: UIImage? // 이미지
    var regdate: Date? // 작성일
    var objectID: NSManagedObjectID?
}
