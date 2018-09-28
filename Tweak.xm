#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIStatusBarItemView.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

@interface UIStatusBarTimeItemView : UIStatusBarItemView {
	NSString* _timeString;
}
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
-(void)startCompassUpdates;
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

%hook UIStatusBarTimeItemView

    %new
    -(void)startCompassUpdates{
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = (id)self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingHeading];
    }

    %new
    -(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
        degrees = (int)locationManager.heading.magneticHeading;
        NSLog(@"from delegate method: %i", degrees);
        if ((degrees >= 339) || (degrees <= 22)) {
            directionString = @"N";

        }else if ((degrees > 23) && (degrees <= 68)) {
            directionString = @"NE";

        }else if ((degrees > 69) && (degrees <= 113)) {
            directionString = @"E";

        }else if ((degrees > 114) && (degrees <= 158)) {
            directionString = @"SE";

        }else if ((degrees > 159) && (degrees <= 203)) {
            directionString = @"S";

        }else if ((degrees > 204) && (degrees <= 248)) {
            directionString = @"SW";

        }else if ((degrees > 249) && (degrees <= 293)) {
           directionString = @"W";

        }else if ((degrees > 294) && (degrees <= 338)) {
           directionString = @"NW";
        }
    }

    -(id)contentsImage{
        [[%c(UIStatusBarTimeItemView) alloc] startCompassUpdates];
        __strong NSString *&timeString = MSHookIvar<NSString *>(self, "_timeString");
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
        NSString *formedString = [[NSString stringWithFormat:@"%ld/%ld | %@:%@ | %@MB | %@", (long)day, (long)month, hs, ms, STGetSystemRAM(), directionString] retain];
        timeString = formedString;
        return %orig();
    }

%end
