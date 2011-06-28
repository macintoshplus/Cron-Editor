//
//  myController.m
//  CronEditor
//
//  Created by Jean-Baptiste Nahan on 15/02/08.
//  Copyright Jean-Baptiste Nahan 2008. All rights reserved.
//
//  Licence CeCILL-v2, see Licence_CeCILL_V2-fr.txt for more
//

#include <Security/Authorization.h>
#include <Security/AuthorizationDB.h>
#include <Security/AuthorizationTags.h>

#include <sys/types.h>
#include <unistd.h>

#import "myController.h"

@implementation myController
/* INIT */
- (id)init{
	self = [super init];
	if(self){
		_cronFile = [[NSMutableArray alloc] init];
		_cronFileTasks = [[NSMutableArray alloc] init];
		//NSLog(@"getuid = %i ; getgid = %i ; geteuid = %i",getuid(),getgid(),geteuid());
		//setuid(0);
		isModifier=FALSE;
		fileInEdit=FALSE;
		
		if(geteuid()!=0){
			if([self launchAuthPrgm]!=0) [NSApp terminate:self];
		}
	}
	
	return self;
}

- (void)awakeFromNib{
	//NSLog(@"awakeFromNib");
	
	 NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];	
    [toolbar setAutosavesConfiguration:YES];
    [mainwin setToolbar:[toolbar autorelease]];
	
	[edit_log removeAllItems];
	
	[self createCronFileMenu];
}

/* Others */
- (void)loadThisFile:(NSString*)path{
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory){
	
	if(geteuid()!=0 && ![[NSFileManager defaultManager] isReadableFileAtPath:path]){
		NSAlert * a = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"fileNotReadable",@"Localizable",@"Other") defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedStringFromTable(@"fileNotWritableDesc",@"Localizable",@"Other"),path]];
		[a beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
		fileInEdit=TRUE;
		isModifier=FALSE;
		NSString * content = [NSString stringWithContentsOfFile:path];
		//NSLog(@"content = %@",content);
		NSArray * ar = [content componentsSeparatedByString:@"\n"];
		//NSLog(@"ar = %@",ar);
		NSArray * param;
		NSString * s;
		NSEnumerator * e = [ar objectEnumerator];
		id obj;
		
		if(_cronFileTasks) [_cronFileTasks release];
		_cronFileTasks = [[NSMutableArray alloc] init];
		
		NSMutableDictionary * dico;
		
		while(obj = [e nextObject]){
			if([obj length]>0){
				//NSLog(@"Permier char : %c",[obj characterAtIndex:0]);
				if(![[NSString stringWithFormat:@"%c",[obj characterAtIndex:0]] isEqualToString:@"#"])
				{
					dico = [[NSMutableDictionary alloc] init];
					[dico setObject:obj forKey:@"ligne"];
					param = [obj componentsSeparatedByString:@" "];
					[dico setObject:[param objectAtIndex:0] forKey:@"minute"];
					[dico setObject:[param objectAtIndex:1] forKey:@"heure"];
					[dico setObject:[param objectAtIndex:2] forKey:@"jour"];
					[dico setObject:[param objectAtIndex:3] forKey:@"mois"];
					[dico setObject:[param objectAtIndex:4] forKey:@"jourSemaine"];
					s=[NSString stringWithFormat:@"%@ %@ %@ %@ %@ ",[param objectAtIndex:0],[param objectAtIndex:1],[param objectAtIndex:2],[param objectAtIndex:3],[param objectAtIndex:4]];
					param = [obj componentsSeparatedByString:s];
					//NSLog(@"%@",param);
					param = [[param objectAtIndex:1] componentsSeparatedByString:@">"];
					//NSLog(@"%@",param);
					[dico setObject:[param objectAtIndex:0] forKey:@"tache"];
					if([param count]>1) [dico setObject:[param objectAtIndex:1] forKey:@"log"];
					else [dico setObject:NSLocalizedStringFromTable(@"sendmail",@"Localizable",@"Other") forKey:@"log"];
					[dico setObject:[NSNumber numberWithBool:FALSE] forKey:@"DELETE"];
					
					//NSLog(@"%@",dico);
					
					[_cronFileTasks addObject:dico];
				}
			}//else NSLog(@"Ligne Vide");
		}
		
	}else{
		NSAlert * a = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"FileNotFound",@"Localizable",@"Other") defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedStringFromTable(@"FileNotFoundDesc",@"Localizable",@"Other"),path]];
		[a beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
	
	[cronDataTable reloadData];
}

