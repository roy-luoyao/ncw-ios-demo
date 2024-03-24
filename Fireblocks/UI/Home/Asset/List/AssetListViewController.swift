//
//  AssetListViewController.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 14/06/2023.
//

import UIKit
import NVActivityIndicatorView
import SwiftUI

class AssetListViewController: UIViewController {
    
    private let headerHeight: CGFloat = 240
    
    //MARK: - PROPERTIES
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    @IBOutlet weak var refreshIndicator: NVActivityIndicatorView!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var bottomErrorView: UIView!
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.register(AssetViewCell.nib, forCellReuseIdentifier: AssetViewCell.nibName)
            tableView.delegate = self
            tableView.dataSource = self
            configureRefreshControl()
        }
    }
    
    
    let viewModel = AssetListViewModel.shared
    
    //MARK: - LIFECYCLE Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        viewModel.delegate = self
        viewModel.fetchAssets()
        viewModel.listenToTransferChanges()
        activityIndicator.startAnimating()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if tableView.refreshControl?.frame != nil {
            var frame = tableView.refreshControl!.frame
            frame.origin = CGPoint(x: (frame.width - 40)/2.0, y: (frame.height - 40)/2.0)
            frame.size = CGSize(width: 40, height: 40)
            
            refreshIndicator.frame = frame
        }
    }
    
    //MARK: - FUNCTIONS
    
    private func configureRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.tintColor = .clear
        tableView.refreshControl?.backgroundColor = .clear
        refreshIndicator.translatesAutoresizingMaskIntoConstraints = true
        tableView.refreshControl?.addSubview(refreshIndicator)

        tableView.refreshControl?.addTarget(self, action: #selector(refreshAssets), for: .valueChanged)
        refreshIndicator.type = .circleStrokeSpin
        refreshIndicator.color = AssetsColors.primaryBlue.getColor()

    }
    
    private func configureView(){
        activityIndicator.type = .circleStrokeSpin
        activityIndicator.color = AssetsColors.primaryBlue.getColor()
    }
    
    @IBAction func settingsTapped(_ sender: UIButton){
        let vc = SettingsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToChooseAssetScreen(flowType: ChooseAssetFlowType) {
        let vc = ChooseAssetViewController(nibName: ChooseAssetViewController.identifier, bundle: nil)
        vc.viewModel.assets = self.viewModel.getAssets()
        vc.viewModel.chooseAssetFlowType = flowType
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func refreshAssets(){
        self.refreshIndicator.startAnimating()
        viewModel.fetchAssets()
    }

    private func showAlertView(message: String){
        showAlert(description: message, bottomAnchor: bottomErrorView.bottomAnchor)
    }

}

extension AssetListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = AssetHeaderUIView()
        header.setCurrenBalance(viewModel.getBalance())
        header.setDelegate(self)
        header.isButtonsEnabled(viewModel.getIsButtonsEnabled())
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getAssetsCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AssetViewCell.nibName, for: indexPath) as? AssetViewCell else {
            return UITableViewCell()
        }
        
        let asset = viewModel.getAssets()[indexPath.row]
        cell.configCellWith(asset: asset)
        
        return cell
    }
}

extension AssetListViewController: AssetListViewModelDelegate {
    @MainActor
    func refreshData()  {
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
            self.refreshIndicator.stopAnimating()
        }
        
    }
    
    @MainActor
    func gotError()  {
        DispatchQueue.main.async {
            self.errorView.alpha = 0
            self.errorView.isHidden = false
            self.tableView.isScrollEnabled = false
            self.activityIndicator.stopAnimating()
            self.refreshIndicator.stopAnimating()
            self.tableView.refreshControl?.endRefreshing()

            UIView.animate(withDuration: 0.3) {
                self.errorView.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.errorView.alpha = 0
                    }, completion: { finished in
                        self.errorView.isHidden = true
                        self.tableView.isScrollEnabled = true
                    })
                }

            }
        }
    }
}

extension AssetListViewController: AssetHeaderDelegate {
    @objc func sendButtonTapped(){
        navigateToChooseAssetScreen(flowType: .send)
    }
    
    @objc func receiveButtonTapped(){
        navigateToChooseAssetScreen(flowType: .receive)
    }
    
    @objc func plusButtonTapped(){
        let vc = AddAssetsViewController(devideId: FireblocksManager.shared.getDeviceId(), delegate: self)
        let nc = UINavigationController(rootViewController: vc)
        nc.isModalInPresentation = true
        self.present(nc, animated: true)
    }
}

extension AssetListViewController: AddAssetsViewControllerDelegate {
    func dismissAddAssets(addedAssets: [Asset], failedAssets: [Asset]) {
        self.dismiss(animated: true)
        if failedAssets.count > 0 {
            let prefix = failedAssets.count > 1 ? "The following assets were" : "The following asset was"
            var assets: String = ""
            failedAssets.forEach { asset in
                assets += " \(asset.symbol),"
            }
            assets.removeLast()
            self.showAlertView(message: "\(prefix) not added: \(assets).\nPlease try again\n")
        }
        if addedAssets.count > 0 {
            activityIndicator.startAnimating()
            refreshAssets()
        }
    }
}

