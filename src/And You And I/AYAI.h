//
//  AYAI.h
//  And You And I
//
//  Created by sga on 08.03.14.
//  Copyright (c) 2014 Stephan André. All rights reserved.
//

#import "FIXMES.h"
#import "iToast.h"
#import "AYAIAppDelegate.h"

#pragma mark Global macros and defines

#define LS(string) NSLocalizedString(@string, nil)

#define DARKTOASTER(string) {NSLog(LS(string));[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:LS(string)] setGravity:iToastGravityCenter] setDuration:iToastDurationLong] setFontSize:18] setUseShadow:FALSE] setBgRed:100.0/255] setBgGreen:100.0/255] setBgBlue:100.0/255] setBgAlpha:1.0] show];}];}

#define BLUETOASTER(string) {NSLog(LS(string));[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:LS(string)] setGravity:iToastGravityBottom] setDuration:iToastDurationShort] setFontSize:13] setUseShadow:FALSE] setBgRed:50.0/255] setBgGreen:50.0/255] setBgBlue:250.0/255] setBgAlpha:1.0] show];}];}
#define REDTOASTER(string) {NSLog(LS(string));[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:LS(string)] setGravity:iToastGravityBottom] setDuration:iToastDurationLong] setFontSize:13] setUseShadow:FALSE] setBgRed:250.0/255] setBgGreen:50.0/255] setBgBlue:50.0/255] setBgAlpha:1.0] show];}];}
#define GREENTOASTER(string) {NSLog(LS(string));[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:LS(string)] setGravity:iToastGravityBottom] setDuration:iToastDurationShort] setFontSize:13] setUseShadow:FALSE] setBgRed:50.0/255] setBgGreen:200.0/255] setBgBlue:50.0/255] setBgAlpha:1.0] show];}];}
#define YELLOWTOASTER(string) {NSLog(LS(string));[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:LS(string)] setGravity:iToastGravityBottom] setDuration:iToastDurationShort] setFontSize:13] setUseShadow:FALSE] setBgRed:200.0/255] setBgGreen:200.0/255] setBgBlue:50.0/255] setBgAlpha:1.0] show];}];}
#define GRAYTOASTER(string) {NSLog(LS(string));[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:LS(string)] setGravity:iToastGravityBottom] setDuration:iToastDurationShort] setFontSize:13] setUseShadow:FALSE] setBgRed:200.0/255] setBgGreen:200.0/255] setBgBlue:200.0/255] setBgAlpha:1.0] show];}];}

#define BLUETOASTERNS(string) {NSLog(@"%@",string);[[NSOperationQueue mainQueue] addOperationWithBlock:^{[[[[[[[[[[iToast makeText:string] setGravity:iToastGravityBottom] setDuration:iToastDurationShort] setFontSize:13] setUseShadow:FALSE] setBgRed:50.0/255] setBgGreen:50.0/255] setBgBlue:250.0/255] setBgAlpha:1.0] show];}];}

