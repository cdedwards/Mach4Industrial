-----------------------------------------------------------------------------
-- Name:        Straight Font Module
-- Author:      B Barker
-- Modified by:
-- Created:     03/11/2015
-- Copyright:   (c) 2015 Newfangled Solutions. All rights reserved.
-- Modified 12/10/21 Changed to aloow the new font engraving screen to do more Like the posting angle and translate 
-----------------------------------------------------------------------------
 post = {}
 post.height = .5;
 post.heightRapid = .5;
 post.heightFeed = .05;
 post.heightDepth = -.025;
 post.feedPlung = 10;
 post.feedCut = 20;
 post.RPM = 100000;
 post.Cool = 8;

 post.lastFeed = -.99999999;
 post.lastX = -.99999999; -- Position of the last move output (could have rotation)
 post.lastY = -.99999999;
 post.lastZ = -.99999999; 
 post.lastG = -1;
 post.letterStartX = 0.0;
 post.letterStartY = 0.0;
 post.GcodeString = '';
 post.letterSpace = post.height * .25;
 post.rotpoint = {};
 post.rotpoint.x = 0.0;
 post.rotpoint.y = 0.0;
 post.rotpoint.angle = 0.0
 post.transpoint = {};
 post.transpoint.x = 0;
 post.transpoint.y = 0;

function post.SetLetterAngle(angle)
	post.rotpoint.angle = angle
end

function post.GetLetterAngle()
	return post.rotpoint.angle
end

function post.SetLetterStart(x, y)
	post.letterStartX = x;
	post.letterStartY = y;
end

function post.GetLetterStart()
	return post.letterStartX ,post.letterStartY
end

function post.SetLetterRotationPoint(x, y)
	post.rotpoint.x = x;
	post.rotpoint.y = y;
end

function post.GetLetterRotationPoint()
	return post.rotpoint.x ,post.rotpoint.y 
end

function post.SetTranslation(x, y)
	post.transpoint.x = x;
	post.transpoint.y = y;
end

function post.GetSetTranslation()
	return post.transpoint.x ,post.transpoint.y 
end
function  post.setLetterSpace(v)
	 post.letterSpace = v;
end
function  post.getLetterSpace()
	 return post.letterSpace;
end
function  post.setXStart(v)
	 post.letterStartX = v;
end

function  post.setYStart(v)
	 post.letterStartY = v;
end

function  post.setHeight(v)
	 post.height = v;
end

function  post.setRapidHeight(v)
	 post.heightRapid = v;
end

function  post.setFeedHeight(v)
	 post.heightFeed = v;
end

function  post.setDepth(v)
	 post.heightDepth = v;
end

function  post.setFeedPlung(v)
	 post.feedPlung = v;
end

function  post.setFeedCut(v)
	 post.feedCut = v;
end

function  post.setRPM(v)
	 post.RPM = v;
end

function  post.setCool(v)
	 post.Cool = v;
end

function  post.ProgStart()
	local gheader = "(Font Engraving)\n"
	gheader = gheader .. string.format("G90 G80 G49\nG0 X0 Y0\nS%.0f M3\nG00 Z%.4f M%.0f\n", tonumber( post.RPM), tonumber( post.heightRapid), tonumber( post.Cool))
	return gheader
end

function  post.ProgEnd()
	local gfooter = string.format("\nG00 Z%.4f M9\nM30\n",  post.heightRapid)
	return gfooter
end

function post.calcpoint(xpos,ypos)
	xpos, ypos = post.ScalePoint(xpos,ypos);
	
	xpos = xpos +  post.letterStartX; -- Shif to the end of the last X move 
	ypos = ypos +  post.letterStartY; -- Shift tto the end of the Y axis
	
	xpos, ypos = post.RotatePoint(xpos,ypos);
	
	
	
	xpos,ypos = post.TranslatePoint(xpos,ypos);
	return xpos, ypos
end

