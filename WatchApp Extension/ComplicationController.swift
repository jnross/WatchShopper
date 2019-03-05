//
//  ComplicationController.swift
//  DeleteMe WatchKit Extension
//
//  Created by Joseph Ross on 3/3/19.
//  Copyright © 2019 Joseph Ross. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        
        getLocalizableSampleTemplate(for: complication) { (template) in
            guard let template = template else {
                handler(nil)
                return
                
            }
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        getLocalizableSampleTemplate(for: complication, withHandler: handler)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        switch complication.family {
        case .circularSmall:
            let image = #imageLiteral(resourceName: "Circular")
            let imageProvider = CLKImageProvider(onePieceImage: image)
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = imageProvider
            handler(template)
        case .graphicCircular:
            let image = #imageLiteral(resourceName: "Graphic Circular")
            let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: image)
            let template = CLKComplicationTemplateGraphicCircularImage()
            template.imageProvider = fullColorImageProvider
            handler(template)
        case .modularSmall:
            let image = #imageLiteral(resourceName: "Modular")
            let imageProvider = CLKImageProvider(onePieceImage: image)
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = imageProvider
            handler(template)
        case .utilitarianSmall:
            let image = #imageLiteral(resourceName: "Utilitarian")
            let imageProvider = CLKImageProvider(onePieceImage: image)
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            template.imageProvider  = imageProvider
            handler(template)
        case .extraLarge:
            let image = #imageLiteral(resourceName: "Extra Large")
            let imageProvider = CLKImageProvider(onePieceImage: image)
            let template = CLKComplicationTemplateExtraLargeSimpleImage()
            template.imageProvider = imageProvider
            handler(template)
        case .graphicCorner:
            let image = #imageLiteral(resourceName: "Graphic Corner")
            let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: image)
            let template = CLKComplicationTemplateGraphicCornerCircularImage()
            template.imageProvider = fullColorImageProvider
            handler(template)
        default:
            handler(nil)
        }
    }
    
}
