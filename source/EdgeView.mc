using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time.Gregorian as Cal;
using Toybox.ActivityMonitor as Act;

var partialUpdatesAllowed;

class EdgeView extends Ui.WatchFace {

    enum {
        ALIGN_TOP, //Top pixel
        ALIGN_MID, //Middle pixel
        ALIGN_BOT, //Pixel below lowest pixel
        ALIGN_RIGHT,
        ALIGN_LEFT
    }

    enum {
        DATA_BATTERY,
        DATA_STAIRS,
        DATA_INTENSITY,
        DATA_STEPS,
        DATA_HR,

        DATA_NONE = 100
    }

    //Bitmaps
    var alarmBitmap;
    var batteryBitmap;
    var batteryChargingBitmap;
    var heartBitmap;
    var intensityBitmap;
    var moveBarBigBitmap;
    var moveBarSmallBitmap;
    var notificationBitmap;
    var phoneBitmap;
    var sleepBitmap;
    var stairBitmap;
    var star1Bitmap;
    var star2Bitmap;
    var star3Bitmap;
    var stepBitmap;

    var actInfo;
    var sysStats;
    var devSettings;

    var highPowerMode = true;
    var secLocation = [0, 0];
    var secDimension = [0, 0];
    var secFont = Gfx.FONT_MEDIUM;
    var fgColor;

    const BAR_WIDTH = 6;
    const LOW_BATT_PERCENTAGE = 20;