function  post.G0(xpos,ypos)
	local rval = '';
	if( tonumber( post.lastG) ~= 0 ) then
		rval = rval .. 'G0 ';
		 post.lastG = 0;
	end
	xpos, ypos = post.calcpoint(xpos,ypos)
	if( tonumber( post.lastX) ~= tonumber(xpos) ) then
		rval = rval .. string.format('X%.4f ', xpos);
		 post.lastX = xpos;
	end
	if( tonumber( post.lastY) ~= tonumber(ypos) ) then
		rval = rval .. string.format('Y%.4f ', ypos);
		 post.lastY = ypos;
	end
	if(rval ~= '')then
		rval = rval .. '\n'
	end
	 post.GcodeString =  post.GcodeString .. rval;
	return (rval);
end

function  post.ZDn()-- TODO add code here for the G31.1
	local rval = '';
	if( tonumber( post.lastZ) ~=  tonumber( post.heightDepth) ) then
		if( tonumber( post.lastG) ~= 0 ) then
			rval = rval .. 'G0 ';
			 post.lastG = 0;
		end
		rval = rval .. string.format('Z%.4f\nG1 Z%.4f ',  post.heightFeed , post.heightDepth);
		
		if( tonumber( post.lastFeed) ~= tonumber( post.feedPlung) ) then 
			rval = rval .. string.format('F%.2f ',  post.feedPlung);
			 post.lastFeed =  post.feedPlung;
		end

		 post.lastZ =  post.heightDepth;
		 post.lastG = 1;
		rval = rval .. '\n';
	end
	 post.GcodeString =  post.GcodeString .. rval;
	return (rval);
end

function  post.ZUp()
	local rval = '';
	if( tonumber( post.lastZ) ~=  tonumber( post.heightRapid) ) then
		if( tonumber( post.lastG) ~= 0 ) then
			rval = rval .. 'G0 ';
			 post.lastG = 0;
		end
		rval = rval .. string.format('Z%.4f\n',  post.heightRapid);
		 post.lastZ =  post.heightRapid;
	end
	 post.GcodeString =  post.GcodeString .. rval;
	return (rval);

end

function  post.G1(xpos,ypos)
	local rval = '';
	local feedinXY = false;

	if( tonumber( post.lastG) ~= 1 ) then
		rval = rval .. 'G1 ';
		 post.lastG = 1;
	end
	xpos, ypos = post.calcpoint(xpos,ypos)
	
	if( tonumber( post.lastX) ~= tonumber(xpos) ) then
		rval = rval .. string.format('X%.4f ', xpos);
		 post.lastX = xpos;
		feedinXY = true;
	end

	if( tonumber( post.lastY) ~= tonumber(ypos) ) then
		rval = rval .. string.format('Y%.4f ', ypos);
		 post.lastY = ypos;
		feedinXY = true;
	end

	if( feedinXY == true)then
		if( tonumber( post.lastFeed) ~= tonumber( post.feedCut) ) then 
			rval = rval .. string.format('F%.2f ', tonumber( post.feedCut));
			 post.lastFeed =  post.feedCut;
		end
	end

	if(rval ~= '')then
	rval = rval .. '\n'
	end
	 post.GcodeString =  post.GcodeString .. rval;
	return (rval);
end

function post.RotateIJ(ival, jval)
	local angle = math.atan2(jval,ival)
	local dist = math.sqrt(ival*ival + jval*jval)
	angle = angle + math.rad(post.rotpoint.angle);
	jval = dist * math.sin(angle)
	ival = dist * math.cos(angle)
	return ival, jval
end 

