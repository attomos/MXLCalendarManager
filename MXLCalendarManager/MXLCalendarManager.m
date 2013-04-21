//
//  MXLCalendarManager.m
//  ICSExporter
//
//  Created by Kiran Panesar on 09/04/2013.
//  Copyright (c) 2013 MobileX Labs. All rights reserved.
//

#import "MXLCalendarManager.h"

@implementation MXLCalendarManager

-(void)scanICSFileAtLocalPath:(NSString *)filePath withCompletionHandler:(void (^)(MXLCalendar *, NSError *))callback {
    NSError *fileError;
    NSString *calendarFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&fileError];
    
    if (fileError) {
        callback(nil, fileError);
        return;
    }
    
    // Pull out each line from the calendar file
    NSMutableArray *eventsArray = [NSMutableArray arrayWithArray:[calendarFile componentsSeparatedByString:@"BEGIN:VEVENT"]];
    
    // Remove the first item (that's just all the stuff before the first VEVENT)
    if ([eventsArray count] > 0)
        [eventsArray removeObjectAtIndex:0];
    
    NSScanner *eventScanner;
    
    MXLCalendar *calendar = [[MXLCalendar alloc] init];
    
    // For each event, extract the data
    for (NSString *event in eventsArray) {
        NSString *timezoneIDString;
        NSString *startDateTimeString;
        NSString *endDateTimeString;
        NSString *eventUniqueIDString;
        NSString *recurrenceIDString;
        NSString *createdDateTimeString;
        NSString *descriptionString;
        NSString *lastModifiedDateTimeString;
        NSString *locationString;
        NSString *sequenceString;
        NSString *statusString;
        NSString *summaryString;
        NSString *transString;
        NSString *timeStampString;
        NSString *repetitionString;
        NSString *exceptionRuleString;
        NSMutableArray *exceptionDates = [[NSMutableArray alloc] init];
        
        // Extract event time zone ID
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"DTSTART;TZID=" intoString:nil];
        [eventScanner scanUpToString:@":" intoString:&timezoneIDString];
        timezoneIDString = [[timezoneIDString stringByReplacingOccurrencesOfString:@"DTSTART;TZID=" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        // Extract start time
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:[NSString stringWithFormat:@"DTSTART;TZID=%@:", timezoneIDString] intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&startDateTimeString];
        startDateTimeString = [[startDateTimeString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"DTSTART;TZID=%@:", timezoneIDString] withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        if (!startDateTimeString) {
            eventScanner = [NSScanner scannerWithString:event];
            [eventScanner scanUpToString:@"DTSTART:" intoString:nil];
            [eventScanner scanUpToString:@"\n" intoString:&startDateTimeString];
            startDateTimeString = [[startDateTimeString stringByReplacingOccurrencesOfString:@"DTSTART:" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        }
        
        // Extract end time
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:[NSString stringWithFormat:@"DTEND;TZID=%@:", timezoneIDString] intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&endDateTimeString];
        endDateTimeString = [[endDateTimeString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"DTEND;TZID=%@:", timezoneIDString] withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        if (!endDateTimeString) {
            eventScanner = [NSScanner scannerWithString:event];
            [eventScanner scanUpToString:@"DTEND:" intoString:nil];
            [eventScanner scanUpToString:@"\n" intoString:&endDateTimeString];
            endDateTimeString = [[endDateTimeString stringByReplacingOccurrencesOfString:@"DTEND:" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        }
        
        // Extract timestamp
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"DTSTAMP:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&timeStampString];
        timeStampString = [[timeStampString stringByReplacingOccurrencesOfString:@"DTSTAMP:" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract the unique ID
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"UID:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&eventUniqueIDString];
        eventUniqueIDString = [[eventUniqueIDString stringByReplacingOccurrencesOfString:@"UID:" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract the recurrance ID
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:[NSString stringWithFormat:@"RECURRENCE-ID;TZID=%@:", timezoneIDString] intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&recurrenceIDString];
        recurrenceIDString = [[recurrenceIDString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"RECURRENCE-ID;TZID=%@:", timezoneIDString] withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];

        // Extract the created datetime
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"CREATED:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&createdDateTimeString];
        createdDateTimeString = [[createdDateTimeString stringByReplacingOccurrencesOfString:@"CREATED:" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        
        // Extract event description
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"DESCRIPTION:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&descriptionString];
        descriptionString = [[[descriptionString stringByReplacingOccurrencesOfString:@"DESCRIPTION:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract last modified datetime
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"LAST-MODIFIED:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&lastModifiedDateTimeString];
        lastModifiedDateTimeString = [[[lastModifiedDateTimeString stringByReplacingOccurrencesOfString:@"LAST-MODIFIED:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract the event location
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"LOCATION:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&locationString];
        locationString = [[[locationString stringByReplacingOccurrencesOfString:@"LOCATION:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];

        // Extract the event sequence
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"SEQUENCE:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&sequenceString];
        sequenceString = [[[sequenceString stringByReplacingOccurrencesOfString:@"SEQUENCE:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];

        // Extract the event status
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"STATUS:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&statusString];
        statusString = [[[statusString stringByReplacingOccurrencesOfString:@"STATUS:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];

        // Extract the event summary
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"SUMMARY:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&summaryString];
        summaryString = [[[summaryString stringByReplacingOccurrencesOfString:@"SUMMARY:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract the event transString
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"TRANSP:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&transString];
        transString = [[[transString stringByReplacingOccurrencesOfString:@"TRANSP:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract the event repetition rules
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"RRULE:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&repetitionString];
        repetitionString = [[[repetitionString stringByReplacingOccurrencesOfString:@"RRULE:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Extract the event exception rules
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"EXRULE:" intoString:nil];
        [eventScanner scanUpToString:@"\n" intoString:&exceptionRuleString];
        exceptionRuleString = [[[exceptionRuleString stringByReplacingOccurrencesOfString:@"EXRULE:" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        
        // Set up scanner for 
        eventScanner = [NSScanner scannerWithString:event];
        [eventScanner scanUpToString:@"EXDATE;" intoString:nil];

        while (![eventScanner isAtEnd]) {
            [eventScanner scanUpToString:@":" intoString:nil];
            NSString *exceptionString = [[NSString alloc] init];
            [eventScanner scanUpToString:@"\n" intoString:&exceptionString];
            exceptionString = [[[exceptionString stringByReplacingOccurrencesOfString:@":" withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            
            if (exceptionString) {
                [exceptionDates addObject:exceptionString];
            }
            
            [eventScanner scanUpToString:@"EXDATE;" intoString:nil];
        }
        
        MXLCalendarEvent *event = [[MXLCalendarEvent alloc] initWithStartDate:startDateTimeString
                                                                      endDate:endDateTimeString
                                                                    createdAt:createdDateTimeString
                                                                 lastModified:lastModifiedDateTimeString
                                                                     uniqueID:eventUniqueIDString
                                                                 recurrenceID:recurrenceIDString
                                                                      summary:summaryString
                                                                  description:descriptionString
                                                                     location:locationString
                                                                       status:statusString
                                                              recurrenceRules:repetitionString
                                                               exceptionDates:exceptionDates
                                                                exceptionRule:exceptionRuleString
                                                           timeZoneIdentifier:timezoneIDString];
        [calendar addEvent:event];
        
    }
    
    callback(calendar, nil);
}

@end