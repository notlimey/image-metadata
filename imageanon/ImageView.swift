//
//  ImageView.swift
//  imageanon
//
//  Created by Martin Myhre on 21/06/2024.
//
import SwiftUI

struct ImageView : View {
    var image: NSImage
    var openFilePicker: () -> Void
    var geometry: GeometryProxy
    
    var body: some View {
        
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: min(300, geometry.size.width / 2), height: min(300, geometry.size.width / 2))
                .onTapGesture {
                    openFilePicker()
                }
    }
}



func readableFileSize(_ size: Int64) -> String {
    let units = ["bytes", "KB", "MB", "GB", "TB"]
    let count = 1024.0
    
    var fileSize = Double(size)
    var unitIndex = 0
    
    while fileSize >= count && unitIndex < units.count - 1 {
        fileSize /= count
        unitIndex += 1
    }
    
    return String(format: "%.2f %@", fileSize, units[unitIndex])
}


struct ImageFileInformationView: View {
    var selectedFilePath: String?
    var fileSize: Int64?
    
    var imageWidth: CGFloat?
    var imageHeight: CGFloat?
    
    var body: some View {
        Text("File Information")
            .font(.headline)
            .padding(.bottom, 5)

        Text("File Path: \(selectedFilePath ?? "Unknown")")
            .font(.subheadline)
        if let size = fileSize {
            Text("File Size: \(readableFileSize(size))")
                .font(.subheadline)
        }
        
        if let width = imageWidth, let height = imageHeight {
            Text("Dimensions: \(Int(width)) x \(Int(height)) pixels")
                .font(.subheadline)
        }
    }
}
