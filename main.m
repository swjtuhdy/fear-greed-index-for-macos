#import <Cocoa/Cocoa.h>

static const CGFloat kGaugeWidth = 44.0;
static const CGFloat kGaugeHeight = 22.0;
static const NSInteger kGaugeSegmentCount = 5;
static NSString * const kRapidAPIHost = @"fear-and-greed-index.p.rapidapi.com";
static NSString * const kAppIdentifier = @"fear-greed-index-for-macos";

@interface SentimentQuote : NSObject
@property (nonatomic, strong) NSNumber *value;
@property (nonatomic, copy) NSString *classification;
@property (nonatomic, strong) NSDate *timestamp;
@end

@implementation SentimentQuote
@end

@interface FearGreedService : NSObject
- (NSString *)apiKey;
- (BOOL)saveAPIKey:(NSString *)apiKey error:(NSError **)error;
- (void)fetchLatestQuoteWithCompletion:(void (^)(SentimentQuote *quote, NSError *error))completion;
@end

@interface StatusController : NSObject
- (void)start;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation FearGreedService

- (NSURL *)configURL {
    NSArray<NSURL *> *appSupportURLs =
        [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupportURL = appSupportURLs.firstObject;
    return [[appSupportURL URLByAppendingPathComponent:kAppIdentifier] URLByAppendingPathComponent:@"config.plist"];
}

- (NSString *)apiKey {
    const char *environmentKey = getenv("FEAR_GREED_RAPIDAPI_KEY");
    if (environmentKey != NULL) {
        NSString *envValue = [NSString stringWithUTF8String:environmentKey];
        if (envValue.length > 0) {
            return envValue;
        }
    }

    NSURL *configURL = [self configURL];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfURL:configURL];
    NSString *fileValue = [config[@"rapidapi_key"] isKindOfClass:[NSString class]] ? config[@"rapidapi_key"] : nil;
    if (fileValue.length > 0) {
        return fileValue;
    }

    return nil;
}

- (BOOL)saveAPIKey:(NSString *)apiKey error:(NSError **)error {
    NSURL *configURL = [self configURL];
    NSURL *directoryURL = [configURL URLByDeletingLastPathComponent];

    if (![[NSFileManager defaultManager] createDirectoryAtURL:directoryURL
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:error]) {
        return NO;
    }

    if (apiKey.length == 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:configURL.path]) {
            return [[NSFileManager defaultManager] removeItemAtURL:configURL error:error];
        }
        return YES;
    }

    NSDictionary *config = @{@"rapidapi_key": apiKey};
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:config
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                                  options:0
                                                                    error:error];
    if (plistData == nil) {
        return NO;
    }

    return [plistData writeToURL:configURL options:NSDataWritingAtomic error:error];
}

- (void)fetchLatestQuoteWithCompletion:(void (^)(SentimentQuote *quote, NSError *error))completion {
    NSURL *url = [NSURL URLWithString:@"https://fear-and-greed-index.p.rapidapi.com/v1/fgi"];
    if (url == nil) {
        NSError *error = [NSError errorWithDomain:@"FearGreedMenuBar"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid RapidAPI Fear & Greed URL"}];
        completion(nil, error);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 15.0;
    [request setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:kRapidAPIHost forHTTPHeaderField:@"x-rapidapi-host"];
    NSString *apiKey = [self apiKey];
    if (apiKey.length == 0) {
        NSError *configError = [NSError errorWithDomain:@"FearGreedMenuBar"
                                                   code:1005
                                               userInfo:@{NSLocalizedDescriptionKey: @"RapidAPI key is missing. Run setup-api-key.command first."}];
        completion(nil, configError);
        return;
    }
    [request setValue:apiKey forHTTPHeaderField:@"x-rapidapi-key"];

    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            completion(nil, error);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]] || httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            NSError *statusError = [NSError errorWithDomain:@"FearGreedMenuBar"
                                                       code:1002
                                                   userInfo:@{NSLocalizedDescriptionKey: @"RapidAPI Fear & Greed endpoint returned an invalid response"}];
            completion(nil, statusError);
            return;
        }

        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError != nil || ![json isKindOfClass:[NSDictionary class]]) {
            NSError *parseError = jsonError ?: [NSError errorWithDomain:@"FearGreedMenuBar"
                                                                   code:1003
                                                               userInfo:@{NSLocalizedDescriptionKey: @"Unable to parse RapidAPI Fear & Greed response"}];
            completion(nil, parseError);
            return;
        }

        NSDictionary *root = (NSDictionary *)json;
        NSDictionary *fgi = [root[@"fgi"] isKindOfClass:[NSDictionary class]] ? root[@"fgi"] : root;
        NSDictionary *current = [fgi[@"now"] isKindOfClass:[NSDictionary class]] ? fgi[@"now"] : fgi;

        NSNumber *score = [self parseScoreFromJSON:current];
        if (score == nil) {
            NSError *missingError = [NSError errorWithDomain:@"FearGreedMenuBar"
                                                        code:1004
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Could not find Fear & Greed score in RapidAPI response"}];
            completion(nil, missingError);
            return;
        }

        SentimentQuote *quote = [[SentimentQuote alloc] init];
        quote.value = score;
        quote.classification = [self parseClassificationFromJSON:current] ?: [self classificationForScore:score.doubleValue];
        quote.timestamp = [self parseTimestampFromJSON:root] ?: [NSDate date];

        completion(quote, nil);
    }];

    [task resume];
}

