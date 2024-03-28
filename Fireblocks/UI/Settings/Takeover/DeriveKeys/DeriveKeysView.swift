//
//  DeriveKeysView.swift
//  NCW-sandbox
//
//  Created by Dudi Shani-Gabay on 06/03/2024.
//

import SwiftUI
import FireblocksSDK

struct DeriveKeysView: View {
    @StateObject var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Text(viewModel.title)
                    .font(.body1)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 16)
                List {
                    ForEach(viewModel.sortedPrivateKeys(), id: \.self) { keyData in
                        if let algorithm = keyData.algorithm?.rawValue {
                            if let privateKey = keyData.privateKey {
                                Section(algorithm) {
                                    AssetCell(privateKey: privateKey, copyTextTitle: viewModel.getKeysTitle(algorithm: algorithm), copiedText: $viewModel.copiedText) {
                                        HStack {
                                            Text(viewModel.getKeysTitle(algorithm: algorithm))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                        }
                                    }
                                }
                                .listRowSeparator(.hidden)
                            }
                            
                            if algorithm != Algorithm.MPC_EDDSA_ED25519.rawValue {
                                if let items = viewModel.items[algorithm] {
                                    ForEach(items, id: \.assetSummary) { item in
                                        if let asset = item.assetSummary.asset, let privateKey = item.privateKey {
                                            Section {
                                                AssetCell(privateKey: privateKey, copyTextTitle: asset.name, copiedText: $viewModel.copiedText) {
                                                    DerivedAssetRow(asset: asset)
                                                }
                                                
                                                if let wif = item.wif {
                                                    AssetCell(privateKey: wif, copyTextTitle: asset.name, copiedText: $viewModel.copiedText) {
                                                        HStack {
                                                            Text("WIF")
                                                                .foregroundStyle(.secondary)
                                                            Spacer()
                                                        }
                                                    }
                                                }
                                            }
                                            .listRowSeparator(.hidden)

                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listRowSeparator(.hidden)
                Spacer()
                
            }
            .padding(.vertical, 24)
            
            VStack(spacing: 0) {
                Spacer()
                Label {
                    Text("\(viewModel.copiedText ?? "") Key  Copied")
                } icon: {
                    Image(systemName: "checkmark")
                }
                .padding(16)
                .background(AssetsColors.gray1.color())
                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                .opacity(viewModel.copiedText == nil ? 0 : 1)
                
            }
            .padding(.vertical, 24)
            
        }
        .animation(.default, value: viewModel.copiedText)
        .navigationTitle(viewModel.navigationBarTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AssetCell<Content: View>: View {
    let privateKey: String
    let copyTextTitle: String
    @Binding var copiedText: String?
    @State var isExposed: Bool = false
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                content
                Spacer()
                
                Image(uiImage: AssetsIcons.copy.getIcon())
                    .imageScale(.large)
                    .onTapGesture {
                        copiedText = copyTextTitle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if copiedText == copyTextTitle {
                                copiedText = nil
                            }
                        }
                        UIPasteboard.general.string = privateKey
                        
                    }
                
                Image(uiImage: isExposed ?  AssetsIcons.eye.getIcon() : AssetsIcons.eyeCrossedOut.getIcon())
                    .imageScale(.large)
                    .onTapGesture {
                        withAnimation {
                            isExposed.toggle()
                        }
                    }
            }
            
            HStack {
                if !isExposed {
                    SecureField("", text: .constant(privateKey))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .disabled(true)
                        .multilineTextAlignment(.leading)
                    
                } else {
                    Text(privateKey)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .multilineTextAlignment(.leading)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AssetsColors.gray2.color(), lineWidth: 1)
            )
            
        }


    }
}

//#Preview {
//    DeriveKeysView(viewModel: DeriveKeysView.ViewModel(privateKeys: ["XXXX"]))
//}
