/*
 *  $Id$
 *
 *  Copyright (C) 2005, 2006 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "FormatsPreferencesController.h"
#import "CoreAudioUtilities.h"
#import "EncoderController.h"
#import "EncoderSettingsSheet.h"
#import "CoreAudioSettingsSheet.h"
#import "LibsndfileSettingsSheet.h"
#import "FLACSettingsSheet.h"
#import "MonkeysAudioSettingsSheet.h"
#import "WavPackSettingsSheet.h"
#import "OggVorbisSettingsSheet.h"
#import "MP3SettingsSheet.h"
#import "SpeexSettingsSheet.h"

#import "CoreAudioUtilities.h"

#include <sndfile/sndfile.h>

@implementation FormatsPreferencesController

- (id) init
{
	NSMutableArray			*libsndfileFormats;
	NSArray					*coreAudioFormats;
	NSDictionary			*formatDictionary;
	SF_FORMAT_INFO			formatInfo;
	SF_INFO					info;
	NSArray					*objects;
	NSArray					*keys;
	int						i, majorCount;
	unsigned				j;

	if((self = [super initWithWindowNibName:@"FormatsPreferences"])) {
		
		coreAudioFormats			= getCoreAudioWritableTypes();
		libsndfileFormats			= [NSMutableArray arrayWithCapacity:20];
		_availableFormats			= [NSMutableArray array];

		// Get the list of libsndfile major formats
		sf_command(NULL, SFC_GET_FORMAT_MAJOR_COUNT, &majorCount, sizeof(int)) ;
		
		// Generic defaults
		info.channels		= 1;
		info.samplerate		= 0;

		// Loop through each major format and add it to the list of available formats
		for(i = 0; i < majorCount; ++i) {
			formatInfo.format = i;
			sf_command(NULL, SFC_GET_FORMAT_MAJOR, &formatInfo, sizeof(formatInfo));
			
			objects = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:formatInfo.format],
				[NSString stringWithCString:formatInfo.name encoding:NSASCIIStringEncoding],
				[NSString stringWithCString:formatInfo.extension encoding:NSASCIIStringEncoding],
				nil];
			
			keys = [NSArray arrayWithObjects:
				@"format",
				@"name",
				@"extension",
				nil];

			[libsndfileFormats addObject:[NSMutableDictionary dictionaryWithObjects:objects forKeys:keys]];
		}
		
		// Add the built-in formats to the list
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"FLAC", @"Built-In", [NSNumber numberWithInt:kComponentFLAC], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Ogg FLAC", @"Built-In", [NSNumber numberWithInt:kComponentOggFLAC], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Monkey's Audio", @"Built-In", [NSNumber numberWithInt:kComponentMonkeysAudio], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"WavPack", @"Built-In", [NSNumber numberWithInt:kComponentWavPack], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Ogg Vorbis", @"Built-In", [NSNumber numberWithInt:kComponentOggVorbis], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"MP3", @"Built-In", [NSNumber numberWithInt:kComponentMP3], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		[_availableFormats addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Speex", @"Built-In", [NSNumber numberWithInt:kComponentSpeex], nil] forKeys:[NSArray arrayWithObjects:@"name", @"source", @"component", nil]]];
		
		// Add CoreAudio formats
		for(j = 0; j < [coreAudioFormats count]; ++j) {
			formatDictionary = [coreAudioFormats objectAtIndex:j];

			objects = [NSArray arrayWithObjects:
				[formatDictionary objectForKey:@"fileTypeName"],
				@"Core Audio",
				[NSNumber numberWithInt:kComponentCoreAudio],
				[formatDictionary objectForKey:@"fileType"],
				[formatDictionary objectForKey:@"extensionsForType"],
				[formatDictionary objectForKey:@"dataFormats"],
				nil];
			
			keys = [NSArray arrayWithObjects:
				@"name",
				@"source",
				@"component",
				@"fileType",
				@"extensionsForType",
				@"dataFormats",
				nil];
			
			[_availableFormats addObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
		}

		// Add libsndfile formats
		for(j = 0; j < [libsndfileFormats count]; ++j) {
			formatDictionary = [libsndfileFormats objectAtIndex:j];

			objects = [NSArray arrayWithObjects:
				[formatDictionary objectForKey:@"name"],
				@"libsndfile",
				[NSNumber numberWithInt:kComponentLibsndfile],
				[formatDictionary objectForKey:@"format"],
				[formatDictionary objectForKey:@"extension"],
				nil];
			
			keys = [NSArray arrayWithObjects:
				@"name",
				@"source",
				@"component",
				@"majorFormat",
				@"extension",
				nil];
			
			[_availableFormats addObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
			
			NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
			_availableFormats = [[_availableFormats sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]] retain];

		}
		
		return self;		
	}
	
	return nil;
}

- (void) dealloc
{
	[_availableFormats release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[_configuredFormatsController setSortDescriptors:[NSArray arrayWithObjects:
		[[[NSSortDescriptor alloc] initWithKey:@"active" ascending:YES] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:@"nickname" ascending:YES] autorelease],
		nil]];
	
	[_availableFormatsController setSortDescriptors:[NSArray arrayWithObjects:
		[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:@"source" ascending:YES] autorelease],
		nil]];
}

- (IBAction)		addOutputFormat:(id)sender
{
	NSMutableDictionary		*result					= nil;
	NSDictionary			*defaultSettings		= nil;
	NSMutableDictionary		*customSettings			= nil;
	NSArray					*types					= nil;
	NSDictionary			*type					= nil;
	unsigned				i						= 0;

	result	= [NSMutableDictionary dictionary];
	types	= [_availableFormatsController selectedObjects];
	
	for(i = 0; i < [types count]; ++i) {
		type = [types objectAtIndex:i];
		
		[result setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
		[result setObject:[type valueForKey:@"name"] forKey:@"name"];
		[result setObject:[type valueForKey:@"source"] forKey:@"source"];
		[result setObject:[type valueForKey:@"component"] forKey:@"component"];
		
		// Configure default encoder settings
		switch([[result objectForKey:@"component"] intValue]) {			

			// Libraries
			case kComponentCoreAudio:
				customSettings = [NSMutableDictionary dictionary];
				[customSettings addEntriesFromDictionary:[CoreAudioSettingsSheet defaultSettings]];
				[customSettings setObject:[type objectForKey:@"fileType"] forKey:@"fileType"];
				[customSettings setObject:[type objectForKey:@"name"] forKey:@"fileTypeName"];
				[customSettings setObject:[type objectForKey:@"extensionsForType"] forKey:@"extensionsForType"];
				defaultSettings = customSettings;
				break;

			case kComponentLibsndfile:
				customSettings = [NSMutableDictionary dictionary];
				[customSettings addEntriesFromDictionary:[LibsndfileSettingsSheet defaultSettings]];
				[customSettings setObject:[type objectForKey:@"majorFormat"] forKey:@"majorFormat"];
				[customSettings setObject:[type objectForKey:@"extension"] forKey:@"extension"];
				defaultSettings = customSettings;
				break;

			// Lossless/hybrid compressors
			case kComponentFLAC:			defaultSettings = [FLACSettingsSheet defaultSettings];				break;
			case kComponentOggFLAC:			defaultSettings = [FLACSettingsSheet defaultSettings];				break;
			case kComponentMonkeysAudio:	defaultSettings = [MonkeysAudioSettingsSheet defaultSettings];		break;
			case kComponentWavPack:			defaultSettings = [WavPackSettingsSheet defaultSettings];			break;
				
			// Lossy encoders
			case kComponentOggVorbis:		defaultSettings = [OggVorbisSettingsSheet defaultSettings];			break;
			case kComponentMP3:				defaultSettings = [MP3SettingsSheet defaultSettings];				break;
			case kComponentSpeex:			defaultSettings = [SpeexSettingsSheet defaultSettings];				break;

			default:						defaultSettings = [NSDictionary dictionary];						break;
		}
		
		[result setObject:defaultSettings forKey:@"userInfo"];
		
		if(NO == [[_configuredFormatsController arrangedObjects] containsObject:result]) {
			[_configuredFormatsController addObject:result];
			[_configuredFormatsController setSelectedObjects:[NSArray arrayWithObject:result]];
			[self editOutputFormat:self];
		}
	}	
}

- (IBAction)		removeOutputFormat:(id)sender
{
	if(NSNotFound != [_configuredFormatsController selectionIndex]) {
		[_configuredFormatsController removeObjectAtArrangedObjectIndex:[_configuredFormatsController selectionIndex]];
	}
}

- (IBAction)		editOutputFormat:(id)sender
{
	unsigned				idx						= 0;
	NSMutableDictionary		*format					= nil;
	NSMutableDictionary		*settings				= nil;
	EncoderSettingsSheet	*settingsSheet			= nil;
	Class					settingsSheetClass		= nil;
	
	idx			= [_configuredFormatsController selectionIndex];

	if(NSNotFound == idx) {
		return;
	}
	
	format		= [[_configuredFormatsController arrangedObjects] objectAtIndex:idx];	
	settings	= [format objectForKey:@"userInfo"];
	
	switch([[format objectForKey:@"component"] intValue]) {

		case kComponentCoreAudio:		settingsSheetClass = [CoreAudioSettingsSheet class];		break;
		case kComponentLibsndfile:		settingsSheetClass = [LibsndfileSettingsSheet class];		break;

		case kComponentFLAC:			settingsSheetClass = [FLACSettingsSheet class];				break;
		case kComponentOggFLAC:			settingsSheetClass = [FLACSettingsSheet class];				break;
		case kComponentMonkeysAudio:	settingsSheetClass = [MonkeysAudioSettingsSheet class];		break;
		case kComponentWavPack:			settingsSheetClass = [WavPackSettingsSheet class];			break;

		case kComponentOggVorbis:		settingsSheetClass = [OggVorbisSettingsSheet class];		break;
		case kComponentMP3:				settingsSheetClass = [MP3SettingsSheet class];				break;
		case kComponentSpeex:			settingsSheetClass = [SpeexSettingsSheet class];			break;
			
		default:
			NSLog(@"Unknown component %@", [format objectForKey:@"component"]);
			break;
	}

	settingsSheet = [[[settingsSheetClass alloc] initWithSettings:settings] autorelease];
	[settingsSheet setSearchKey:format];
	[settingsSheet setUserInfo:format];
	[settingsSheet editSettings];
}		

- (unsigned)		countOfAvailableFormats							{ return [_availableFormats count]; }
- (NSDictionary *)	objectInAvailableFormatsAtIndex:(unsigned)idx	{ return [_availableFormats objectAtIndex:idx]; }

@end