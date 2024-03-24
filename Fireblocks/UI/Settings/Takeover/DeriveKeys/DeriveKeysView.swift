//
//  DeriveKeysView.swift
//  NCW-sandbox
//
//  Created by Dudi Shani-Gabay on 06/03/2024.
//

import SwiftUI
import FireblocksDev

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
                    ForEach(Array(viewModel.items.keys), id: \.self) { key in
                        if let keyData = viewModel.items[key] {
                            Section(key) {
                                ForEach(keyData, id: \.assetSummary) { item in
                                    if let asset = item.assetSummary.asset {
                                        Section {
                                            VStack(spacing: 12) {
                                                HStack(spacing: 8) {
                                                    VStack(spacing: 0) {
                                                        DerivedAssetRow(asset: asset)
                                                            .padding(4)
                                                    }
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.black)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                                                    
                                                    Text(asset.name)
                                                        .font(.body1)
                                                        .multilineTextAlignment(.leading)
                                                    Spacer()
                                                    
                                                    if let data = item.keyData?.data {
                                                        Image(uiImage: AssetsIcons.copy.getIcon())
                                                            .imageScale(.large)
                                                            .onTapGesture {
                                                                viewModel.selectedAsset = asset
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                                    if viewModel.selectedAsset?.id == asset.id {
                                                                        viewModel.selectedAsset = nil
                                                                    }
                                                                }
                                                                UIPasteboard.general.string = data
                                                                
                                                            }
                                                        
                                                        Image(uiImage: item.isExposed ?  AssetsIcons.eye.getIcon() : AssetsIcons.eyeCrossedOut.getIcon())
                                                            .imageScale(.large)
                                                            .onTapGesture {
                                                                withAnimation {
                                                                    if let index = viewModel.items[key]?.firstIndex(where: {$0.assetSummary.asset?.id == asset.id}) {
                                                                        viewModel.items[key]?[index].isExposed.toggle()
                                                                    }
                                                                }
                                                            }
                                                    }
                                                }
                                                
                                                HStack {
                                                    if let data = item.keyData?.data {
                                                        if !item.isExposed {
                                                            SecureField("", text: .constant(data))
                                                                .frame(maxWidth: .infinity)
                                                                .padding()
                                                                .disabled(true)
                                                                .multilineTextAlignment(.leading)
                                                            
                                                        } else {
                                                            Text(data)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .padding()
                                                                .multilineTextAlignment(.leading)
                                                        }
                                                    } else {
                                                        ProgressView()
                                                    }
                                                }
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(AssetsColors.gray2.color(), lineWidth: 1)
                                                )
                                                
                                                
                                            }
                                            
                                            if let wif = item.wif {
                                                VStack(spacing: 12) {
                                                    HStack(spacing: 8) {
                                                        Text("WIF")
                                                            .font(.body1)
                                                            .multilineTextAlignment(.leading)
                                                        Spacer()
                                                        
                                                        Image(uiImage: AssetsIcons.copy.getIcon())
                                                            .imageScale(.large)
                                                            .onTapGesture {
                                                                viewModel.selectedAsset = asset
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                                    if viewModel.selectedAsset?.id == asset.id {
                                                                        viewModel.selectedAsset = nil
                                                                    }
                                                                }
                                                                UIPasteboard.general.string = wif
                                                                
                                                            }
                                                        
                                                        Image(uiImage: item.isExposed ?  AssetsIcons.eye.getIcon() : AssetsIcons.eyeCrossedOut.getIcon())
                                                            .imageScale(.large)
                                                            .onTapGesture {
                                                                withAnimation {
                                                                    if let index = viewModel.items[key]?.firstIndex(where: {$0.assetSummary.asset?.id == asset.id}) {
                                                                        viewModel.items[key]?[index].isWifExposed.toggle()
                                                                    }
                                                                }
                                                            }
                                                    }
                                                    
                                                    HStack {
                                                        if !item.isWifExposed {
                                                            SecureField("", text: .constant(wif))
                                                                .frame(maxWidth: .infinity)
                                                                .padding()
                                                                .disabled(true)
                                                                .multilineTextAlignment(.leading)
                                                            
                                                        } else {
                                                            Text(wif)
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
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                Spacer()
                
            }
            .padding(.vertical, 24)
            
            VStack(spacing: 0) {
                Spacer()
                Label {
                    Text("\(viewModel.selectedAsset?.name ?? "") Key  Copied")
                } icon: {
                    Image(systemName: "checkmark")
                }
                .padding(16)
                .background(AssetsColors.gray1.color())
                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                .opacity(viewModel.selectedAsset == nil ? 0 : 1)
                
            }
            .padding(.vertical, 24)
            
        }
        .animation(.default, value: viewModel.selectedAsset)
        .navigationTitle(viewModel.navigationBarTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DeriveKeysView(viewModel: DeriveKeysView.ViewModel(privateKeys: ["XXXX"]))
}
