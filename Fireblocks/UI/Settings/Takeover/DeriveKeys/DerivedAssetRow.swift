//
//  DerivedAssetRow.swift
//  NCW-sandbox
//
//  Created by Dudi Shani-Gabay on 06/03/2024.
//

import SwiftUI

struct DerivedAssetRow: View {
    let asset: Asset
    
    var body: some View {
        HStack {
            VStack(spacing: 0) {
                Group {
                    if let iconURL = asset.iconUrl {
                        AsyncImage(url: URL(string: iconURL)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure(let error):
                                Image(uiImage: asset.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            @unknown default:
                                EmptyView()
                                
                            }
                        }
                        
                    } else {
                        Image(uiImage: asset.image)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .padding(4)
            }
            .frame(width: 32, height: 32)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8.0))

            Text(asset.name)
                .font(.body1)
                .multilineTextAlignment(.leading)

        }
    }
}

//#Preview {
//    DerivedAssetRow(asset: Ass)
//}
