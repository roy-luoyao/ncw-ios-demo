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
    @IBOutlet weak var iCloudButton: AppActionBotton!
    @IBOutlet weak var manuallyButton: AppActionBotton!
    
    private lazy var viewModel = { BackupViewModel(self, actionType) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfBackupExist()
        configureUI()
    }
    
    private func checkIfBackupExist() {
        if actionType is Backup {
            showActivityIndicator()
            viewModel.checkIfBackupExist()
        }
    }
    
    private func configureUI() {
        self.navigationItem.title = actionType.viewControllerTitle
        titleLabel.text = actionType.explanation
        googleDriveButton.config(title: actionType.googleTitle, image: AssetsIcons.googleIcon.getIcon(), style: .Secondary)
        iCloudButton.config(title: actionType.iCloudTitle, image: AssetsIcons.appleIcon.getIcon(), style: .Secondary)
        manuallyButton.config(title: actionType.manuallyTitle, image: AssetsIcons.save.getIcon(), style: .Secondary)
    }
    
    @IBAction func driveBackupTapped(_ sender: AppActionBotton) {
        authenticateUser()
    }
    
    @IBAction func iCloudBackupTapped(_ sender: AppActionBotton) {
        actionType.performICloudAction()
    }
    
    @IBAction func goBackTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @MainActor
    @IBAction func manuallyBackupTapped(_ sender: AppActionBotton) {
        Task {
            showActivityIndicator()
            let vc = ManuallyInputViewController()
            vc.manuallyInputStrategy = await viewModel.getManuallyInputStrategy()
            hideActivityIndicator()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func authenticateUser() {
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
                print("Authentication failed with: \(String(describing: error?.localizedDescription)).")
                return
            }
            
            guard let gidUser = result?.user else {
                print("GIDGoogleUser is nil")
                return
            }
            
            actionType.performDriveAction(gidUser)
        }
    }
    
    private func navigateToBackupStatusViewController() {
        let vc = BackupStatusViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToBackupDetailsViewController(_ backupData: BackupData) {
        let vc = BackupDetailsViewController()
        vc.delegate = self
        vc.backupData = backupData
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
            if let backupData = backupData {
                self.navigateToBackupDetailsViewController(backupData)
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
    func backupToGoogleDrive(_ gidUser: GIDGoogleUser) {
        showActivityIndicator()
        viewModel.backupToGoogleDrive(gidUser)
    }
    
    func backupToICloud() {
        showActivityIndicator()
        viewModel.backupToICloud()
    }
    
    func recoverFromGoogleDrive(_ gidUser: GIDGoogleUser) {
        showActivityIndicator()
        viewModel.recoverFromGoogleDrive(gidUser)
    }
    
    func recoverFromICLoud() {
        showActivityIndicator()
        viewModel.recoverFromICloud()
    }
}

extension BackupViewController: UpdateBackupDelegate {
    func updateBackupToGoogleDrive() {
        driveBackupTapped(AppActionBotton())
    }
    
    func updateBackupToICloud() {
        iCloudBackupTapped(AppActionBotton())
    }
    
    func updateBackupToExternal() {
        manuallyBackupTapped(AppActionBotton())
    }

}

