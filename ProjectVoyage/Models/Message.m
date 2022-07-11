//
//  Message.m
//  ProjectVoyage
//
//  Created by Gui David on 7/8/22.
//

#import "Message.h"

@implementation Message

- (id)init {
    self = [super init];
    if (self)
    {
        self.sender = MessageSenderMyself;
        self.status = MessageStatusSending;
        self.text = @"";
        self.height = 44;
        self.date = [NSDate date];
        self.identifier = @"";
    }
    return self;
}

+ (Message *)messageFromDictionary:(NSDictionary *)dictionary {
    Message *message = [[Message alloc] init];
    message.text = dictionary[@"text"];
    message.identifier = dictionary[@"message_id"];
    message.status = [dictionary[@"status"] integerValue] + 1;
    
    NSString *dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSS";
    
    //Date in UTC
    NSTimeZone *inputTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
    [inputDateFormatter setTimeZone:inputTimeZone];
    [inputDateFormatter setDateFormat:dateFormat];
    NSDate *date = [inputDateFormatter dateFromString:dictionary[@"sent"]];
    
    //Convert time in UTC to Local TimeZone
    NSTimeZone *outputTimeZone = [NSTimeZone localTimeZone];
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
    [outputDateFormatter setTimeZone:outputTimeZone];
    [outputDateFormatter setDateFormat:dateFormat];
    NSString *outputString = [outputDateFormatter stringFromDate:date];
    
    message.date = [outputDateFormatter dateFromString:outputString];
    
    return message;
}

@end
