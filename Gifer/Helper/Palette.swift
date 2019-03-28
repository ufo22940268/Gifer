//
//  Color.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/28.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

public struct Palette
{
    public static var Turquoise: UIColor
    {
        return UIColor.init(hex: "1abc9c")
    }
    public static var Alizarin: UIColor
    {
        return UIColor.init(hex: "e74c3c")
    }
    public static var Emerald: UIColor
    {
        return UIColor.init(hex: "2ecc71")
    }
    public static var Amethyst: UIColor
    {
        return UIColor.init(hex: "9b59b6")
    }
    public static var WetAsphalt: UIColor
    {
        return UIColor.init(hex: "34495e")
    }
    public static var Nephritis: UIColor
    {
        return UIColor.init(hex: "27ae60")
    }
    public static var BelizeHole: UIColor
    {
        return UIColor.init(hex: "2980b9")
    }
    public static var Wisteria: UIColor
    {
        return UIColor.init(hex: "8e44ad")
    }
    public static var Sunflower: UIColor
    {
        return UIColor.init(hex: "f1c40f")
    }
    public static var Carrot: UIColor
    {
        return UIColor.init(hex: "e67e22")
    }
    public static var Clouds: UIColor
    {
        return UIColor.init(hex: "ecf0f1")
    }
    public static var Concentrate: UIColor
    {
        return UIColor.init(hex: "95a5a6")
    }
    public static var Orange: UIColor
    {
        return UIColor.init(hex: "f39c12")
    }
    public static var Pumpkin: UIColor
    {
        return UIColor.init(hex: "d35400")
    }
    public static var Pomegranate: UIColor
    {
        return UIColor.init(hex: "c0392b")
    }
    public static var Silver: UIColor
    {
        return UIColor.init(hex: "bdc3c7")
    }
    public static var Red: UIColor
    {
        return UIColor.init(hex: "f44336")
    }
    public static var Pink: UIColor
    {
        return UIColor.init(hex: "e91e63")
    }
    public static var Purple: UIColor
    {
        return UIColor.init(hex: "9c27b0")
    }
    public static var DeepPurple: UIColor
    {
        return UIColor.init(hex: "673ab7")
    }
    public static var Indigo: UIColor
    {
        return UIColor.init(hex: "3f51b5")
    }
    public static var Blue: UIColor
    {
        return UIColor.init(hex: "2196f3")
    }
    public static var Cyan: UIColor
    {
        return UIColor.init(hex: "00bcd4")
    }
    public static var Teal: UIColor
    {
        return UIColor.init(hex: "009688")
    }
    public static var LightGreen: UIColor
    {
        return UIColor.init(hex: "8bc34a")
    }
    public static var Lime: UIColor
    {
        return UIColor.init(hex: "cddc39")
    }
    public static var Yellow: UIColor
    {
        return UIColor.init(hex: "ffeb3b")
    }
    public static var Amber: UIColor
    {
        return UIColor.init(hex: "ffc107")
    }
    public static var DeepOrange: UIColor
    {
        return UIColor.init(hex: "ff5722")
    }
    public static var Brown: UIColor
    {
        return UIColor.init(hex: "795548")
    }
    public static var Steel: UIColor
    {
        return UIColor.init(hex: "607d8b")
    }
    public static var PaleDogwood: UIColor
    {
        return UIColor.init(hex: "EFD1C6")
    }
    public static var Hazelnut: UIColor
    {
        return UIColor.init(hex: "CFB095")
    }
    public static var Kale: UIColor
    {
        return UIColor.init(hex: "5A7247")
    }
    public static var Lapis: UIColor
    {
        return UIColor.init(hex: "004B8D")
    }
    public static var Niagara:UIColor
    {
        return UIColor.init(hex: "5487A4")
    }
    public static var Grenadine: UIColor
    {
        return UIColor.init(hex: "DF3F32")
    }
    public static var TawnyPort: UIColor
    {
        return UIColor.init(hex: "5C2C35")
    }
    public static var BalletSlipper: UIColor
    {
        return UIColor.init(hex: "EBCED5")
    }
    public static var Butterum: UIColor
    {
        return UIColor.init(hex: "C68F65")
    }
    public static var NavyPeony: UIColor
    {
        return UIColor.init(hex: "223A5E")
    }
    public static var NeutralGray: UIColor
    {
        return UIColor.init(hex: "8E918F")
    }
    public static var ShadedSpruce: UIColor
    {
        return UIColor.init(hex: "00585E")
    }
    public static var GoldenLime: UIColor
    {
        return UIColor.init(hex: "9A9738")
    }
    public static var Marina: UIColor
    {
        return UIColor.init(hex: "4F84C4")
    }
    public static var AutumnMaple: UIColor
    {
        return UIColor.init(hex: "C46215")
    }
    
    public static var allColors = [.white, Palette.Turquoise, Palette.Alizarin, Palette.Emerald, Palette.Amethyst, Palette.WetAsphalt, Palette.Nephritis, Palette.BelizeHole, Palette.Wisteria, Palette.Sunflower, Palette.Carrot, Palette.Clouds, Palette.Concentrate, Palette.Orange, Palette.Pumpkin, Palette.Pomegranate, Palette.Silver, Palette.Red, Palette.Pink, Palette.Purple, Palette.DeepPurple, Palette.Indigo, Palette.Blue, Palette.Cyan, Palette.Teal, Palette.LightGreen, Palette.Lime, Palette.Yellow, Palette.Amber, Palette.DeepOrange, Palette.Brown, Palette.Steel, Palette.PaleDogwood, Palette.Hazelnut, Palette.Kale, Palette.Lapis, Palette.Niagara, Palette.Grenadine, Palette.TawnyPort, Palette.BalletSlipper, Palette.Butterum, Palette.NavyPeony, Palette.NeutralGray, Palette.ShadedSpruce, Palette.GoldenLime, Palette.Marina, Palette.AutumnMaple]
}

fileprivate extension UIColor
{
    convenience init(hex: String)
    {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
