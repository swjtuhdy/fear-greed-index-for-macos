#import <Cocoa/Cocoa.h>

static NSArray<NSNumber *> *IconSizes(void) {
    return @[@16, @32, @64, @128, @256, @512, @1024];
}

static NSColor *ColorForValue(CGFloat value) {
    if (value <= 24.0) {
        return [NSColor colorWithRed:0.86 green:0.20 blue:0.22 alpha:1.0];
    }
    if (value <= 44.0) {
        return [NSColor colorWithRed:0.95 green:0.52 blue:0.19 alpha:1.0];
    }
    if (value <= 55.0) {
        return [NSColor colorWithRed:0.98 green:0.78 blue:0.20 alpha:1.0];
    }
    if (value <= 74.0) {
        return [NSColor colorWithRed:0.26 green:0.73 blue:0.43 alpha:1.0];
    }
    return [NSColor colorWithRed:0.05 green:0.68 blue:0.72 alpha:1.0];
}

static void DrawIcon(CGFloat side) {
    NSRect bounds = NSMakeRect(0, 0, side, side);
    CGFloat cornerRadius = side * 0.24;

    NSColor *topColor = [NSColor colorWithRed:0.08 green:0.12 blue:0.17 alpha:1.0];
    NSColor *bottomColor = [NSColor colorWithRed:0.13 green:0.18 blue:0.24 alpha:1.0];
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, side * 0.03, side * 0.03)
                                                               xRadius:cornerRadius
                                                               yRadius:cornerRadius];
    [backgroundGradient drawInBezierPath:background angle:-90.0];

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.18];
    shadow.shadowOffset = NSMakeSize(0, -side * 0.025);
    shadow.shadowBlurRadius = side * 0.05;
    [NSGraphicsContext saveGraphicsState];
    [shadow set];
    [[NSColor colorWithWhite:1.0 alpha:0.06] setStroke];
    background.lineWidth = MAX(1.0, side * 0.01);
    [background stroke];
    [NSGraphicsContext restoreGraphicsState];

    NSString *title = @"FGI";
    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:side * 0.105],
        NSForegroundColorAttributeName: [[NSColor whiteColor] colorWithAlphaComponent:0.72]
    };
    NSSize titleSize = [title sizeWithAttributes:titleAttrs];
    [title drawAtPoint:NSMakePoint((side - titleSize.width) / 2.0, side * 0.74) withAttributes:titleAttrs];

    NSPoint center = NSMakePoint(side / 2.0, side * 0.28);
    CGFloat radius = side * 0.23;
    CGFloat segmentGap = 4.0;
    NSInteger segmentCount = 5;
    CGFloat segmentSweep = (180.0 - (segmentCount - 1) * segmentGap) / (CGFloat)segmentCount;

    for (NSInteger segment = 0; segment < segmentCount; segment++) {
        CGFloat startAngle = 180.0 - segment * (segmentSweep + segmentGap);
        CGFloat endAngle = startAngle - segmentSweep;

        NSBezierPath *segmentPath = [NSBezierPath bezierPath];
        segmentPath.lineWidth = side * 0.062;
        [segmentPath appendBezierPathWithArcWithCenter:center
                                                radius:radius
                                            startAngle:startAngle
                                              endAngle:endAngle
                                             clockwise:YES];

        CGFloat threshold = ((segment + 1) * 100.0) / segmentCount;
        [[ColorForValue(threshold - 0.1) colorWithAlphaComponent:1.0] setStroke];
        [segmentPath stroke];
    }

    CGFloat gaugeValue = 58.0;
    CGFloat radians = (180.0 - gaugeValue * 1.8) * M_PI / 180.0;
    NSPoint tip = NSMakePoint(center.x + cos(radians) * radius, center.y + sin(radians) * radius);
    NSBezierPath *needle = [NSBezierPath bezierPath];
    needle.lineWidth = side * 0.022;
    [needle moveToPoint:center];
    [needle lineToPoint:tip];
    [[NSColor whiteColor] setStroke];
    [needle stroke];

    NSBezierPath *hub = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - side * 0.028,
                                                                          center.y - side * 0.028,
                                                                          side * 0.056,
                                                                          side * 0.056)];
    [[NSColor whiteColor] setFill];
    [hub fill];

    NSString *valueText = @"58";
    NSDictionary *valueAttrs = @{
        NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:side * 0.12 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor whiteColor]
    };
    NSSize valueSize = [valueText sizeWithAttributes:valueAttrs];
    [valueText drawAtPoint:NSMakePoint((side - valueSize.width) / 2.0, side * 0.44) withAttributes:valueAttrs];
}

static BOOL WritePNG(NSImage *image, NSURL *url) {
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (cgImage == NULL) {
        return NO;
    }

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    NSData *pngData = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return [pngData writeToURL:url atomically:YES];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc != 2) {
            fprintf(stderr, "Usage: generate_app_icon <output-iconset-dir>\n");
            return 1;
        }

        NSString *outputPath = [NSString stringWithUTF8String:argv[1]];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        [[NSFileManager defaultManager] createDirectoryAtURL:outputURL withIntermediateDirectories:YES attributes:nil error:nil];

        for (NSNumber *sizeNumber in IconSizes()) {
            CGFloat size = sizeNumber.doubleValue;
            NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
            [image lockFocus];
            DrawIcon(size);
            [image unlockFocus];

            NSString *baseName = [NSString stringWithFormat:@"icon_%@x%@", sizeNumber, sizeNumber];
            NSURL *pngURL = [outputURL URLByAppendingPathComponent:[baseName stringByAppendingString:@".png"]];
            if (!WritePNG(image, pngURL)) {
                fprintf(stderr, "Failed to write %s\n", pngURL.path.UTF8String);
                return 1;
            }

            if (size <= 512) {
                NSString *retinaName = [NSString stringWithFormat:@"icon_%@x%@%@2x", sizeNumber, sizeNumber, @"@"];
                NSURL *retinaURL = [outputURL URLByAppendingPathComponent:[retinaName stringByAppendingString:@".png"]];
                if (!WritePNG(image, retinaURL)) {
                    fprintf(stderr, "Failed to write %s\n", retinaURL.path.UTF8String);
                    return 1;
                }
            }
        }
    }

    return 0;
}
