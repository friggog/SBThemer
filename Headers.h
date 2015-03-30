@interface SBClockApplicationIconImageView : /*SBLiveIconImageView*/ NSObject
{
	CALayer *_seconds;
	CALayer *_minutes;
	CALayer *_hours;
	CALayer *_blackDot;
	CALayer *_redDot;
}
@end

@interface SBIconAccessoryImage : UIImage
{
    NSString *_countedMapKey;
}
@property(copy, nonatomic) NSString *countedMapKey;
- (id)initWithImage:(id)arg1;
@end

@interface SBIconBadgeView : UIView
@end
