//
//  FirstPageViewModel.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/8/20.
//

import Foundation
import RxSwift
import RxCocoa

protocol LoginViewModelType {
    // MARK: - Input
    var view: LoginView! { get set }
    
    // MARK: - Output
    var usernameTextPublishSubject: PublishSubject<String> { get set }
    var passwordTextPublishSubject: PublishSubject<String> { get set }
    func isValid() -> Observable<Bool>
}

class LoginViewModel {
    // MARK: - Input
    weak var view: LoginView!
    private let moduleAssembly: ModuleAssemblyType
    
    // MARK: - Output
    var usernameTextPublishSubject = PublishSubject<String>()
    var passwordTextPublishSubject = PublishSubject<String>()
    
    init(moduleAssembly: ModuleAssemblyType, name: String, surname: String) {
        self.moduleAssembly = moduleAssembly
    }
}

extension LoginViewModel: LoginViewModelType {
    func isValid() -> Observable<Bool> {
        Observable.combineLatest(usernameTextPublishSubject.asObserver().startWith(""), passwordTextPublishSubject.asObserver().startWith("")).map { username, password in
            return username.count > 3 && password.count > 3
        }.startWith(false)
    }
}
