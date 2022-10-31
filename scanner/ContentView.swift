//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraRunner()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