- (void)saveFileAt:(NSString*)path{
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory){
	
	if(geteuid()!=0 && ![[NSFileManager defaultManager] isWritableFileAtPath:path]){
		NSAlert * a = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"fileNotWritable",@"Localizable",@"Other") defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedStringFromTable(@"fileNotWritableDesc",@"Localizable",@"Other"),path]];
		[a beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	
		NSString * content = [NSString stringWithContentsOfFile:path];
		//NSLog(@"content = %@",content);
		NSMutableArray * resultFile = [NSMutableArray arrayWithArray:[content componentsSeparatedByString:@"\n"]];
		//NSLog(@"resultFile = %@",resultFile);
		NSEnumerator * e;
		NSEnumerator * e2 = [_cronFileTasks objectEnumerator];
		
		//NSMutableArray * resultFile = [[NSMutableArray alloc] init];
		id obj;
		id obj2;
		
		int i=0;
		NSString * result;
		
		while(obj2 = [e2 nextObject]){
			
			// crŽation du rŽsultat de la ligne
			result = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@",[obj2 objectForKey:@"minute"],[obj2 objectForKey:@"heure"],[obj2 objectForKey:@"jour"],[obj2 objectForKey:@"mois"],[obj2 objectForKey:@"jourSemaine"],[obj2 objectForKey:@"tache"]];
			if([[obj2 objectForKey:@"log"] length]>0 && ![[obj2 objectForKey:@"log"] isEqualToString:NSLocalizedStringFromTable(@"sendmail",@"Localizable",@"Other")])
			result = [NSString stringWithFormat:@"%@ >%@",result,[obj2 objectForKey:@"log"]];
			
			if([[obj2 objectForKey:@"ligne"] length]>0){ //si pas une nouvelle ligne
				//e = [resultFile objectEnumerator];
				i=0;
				BOOL found=FALSE;
				while(i<[resultFile count] && found==FALSE){
					//NSLog(@"'%@' = '%@'",[obj2 objectForKey:@"ligne"],[resultFile objectAtIndex:i]);
					if([[obj2 objectForKey:@"ligne"] isEqualToString:[resultFile objectAtIndex:i]]){
						if([[obj2 objectForKey:@"DELETE"] isEqualTo:[NSNumber numberWithBool:FALSE]]){
							//NSLog(@"Ligne Egale et pas supprimer");
							[resultFile replaceObjectAtIndex:i withObject:result];
						}else{
							//NSLog(@"Ligne Egale et supprimer");
							[resultFile removeObjectAtIndex:i];
						}
						found=TRUE;
					}
					i++;
				}
			}else{ //nouvelle ligne

				//[obj2 setObject:result forKey:@"ligne"];
				//NSLog(@"%@",obj2);
				[resultFile addObject:result];
			}
		}
		
		//NSLog(@"resultFile : \n%@",resultFile);
		e = [resultFile objectEnumerator];
		NSString * fileString = [[NSString alloc] init];
		while(obj = [e nextObject]){
			fileString = [fileString stringByAppendingFormat:@"\n%@",obj];
		}
		
		//NSLog(@"fileString : \n%@",fileString);
		
		[fileString writeToFile:path atomically:NO];
		
		isModifier=FALSE;
		fileInEdit=FALSE;
		[self loadCronTab:cronFileMenu];
		
	}
}

