//
//  ReceiptScannerView.swift
//  ExpenseTracker
//
//  Thin SwiftUI wrapper around VisionKit's native document scanner
//  (`VNDocumentCameraViewController`). It gives us edge detection, perspective
//  correction, and multi-page capture for free; we just grab the first page
//  and hand it back for OCR.
//
//  Requires a physical device with a camera (NSCameraUsageDescription is set
//  in the build settings). It will not function on the Simulator.
//

import SwiftUI
import VisionKit

struct ReceiptScannerView: UIViewControllerRepresentable {
    /// Called with the first captured page once scanning finishes.
    var onComplete: (UIImage) -> Void
    /// Called when the user cancels or capture fails.
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: ReceiptScannerView

        init(_ parent: ReceiptScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                parent.onCancel()
                return
            }
            let image = scan.imageOfPage(at: 0)
            parent.onComplete(image)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onCancel()
        }
    }
}
