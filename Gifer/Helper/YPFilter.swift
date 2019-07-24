//
//  YPFilter.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import UIKit
import CoreImage

public typealias FilterApplierType = ((_ image: CIImage) -> CIImage?)

public struct YPFilter {
    var name = ""
    private var applier: FilterApplierType?
    var progress: Double = 1.0
    
    /// The normal filter doesn't have applier.
    var hasApplier: Bool {
        return applier != nil
    }
    
    func applyFilter(image: CIImage) -> CIImage {
        guard let applier = applier, let filterImage = applier(image) else { return image }
        return image.applyingFilter("CIDissolveTransition", parameters: ["inputTargetImage": filterImage, "inputTime": self.progress])
    }
    
    public init(name: String, coreImageFilterName: String) {
        self.name = name
        self.applier = YPFilter.coreImageFilter(name: coreImageFilterName)
    }
    
    public init(name: String, applier: FilterApplierType?) {
        self.name = name
        self.applier = applier
    }
}

extension YPFilter {
    public static func coreImageFilter(name: String) -> FilterApplierType {
        return { (image: CIImage) -> CIImage? in
            let filter = CIFilter(name: name)
            filter?.setValue(image, forKey: kCIInputImageKey)
            return filter?.outputImage!
        }
    }
    
    public static func clarendonFilter(foregroundImage: CIImage) -> CIImage? {
        let backgroundImage = getColorImage(red: 127, green: 187, blue: 227, alpha: Int(255 * 0.2), rect: foregroundImage.extent)
        return foregroundImage.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": backgroundImage,
            ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.35,
                "inputBrightness": 0.05,
                "inputContrast": 1.1,
                ])
    }
    
    public static func nashvilleFilter(foregroundImage: CIImage) -> CIImage? {
        let backgroundImage = getColorImage(red: 247, green: 176, blue: 153, alpha: Int(255 * 0.56), rect: foregroundImage.extent)
        let backgroundImage2 = getColorImage(red: 0, green: 70, blue: 150, alpha: Int(255 * 0.4), rect: foregroundImage.extent)
        return foregroundImage
            .applyingFilter("CIDarkenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage,
                ])
            .applyingFilter("CISepiaTone", parameters: [
                "inputIntensity": 0.2,
                ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.2,
                "inputBrightness": 0.05,
                "inputContrast": 1.1,
                ])
            .applyingFilter("CILightenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage2,
                ])
    }
    
    public static func apply1977Filter(ciImage: CIImage) -> CIImage? {
        let filterImage = getColorImage(red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1), rect: ciImage.extent)
        let backgroundImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05,
                ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3,
                ])
        return filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage,
                ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1),
                ])
    }
    
    public static func toasterFilter(ciImage: CIImage) -> CIImage? {
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        let centerWidth = width / 2.0
        let centerHeight = height / 2.0
        let radius0 = min(width / 4.0, height / 4.0)
        let radius1 = min(width / 1.5, height / 1.5)
        
        let color0 = self.getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let color1 = self.getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let circle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: centerWidth, y: centerHeight),
            "inputRadius0": radius0,
            "inputRadius1": radius1,
            "inputColor0": color0,
            "inputColor1": color1,
            ])?.outputImage?.cropped(to: ciImage.extent)
        
        return ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0,
                "inputBrightness": 0.01,
                "inputContrast": 1.1,
                ])
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": circle!,
                ])
    }
    
    
    public static func hazeRemovalFilter(image: CIImage) -> CIImage? {
        let filter = HazeRemovalFilter()
        filter.inputImage = image
        return filter.outputImage
    }
    
    private static func getColor(red: Int, green: Int, blue: Int, alpha: Int = 255) -> CIColor {
        return CIColor(red: CGFloat(Double(red) / 255.0),
                       green: CGFloat(Double(green) / 255.0),
                       blue: CGFloat(Double(blue) / 255.0),
                       alpha: CGFloat(Double(alpha) / 255.0))
    }
    
    private static func getColorImage(red: Int, green: Int, blue: Int, alpha: Int = 255, rect: CGRect) -> CIImage {
        let color = self.getColor(red: red, green: green, blue: blue, alpha: alpha)
        return CIImage(color: color).cropped(to: rect)
    }
}

