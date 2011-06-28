//
//  myLicenseWin.m
//  CronEditor
//
//  Created by Jean-Baptiste Nahan on 15/02/08.
//  Copyright Jean-Baptiste Nahan 2008. All rights reserved.
//
//  Licence CeCILL-v2, see Licence_CeCILL_V2-fr.txt for more
//

#import "myLicenseWin.h"

@implementation myLicenseWin

- (void) awakeFromNib
{
	NSString *path;
	path = [[NSBundle mainBundle] pathForResource:@"Licence_CeCILL_V2-fr" ofType:@"txt"];
	//[content setStringValue:[NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:nil]];
	[content insertText:[NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:nil]];
}


@end
