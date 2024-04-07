//
//  FeeRateViewController.swift
//  Fireblocks
//
//  Created by Fireblocks Ltd. on 04/07/2023.
//

import UIKit

class FeeRateViewController: UIViewController {

//MARK: - PROPERTIES 
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(FeeRateCell.nib, forCellReuseIdentifier: FeeRateCell.nibName)
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    @IBOutlet weak var createTransactionButton: AppActionBotton!
    
    var selectedIndexPath: IndexPath?
    let viewModel = FeeRateViewModel()
    
    //MARK: - LIFECYCLE Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        configButtons()
        viewModel.delegate = self
        viewModel.fetchFeeRates()
    }
    
    private func configButtons(){
        navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(handleCloseTap))]
        self.navigationItem.title = "Fee"
        createTransactionButton.config(title: "Create transaction", style: .Primary)
        createTransactionButton.isEnabled = viewModel.isContinueButtonEnabled()
    }
    
    @objc private func handleCloseTap() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func createTransactionTapped(_ sender: AppActionBotton) {
        showActivityIndicator(message: LocalizableStrings.feeActivityIndicatorMessage)
        viewModel.createTransaction()
    }
    
    private func navigateToApproveScreen(){
        if let transaction = viewModel.getTransaction() {
            let vc = ApproveViewController(nibName: "ApproveViewController", bundle: nil)
            vc.viewModel.transaction = transaction
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func showAlertView(){
        showAlert(
            description: LocalizableStrings.accountCreationFailed,
            bottomAnchor: createTransactionButton.topAnchor
        )
    }
}

//MARK: - UITableViewDataSource
extension FeeRateViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getFeesCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeeRateCell.nibName, for: indexPath) as? FeeRateCell  else {
            return UITableViewCell()
        }
        
        let fee = viewModel.getFees()[indexPath.row]
        let assetName = viewModel.transaction?.asset.symbol ?? ""
        cell.configCell(with: fee, assetName: assetName)
        let selectedFeeIndex = viewModel.getSelectedIndex()
        
        if indexPath.row == selectedFeeIndex {
            selectedIndexPath = indexPath
            cell.setSelected(isSelected: true)
        }
        
        return cell
    }
}

//MARK: - UITableViewDelegate
extension FeeRateViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FeeRateCell {
            cell.setSelected(isSelected: true)
        }
        
        if let selectedIndexPath = selectedIndexPath, let previousCell = tableView.cellForRow(at: selectedIndexPath) as? FeeRateCell {
            previousCell.setSelected(isSelected: false)
        }
        
        viewModel.selectFee(at: indexPath.row)
        selectedIndexPath = indexPath
        self.createTransactionButton.isEnabled = self.viewModel.isContinueButtonEnabled()
    }
}

extension FeeRateViewController: FeeRateViewModelDelegate {
    func isTransactionCreated(isCreated: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hideActivityIndicator()
            if isCreated {
                self.navigateToApproveScreen()
            } else {
                self.showAlertView()
                self.createTransactionButton.isEnabled = false
            }
        }
    }
    
    func refreshData() {
        DispatchQueue.main.async { [weak self] in
            if let self {
                self.tableView.reloadData()
                self.createTransactionButton.isEnabled = self.viewModel.isContinueButtonEnabled()
            }
        }
    }
}