function  post.G2(xpos, ypos, ival, jval)
	local rval = '';
	local feedinXY = false;
	
	if(tonumber( post.lastG) ~= 2) then
		rval = rval .. 'G2 ';
		 post.lastG = 2;
	end
	ival = ival *  post.height;
	jval = jval *  post.height;
	ival,jval = post.RotateIJ(ival, jval)
	
	xpos, ypos = post.calcpoint(xpos,ypos)
	--TODO IJ's are no longer Valid
	

	if (tonumber( post.lastX) ~= tonumber(xpos)) then
		rval = rval .. string.format('X%.4f ', xpos);
		 post.lastX = xpos;
		feedinXY = true;
	end
	
	if (tonumber( post.lastY) ~= tonumber(ypos)) then
		rval = rval .. string.format('Y%.4f ', ypos);
		 post.lastY = ypos;
		feedinXY = true;
	end
	
	rval = rval .. string.format('I%.4f J%.4f ', ival, jval)
	
	if (feedinXY == true) then
		if (tonumber( post.lastFeed) ~= tonumber( post.feedCut)) then
			rval = rval .. string.format('F%.2f ',  post.feedCut);
			 post.lastFeed =  post.feedCut;
		end
	end
	
	if (rval ~= '') then
		rval = rval .. '\n'
	end
	
	 post.GcodeString =  post.GcodeString .. rval;
	return (rval);
end

function  post.G3(xpos, ypos, ival, jval)
	local rval = '';
	local feedinXY = false;
	
	if(tonumber( post.lastG) ~= 3) then
		rval = rval .. 'G3 ';
		 post.lastG = 3;
	end
	
	ival = ival *  post.height;
	jval = jval *  post.height;
	ival,jval = post.RotateIJ(ival, jval)
	xpos, ypos = post.calcpoint(xpos,ypos)

	if (tonumber( post.lastX) ~= tonumber(xpos)) then
		rval = rval .. string.format('X%.4f ', xpos);
		 post.lastX = xpos;
		feedinXY = true;
	end
	
	if (tonumber( post.lastY) ~= tonumber(ypos)) then
		rval = rval .. string.format('Y%.4f ', ypos);
		 post.lastY = ypos;
		feedinXY = true;
	end
	
	rval = rval .. string.format('I%.4f J%.4f ', ival, jval)
	
	if (feedinXY == true) then
		if (tonumber( post.lastFeed) ~= tonumber( post.feedCut)) then
			rval = rval .. string.format('F%.2f ',  post.feedCut);
			 post.lastFeed =  post.feedCut;
		end
	end
	
	if (rval ~= '') then
		rval = rval .. '\n'
	end
	
	 post.GcodeString =  post.GcodeString .. rval;
	return (rval);
end

function  post.AddWidth(Width) -- Returns the Gcode for the letter and the width of the letter  Calling this function will also incerment the start of the next letter 
	local rval =  post.GcodeString;
	 post.GcodeString = '';
	 post.letterStartX = ( post.letterStartX +  post.height*Width) + (post.letterSpace);
	return rval,Width;
end

function  post.ClearSettings(xpos, ypos)
	if (xpos == nil) then
		xpos = 0
	end
	if (ypos == nil) then
		ypos = 0
	end
	 post.letterStartX = xpos;
	 post.letterStartY = ypos;
	post.SetTranslation(0, 0) 
	post.lastX = -.99999999; 
	post.lastY = -.99999999;
	post.lastFeed = -.99999999;
	post.lastZ = -.99999999;
end

function post.RotatePoint(x, y)
	local mag = {};
	mag.x = x - post.rotpoint.x;
	mag.y = y - post.rotpoint.y;
	local startangle = math.atan2(mag.y, mag.x);
	local dist = math.sqrt((mag.x* mag.x) + (mag.y* mag.y));
	local a =  startangle + math.rad(post.rotpoint.angle);
	x = post.rotpoint.x + dist * math.cos(a);
	y = post.rotpoint.y + dist * math.sin(a);
	return x,y
end

function post.TranslatePoint(x, y)
	x = x + post.transpoint.x;
	y = y + post.transpoint.y;
	return x,y
end

function post.ScalePoint(x, y)
	x = x * post.height;
	y = y * post.height;
	return x,y
end

return  post





