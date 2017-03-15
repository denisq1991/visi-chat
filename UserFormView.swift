//
//  UserFormView.swift
//  nv-comms
//
//  Created by Denis Quaid on 15/03/2017.
//  Copyright © 2017 dquaid. All rights reserved.
//

import Foundation
import UIKit

protocol UserFormDelegate {
    func saveUser(name: String, email: String)
}

class UserFormView : UIView {
    
    @IBOutlet var userNameTextField: UITextField?
    @IBOutlet var emailTextField: UITextField?
    @IBOutlet var sumbmitButton: UIButton?
    
    var delegate: UserFormDelegate?
    
    func willMoveToSuperview(newSuperview: UIView) {
        super.willMove(toSuperview: newSuperview)
        
    }

    
    @IBAction func didAddNewUser(sender: Any) {
        guard let userName: String = self.userNameTextField?.text,
            let emailAddress: String = self.emailTextField?.text else {
                return
        }
        
        self.delegate?.saveUser(name: userName, email: emailAddress)
    }
    
}