- (NSNumber *)parseScoreFromJSON:(NSDictionary *)json {
    NSArray<NSString *> *candidateKeys = @[@"now", @"score", @"value", @"fgi"];
    for (NSString *key in candidateKeys) {
        id value = json[key];
        NSNumber *number = [self numberFromValue:value];
        if (number != nil) {
            return number;
        }
    }
    return nil;
}

- (NSString *)parseClassificationFromJSON:(NSDictionary *)json {
    NSArray<NSString *> *candidateKeys = @[@"valueText", @"rating", @"classification", @"label", @"status", @"sentiment"];
    for (NSString *key in candidateKeys) {
        id value = json[key];
        if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) {
            return value;
        }
    }
    return nil;
}

- (NSDate *)parseTimestampFromJSON:(NSDictionary *)json {
    NSDictionary *lastUpdated = [json[@"lastUpdated"] isKindOfClass:[NSDictionary class]] ? json[@"lastUpdated"] : nil;
    if (lastUpdated != nil) {
        id epochValue = lastUpdated[@"epochUnixSeconds"];
        if ([epochValue isKindOfClass:[NSNumber class]]) {
            return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)epochValue doubleValue]];
        }
    }

    NSArray<NSString *> *candidateKeys = @[@"timestamp", @"updated_at", @"updatedAt", @"last_update"];
    for (NSString *key in candidateKeys) {
        id value = json[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)value doubleValue]];
        }
        if ([value isKindOfClass:[NSString class]]) {
            NSString *stringValue = (NSString *)value;
            if (stringValue.length == 0) {
                continue;
            }

            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            NSNumber *epoch = [numberFormatter numberFromString:stringValue];
            if (epoch != nil) {
                return [NSDate dateWithTimeIntervalSince1970:epoch.doubleValue];
            }

            NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
            isoFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssXXXXX";
            NSDate *date = [isoFormatter dateFromString:stringValue];
            if (date != nil) {
                return date;
            }
        }
    }
    return nil;
}

- (NSNumber *)numberFromValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        return [formatter numberFromString:(NSString *)value];
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)value;
        NSArray<NSString *> *nestedKeys = @[@"score", @"value", @"now"];
        for (NSString *nestedKey in nestedKeys) {
            NSNumber *nestedNumber = [self numberFromValue:dictionary[nestedKey]];
            if (nestedNumber != nil) {
                return nestedNumber;
            }
        }
    }
    return nil;
}

- (NSString *)classificationForScore:(double)score {
    if (score <= 25.0) {
        return @"Extreme Fear";
    }
    if (score <= 44.0) {
        return @"Fear";
    }
    if (score <= 55.0) {
        return @"Neutral";
    }
    if (score <= 74.0) {
        return @"Greed";
    }
    return @"Extreme Greed";
}

@end

@interface StatusController ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *statusMenu;
@property (nonatomic, strong) NSMenuItem *currentValueItem;
@property (nonatomic, strong) NSMenuItem *classificationItem;
@property (nonatomic, strong) NSMenuItem *updatedAtItem;
@property (nonatomic, strong) NSMenuItem *sourceItem;
@property (nonatomic, strong) NSMenuItem *apiKeyItem;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) FearGreedService *service;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation StatusController

