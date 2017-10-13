//
//  MailController.h
//  Wakeable
//
//  Created by Evan Snyder on 10/12/17.
//  Copyright © 2017 Evan Snyder. All rights reserved.
//

#ifndef MailController_h
#define MailController_h

#import <MessageUI/MFMailComposeViewController.h>

@interface MailController : NSObject<MFMailComposeViewControllerDelegate>

+ (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error;
+ (void) sendWakeableEmail;

@end

#endif /* MailController_h */
