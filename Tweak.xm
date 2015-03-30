#import "Headers.h"

#define WINTERBOARD_PREFS_PATH [NSHomeDirectory() stringByAppendingString:@"/Library/Preferences/com.saurik.WinterBoard.plist"]
#define THEME_BASE_PATH @"/Library/Themes"

static NSMutableDictionary * dictToApply = nil;



// GETS UICOLOR FROM A HEX STRING OF FORMAT #XXXXXX

static UIColor* UIColorFromHexString(NSString* hexString) {
  if(!hexString || ![hexString isKindOfClass:[NSString class]])
    return nil;
  unsigned rgbValue = 0;
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:1]; // bypass '#' character
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

// DARKENS UICOLOUR TO SPECIFIED BRIGHTNESS

static UIColor * DarkenedUIColor(UIColor* color, CGFloat mod) {
  CGFloat hue, saturation, brightness, alpha;
  if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
		return [UIColor colorWithHue:hue saturation:saturation brightness:brightness*mod alpha:alpha];
	}

  CGFloat white;
  if ([color getWhite:&white alpha:&alpha])
    return [UIColor colorWithWhite:white alpha:alpha];

  return nil;
}

// CHANGES THE COLOUR OF A UIIMAGE WHILE MAINTAINING ALPHA VALUES

static UIImage * imageWithBurnTint(UIImage * img, UIColor* color) {
  UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0, img.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGContextDrawImage(context, rect, img.CGImage);
  CGContextSetBlendMode(context, kCGBlendModeSourceIn);
  [color setFill];
  CGContextFillRect(context, rect);
  UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return coloredImage;
}

%hook SBClockApplicationIconImageView

// CLOCK COLOURS

- (id)initWithFrame:(CGRect)arg1 {
	SBClockApplicationIconImageView * icon = %orig;

	if(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"redDot"] != nil)
		MSHookIvar<CALayer*>(icon,"_redDot").backgroundColor = UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"redDot"]).CGColor;

	if(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"blackDot"] != nil)
		MSHookIvar<CALayer*>(icon,"_blackDot").backgroundColor = UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"blackDot"]).CGColor;

	if(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"hours"] != nil)
		MSHookIvar<CALayer*>(icon,"_hours").backgroundColor = UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"hours"]).CGColor;

	if(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"minutes"] != nil)
		MSHookIvar<CALayer*>(icon,"_minutes").backgroundColor = UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"minutes"]).CGColor;

	if(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"seconds"] != nil)
		MSHookIvar<CALayer*>(icon,"_seconds").backgroundColor = UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerClock"])[@"seconds"]).CGColor;

	return icon;
}

%end

%hook SBIconBadgeView

// NOT THE NEATEST WAY TO DO THIS, BUT APPLE HAVE IMPLEMENTED BADGES IN A PECULIAR WAY AND THIS IS THE BEST (EASIEST) WAY I CAN FIND AT THE MINUTE

// BADGE TEXT COLOUR

+ (id)_checkoutImageForText:(id)arg1 highlighted:(_Bool)arg2 {
	SBIconAccessoryImage * o = %orig;
	if(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"text"] != nil) {
		UIImage * tintedImage = imageWithBurnTint(o,UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"text"]));
		SBIconAccessoryImage * n = [[%c(SBIconAccessoryImage) alloc] initWithImage:tintedImage];
		n.countedMapKey = o.countedMapKey;
		return n;
	}
	else
		return o;
}

// BADGE BACKGROUND COLOUR

+ (id)_checkoutBackgroundImage {
	SBIconAccessoryImage * o = %orig;
	if(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"background"] != nil) {
		UIImage * tintedImage = imageWithBurnTint(o,UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"background"]));
		SBIconAccessoryImage * n = [[%c(SBIconAccessoryImage) alloc] initWithImage:tintedImage];
		n.countedMapKey = o.countedMapKey;
		return n;
	}
	else
		return o;
}

// BORDER COLOUR

- (void)configureForIcon:(id)arg1 location:(int)arg2 highlighted:(_Bool)arg3{
	%orig;
	if(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"border"] != nil) {
		self.layer.cornerRadius = self.frame.size.height/2;
		self.layer.borderWidth = 1;
		self.layer.borderColor = UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"border"]).CGColor;
	}
}

// MANUALLY UPDATES BORDER COLOUR WHEN THE ICON IS PRESSED (HAPPENS AUTOMATICALLY FOR BACKGROUND/TEXT)

- (void)setAccessoryBrightness:(double)arg1 {
	if(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"border"] != nil)
		self.layer.borderColor = DarkenedUIColor(UIColorFromHexString(((NSDictionary*)dictToApply[@"SBThemerBadge"])[@"border"]),arg1).CGColor;
	%orig;
}

%end

%ctor {

  // READS WINTERBOARD'S PREFERENCE FILE AND TAKES THE HIGHEST PRIORITY INFO CONTAINING SBTHEMER RELATED STUFF

	NSArray * winterboardThemes = [[NSDictionary alloc] initWithContentsOfFile:WINTERBOARD_PREFS_PATH][@"Themes"];
	dictToApply = [[NSMutableDictionary alloc] init];

	for (NSDictionary *theme in winterboardThemes)
	{
		if ([theme[@"Active"] boolValue])
		{
			NSString * themeName = theme[@"Name"];
			NSString * path = [NSString stringWithFormat:@"%@/%@.theme/Info.plist",THEME_BASE_PATH,themeName];
			NSDictionary * themeDict = [NSDictionary dictionaryWithContentsOfFile:path];

			if(dictToApply[@"SBThemerClock"] == nil) {
				dictToApply[@"SBThemerClock"] = themeDict[@"SBThemerClock"];
			}
			if(dictToApply[@"SBThemerBadge"] == nil) {
				dictToApply[@"SBThemerBadge"] = themeDict[@"SBThemerBadge"];
			}
		}
	}
}
