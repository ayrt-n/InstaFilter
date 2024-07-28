//
//  ContentView.swift
//  Instafilter
//
//  Created by Ayrton Parkinson on 2024/07/27.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    @State private var filterAngle = 0.5
    
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    private var inputKeys: [String] { currentFilter.inputKeys }
    let context = CIContext()
    
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No Picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                
                VStack {
                    if inputKeys.contains(kCIInputIntensityKey) {
                        HStack {
                            Text("Intensity")
                                .foregroundStyle(processedImage == nil ? .secondary : .primary)
                            Slider(value: $filterIntensity)
                                .onChange(of: filterIntensity, applyProcessing)
                                .disabled(processedImage == nil)
                        }
                    }
                    
                    if inputKeys.contains(kCIInputRadiusKey) {
                        HStack {
                            Text("Radius")
                                .foregroundStyle(processedImage == nil ? .secondary : .primary)
                            Slider(value: $filterRadius)
                                .onChange(of: filterRadius, applyProcessing)
                                .disabled(processedImage == nil)
                        }
                    }
                    
                    if inputKeys.contains(kCIInputScaleKey) {
                        HStack {
                            Text("Scale")
                                .foregroundStyle(processedImage == nil ? .secondary : .primary)
                            Slider(value: $filterScale)
                                .onChange(of: filterScale, applyProcessing)
                                .disabled(processedImage == nil)
                        }
                    }
                    
                    if inputKeys.contains(kCIInputAngleKey) {
                        HStack {
                            Text("Angle")
                                .foregroundStyle(processedImage == nil ? .secondary : .primary)
                            Slider(value: $filterAngle)
                                .onChange(of: filterAngle, applyProcessing)
                                .disabled(processedImage == nil)
                        }
                    }
                }
                .padding(.vertical)
                
                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(processedImage == nil)
                    
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Hue Adjust") { setFilter(CIFilter.hueAdjust()) }
            }
        }
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
        if inputKeys.contains(kCIInputAngleKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputAngleKey)}
        
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount >= 20 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}
