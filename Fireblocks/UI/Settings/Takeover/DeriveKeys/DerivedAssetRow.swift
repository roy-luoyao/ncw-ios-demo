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
}

//#Preview {
//    DerivedAssetRow(asset: Ass)
//}
