/* myController */
//
//  myController.h
//  CronEditor
//
//  Created by Jean-Baptiste Nahan on 15/02/08.
//  Copyright Jean-Baptiste Nahan 2008. All rights reserved.
//
//  Licence CeCILL-v2, see Licence_CeCILL_V2-fr.txt for more
//

#import <Cocoa/Cocoa.h>

@interface myController : NSObject
{
    IBOutlet NSTableView *cronDataTable;
    IBOutlet NSPopUpButton *cronFileMenu;
    IBOutlet NSTextField *edit_command;
    IBOutlet NSTextField *edit_dayOfMonth;
    IBOutlet NSPopUpButton *edit_dayOfWeek;
    IBOutlet NSTextField *edit_hour;
    IBOutlet NSComboBox *edit_log;
    IBOutlet NSTextField *edit_minute;
    IBOutlet NSPopUpButton *edit_month;
    IBOutlet NSPopUpButton *presetMenu;
    IBOutlet NSButton *apply_button;
	IBOutlet NSWindow *mainwin;
	
	NSMutableArray * _cronFile;
	
	NSMutableArray * _cronFileTasks;
	
	BOOL fileInEdit;
	BOOL isModifier;
	
    AuthorizationRef                _authRef;
    AuthorizationItem               _authItem;
    AuthorizationRights             _authRights;
	
	
}
/* Others */

- (void)loadThisFile:(NSString*)path;
- (void)saveFileAt:(NSString*)path;
- (void)createCronFileMenu;
- (void)setDetailDataForRow:(int)rowIndex;
- (void)setDefaultDetailData;
- (int) preAuthorize;
- (int) launchAuthPrgm;

/*  IBACTION */
- (IBAction)addLine:(id)sender;
- (IBAction)applyChangeLine:(id)sender;
- (IBAction)cancelCronTab:(id)sender;
- (IBAction)deleteLine:(id)sender;
- (IBAction)editLine:(id)sender;
- (IBAction)loadCronTab:(id)sender;
- (IBAction)presetSelected:(id)sender;
- (IBAction)saveCronTab:(id)sender;
@end