    function initialize() {
        WatchFace.initialize();
        partialUpdatesAllowed = ( Ui.WatchFace has :onPartialUpdate );
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));

        //Load bitmaps
        alarmBitmap = Ui.loadResource( Rez.Drawables.id_alarm );
        batteryBitmap = Ui.loadResource( Rez.Drawables.id_battery );
        batteryChargingBitmap = Ui.loadResource( Rez.Drawables.id_batteryCharging );
        heartBitmap = Ui.loadResource( Rez.Drawables.id_heart );
        intensityBitmap = Ui.loadResource( Rez.Drawables.id_intensity );
        moveBarBigBitmap = Ui.loadResource( Rez.Drawables.id_moveBarBig );
        moveBarSmallBitmap = Ui.loadResource( Rez.Drawables.id_moveBarSmall );
        notificationBitmap = Ui.loadResource( Rez.Drawables.id_notification );
        phoneBitmap = Ui.loadResource( Rez.Drawables.id_phone );
        sleepBitmap = Ui.loadResource( Rez.Drawables.id_sleep );
        stairBitmap = Ui.loadResource( Rez.Drawables.id_stair );
        star1Bitmap = Ui.loadResource( Rez.Drawables.id_star1 );
        star2Bitmap = Ui.loadResource( Rez.Drawables.id_star2 );
        star3Bitmap = Ui.loadResource( Rez.Drawables.id_star3 );
        stepBitmap = Ui.loadResource( Rez.Drawables.id_steps );
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        //TODO: Are these causing more harm than good?
        actInfo = Act.getInfo();
        sysStats = Sys.getSystemStats();
        devSettings = Sys.getDeviceSettings();
        fgColor = App.getApp().getProperty("ForegroundColor");

        dc.clearClip();

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var locUpperY = dc.getHeight() / 2;
        var locLowerY = dc.getHeight() / 2;
        var timeDim = drawTime(dc, locUpperY, ALIGN_MID);
        locUpperY -= (timeDim[1] / 2 + 5);
        locLowerY += (timeDim[1] / 2 + 5);

        locUpperY -= drawDate(dc, locUpperY, ALIGN_BOT)[1] - 4;
        locUpperY -= drawIcons(dc, locUpperY, ALIGN_BOT)[1] + 4;
        locUpperY -= drawBattery(dc, locUpperY, ALIGN_BOT)[1];

        locLowerY += drawHistory(dc, locLowerY, ALIGN_TOP)[1];
        locLowerY += drawDataField(dc, locLowerY, ALIGN_TOP, dc.getWidth() / 2, ALIGN_MID)[1];

        drawMoveBars(dc, dc.getHeight(), ALIGN_BOT);
        drawBars(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        highPowerMode = true;
        Ui.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        highPowerMode = false;
        Ui.requestUpdate();
    }

    function drawTime(dc, locY, alignment) {
        //Variables
        var timeFormat = "$1$:$2$";
        var clockTime = Sys.getClockTime();
        var hours = clockTime.hour;
        var timeFont = Gfx.FONT_NUMBER_THAI_HOT;
        var locX = dc.getWidth() / 2;
        var just = Gfx.TEXT_JUSTIFY_CENTER;

        var retWidth;
        var retHeight;

        dc.setColor(fgColor, Gfx.COLOR_TRANSPARENT);

        //Get time information
        if (!Sys.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
            if(hours == 0) {
                hours = 12;
            }
        }

        //Time string
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        //Dimensions
        var timeDim = dc.getTextDimensions(timeString, timeFont);
        timeDim[1] -= Gfx.getFontDescent(timeFont) * 2; //NOTE: This may not always work...
        retWidth = timeDim[0];
        retHeight = timeDim[1];

        //Align
        if( ALIGN_MID == alignment ) {
            just |= Gfx.TEXT_JUSTIFY_VCENTER;
        } else if( ALIGN_BOT == alignment ) {
            locY -= timeDim[1];
        }

        if( highPowerMode || partialUpdatesAllowed ) {
            var secSpace = 4;
            //Adjust for seconds being included
            var secondString = clockTime.sec.format("%02d");

            secDimension = dc.getTextDimensions("88", secFont); //Do 88 to make sure we can handle larger width numbers
            secDimension[0] += secSpace;
            retWidth = timeDim[0] + secDimension[0];
            locX = dc.getWidth() / 2 - retWidth / 2 + timeDim[0] / 2; //Uncomment to center
            var yOffset = ((timeDim[1] / 2) < secDimension[1]) ? timeDim[1] / 2 : secDimension[1];
            secLocation = [locX + timeDim[0] / 2 + secSpace, locY - yOffset];

            //Draw seconds
            dc.drawText(secLocation[0], secLocation[1], secFont, secondString, Gfx.TEXT_JUSTIFY_LEFT);
        }

        //Draw time
        dc.drawText(locX, locY, timeFont, timeString, just);

        return [retWidth, retHeight];
    } /* drawTime() */

    function drawMoveBars(dc, locY, alignment) {
        var retWidth = 0;
        var retHeight = 0;

        if( !devSettings.activityTrackingOn || !App.getApp().getProperty("ShowMoveBars")) {
            return [retWidth, retHeight];
        }

        if( Sys.SCREEN_SHAPE_RECTANGLE == devSettings.screenShape ) {
            //Get dimensions
            retWidth = moveBarSmallBitmap.getWidth() * 4 + moveBarBigBitmap.getWidth();
            retHeight = moveBarBigBitmap.getHeight();

            //Determine X and Y
            var moveBarX = ( dc.getWidth() - retWidth ) / 2;
            if( ALIGN_MID == alignment ) {
                locY -= moveBarBigBitmap.getHeight() / 2;
            } else if( ALIGN_BOT == alignment ) {
                locY -= moveBarBigBitmap.getHeight();
            }

            //Draw move bars based on the activity level
            if( actInfo.moveBarLevel > 0 ) {
                dc.drawBitmap(moveBarX, locY, moveBarBigBitmap);   moveBarX += moveBarBigBitmap.getWidth();
            }
            for( var i = 1; i < actInfo.moveBarLevel; i++ ) {
                dc.drawBitmap(moveBarX, locY, moveBarSmallBitmap); moveBarX += moveBarSmallBitmap.getWidth();
            }

        } else if( Sys.SCREEN_SHAPE_ROUND == devSettings.screenShape ) {
            //Get dimensions
            var smallStart = 178;
            var smallSize = 9;
            var smallSpace = 4;
            var bigEnd = 182;
            var bigStart = bigEnd + (smallSpace + smallSize) * 4 - smallSpace;

            dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);

            //Draw move bars based on the activity level
            if( actInfo.moveBarLevel > 0 ) {
                for( var i = 0; i < BAR_WIDTH; i++ ) {
                    dc.drawArc(dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 - BAR_WIDTH + i - BAR_WIDTH, Gfx.ARC_CLOCKWISE, bigStart, bigEnd );
                }

            }
            for( var bar = 1; bar < actInfo.moveBarLevel; bar++ ) {
                for( var i = 0; i < BAR_WIDTH; i++ ) {
                    dc.drawArc(dc.getWidth() / 2, dc.getHeight() / 2 - 1, dc.getWidth() / 2 - BAR_WIDTH + i - BAR_WIDTH, Gfx.ARC_CLOCKWISE, smallStart, smallStart - smallSize);
                }
                smallStart -= smallSize + smallSpace;
            }
        }

        return [retWidth, retHeight];
    } /* drawMoveBars() */

    function drawBattery(dc, locY, alignment) {
        var color = Gfx.COLOR_GREEN;
        var percentageText = "";
        var battBitmap = batteryBitmap;
        var battFont = Gfx.FONT_XTINY;

        if( ALIGN_MID == alignment ) {
            locY -= battBitmap.getHeight() / 2;
        } else if( ALIGN_BOT == alignment ) {
            locY -= battBitmap.getHeight();
        }

        var retWidth = battBitmap.getWidth();
        var retHeight = max( [batteryBitmap.getHeight(), batteryChargingBitmap.getHeight(), dc.getTextDimensions("T", battFont)[1]] );

        if( sysStats.battery < LOW_BATT_PERCENTAGE ) {
            color = Gfx.COLOR_YELLOW;
            percentageText = " " + sysStats.battery.format("%d") + "%";
            retWidth += dc.getTextWidthInPixels(percentageText, battFont);
        }

        if( Sys.Stats has( :charging ) && sysStats.charging ) {
            battBitmap = batteryChargingBitmap;
        }

        if( battBitmap.getWidth() == 0 ) {
            dc.drawBitmap(dc.getWidth(), dc.getHeight());
        }

        var locX = dc.getWidth() / 2 - ( battBitmap.getWidth() + dc.getTextWidthInPixels(percentageText, battFont) ) / 2;
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(locX + 1, locY + 1, (battBitmap.getWidth() - 4) * sysStats.battery / 100 + 1, battBitmap.getHeight() - 2);

        dc.drawBitmap(locX, locY, battBitmap);
        locX += battBitmap.getWidth();

        dc.drawText(locX, locY + battBitmap.getHeight() / 2, battFont, percentageText, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);

        return [retWidth, retHeight];
    } /* drawBattery() */

    function drawBars(dc) {
        var leftBarColor = Gfx.COLOR_TRANSPARENT;
        var leftBarInfo = App.getApp().getProperty("LeftBarInfo");
        var leftBarPercentage = 0.0;

        var rightBarColor = Gfx.COLOR_TRANSPARENT;
        var rightBarInfo = App.getApp().getProperty("RightBarInfo");
        var rightBarPercentage = 0.0;

        if( devSettings.activityTrackingOn ) {
            rightBarPercentage = actInfo.steps * 1.0 / actInfo.stepGoal;
        } else {
            rightBarPercentage = 0.0;
            leftBarInfo = DATA_BATTERY;
        }

        //Make sure bars are valid, else default to none. Setup color and percentages
        if( DATA_BATTERY == leftBarInfo ) { //Batery
            leftBarPercentage = sysStats.battery / 100.0;
            leftBarColor = Gfx.COLOR_GREEN;

            if( sysStats.battery < LOW_BATT_PERCENTAGE ) {
                leftBarColor = Gfx.COLOR_YELLOW;
            }
        } else if( DATA_STAIRS == leftBarInfo && ( Act.Info has :floorsClimbed ) ) { //Stairs Climbed
            leftBarColor = Gfx.COLOR_PURPLE;
            leftBarPercentage = actInfo.floorsClimbed * 1.0 / actInfo.floorsClimbedGoal;
        } else if( DATA_INTENSITY == leftBarInfo && ( Act.Info has :activeMinutesWeek ) ) { //Active/Intensity Minutes
            leftBarColor = Gfx.COLOR_ORANGE;
            leftBarPercentage = actInfo.activeMinutesWeek.total * 1.0 / actInfo.activeMinutesWeekGoal;
        } else if( DATA_STEPS == leftBarInfo && devSettings.activityTrackingOn ) { //Stairs
            leftBarPercentage = actInfo.steps * 1.0 / actInfo.stepGoal;
            leftBarColor = Gfx.COLOR_BLUE;
        }

        if( DATA_BATTERY == rightBarInfo ) { //Batery
            rightBarPercentage = sysStats.battery / 100.0;
            rightBarColor = Gfx.COLOR_GREEN;

            if( sysStats.battery < LOW_BATT_PERCENTAGE ) {
                rightBarColor = Gfx.COLOR_YELLOW;
            }
        } else if( DATA_STAIRS == rightBarInfo && ( Act.Info has :floorsClimbed ) ) { //Stairs Climbed
            rightBarColor = Gfx.COLOR_PURPLE;
            rightBarPercentage = actInfo.floorsClimbed * 1.0 / actInfo.floorsClimbedGoal;
        } else if( DATA_INTENSITY == rightBarInfo && ( Act.Info has :activeMinutesWeek ) ) { //Active/Intensity Minutes
            rightBarColor = Gfx.COLOR_ORANGE;
            rightBarPercentage = actInfo.activeMinutesWeek.total * 1.0 / actInfo.activeMinutesWeekGoal;
        } else if( DATA_STEPS == rightBarInfo && devSettings.activityTrackingOn ) { //Stairs
            rightBarPercentage = actInfo.steps * 1.0 / actInfo.stepGoal;
            rightBarColor = Gfx.COLOR_BLUE;
        }

        if( Sys.SCREEN_SHAPE_RECTANGLE == devSettings.screenShape ) {
            //Draw left bar
            var leftBarHeight = (dc.getHeight() * leftBarPercentage).toNumber();
            if( leftBarHeight > dc.getHeight() ) {
                leftBarHeight = dc.getHeight();
            }
            if( leftBarHeight > 0 ) {
                for( var i = 0; i < BAR_WIDTH; i++ ) {
                    dc.setColor(leftBarColor, Gfx.COLOR_TRANSPARENT);
                    dc.fillRectangle(0, dc.getHeight() - leftBarHeight, BAR_WIDTH, leftBarHeight);
                }
            }

            //Draw right bar
            var rightBarHeight = (dc.getHeight() * rightBarPercentage).toNumber();
            if( rightBarHeight > dc.getHeight() ) {
                rightBarHeight = dc.getHeight();
            }
            if( rightBarHeight > 0 ) {
                for( var i = 0; i < BAR_WIDTH; i++ ) {
                    dc.setColor(rightBarColor, Gfx.COLOR_TRANSPARENT);
                    dc.fillRectangle(dc.getWidth() - BAR_WIDTH, dc.getHeight() - rightBarHeight, BAR_WIDTH, rightBarHeight);
                }
            }
        } else if( Sys.SCREEN_SHAPE_ROUND == devSettings.screenShape ) {
            //Draw left bar
            var leftArcEnd = (270 - 180 * leftBarPercentage).toNumber();
            if( leftArcEnd < 270 - 180 ) {
                leftArcEnd = 90;
            }
            if( leftArcEnd != 270 ) {
                for( var i = 0; i < BAR_WIDTH + 1; i++ ) {
                    dc.setColor(leftBarColor, Gfx.COLOR_TRANSPARENT);
                    dc.drawArc(dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 - BAR_WIDTH + i + 1, Gfx.ARC_CLOCKWISE, 270, leftArcEnd );
                }
            }

            //Draw right bar
            var rightBarArcEnd = (180 * rightBarPercentage + 270).toNumber();
            if( rightBarArcEnd > 270 + 180 ) {
                rightBarArcEnd = 450;
            }

            if( rightBarArcEnd != 270 ) {
                for( var i = 0; i < BAR_WIDTH + 1; i++ ) {
                    dc.setColor(rightBarColor, Gfx.COLOR_TRANSPARENT);
                    dc.drawArc(dc.getWidth() / 2 - 1, dc.getHeight() / 2, dc.getWidth() / 2 - BAR_WIDTH + i + 1, Gfx.ARC_COUNTER_CLOCKWISE, 270, rightBarArcEnd );
                }
            }
        }
    } /* drawBars() */

    function drawIcons(dc, locY, alignment) {
        //Dimensions
        var retHeight = alarmBitmap.getHeight(); //All are same height, don't do max([alarmBitmap.getHeight(), sleepBitmap.getHeight(), phoneBitmap.getHeight()]);
        var retWidth = 0;
        var locX;
        var numIcons = 0;
        var noIconSpace = 6;
        var maxIcons = 4;
        var spacer = 12;

        //Align
        if( ALIGN_MID == alignment ) {
            locY -= retHeight / 2;
        } else if( ALIGN_BOT == alignment ) {
            locY -= retHeight;
        }

        //Get total width
        if( devSettings.doNotDisturb ) {
            retWidth += sleepBitmap.getWidth();
            numIcons++;
        }
        if( devSettings.notificationCount > 0 ) {
            retWidth += notificationBitmap.getWidth();
            numIcons++;
        }
        if( devSettings.phoneConnected ) {
            retWidth += phoneBitmap.getWidth();
            numIcons++;
        }
        if( devSettings.alarmCount > 0 ) {
            retWidth += alarmBitmap.getWidth();
            numIcons++;
        }

        spacer += (maxIcons - numIcons) * noIconSpace;

        retWidth += ( numIcons - 1 ) * spacer;
        locX = ( dc.getWidth() - retWidth ) / 2;

        //Draw icons
        if( devSettings.doNotDisturb ) {
            dc.drawBitmap(locX, locY, sleepBitmap);
            locX += sleepBitmap.getWidth() + spacer;
        }
        if( devSettings.notificationCount > 0 ) {
            dc.drawBitmap(locX, locY, notificationBitmap);
            locX += notificationBitmap.getWidth() + spacer;
        }
        if( devSettings.phoneConnected ) {
            dc.drawBitmap(locX, locY, phoneBitmap);
            locX += phoneBitmap.getWidth() + spacer;
        }
        if( devSettings.alarmCount > 0 ) {
            dc.drawBitmap(locX, locY, alarmBitmap);
            locX += alarmBitmap.getWidth() + spacer;
        }

        return [retWidth, retHeight];
    } /* drawIcons() */

    function drawDate(dc, locY, alignment) {
        //Setup
        var date = Cal.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$, $2$ $3$", [date.day_of_week, date.month, date.day]);
        var just = Gfx.TEXT_JUSTIFY_CENTER;
        var dateFont = Gfx.FONT_MEDIUM;

        //Determine dimensions
        var dateDim = dc.getTextDimensions(dateString, dateFont);

        //Align
        if( ALIGN_MID == alignment ) {
            just |= Gfx.TEXT_JUSTIFY_VCENTER;
        } else if( ALIGN_BOT == alignment ) {
            locY -= dateDim[1];
        }

        //Draw the date
        dc.setColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, locY, dateFont, dateString, just);

        return dateDim;
    } /* drawDate() */

    function drawHistory(dc, locY, alignment) {
        var spacer = 2;
        var numDays = 6;
        var textFont = Gfx.FONT_XTINY;
        var retWidth = 0;
        var retHeight = 0;

        //Align
        if( ALIGN_MID == alignment ) {
            locY -= retHeight / 2;
        } else if( ALIGN_BOT == alignment ) {
            locY -= retHeight;
        }

        var date = Cal.info( Time.now(), Time.FORMAT_SHORT );
        var dayOfWeek = date.day_of_week;

        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );

        var textDim = dc.getTextDimensions( "98%", textFont );
        textDim[1] -= Gfx.getFontDescent(textFont);

        var spacePerDay = ( star3Bitmap.getWidth() > textDim[0] ) ? star3Bitmap.getWidth() + spacer : textDim[0] + spacer;

        if( Sys.SCREEN_SHAPE_ROUND == devSettings.screenShape ) {
            var radius = dc.getWidth() / 2 - (BAR_WIDTH - 1);
            var offset = ( locY > radius ) ? locY + star3Bitmap.getHeight() + Gfx.getFontAscent(textFont) - radius : radius - locY;
            retWidth = (Math.sqrt( radius * radius - offset * offset) * 2).toNumber(); //Pythagorean theorem to find screen's edge from center, x2 for symmetry
        } else if( Sys.SCREEN_SHAPE_RECTANGLE ) {
            retWidth = dc.getWidth() - (BAR_WIDTH + spacer) * 2;
        }
        while( retWidth < ( spacePerDay * numDays ) ) {
            numDays--;
        }

        var yesterday = ( dayOfWeek + 6 ) % 7;

        var history = Act.getHistory();
        numDays = ( history.size() < numDays ) ? history.size() : numDays;
        retWidth = numDays * spacePerDay;

        if( history != null && history.size() > 0 ) {
            //Information about the days. Index 0 is 'yesterday', Index 1 was two days ago, etc...
            var percents = new [numDays];
            var days = new [numDays];

            for( var i = 0; i < numDays; i++ ) {
                if( history[i].steps != null && history[i].stepGoal != null && history[i].stepGoal > 0 ) {
                    var historyMoment = Cal.info( history[i].startOfDay, Time.FORMAT_LONG ); //Get info from day in history
                    percents[i] = ( history[i].steps.toFloat() / history[i].stepGoal.toFloat() * 100.0 ).toNumber(); //Get step goal percentage that day
                    days[i] = historyMoment.day_of_week.toCharArray()[0]; //Get first letter of weekday
                }
            }

            var percHeight = (star3Bitmap.getHeight() > textDim[1]) ? star3Bitmap.getHeight() : textDim[1]; //Taller of stars or text
            var percMidY = locY + percHeight / 2;
            var textY = locY + percHeight;
            var dayMidX = (dc.getWidth() - retWidth + spacePerDay) / 2;
            retHeight = percHeight + textDim[1]; //TODO: Dont' have magic number

            for( var day = numDays - 1; day >= 0; day-- ) {
                if( percents[day] < 100 ) {
                    dc.drawText( dayMidX, percMidY, textFont, percents[day] + "%", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
                } else if(percents[day] >= 300) {
                    dc.drawBitmap( dayMidX - star3Bitmap.getWidth() / 2, percMidY - star3Bitmap.getHeight() / 2, star3Bitmap );
                } else if(percents[day] >= 200) {
                    dc.drawBitmap( dayMidX - star2Bitmap.getWidth() / 2, percMidY - star2Bitmap.getHeight() / 2, star2Bitmap );
                } else if(percents[day] >= 100) {
                    dc.drawBitmap( dayMidX - star1Bitmap.getWidth() / 2, percMidY - star1Bitmap.getHeight() / 2, star1Bitmap );
                }

                dc.drawText( dayMidX, textY - 4, textFont, days[day], Gfx.TEXT_JUSTIFY_CENTER );
                dayMidX += spacePerDay;
            }
        }

        return [retWidth, retHeight];
    }

    function drawDataField(dc, locY, alignmentY, locX, alignmentX) {
        var dataFieldInfo = App.getApp().getProperty("DataFieldInfo");
        var iconBitmap = null;

        if( ( DATA_STAIRS    == dataFieldInfo && !( Act.Info has :floorsClimbed )        ) ||
            ( DATA_STEPS     == dataFieldInfo && !devSettings.activityTrackingOn         ) ||
            ( DATA_INTENSITY == dataFieldInfo && !( Act.Info has :activeMinutesWeek )    ) ||
            ( DATA_HR        == dataFieldInfo && !( Act has :HeartRateSample )           ) ||
            ( DATA_NONE      == dataFieldInfo ) ) {
            return [0, 0];
        }

        var font = Gfx.FONT_SMALL;
        var text = App.getApp().getProperty("ShowDataFieldIcon") ? " " : ""; //Pad with space if using icon

        switch( dataFieldInfo ) {
            case DATA_STAIRS:
                text += actInfo.floorsClimbed.toString();
                iconBitmap = stairBitmap;
                break;

            case DATA_STEPS:
                text += actInfo.steps;
                iconBitmap = stepBitmap;
                break;

            case DATA_INTENSITY:
                text += actInfo.activeMinutesWeek.total;
                iconBitmap = intensityBitmap;
                break;

            case DATA_HR:
                var oneMinute = new Time.Duration(60);
                var hrIterator = ActivityMonitor.getHeartRateHistory(1, true);

                var hr = hrIterator.next();
                //If the sample is valid and from the last minute, display it
                if( hr != null && hr.heartRate != Act.INVALID_HR_SAMPLE && Time.now().lessThan(hr.when.add(oneMinute)) ) {
                    text += hr.heartRate.toString();
                } else {
                    text += "--";
                }
                iconBitmap = heartBitmap;
                break;

            default:
                return [0, 0];
        }

        if( !App.getApp().getProperty("ShowDataFieldIcon") ) {
            iconBitmap = null;
        }

        var retWidth = dc.getTextWidthInPixels(text, font) + (iconBitmap != null ? iconBitmap.getWidth() : 0);
        var retHeight = max([(iconBitmap == null ? 0 : iconBitmap.getHeight()),Gfx.getFontHeight(font)]);

        dc.setColor(fgColor, Gfx.COLOR_TRANSPARENT);

        //Align Y
        if( ALIGN_MID == alignmentY ) {
            locY -= retHeight / 2;
        } else if( ALIGN_BOT == alignmentY ) {
            locY -= retHeight;
        }

        //Align X - Align to center
        if( ALIGN_LEFT == alignmentX ) {
            locX += retWidth / 2;
        } else if( ALIGN_RIGHT == alignmentX ) {
            locX -= retWidth / 2;
        }

        if(iconBitmap != null) {
            dc.drawBitmap(locX - retWidth / 2, locY + retHeight / 2 - iconBitmap.getHeight() / 2, iconBitmap);
        }

        var centerY = locY + retHeight / 2;
        dc.drawText(locX + retWidth / 2, centerY, font, text, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);

        return [retWidth, retHeight];
    } /* drawDataField() */

    function max(numbers) {
        var max = numbers[0];
        for( var i = 1; i < numbers.size(); i++ ) {
            if( max < numbers[i] ) {
                max = numbers[i];
            }
        }

        return max;
    }

    var curClip;
    // Handle the partial update event
    function onPartialUpdate( dc ) {
        var secondString = System.getClockTime().sec.format("%02d");

        // Update the cliping rectangle to the new location of the second hand.
        dc.setClip(secLocation[0], secLocation[1], secDimension[0] + 1, secDimension[1] + 1);

        // Draw the second hand to the screen.
        dc.setColor(fgColor, Graphics.COLOR_BLACK);
        dc.drawText(secLocation[0], secLocation[1], secFont, secondString, Gfx.TEXT_JUSTIFY_LEFT);
   }
}

class EdgeDelegate extends Ui.WatchFaceDelegate {

    function initialize() {
        Ui.WatchFaceDelegate.initialize();
    }

    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
        Ui.requestUpdate();
    }
}