- (instancetype)init {
    self = [super init];
    if (self) {
        _service = [[FearGreedService alloc] init];
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterNoStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return self;
}

- (void)start {
    [self configureStatusItem];
    [self refresh];
    [self scheduleRefresh];
}

- (void)configureStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:44.0];
    self.statusItem.button.toolTip = @"Fear & Greed Index";
    self.statusItem.button.imagePosition = NSImageOnly;
    self.statusItem.button.image = [self gaugeImageForValue:-1 classification:nil];

    self.currentValueItem = [[NSMenuItem alloc] initWithTitle:@"Fear & Greed: --" action:nil keyEquivalent:@""];
    self.classificationItem = [[NSMenuItem alloc] initWithTitle:@"Classification: --" action:nil keyEquivalent:@""];
    self.updatedAtItem = [[NSMenuItem alloc] initWithTitle:@"Updated: --" action:nil keyEquivalent:@""];
    self.sourceItem = [[NSMenuItem alloc] initWithTitle:@"Source: fear-and-greed-index.p.rapidapi.com/v1/fgi" action:nil keyEquivalent:@""];

    self.statusMenu = [[NSMenu alloc] init];
    [self.statusMenu addItem:self.currentValueItem];
    [self.statusMenu addItem:self.classificationItem];
    [self.statusMenu addItem:self.updatedAtItem];
    [self.statusMenu addItem:self.sourceItem];
    [self.statusMenu addItem:[NSMenuItem separatorItem]];

    self.apiKeyItem = [[NSMenuItem alloc] initWithTitle:@"Set API Key..."
                                                 action:@selector(handleSetAPIKey:)
                                          keyEquivalent:@"k"];
    self.apiKeyItem.target = self;
    [self.statusMenu addItem:self.apiKeyItem];

    NSMenuItem *refreshItem = [[NSMenuItem alloc] initWithTitle:@"Refresh Now"
                                                         action:@selector(handleManualRefresh:)
                                                  keyEquivalent:@"r"];
    refreshItem.target = self;
    [self.statusMenu addItem:refreshItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                      action:@selector(handleQuit:)
                                               keyEquivalent:@"q"];
    quitItem.target = self;
    [self.statusMenu addItem:quitItem];

    self.statusItem.menu = self.statusMenu;
    self.statusItem.visible = YES;
}

- (void)scheduleRefresh {
    [self.refreshTimer invalidate];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:3600.0
                                                         target:self
                                                       selector:@selector(handleTimerRefresh:)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)refresh {
    [self applyLoadingState];

    [self.service fetchLatestQuoteWithCompletion:^(SentimentQuote *quote, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (quote != nil) {
                [self applyQuote:quote];
            } else {
                [self applyError:error];
            }
        });
    }];
}

- (void)applyLoadingState {
    self.statusItem.button.image = [self gaugeImageForValue:-1 classification:nil];
    self.statusItem.button.toolTip = @"Fear & Greed Index: Loading...";
    self.currentValueItem.title = @"Fear & Greed: Loading...";
    self.classificationItem.title = @"Classification: --";
    self.updatedAtItem.title = @"Updated: --";
}

- (void)applyQuote:(SentimentQuote *)quote {
    NSInteger roundedValue = (NSInteger)llround(quote.value.doubleValue);
    self.statusItem.button.image = [self gaugeImageForValue:quote.value.doubleValue classification:quote.classification];
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"Fear & Greed: %ld (%@)", (long)roundedValue, quote.classification];
    self.currentValueItem.title = [NSString stringWithFormat:@"Fear & Greed: %ld / 100", (long)roundedValue];
    self.classificationItem.title = [NSString stringWithFormat:@"Classification: %@", quote.classification];
    self.updatedAtItem.title = [NSString stringWithFormat:@"Updated: %@", [self.dateFormatter stringFromDate:quote.timestamp]];
}

- (void)applyError:(NSError *)error {
    self.statusItem.button.image = [self gaugeImageForValue:-2 classification:nil];
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"Fear & Greed failed: %@", error.localizedDescription ?: @"Unknown error"];
    self.currentValueItem.title = @"Fear & Greed: Failed to load";
    self.classificationItem.title = @"Classification: --";
    self.updatedAtItem.title = @"Updated: --";
}

