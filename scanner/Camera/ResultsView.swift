//
//  ResultsView.swift
//

import SwiftUI
import Vision

class ResultsView: UIView {
    private let imageView: UIImageView
    private let cgImage: CGImage
    private let detectionLayer = CALayer()

    required init(cgImage: CGImage, screenRect: CGRect) {
        let image = UIImage(cgImage: cgImage)
        let reducedImage = image.scaleImage(byPercentage: 0.6)
        self.imageView = UIImageView(image: reducedImage)
        self.cgImage = cgImage
        super.init(frame: screenRect)
        layer.frame = screenRect
        
        imageView.center = CGPoint(x: screenRect.size.width / 2, y: screenRect.size.height / 2)
        addSubview(imageView)
        layer.addSublayer(detectionLayer)

        detectText()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func detectText() {
        let detectionHandler = DetectionHandler()
        detectionHandler.extractDetections = { [unowned self] observations in
            var text = ""
            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { return }

//                let string = candidate.string
                
//                for (index, char) in string.enumerated() {
//                    print(char)
//                    let boxObservation = try? candidate.boundingBox(for: string.index(string.startIndex, offsetBy: index)..<string.index(string.startIndex, offsetBy: index))
//                    guard let boundingBox = boxObservation?.boundingBox else { return }
//                    let rect = VNImageRectForNormalizedRect(boundingBox, Int(frame.size.width), Int(frame.size.height))
//                    let textBox = UITextView(frame: rect)
//                    addSubview(textBox)
//                    textBox.translatesAutoresizingMaskIntoConstraints = false
//                    textBox.text = String(char)
//                    textBox.delegate = self
//                }
                let stringRange = candidate.string.startIndex..<candidate.string.endIndex
                let boxObservation = try? candidate.boundingBox(for: stringRange)

                guard let boundingBox = boxObservation?.boundingBox else { return }

                text += "\(candidate.string)\n"
                print(candidate.string)

                let objectBounds = VNImageRectForNormalizedRect(boundingBox, Int(cgImage.width), Int(cgImage.height))
                let textRect = CGRect(x: objectBounds.minX + imageView.center.x - (imageView.image?.size.width)! / 2,
                                      y: objectBounds.minY + imageView.center.y - (imageView.image?.size.height)! / 2,
                                      width: objectBounds.width, height: objectBounds.height)
                let boxLayer = drawBoundingBox(textRect)
//                detectionLayer.addSublayer(boxLayer)
            }
            let button = Button(xByPercentage: 0.1, yByPercentage: 0.9)
            button.tapAction = {
                UIPasteboard.general.string = text
                let alert = UIAlertController(title: "Text copied", message: nil, preferredStyle: .actionSheet)

                guard let rootViewController = self.window?.rootViewController else { return }
                rootViewController.present(alert, animated: true, completion: {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
                        rootViewController.dismiss(animated: true, completion: nil)
                    })
                })
            }
            DispatchQueue.main.async { [unowned self] in
                addSubview(button)
            }
//            let textView = UITextView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: image!.size))
////            textView.contentInsetAdjustmentBehavior = .automatic
//
////            textView.center = center
//////            textView.textAlignment = NSTextAlignment.justified
//////            textView.backgroundColor = UIColor.lightGray
////
////            // Use RGB colour
//            textView.backgroundColor = UIColor.clear
////
////            // Update UITextView font size and colour
//////            textView.font = UIFont.systemFont(ofSize: 8)
//            textView.textColor = UIColor.white
////
//////            textView.font = UIFont.boldSystemFont(ofSize: 8)
//////            textView.font = UIFont(name: "Verdana", size: 8)
////
////            // Capitalize all characters user types
//////            textView.autocapitalizationType = UITextAutocapitalizationType.allCharacters
////
////            // Make UITextView web links clickable
//            textView.isSelectable = true
//            textView.isUserInteractionEnabled = true
//            textView.isEditable = false
//////            textView.dataDetectorTypes = UIDataDetectorTypes.link
////
////            // Make UITextView corners rounded
//////             textView.layer.cornerRadius = 10
////
////            // Enable auto-correction and Spellcheck
//////             textView.autocorrectionType = UITextAutocorrectionType.yes
//////             textView.spellCheckingType = UITextSpellCheckingType.yes
////             // myTextView.autocapitalizationType = UITextAutocapitalizationType.None
////
////            // Make UITextView Editable
////            textView.isEditable = false
//
//            textView.text = text
//
//            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
//            tap.numberOfTapsRequired = 2
//            textView.addGestureRecognizer(tap)
//            addSubview(textView)
        }
        
        let request = VNRecognizeTextRequest(completionHandler: detectionHandler.handeler)
        request.recognitionLevel = .accurate

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.main.async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error in performing Image request: \(error)")
            }
        }
    }

    @objc
    func tapped(_ recognizer: UITapGestureRecognizer?) {
        print("test")
        let textView_New = recognizer?.view as? UITextView
        let pos = recognizer?.location(in: textView_New)

        let tapPos = textView_New?.closestPosition(to: pos ?? CGPoint.zero)

        var word: UITextRange? = nil
        if let tapPos {
            word = textView_New?.tokenizer.rangeEnclosingPosition(tapPos, with: .word, inDirection: .layout(UITextLayoutDirection.right))
        }
        printContent(word)
    }

    private func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 2.0
        boxLayer.backgroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        boxLayer.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        boxLayer.cornerRadius = 4
        return boxLayer
    }
}
