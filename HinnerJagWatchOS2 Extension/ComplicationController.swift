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
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward, .Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        var template: CLKComplicationTemplate?
        if let logo = UIImage(named: trainTemplate) {
            let imageProviderTrain = CLKImageProvider(onePieceImage: logo)
            switch complication.family {
            case .ModularSmall:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .ModularLarge:
                template = nil
            case .UtilitarianSmall:
                let modularTemplate = CLKComplicationTemplateUtilitarianSmallSquare()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .UtilitarianLarge:
                template = nil
            case .CircularSmall:
                let modularTemplate = CLKComplicationTemplateCircularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            }
        }
        if let template = template {
            let timelineEntry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template)
            handler(timelineEntry)
        } else {
            handler(nil)
        }
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(nil);
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        var template: CLKComplicationTemplate?
        if let logo = UIImage(named: trainTemplate) {
            let imageProviderTrain = CLKImageProvider(onePieceImage: logo)
            switch complication.family {
            case .ModularSmall:
                let modularTemplate = CLKComplicationTemplateModularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .ModularLarge:
                template = nil
            case .UtilitarianSmall:
                let modularTemplate = CLKComplicationTemplateUtilitarianSmallSquare()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            case .UtilitarianLarge:
                template = nil
            case .CircularSmall:
                let modularTemplate = CLKComplicationTemplateCircularSmallSimpleImage()
                modularTemplate.imageProvider = imageProviderTrain
                modularTemplate.tintColor = tintColor
                template = modularTemplate
            }
        }
        handler(template)
    }
    
}
