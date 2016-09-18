//
//  ComplicationController.swift
//  HinnerJagWatchOS2 Extension
//
//  Created by Wilhelm Eklund on 27/08/15.
//  Copyright © 2015 Wilhelm Eklund. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    let trainTemplate = "train_template"
    let tintColor = UIColor(red: 1.0/255.0, green: 152.0/255.0, blue: 117.0/255.0, alpha: 1)
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    private func getTimelineStartDate(for complication: CLKComplication, withHandler handler: (Date?) -> Void) {
        handler(nil)
    }
    
    private func getTimelineEndDate(for complication: CLKComplication, withHandler handler: (Date?) -> Void) {
        handler(nil)
    }
    
    private func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    public func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        var template: CLKComplicationTemplate?
        if let logo = UIImage(named: trainTemplate) {
            let imageProviderTrain = CLKImageProvider(onePieceImage: logo)
            switch complication.family {
            case .modularSmall:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .modularLarge:
                template = nil
            case .utilitarianSmall:
                let modularTemplate = CLKComplicationTemplateUtilitarianSmallSquare()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .utilitarianLarge:
                template = nil
            case .circularSmall:
                let modularTemplate = CLKComplicationTemplateCircularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            default:
                template = nil
            }
        }
        if let template = template {
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(timelineEntry)
        } else {
            handler(nil)
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
    private func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        var template: CLKComplicationTemplate?
        if let logo = UIImage(named: trainTemplate) {
            let imageProviderTrain = CLKImageProvider(onePieceImage: logo)
            switch complication.family {
            case .modularSmall:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .modularLarge:
                template = nil
            case .utilitarianSmall:
                let modularTemplate = CLKComplicationTemplateUtilitarianSmallSquare()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .utilitarianLarge:
                template = nil
            case .circularSmall:
                let modularTemplate = CLKComplicationTemplateCircularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            default:
                template = nil
            }
        }
        handler(template)
    }
    
    private func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        handler(nil)
    }
    
}
