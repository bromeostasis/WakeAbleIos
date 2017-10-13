//
//  MailController.m
//  Wakeable
//
//  Created by Evan Snyder on 10/12/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MailController.h"

@implementation MailController

+ (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

+ (void) sendWakeableEmail {
    if (![MFMailComposeViewController canSendMail]) {
        NSLog(@"Mail services are not available.");
        return;
    }
    
    MFMailComposeViewController* mailComposer = [[MFMailComposeViewController alloc] init];
    
    mailComposer.mailComposeDelegate = self;
    [mailComposer setSubject:@"This thing didn't work!"];
    NSArray *toRecipients = [NSArray arrayWithObject:@"wakeable.team@gmail.com"];
    [mailComposer setToRecipients:toRecipients];
    NSString *emailBody = @"We love feedback! Please include below: a short description of the problem your facing along with the approximate time of failure if possible. We'll look into the problem and get back to you as soon as possible.";
    [mailComposer setMessageBody:emailBody isHTML:NO];
    
    [self attachCrashLogs:mailComposer];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mailComposer animated:YES completion:nil];
}

+ (void) attachCrashLogs:(MFMailComposeViewController *) mailComposer {
    // Attach the Crash Log..
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"wakeable-log.txt"];
    NSData *myData = [NSData dataWithContentsOfFile:logPath];
    [mailComposer addAttachmentData:myData mimeType:@"Text/XML" fileName:@"wakeable-log.txt"];
}

@end
