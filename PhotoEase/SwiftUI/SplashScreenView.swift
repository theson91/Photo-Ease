//
//  SplashScreenView.swift
//  PhotoEase
//
//  Created by Son on 01/03/2025.
//

import Foundation
import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        VStack {
            if isActive {
                ContentView()
            } else {
                VStack {
                    Image("img_app_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                    Text("PhotoEase")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear { // Display the splash screen for 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
        .ignoresSafeArea()
    }
}
