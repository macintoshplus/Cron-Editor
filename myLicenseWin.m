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
