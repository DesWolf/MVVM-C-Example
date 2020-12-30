//
//  SecondPageViewController.swift
//  MVVM+C
//
//  Created by Максим Окунеев on 12/8/20.
//

import UIKit

protocol MainPageView: class, PresentingView, WindowTransitioner {
    var viewModel: MainPageViewModelType! { get set }
}

class MainPageViewController: UIViewController {
    
    @IBOutlet weak var nameTextFieldisChanged: UILabel!
    
    public var viewModel: MainPageViewModelType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("----->>> Main Page open. Data: ", viewModel.data)
    }
    
    
    
}

extension MainPageViewController: MainPageView {}