- (void)createCronFileMenu{
	NSString * path = @"/etc/crontab";
	//NSLog(@"Path : %@",path);
	BOOL isDirectory;
	NSEnumerator * e;
	id obj;
	if([[NSFileManager defaultManager] fileExistsAtPath:path]){
		
		//NSLog(@"Path found : %@",path);
		[_cronFile addObject:path];
	}
	path = @"/var/cron/tabs/";
	//NSLog(@"Path : %@",path);
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory){
		//NSLog(@"Mac Os X Client");
		//NSLog(@"Path found : %@",path);
		NSArray * content = [[NSFileManager defaultManager] directoryContentsAtPath:path];
		e = [content objectEnumerator];
		NSString * filePath;
		
		while (obj = [e nextObject]){
			filePath = [NSString stringWithFormat:@"%@%@",path,obj];
			if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory){
				//Ajoute si le fichier existe et si c'est pas un dossier
				//NSLog(@"Path found : %@",filePath);
				[_cronFile addObject:filePath];
			}
		
		}
	}
	
	path = @"/usr/lib/cron/tabs/";
	//NSLog(@"Path : %@",path);
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory){
		//NSLog(@"Mac Os X Server");
		//NSLog(@"Path found : %@",path);
		NSArray * content = [[NSFileManager defaultManager] directoryContentsAtPath:path];
		e = [content objectEnumerator];
		NSString * filePath;
		
		while (obj = [e nextObject]){
			filePath = [NSString stringWithFormat:@"%@%@",path,obj];
			if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory){
				//Ajoute si le fichier existe et si c'est pas un dossier
				//NSLog(@"Path found : %@",filePath);
				[_cronFile addObject:filePath];
			}
		
		}
	}
	
	
	//NSLog(@"_cronFile : %@",_cronFile);
	
	[cronFileMenu removeAllItems];
	
	e = [_cronFile objectEnumerator];
	while(obj = [e nextObject]){
		[cronFileMenu addItemWithTitle:obj];
	}
	
	[cronFileMenu selectItemAtIndex:-1];
	
}

- (void)setDetailDataForRow:(int)rowIndex
{
	
    [edit_command setStringValue:[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"tache"]];
    [edit_dayOfMonth setStringValue:[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"jour"]];
	if([[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"jourSemaine"] isEqualToString:@"*"]) [edit_dayOfWeek selectItemWithTag:-1];
	else [edit_dayOfWeek selectItemWithTag:[[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"jourSemaine"] intValue]]; //popup
    [edit_hour setStringValue:[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"heure"]];
    [edit_log setStringValue:[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"log"]];
    [edit_minute setStringValue:[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"minute"]];
	if([[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"mois"] isEqualToString:@"*"]) [edit_month selectItemWithTag:-1];
    else [edit_month selectItemWithTag:[[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"mois"] intValue]]; //popup
}


- (void)setDefaultDetailData
{
	
    [edit_command setStringValue:@""];
    [edit_dayOfMonth setStringValue:@"*"];
    [edit_dayOfWeek selectItemWithTag:-1]; //popup
    [edit_hour setStringValue:@"*"];
    [edit_log setStringValue:NSLocalizedStringFromTable(@"sendmail",@"Localizable",@"Other")];
    [edit_minute setStringValue:@"*"];
    [edit_month selectItemWithTag:-1]; //popup
}


- (int) preAuthorize
{
	int						err;
    AuthorizationFlags      authFlags;


	//NSLog (@"MyWindowController: preAuthorize");

	if (_authRef)
		return errAuthorizationSuccess;
		
	//NSLog (@"MyWindowController: preAuthorize: ** calling AuthorizationCreate...**\n");
    
	authFlags = kAuthorizationFlagDefaults;
	err = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, authFlags, &_authRef);
	if (err != errAuthorizationSuccess)
		return err;

	//NSLog (@"MyWindowController: preAuthorize: ** calling AuthorizationCopyRights...**\n");
	
	_authItem.name = kAuthorizationRightExecute;
	_authItem.valueLength = 0;
	_authItem.value = NULL;
	_authItem.flags = 0;
	_authRights.count = 1;
	_authRights.items = (AuthorizationItem*) malloc (sizeof (_authItem));
	memcpy (&_authRights.items[0], &_authItem, sizeof (_authItem));
	authFlags = kAuthorizationFlagDefaults
		| kAuthorizationFlagExtendRights
		| kAuthorizationFlagInteractionAllowed
		| kAuthorizationFlagPreAuthorize;
	err = AuthorizationCopyRights (_authRef, &_authRights, kAuthorizationEmptyEnvironment, authFlags, NULL);
	
	return err;
}

