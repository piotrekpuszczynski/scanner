//
//  ContentView.swift
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraRunner()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
