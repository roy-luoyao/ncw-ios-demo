//
//  BackupViewController.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 25/06/2023.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST_Drive
import FirebaseAuth
import CloudKit

class BackupViewController: UIViewController{
    
    static let identifier = "BackupViewController"
    
    lazy var actionType: BackupViewControllerStrategy = { Backup(delegate: self) }()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var googleDriveButton: AppActionBotton!
    @IBOutlet weak var googleDriveContainerHC: NSLayoutConstraint!
    @IBOutlet weak var iCloudButton: AppActionBotton!
    @IBOutlet weak var iCloudDriveContainerHC: NSLayoutConstraint!
    @IBOutlet weak var tryAgainButton: AppActionBotton!
    @IBOutlet weak var tryAgainContainerHC: NSLayoutConstraint!
    
    private lazy var viewModel = { BackupViewModel(self, actionType, self) }()

    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfBackupExist()
        configureUI()
    }
    
    func updateSourceView(didComeFromGenerateKeys: Bool = false) {
        viewModel.didComeFromGenerateKeys = didComeFromGenerateKeys
    }
    
    private func checkIfBackupExist() {
        tryAgainContainerHC.constant = 0
        tryAgainButton.layoutIfNeeded()
        showActivityIndicator()
        viewModel.checkIfBackupExist()
    }
    
    private func configureUI() {
        self.navigationItem.title = actionType.viewControllerTitle
        titleLabel.text = actionType.explanation
        if actionType is Backup {
            googleDriveButton.config(title: actionType.googleTitle, image: AssetsIcons.googleIcon.getIcon(), style: .Secondary)
            iCloudButton.config(title: actionType.iCloudTitle, image: AssetsIcons.appleIcon.getIcon(), style: .Secondary)
        } else {
            googleDriveContainerHC.constant = 0
            iCloudDriveContainerHC.constant = 0
            navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(settingsTapped))]
        }
    }
    
    @objc func settingsTapped(){
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func driveBackupTapped(_ sender: AppActionBotton) {
        showActivityIndicator()
        if actionType is Recover {
            recoverFromGoogleDrive()
        } else {
            Task {
                let passphraseInfo = await viewModel.getPassphraseInfo(location: .GoogleDrive)
                authenticateUser(passphraseId: passphraseInfo.passphraseId) { _ in
                }
            }
        }
    }
    
    @IBAction func iCloudBackupTapped(_ sender: AppActionBotton) {
        showActivityIndicator()
        Task {
            let passphraseInfo = await viewModel.getPassphraseInfo(location: .iCloud)
            actionType.performICloudAction(passphraseId: passphraseInfo.passphraseId)
        }
    }
    
    @IBAction func tryAgainTapped(_ sender: AppActionBotton) {
        checkIfBackupExist()
    }
    
    @IBAction func goBackTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func authenticateUser(passphraseId: String, callback: @escaping (String) -> ()) {
        guard let gidConfig = viewModel.getGidConfiguration() else {
            print("❌ BackupViewController, gidConfig is nil.")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = gidConfig
        GIDSignIn.sharedInstance.signIn(
            withPresenting: self,
            hint: nil,
            additionalScopes: viewModel.getGoogleDriveScope()
        ) { [unowned self] result, error in
            
            guard error == nil else {
                hideActivityIndicator()
                print("Authentication failed with: \(String(describing: error?.localizedDescription)).")
                return
            }
            
            guard let gidUser = result?.user else {
                hideActivityIndicator()
                print("GIDGoogleUser is nil")
                return
            }
            
            actionType.performDriveAction(gidUser, passphraseId: passphraseId, callback: callback)
        }
    }
    
    private func navigateToBackupStatusViewController() {
        let vc = BackupStatusViewController(didComeFromGenerateKeys: viewModel.didComeFromGenerateKeys)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToAssetsViewController() {
        if let window = view.window {
            let rootViewController = UINavigationController()
            let vc = TabBarViewController()
            rootViewController.pushViewController(vc, animated: true)
            window.rootViewController = rootViewController
        }
        
    }
    
    private func showError(message: String) {
        showAlert(description: message, edgePadding: 16)
    }
}

extension BackupViewController: BackupDelegate {
    func isBackupExist(_ backupData: BackupData?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.hideActivityIndicator()
            if actionType is Backup {
                if let backupData = backupData {
                    UIView.animate(withDuration: 0.3) {
                        self.titleLabel.attributedText = self.viewModel.getBackupDetails(backupData: backupData)
                    }
                }
            } else {
                if let backupData = backupData, let location = backupData.location {
                    if location == BackupProvider.GoogleDrive.rawValue {
                        googleDriveButton.config(title: actionType.googleTitle, image: AssetsIcons.googleIcon.getIcon(), style: .Secondary)
                        googleDriveContainerHC.constant = 58.0
                    } else if location == BackupProvider.iCloud.rawValue {
                        iCloudButton.config(title: actionType.iCloudTitle, image: AssetsIcons.appleIcon.getIcon(), style: .Secondary)
                        iCloudDriveContainerHC.constant = 58.0
                    }
                    self.view.layoutIfNeeded()
                } else {
                    tryAgainButton.config(title: actionType.tryAgainTitle, style: .Secondary)
                    tryAgainContainerHC.constant = 58.0
                    showError(message: LocalizableStrings.failedToRecoverWallet)
                }
            }
        }
    }
    
    func isBackupSucceed(_ isSucceed: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.hideActivityIndicator()
            if isSucceed {
                self.navigateToBackupStatusViewController()
            } else {
                self.showError(message: LocalizableStrings.failedToCreateKeyBackup)
            }
        }
    }
    
    func isRecoverSucceed(_ isSucceed: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.hideActivityIndicator()
            if isSucceed {
                self.navigateToAssetsViewController()
            } else {
                self.showError(message: LocalizableStrings.failedToRecoverWallet)
            }
        }
    }
}

