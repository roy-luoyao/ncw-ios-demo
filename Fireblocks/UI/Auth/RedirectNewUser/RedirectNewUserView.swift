//
//  RedirectNewUserView.swift
//  NCW-sandbox
//
//  Created by Dudi Shani-Gabay on 25/01/2024.
//

import SwiftUI

struct RedirectNewUserView: View {
    @Environment (\.dismiss) var dismiss
    @StateObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                Image(AssetsIcons.addDeviceImage.rawValue)
                    .padding(.top, 12)
                    .padding(.bottom, 42)

                Text("You can add this device to your existing wallet or recover your existing wallet on this device.")
                    .font(.body4)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 74)

                Button {
                    viewModel.addDeviceTapped()
                } label: {
                    HStack {
                        Spacer()
                        Image(AssetsIcons.scanQrCode.rawValue)
                        Text("Add device from sign-in screen")
                            .font(.body1)
                        Spacer()
                    }
                    .padding(16)
                    .contentShape(Rectangle())

                }
                .tint(.white)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .background(AssetsColors.gray1.color())
                .cornerRadius(16)

                HStack {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(AssetsColors.gray2.color())
                    Text("or")
                        .font(.body1)
                        .foregroundColor(AssetsColors.gray3.color())
                        .padding(16)
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(AssetsColors.gray2.color())

                }
                Button {
                    viewModel.recoverTapped()
                } label: {
                    HStack {
                        Spacer()
                        Image(AssetsIcons.scanQrCode.rawValue)
                        Text("Recover wallet")
                            .font(.body1)
                        Spacer()
                    }
                    .padding(16)
                    .contentShape(Rectangle())

                }
                .tint(.white)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .background(AssetsColors.gray1.color())
                .cornerRadius(16)

                Spacer()
                
                Button("Share Logs") {
                    NotificationCenter.default.post(name: Notification.Name("sendLogs"), object: nil, userInfo: nil)
                }
            }
            .padding(16)

        }
        .onAppear() {
            viewModel.didInit()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.signOut()
                } label: {
                    Image(AssetsIcons.close.rawValue)
                }
                .tint(.white)
            }
        }
        .navigationTitle("Add your keys to this device")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .interactiveDismissDisabled()
    }
}

struct RedirectNewUserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RedirectNewUserView(viewModel: RedirectNewUserView.ViewModel())
        }
    }
}