- (int) launchAuthPrgm
{
    AuthorizationFlags      authFlags;
    int						err;

	// path
	NSString * path = [[NSBundle mainBundle] executablePath];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath: path])
		return -1;

    // auth
    
	if (!_authRef)
	{
		err = [self preAuthorize];
		if (err != errAuthorizationSuccess)
			return err;
	}

    // launch
    
   // NSLog (@"MyWindowController: launchWithPath: ** calling AuthorizationExecuteWithPrivileges...**\n");
    authFlags = kAuthorizationFlagDefaults;
    err = AuthorizationExecuteWithPrivileges (_authRef, [path cString], authFlags, NULL, NULL);  
    if(err==0) [NSApp terminate:self];
	
    return err;
}

/* DATA SOURCES */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
//NSLog(@"numberOfRowsInTableView : %i",[_cronFileTasks count]);
return [_cronFileTasks count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
NSString * s;
if([[aTableColumn identifier] isEqualToString:@"Time"]){
	s = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ ",[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"minute"],[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"heure"],[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"jour"],[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"mois"],[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"jourSemaine"]];
}else if([[aTableColumn identifier] isEqualToString:@"command"]){
	s = [NSString stringWithFormat:@"%@ %@ > %@",(([[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"DELETE"] isEqualTo:[NSNumber numberWithBool:TRUE]])? @"[DELETED]":@""),[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"tache"],[[_cronFileTasks objectAtIndex:rowIndex] objectForKey:@"log"]];
}

return s;
}


/* NSNotification */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	//NSLog(@"Changement de ligne : %i",[cronDataTable selectedRow]);
	if([cronDataTable selectedRow]>-1){
		[self setDetailDataForRow:[cronDataTable selectedRow]];
		[apply_button setEnabled:TRUE];
	}else{
		[self setDefaultDetailData];
		[apply_button setEnabled:FALSE];
		
	}
}

