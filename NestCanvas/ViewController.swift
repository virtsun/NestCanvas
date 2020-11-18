//
//  ViewController.swift
//  NestCanvas
//
//  Created by 孙兰涛 on 2020/11/18.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubview(NestView(frame: self.view.bounds))
    }


}