extension BackupViewController: BackupProviderDelegate {
    func backupToGoogleDrive(_ gidUser: GIDGoogleUser, passphraseId: String) {
        showActivityIndicator()
        viewModel.backupToGoogleDrive(gidUser, passphraseId: passphraseId)
    }
    
    func backupToICloud(passphraseId: String) {
        showActivityIndicator()
        viewModel.backupToICloud(passphraseId: passphraseId)
    }
    
    func recoverFromGoogleDrive() {
        showActivityIndicator()
        Task {
            let isSucceeded = await viewModel.recoverMpcKeys(recoverProvider: .GoogleDrive)
            DispatchQueue.main.async {
                self.isRecoverSucceed(isSucceeded)
            }
        }
    }
    
    func recoverFromGoogleDrive(_ gidUser: GIDGoogleUser, passphraseId: String, callback: @escaping (String) -> ()) {
        showActivityIndicator()
        viewModel.recoverFromGoogleDrive(gidUser, passphraseId: passphraseId, callback: callback)
    }
    
    func recoverFromICLoud() {
        showActivityIndicator()
        Task {
            let isSucceeded = await viewModel.recoverMpcKeys(recoverProvider: .iCloud)
            DispatchQueue.main.async {
                self.isRecoverSucceed(isSucceeded)
            }
        }
    }
}

extension BackupViewController: UpdateBackupDelegate {
    func updateBackupToGoogleDrive() {
        Task {
            let passphraseInfo = await viewModel.getPassphraseInfo(location: .GoogleDrive)
            authenticateUser(passphraseId: passphraseInfo.passphraseId) { _ in
            }
        }
    }
    
    func updateBackupToICloud() {
        iCloudBackupTapped(AppActionBotton())
    }
    
}

extension BackupViewController: ResolveRecoverDelegate {
    func recover(passphraseId: String, provider: BackupProvider, callback: @escaping (String) -> ()) {
        switch provider {
        case .iCloud:
            actionType.performICloudAction(passphraseId: passphraseId)
        case .GoogleDrive:
            DispatchQueue.main.async {
                self.authenticateUser(passphraseId: passphraseId, callback: callback)
            }
        }
    }
}
