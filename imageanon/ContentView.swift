import SwiftUI
import UniformTypeIdentifiers
import ImageIO

struct ContentView: View {
    @State private var selectedImage: NSImage? = nil
    @State private var selectedFilePath: String? = nil
    @State private var fileSize: Int64? = nil
    @State private var metadata: [String: Any] = [:]
    
    @State private var imageWidth: CGFloat? = nil
    @State private var imageHeight: CGFloat? = nil
    @State private var newFileName: String = "new_image"
    @State private var selectedMetadataGroup: String?
    @State private var selectedMetadataField: String?

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let image = selectedImage {
                    HStack(alignment: .top) {
                        ImageView(image: image, openFilePicker: openFilePicker, geometry: geometry)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ImageFileInformationView(selectedFilePath: selectedFilePath, fileSize: fileSize,
                                                         
                                                         imageWidth: imageWidth,
                                                         imageHeight: imageHeight)

                                ForEach(groupedMetadataKeys(), id: \.self) { group in
                                    if let groupMetadata = metadata[group] as? [String: Any] {
                                        DisclosureGroup(group) {
                                            VStack(alignment: .leading, spacing: 5) {
                                                ForEach(groupMetadata.keys.sorted(), id: \.self) { key in
                                                    if let value = groupMetadata[key] {
                                                        HStack {
                                                            Text("\(key): \(value)")
                                                                .font(.caption)
                                                                .lineLimit(nil)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                            Spacer()
                                                            Button(action: {
                                                                selectedMetadataGroup = group
                                                                selectedMetadataField = key
                                                                deleteMetadata()
                                                            }) {
                                                                Image(systemName: "trash")
                                                                    .foregroundColor(.red)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .font(.subheadline)
                                        .padding(.top, 5)
                                        HStack {
                                            Spacer()
                                            Button(action: {
                                                selectedMetadataGroup = group
                                                deleteMetadata(groupOnly: true)
                                            }) {
                                                Text("Delete Group")
                                                    .foregroundColor(.red)
                                            }
                                            Spacer()
                                        }
                                    }
                                }

                                HStack {
                                    TextField("New File Name", text: $newFileName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    Spacer()
                                    Button("Save Image") {
                                        saveImage()
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                            .border(Color.gray, width: 1)
                            .cornerRadius(10)
                        }
                        .frame(maxHeight: geometry.size.height)
                    }
                    .padding()
                } else {
                    ImagePickerView(openFilePicker: openFilePicker)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .frame(maxHeight: geometry.size.height)
        }
    }

    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic] // Example allowed image types.
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            selectedFilePath = url.path
            do {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                fileSize = resourceValues.fileSize.map { Int64($0) }
            } catch {
                print("Error retrieving file size: \(error.localizedDescription)")
            }
            if let nsImage = NSImage(contentsOf: url) {
                selectedImage = nsImage
                
                if let rep = nsImage.representations.first {
                    imageWidth = CGFloat(rep.pixelsWide)
                    imageHeight = CGFloat(rep.pixelsHigh)
                }
            }
            extractMetadata(from: url)
        }
    }

    func extractMetadata(from url: URL) {
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
            metadata = imageProperties
        }
    }

    func groupedMetadataKeys() -> [String] {
        // Example grouping; adjust according to actual metadata structure and needs.
        return ["{Exif}", "{IPTC}", "{GPS}", "{TIFF}", "{JFIF}", "{CIFF}", "{Canon}", "{PNG}", "{GIF}", "{JFIF}"]
            .filter { metadata.keys.contains($0) }
    }

    func deleteMetadata(groupOnly: Bool = false) {
        if let group = selectedMetadataGroup {
            if groupOnly {
                metadata.removeValue(forKey: group)
            } else if let field = selectedMetadataField, var groupMetadata = metadata[group] as? [String: Any] {
                groupMetadata.removeValue(forKey: field)
                metadata[group] = groupMetadata
            }
        }
    }
    
    func saveImage() {
        guard let selectedImage = selectedImage else { return }
        
        guard let imageDestinationURL = getSaveURL() else {
            print("Error obtaining save URL")
            return
        }

        guard let imageSource = CGImageSourceCreateWithData(selectedImage.tiffRepresentation! as CFData, nil) else { return }
        
        let typeSpecifier = getUniformType(fileExtension: imageDestinationURL.pathExtension)
        guard let imageDestination = CGImageDestinationCreateWithURL(imageDestinationURL as CFURL, typeSpecifier, 1, nil) else { return }
        
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metadata as CFDictionary)
        
        if CGImageDestinationFinalize(imageDestination) {
            print("Image saved successfully at \(imageDestinationURL.path)")
        } else {
            print("Failed to save image")
        }
    }
    
    func getUniformType(fileExtension: String) -> CFString {
        switch fileExtension.lowercased() {
        case "jpeg", "jpg":
            return UTType.jpeg.identifier as CFString
        case "png":
            return UTType.png.identifier as CFString
        case "tiff":
            return UTType.tiff.identifier as CFString
        case "heic":
            return UTType.heic.identifier as CFString
        default:
            return UTType.image.identifier as CFString
        }
    }
    
    func getSaveURL() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.title = "Save Image"
        savePanel.allowedContentTypes = [.png, .jpeg, .tiff, .heic]
        savePanel.nameFieldStringValue = newFileName
        savePanel.canCreateDirectories = true

        if savePanel.runModal() == .OK {
            return savePanel.url
        } else {
            return nil
        }
    }
}

#Preview {
    ContentView()
}
