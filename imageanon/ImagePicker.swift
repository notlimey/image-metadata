//
//  ImagePicker.swift
//  imageanon
//
//  Created by Martin Myhre on 21/06/2024.
//
import SwiftUI

struct ImagePickerView : View {
    
    var openFilePicker: () -> Void
    
    var body: some View {
        VStack {
            Text("No Image Selected")
                .font(.title)
                .padding(.bottom, 10)
            
            Button(action: openFilePicker) {
                Text("Select an Image")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}
