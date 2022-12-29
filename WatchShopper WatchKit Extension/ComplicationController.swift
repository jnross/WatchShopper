//
//  ComplicationController.swift
//  WatchShopper WatchKit Extension
//
//  Created by Joseph Ross on 10/7/21.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "WatchShopper", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }

    // MARK: - Timeline Population
    
    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        return nil
    }
    

    // MARK: - Sample Templates
    
    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
            // This method will be called once per supported complication, and the results will be cached
        switch complication.family {
        case .circularSmall:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(imageLiteralResourceName: "Complication/Circular"))
            return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: imageProvider)
        case .graphicCircular:
            let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(imageLiteralResourceName: "Complication/Graphic Circular"))
            return CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider)
        case .graphicBezel:
            let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(imageLiteralResourceName: "Complication/Graphic Bezel"))
            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: CLKComplicationTemplateGraphicCircularImage(imageProvider: fullColorImageProvider))
        case .modularSmall:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(imageLiteralResourceName: "Complication/Modular"))
            return CLKComplicationTemplateModularSmallSimpleImage(imageProvider: imageProvider)
        case .utilitarianSmall:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(imageLiteralResourceName: "Complication/Utilitarian"))
            return CLKComplicationTemplateUtilitarianSmallSquare(imageProvider: imageProvider)
        case .graphicCorner:
            let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(imageLiteralResourceName: "Complication/Graphic Corner"))
            return CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: fullColorImageProvider)
        case .extraLarge: fallthrough
        case .graphicRectangular: fallthrough
        case .graphicExtraLarge: fallthrough
        case .modularLarge: fallthrough
        case .utilitarianSmallFlat: fallthrough
        case .utilitarianLarge: fallthrough
        @unknown default:
            return nil
        }
    }
}
