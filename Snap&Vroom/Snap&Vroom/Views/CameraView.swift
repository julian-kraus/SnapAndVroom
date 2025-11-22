//
//  CameraView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI
import UIKit

struct CameraView: View {
    @EnvironmentObject private var navigation: Navigation
    @State private var capturedImage: UIImage? = nil
    @State private var categorizeState: CategorizeState = .idle
    @State private var showCameraSheet: Bool = false

    enum CategorizeState: Equatable {
        case idle
        case processing
    }

    var body: some View {
        ZStack {
            Color(.sixtOrange)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 32)

                // Main content card
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Snap & Print")
                            .font(.headline)
                            .textCase(.uppercase)
                            .foregroundColor(.secondary)

                        Text("Start your trip with a quick photo – we’ll print a souvenir for you to take along.")                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Preview of captured image
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(radius: 8, y: 4)
                            .padding(.horizontal)
                    } else {
                        // Placeholder when no image yet
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                Text("No picture yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // State-driven content
                    Group {
                        switch categorizeState {
                        case .idle:
                            VStack(spacing: 12) {
                                if (capturedImage == nil) {
                                    Button {
                                        showCameraSheet = true
                                    } label: {
                                        Label(
                                            "Take Picture",
                                            systemImage: "camera.fill"
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.black)
                                    .foregroundColor(.white)
                                }

                                if capturedImage == nil {
                                    Text("Or skip this step and continue to your booking.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)

                                    Button {
                                        navigation.goTo(view: .picture_summary)
                                    } label: {
                                        Text("Skip")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.horizontal)

                        case .processing:
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Preparing your printed picture...")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button {
                                    showCameraSheet = true
                                } label: {
                                    Label("Retake Picture", systemImage: "camera.rotate.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 8)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                )
                .padding(.horizontal, 20)

                Spacer()

                /*HStack {
                    backButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }*/
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }

        .fullScreenCover(isPresented: $showCameraSheet) {
            ImagePicker(selectedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { _ in
            navigation.capturedImage = capturedImage
            startCategorizationIfNeeded()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func startCategorizationIfNeeded() {
        guard let image = capturedImage else { return }
        categorizeState = .processing
        classifyImageForCarPrefs(image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let prediction):
                    navigation.carPreferencePrediction = prediction
                    print(prediction.toString())
                case .failure(let error):
                    print("Classification failed:", error)
                }
                categorizeState = .idle
                navigation.goTo(view: .picture_summary)
            }
        }
    }

    var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(.white)
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera

            // Prefer the front (selfie) camera if available
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                picker.cameraDevice = .front
            }
        } else {
            // Simulator or device without camera: fall back to photo library
            picker.sourceType = .photoLibrary
        }

        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