/*  COMBO DATA SOURCES */
- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox{
	return 2;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index{
	if(index==0) return NSLocalizedStringFromTable(@"sendmail",@"Localizable",@"Other");
	
	return @"/dev/null";
}

/* IBActions */

- (IBAction)addLine:(id)sender
{
	NSMutableDictionary * dico;
	dico = [[NSMutableDictionary alloc] init];
	[dico setObject:@"" forKey:@"ligne"];
	[dico setObject:@"*" forKey:@"minute"];
	[dico setObject:@"*" forKey:@"heure"];
	[dico setObject:@"*" forKey:@"jour"];
	[dico setObject:@"*" forKey:@"mois"];
	[dico setObject:@"*" forKey:@"jourSemaine"];
	[dico setObject:@"ls" forKey:@"tache"];
	[dico setObject:NSLocalizedStringFromTable(@"sendmail",@"Localizable",@"Other") forKey:@"log"];
	[dico setObject:[NSNumber numberWithBool:FALSE] forKey:@"DELETE"];
	
	//NSLog(@"%@",dico);
	
	[_cronFileTasks addObject:dico];
	[cronDataTable reloadData];
	[cronDataTable selectRow:[_cronFileTasks count]-1 byExtendingSelection:NO];
	isModifier=TRUE;
	
}

- (IBAction)applyChangeLine:(id)sender
{
	if([[edit_command stringValue] length]==0){
		NSAlert * a = [NSAlert alertWithMessageText:@"Command Not Found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a command line !"];
		[a beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
		return;
	}
	
	isModifier=TRUE;
	int i = [cronDataTable selectedRow];
	[[_cronFileTasks objectAtIndex:i] setObject:[edit_command stringValue] forKey:@"tache"];
	
	if([[edit_dayOfMonth stringValue] length]==0) [edit_dayOfMonth setStringValue:@"*"];
	[[_cronFileTasks objectAtIndex:i] setObject:[edit_dayOfMonth stringValue] forKey:@"jour"];
	
	if([edit_dayOfWeek selectedTag]==-1) [[_cronFileTasks objectAtIndex:i] setObject:@"*" forKey:@"jourSemaine"];
	
	else [[_cronFileTasks objectAtIndex:i] setObject:[NSString stringWithFormat:@"%i",[edit_dayOfWeek selectedTag]] forKey:@"jourSemaine"]; //popup
	
	if([[edit_hour stringValue] length]==0) [edit_hour setStringValue:@"*"];
	[[_cronFileTasks objectAtIndex:i] setObject:[edit_hour stringValue] forKey:@"heure"];
	
	if([[edit_log stringValue] length]==0) [edit_log setStringValue:@"send mail"];
	[[_cronFileTasks objectAtIndex:i] setObject:[edit_log stringValue] forKey:@"log"];
	
	if([[edit_minute stringValue] length]==0) [edit_minute setStringValue:@"*"];
	[[_cronFileTasks objectAtIndex:i] setObject:[edit_minute stringValue] forKey:@"minute"];
	
	if([edit_month selectedTag]==-1) [[_cronFileTasks objectAtIndex:i] setObject:@"*" forKey:@"mois"];
	else [[_cronFileTasks objectAtIndex:i] setObject:[NSString stringWithFormat:@"%i",[edit_month selectedTag]] forKey:@"mois"]; //popup
	
	[cronDataTable reloadData];
	
}

- (IBAction)cancelCronTab:(id)sender
{
	[self loadThisFile:[[cronFileMenu selectedItem] title]];
	[self setDefaultDetailData];
}

- (IBAction)deleteLine:(id)sender
{
	int i = [cronDataTable selectedRow];
	[[_cronFileTasks objectAtIndex:i] setObject:[NSNumber numberWithBool:TRUE] forKey:@"DELETE"];
	[cronDataTable reloadData];
}

- (IBAction)editLine:(id)sender
{
}

- (IBAction)loadCronTab:(id)sender
{
	//NSLog(@"Charger : %@",[[sender selectedItem] title]);
	
	[apply_button setEnabled:FALSE];
	[self loadThisFile:[[sender selectedItem] title]];
}

- (IBAction)presetSelected:(id)sender
{
	/*
	-1 = Preset!
	
	10 = Tous les lundi
	11 = Tous les Samedi
	
	20 = Toutes les minutes
	21 = Toutes les heures
	22 = Tous les jours
	23 = Tous les mois
	24 = Tous les ans
	*/
	int val = [sender selectedTag];
	if(val==10){
		[edit_dayOfMonth setStringValue:@"*"];
		[edit_dayOfWeek selectItemWithTag:1]; //popup
		[edit_hour setStringValue:@"0"];
		[edit_minute setStringValue:@"0"];
		[edit_month selectItemWithTag:-1]; //popup
	}else if(val==11){
		[edit_dayOfMonth setStringValue:@"*"];
		[edit_dayOfWeek selectItemWithTag:0]; //popup
		[edit_hour setStringValue:@"0"];
		[edit_minute setStringValue:@"0"];
		[edit_month selectItemWithTag:-1]; //popup
	}else if(val==20){
		[edit_dayOfMonth setStringValue:@"*"];
		[edit_dayOfWeek selectItemWithTag:-1]; //popup
		[edit_hour setStringValue:@"*"];
		[edit_minute setStringValue:@"*"];
		[edit_month selectItemWithTag:-1]; //popup
	}else if(val==21){
		[edit_dayOfMonth setStringValue:@"*"];
		[edit_dayOfWeek selectItemWithTag:-1]; //popup
		[edit_hour setStringValue:@"*"];
		[edit_minute setStringValue:@"0"];
		[edit_month selectItemWithTag:-1]; //popup
	}else if(val==22){
		[edit_dayOfMonth setStringValue:@"*"];
		[edit_dayOfWeek selectItemWithTag:-1]; //popup
		[edit_hour setStringValue:@"0"];
		[edit_minute setStringValue:@"0"];
		[edit_month selectItemWithTag:-1]; //popup
	}else if(val==23){
		[edit_dayOfMonth setStringValue:@"1"];
		[edit_dayOfWeek selectItemWithTag:-1]; //popup
		[edit_hour setStringValue:@"0"];
		[edit_minute setStringValue:@"0"];
		[edit_month selectItemWithTag:-1]; //popup
	}else if(val==24){
		[edit_dayOfMonth setStringValue:@"1"];
		[edit_dayOfWeek selectItemWithTag:-1]; //popup
		[edit_hour setStringValue:@"0"];
		[edit_minute setStringValue:@"0"];
		[edit_month selectItemWithTag:1]; //popup
	}
	[sender selectItemWithTag:-1];
}

- (IBAction)saveCronTab:(id)sender
{
	[self saveFileAt:[[cronFileMenu selectedItem] title]];
}


/*********************************/
/*            TOOLBAR            */
/*********************************/

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ( [itemIdentifier isEqualToString:@"AddItem"] ) {
		[item setLabel:NSLocalizedStringFromTable(@"Add",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setImage:[NSImage imageNamed:@"list-add"]];
		[item setTarget:self];
		[item setAction:@selector(addLine:)];
    } else if ( [itemIdentifier isEqualToString:@"RemoveItem"] ) {
		[item setLabel:NSLocalizedStringFromTable(@"Del",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setImage:[NSImage imageNamed:@"list-remove"]];
		[item setTarget:self];
		[item setAction:@selector(deleteLine:)];
    } else if ( [itemIdentifier isEqualToString:@"CancelModif"] ) {
		[item setLabel:NSLocalizedStringFromTable(@"UndoC",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setImage:[NSImage imageNamed:@"edit-undo"]];
		[item setTarget:self];
		[item setAction:@selector(cancelCronTab:)];
    } else if ( [itemIdentifier isEqualToString:@"SaveFile"] ) {
		[item setLabel:NSLocalizedStringFromTable(@"SaveC",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setImage:[NSImage imageNamed:@"document-save"]];
		[item setTarget:self];
		[item setAction:@selector(saveCronTab:)];
    } /*else if ( [itemIdentifier isEqualToString:@"SearchItem"] ) {
		NSRect fRect = [searchItemView frame];
		
		[item setLabel:NSLocalizedStringFromTable(@"Find",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setView:searchItemView];
		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];	
    } else if ( [itemIdentifier isEqualToString:@"SearchItemType"] ) {
		NSRect fRect = [searchItemViewType frame];
		
		[item setLabel:NSLocalizedStringFromTable(@"FindByType",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setView:searchItemViewType];
		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];	
    } else if ( [itemIdentifier isEqualToString:@"ListViewMode"] ) {
		NSRect fRect = [searchItemViewType frame];
		
		[item setLabel:NSLocalizedStringFromTable(@"ListMode",@"Localizable",@"Tools")];
		[item setPaletteLabel:[item label]];
		[item setView:listViewType];
		[item setMinSize:fRect.size];
		[item setMaxSize:fRect.size];	
    } */

    return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
				    NSToolbarSpaceItemIdentifier,
				    NSToolbarFlexibleSpaceItemIdentifier,
				    NSToolbarCustomizeToolbarItemIdentifier,
					NSToolbarPrintItemIdentifier,
				    @"AddItem", @"RemoveItem", @"CancelModif", @"SaveFile", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"AddItem", @"RemoveItem",
		NSToolbarFlexibleSpaceItemIdentifier,
		@"SaveFile", @"CancelModif", NSToolbarFlexibleSpaceItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ( [theItem action] == @selector(addLine:) )
		return fileInEdit;
	if ( [theItem action] == @selector(deleteLine:) )
		return [cronDataTable numberOfSelectedRows] > 0;
		
	if ( [theItem action] == @selector(cancelCronTab:) )
		return isModifier;
	if ( [theItem action] == @selector(saveCronTab:) )
		return isModifier;
	
	return YES;
}

@end
