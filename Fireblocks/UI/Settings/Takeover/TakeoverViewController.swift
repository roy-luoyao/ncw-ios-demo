//
//  TakeoverViewController.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 19/07/2023.
//

import UIKit
import FireblocksSDK

class TakeoverViewController: UIViewController {

    private let viewModel = TakeoverViewModel()
    
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var errorMessageView: UIView!
    @IBOutlet weak var createBackupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Export private key"
        showPrivateKeyWarning()
        viewModel.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func createKeyTapped(_ sender: UIButton) {
        self.getTakeoverFullKeys()
    }
    
    private func getTakeoverFullKeys() {
        showActivityIndicator()
        viewModel.getTakeoverFullKeys()
    }
    
    private func navigateToDerivedKeys(_ privateKeys: [String]){
        let vc = DeriveKeysHostingVC(privateKeys: privateKeys)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showErrorMessage() {
        errorMessageView.isHidden = false
        explanationLabel.isHidden = true
    }
    
    private func showPrivateKeyWarning() {
        showAlert(
            title: LocalizableStrings.takeoverWarningTitle,
            description: LocalizableStrings.takeoverWarningDescription,
            alertType: AlertViewType.warning,
            isAnimationEnabled: false,
            bottomAnchor: createBackupButton.topAnchor
        )
    }
}

extension TakeoverViewController: TakeoverViewModelDelegate {
    func didReceiveFullKeys(fullKeys: Set<FullKey>?) {
        DispatchQueue.main.async { [weak self] in
            if let self {
                self.hideActivityIndicator()
                if let fullKeys {
                    let privateKeys = fullKeys.filter({$0.privateKey != nil}).map({$0.privateKey!})
                    self.navigateToDerivedKeys(privateKeys)
                } else {
                    self.showErrorMessage()
                }
            }
        }
    }
}
