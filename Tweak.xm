#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIStatusBarItemView.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

@interface SBStatusBarStateAggregator : NSObject
@end

@interface UIStatusBarTimeItemView : UIStatusBarItemView {
	NSString* _timeString;
}
+(id)sharedInstance;
-(void)drawStatusText;
-(void)startCompassUpdates;
-(void)locationManager:(CLLocationManager *)manager startUpdatingHeading:(CLHeading *)heading startUpdatingLocation:(NSArray *)locations;
@end

CLLocationManager *locationManager;
NSString *directionString = nil;
int degrees;

static NSNumber *STGetSystemRAM(){
  @autoreleasepool{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS){
        NSLog(@"CustomStatusBar: Failed to fetch vm statistics");
    }

    natural_t mem_free = vm_stat.free_count * pagesize;
    NSNumber *freeMemory = [NSNumber numberWithUnsignedInt:round((mem_free / 1024) / 1024)];
    return freeMemory;
  }
}

%hook SBStatusBarStateAggregator

	-(id)_sbCarrierNameForOperator:(id)arg1 {
		NSLog(@"CustomStatusBar: _sbCarrierNameForOperator: %@", arg1);
		%orig();
		return @"";
		//return %orig(arg1); // returns "Salt"
	}
	// -(void)_updateTimeItems {
	// 	//NSLog(@"CustomStatusBar: _updateTimeItems called");
	// 	NSString *serviceString = MSHookIvar<NSString *>(self, "_serviceString");
	// 	//NSLog(@"CustomStatusBar: serviceString: %@", serviceString);
	// 	MSHookIvar<NSString *>(self, "_serviceString") = @"";
	// 	%orig;
	// }

%end

%hook UIStatusBarTimeItemView

	%new
	-(void)drawStatusText {

		NSDate *date = [NSDate date];
    	NSCalendar *calendar = [NSCalendar currentCalendar];
    	NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitDay | NSCalendarUnitMonth) fromDate:date];
    	NSInteger hour = [components hour];
    	NSInteger minute = [components minute];
        //NSInteger second = [components second];
        NSInteger day = [components day];
    	NSInteger month = [components month];
		NSString *hs = hour < 10 ? [NSString stringWithFormat:@"0%ld", (long)hour] : [NSString stringWithFormat:@"%ld", (long)hour];
		NSString *ms = minute < 10 ? [NSString stringWithFormat:@"0%ld", (long)minute] : [NSString stringWithFormat:@"%ld", (long)minute];
		NSLog(@"CustomStatusBar: 2");
		NSLog(@"CustomStatusBar: 3 MSHookIvar: %@", MSHookIvar<NSString *>(self, "_timeString"));
        //NSString *formedString = [[NSString stringWithFormat:@"%ld/%ld | %@:%@ | %@MB | %@", (long)day, (long)month, hs, ms, STGetSystemRAM(), directionString] retain];
        MSHookIvar<NSString *>(self, "_timeString") = [[NSString stringWithFormat:@"%ld/%ld | %@:%@ | %@MB", (long)day, (long)month, hs, ms, STGetSystemRAM()] retain];
	}

    -(id)contentsImage {
		NSLog(@"CustomStatusBar: 1");
		[[%c(UIStatusBarTimeItemView) alloc] drawStatusText];
        return %orig();
    }

%end