class HazeRemovalFilter: CIFilter {
    var inputImage: CIImage!
    var inputColor: CIColor! = CIColor(red: 0.7, green: 0.9, blue: 1.0)
    var inputDistance: Float! = 0.2
    var inputSlope: Float! = 0.0
    var hazeRemovalKernel: CIKernel!
    
    override init()
    {
        // check kernel has been already initialized
        let code: String = """
kernel vec4 myHazeRemovalKernel(
    sampler src,
    __color color,
    float distance,
    float slope)
{
    vec4 t;
    float d;

    d = destCoord().y * slope + distance;
    t = unpremultiply(sample(src, samplerCoord(src)));
    t = (t - d * color) / (1.0 - d);

    return premultiply(t);
}
"""
        self.hazeRemovalKernel = CIKernel(source: code)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage?
    {
        guard let inputImage = self.inputImage,
            let hazeRemovalKernel = self.hazeRemovalKernel,
            let inputColor = self.inputColor,
            let inputDistance = self.inputDistance,
            let inputSlope = self.inputSlope
            else {
                return nil
        }
        let src: CISampler = CISampler(image: inputImage)
        return hazeRemovalKernel.apply(extent: inputImage.extent,
            roiCallback: { (index, rect) -> CGRect in
                return rect
        }, arguments: [
            src,
            inputColor,
            inputDistance,
            inputSlope,
            ])
    }
    
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Haze Removal Filter",
            "inputDistance": [
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeSliderMin: 0.0,
                kCIAttributeSliderMax: 0.7,
                kCIAttributeDefault: 0.2,
                kCIAttributeIdentity : 0.0,
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputSlope": [
                kCIAttributeSliderMin: -0.01,
                kCIAttributeSliderMax: 0.01,
                kCIAttributeDefault: 0.00,
                kCIAttributeIdentity: 0.00,
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            kCIInputColorKey: [
                kCIAttributeDefault: CIColor(red:1.0, green:1.0, blue:1.0, alpha:1.0)
            ],
        ]
    }
}


var AllFilters: [YPFilter] = {
    var filters = [
        YPFilter(name: "无滤镜", applier: nil),
        YPFilter(name: "TC1", applier: YPFilter.nashvilleFilter),
        YPFilter(name: "TC2", applier: YPFilter.toasterFilter),
        YPFilter(name: "TC3", applier: YPFilter.apply1977Filter),
        YPFilter(name: "TC4", applier: YPFilter.clarendonFilter),
        YPFilter(name: "TC5", coreImageFilterName: "CIPhotoEffectChrome"),
        YPFilter(name: "TC6", coreImageFilterName: "CIPhotoEffectFade"),
        YPFilter(name: "BC1", coreImageFilterName: "CIPhotoEffectInstant"),
        YPFilter(name: "BC2", coreImageFilterName: "CIPhotoEffectMono"),
        YPFilter(name: "BC3", coreImageFilterName: "CIPhotoEffectNoir"),
        YPFilter(name: "BC4", coreImageFilterName: "CIPhotoEffectProcess"),
        YPFilter(name: "BC5", coreImageFilterName: "CIPhotoEffectTonal"),
        YPFilter(name: "BC6", coreImageFilterName: "CIPhotoEffectTransfer"),
        YPFilter(name: "BC7", coreImageFilterName: "CILinearToSRGBToneCurve"),
        YPFilter(name: "BC8", coreImageFilterName: "CISRGBToneCurveToLinear"),
        YPFilter(name: "BC9", coreImageFilterName: "CISepiaTone"),
        ]
    
    if UIDevice.isSimulator {
        filters = Array(filters[0...7])
    }
    
    return filters
}()

var NormalFilter: YPFilter = AllFilters.first!

