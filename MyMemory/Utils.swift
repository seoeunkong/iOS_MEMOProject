//
//  Utils.swift
//  MyMemory
//
//  Created by 꼼꼼한재은님 on 2020/05/05.
//  Copyright © 2020 꼼꼼한재은님. All rights reserved.
//

import UIKit

extension UIViewController {
    var tutorialSB: UIStoryboard {
        return UIStoryboard(name: "Tutorial", bundle: Bundle.main)
    }
    func instanceTutorialVC(name: String) -> UIViewController? {
        return self.tutorialSB.instantiateViewController(withIdentifier: name)
    }
}
