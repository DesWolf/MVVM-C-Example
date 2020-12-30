//
//  ViewController.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/8/20.
//

import UIKit
import RxSwift
import RxCocoa

protocol LoginView: class, WindowTransitioner {
    var viewModel: LoginViewModelType! { get set }
    var moduleAssembly: ModuleAssemblyType! { get set }
}

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextFiesd: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    public var viewModel: LoginViewModelType!
    private let disposeBag = DisposeBag()
    
    internal var moduleAssembly: ModuleAssemblyType!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTextFiels()
    }
    
    @IBAction func loginTap(_ sender: Any) {
        guard let vc = try? moduleAssembly.assembledView(for: .secondPage)  else { return }
        transition(to: vc, completion: nil)
    }
    
    private func setupTextFiels() {
        userNameTextField.becomeFirstResponder()
        
        userNameTextField.rx.text.map { $0 ?? ""}.bind(to: viewModel.usernameTextPublishSubject).disposed(by: disposeBag)
        passwordTextFiesd.rx.text.map { $0 ?? ""}.bind(to: viewModel.passwordTextPublishSubject).disposed(by: disposeBag)
        
        viewModel.isValid().bind(to: loginButton.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isValid().map { $0 ? 1 : 0.1 }.bind(to: loginButton.rx.alpha).disposed(by: disposeBag)
    }
}

extension LoginViewController: LoginView {}