- (NSImage *)gaugeImageForValue:(double)value classification:(NSString *)classification {
    NSSize size = NSMakeSize(kGaugeWidth, kGaugeHeight);
    NSImage *image = [[NSImage alloc] initWithSize:size];

    [image lockFocus];

    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0, 0, size.width, size.height));

    NSPoint center = NSMakePoint(size.width / 2.0, 4.0);
    CGFloat radius = 9.0;
    CGFloat segmentGap = 3.8;
    CGFloat segmentSweep = (180.0 - (kGaugeSegmentCount - 1) * segmentGap) / (CGFloat)kGaugeSegmentCount;

    for (NSInteger segment = 0; segment < kGaugeSegmentCount; segment++) {
        CGFloat segmentStart = 180.0 - segment * (segmentSweep + segmentGap);
        CGFloat segmentEnd = segmentStart - segmentSweep;

        NSBezierPath *segmentPath = [NSBezierPath bezierPath];
        segmentPath.lineWidth = 4.0;
        [segmentPath appendBezierPathWithArcWithCenter:center
                                                radius:radius
                                            startAngle:segmentStart
                                              endAngle:segmentEnd
                                             clockwise:YES];

        double threshold = ((segment + 1) * 100.0) / kGaugeSegmentCount;
        NSColor *segmentColor = [self colorForSentimentValue:threshold - 0.1];
        if (value >= 0.0) {
            double clampedValue = MIN(MAX(value, 0.0), 100.0);
            BOOL isActive = clampedValue >= (segment * 100.0 / kGaugeSegmentCount);
            [[segmentColor colorWithAlphaComponent:isActive ? 1.0 : 0.22] setStroke];
        } else {
            [[NSColor colorWithWhite:0.72 alpha:0.38] setStroke];
        }
        [segmentPath stroke];
    }

    if (value >= 0.0) {
        double clampedValue = MIN(MAX(value, 0.0), 100.0);
        double radians = (180.0 - clampedValue * 1.8) * M_PI / 180.0;
        NSPoint tip = NSMakePoint(center.x + cos(radians) * radius, center.y + sin(radians) * radius);
        NSBezierPath *needle = [NSBezierPath bezierPath];
        needle.lineWidth = 2.0;
        [needle moveToPoint:center];
        [needle lineToPoint:tip];
        [[NSColor labelColor] setStroke];
        [needle stroke];

        NSBezierPath *hub = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - 2.1, center.y - 2.1, 4.2, 4.2)];
        [[NSColor labelColor] setFill];
        [hub fill];

        NSString *numberText = [NSString stringWithFormat:@"%ld", (long)llround(clampedValue)];
        NSDictionary *numberAttributes = @{
            NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:8.4 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor labelColor]
        };
        NSSize numberSize = [numberText sizeWithAttributes:numberAttributes];
        NSPoint numberPoint = NSMakePoint((size.width - numberSize.width) / 2.0, 10.4);
        [numberText drawAtPoint:numberPoint withAttributes:numberAttributes];
    } else {
        NSString *symbol = (value == -2.0) ? @"!" : @"…";
        NSDictionary *attributes = @{
            NSFontAttributeName: [NSFont boldSystemFontOfSize:13.0],
            NSForegroundColorAttributeName: (value == -2.0) ? [NSColor systemRedColor] : [NSColor secondaryLabelColor]
        };
        [symbol drawAtPoint:NSMakePoint(16.0, 5.0) withAttributes:attributes];
    }

    [image unlockFocus];
    image.template = NO;
    return image;
}

- (NSColor *)colorForSentimentValue:(double)value {
    if (value <= 24.0) {
        return [NSColor systemRedColor];
    }
    if (value <= 44.0) {
        return [NSColor systemOrangeColor];
    }
    if (value <= 55.0) {
        return [NSColor systemYellowColor];
    }
    if (value <= 74.0) {
        return [NSColor systemGreenColor];
    }
    return [NSColor systemTealColor];
}

- (void)handleManualRefresh:(id)sender {
    [self refresh];
}

- (void)handleSetAPIKey:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Set RapidAPI Key";
    alert.informativeText = @"Paste your Fear & Greed RapidAPI key. The clipboard value will be prefilled when available. Leave it empty to remove the saved key.";
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 360, 24)];
    textField.placeholderString = @"RapidAPI key";
    NSString *existingKey = [self.service apiKey];
    if (existingKey.length > 0) {
        textField.stringValue = existingKey;
    }

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *clipboardString = [pasteboard stringForType:NSPasteboardTypeString];
    if (clipboardString.length > 0 &&
        [clipboardString rangeOfString:@" "].location == NSNotFound &&
        [clipboardString rangeOfString:@"\n"].location == NSNotFound &&
        [clipboardString rangeOfString:@"\t"].location == NSNotFound) {
        textField.stringValue = clipboardString;
    }

    alert.accessoryView = textField;

    NSModalResponse response = [alert runModal];
    if (response != NSAlertFirstButtonReturn) {
        return;
    }

    NSError *saveError = nil;
    if (![self.service saveAPIKey:textField.stringValue error:&saveError]) {
        NSAlert *errorAlert = [[NSAlert alloc] init];
        errorAlert.messageText = @"Failed to save API key";
        errorAlert.informativeText = saveError.localizedDescription ?: @"Unknown error";
        [errorAlert addButtonWithTitle:@"OK"];
        [errorAlert runModal];
        return;
    }

    [self refresh];
}

- (void)handleTimerRefresh:(id)sender {
    [self refresh];
}

- (void)handleQuit:(id)sender {
    [self.refreshTimer invalidate];
    [NSApp terminate:nil];
}

@end

@interface AppDelegate ()
@property (nonatomic, strong) StatusController *statusController;
@end

static AppDelegate *gAppDelegate = nil;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.statusController = [[StatusController alloc] init];
    [self.statusController start];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        gAppDelegate = [[AppDelegate alloc] init];
        application.activationPolicy = NSApplicationActivationPolicyAccessory;
        application.delegate = gAppDelegate;
        [application run];
    }
    return 0;
}
