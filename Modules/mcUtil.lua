local M = {_TYPE='module', _NAME='globtopattern', _VERSION='0.2.1.20120406'}

lfs = require 'lfs'

function M.globtopattern(g)
  -- Some useful references:
  -- - apr_fnmatch in Apache APR.  For example,
  --   http://apr.apache.org/docs/apr/1.3/group__apr__fnmatch.html
  --   which cites POSIX 1003.2-1992, section B.6.

  local p = "^"  -- pattern being built
  local i = 0    -- index in g
  local c        -- char at index i in g.

  -- unescape glob char
  local function unescape()
    if c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = '[^]'
        return false
      end
    end
    return true
  end

  -- escape pattern char
  local function escape(c)
    return c:match("^%w$") and c or '%' .. c
  end

  -- Convert tokens at end of charset.
  local function charset_end()
    while 1 do
      if c == '' then
        p = '[^]'
        return false
      elseif c == ']' then
        p = p .. ']'
        break
      else
        if not unescape() then break end
        local c1 = c
        i = i + 1; c = g:sub(i,i)
        if c == '' then
          p = '[^]'
          return false
        elseif c == '-' then
          i = i + 1; c = g:sub(i,i)
          if c == '' then
            p = '[^]'
            return false
          elseif c == ']' then
            p = p .. escape(c1) .. '%-]'
            break
          else
            if not unescape() then break end
            p = p .. escape(c1) .. '-' .. escape(c)
          end
        elseif c == ']' then
          p = p .. escape(c1) .. ']'
          break
        else
          p = p .. escape(c1)
          i = i - 1 -- put back
        end
      end
      i = i + 1; c = g:sub(i,i)
    end
    return true
  end

  -- Convert tokens in charset.
  local function charset()
    i = i + 1; c = g:sub(i,i)
    if c == '' or c == ']' then
      p = '[^]'
      return false
    elseif c == '^' or c == '!' then
      i = i + 1; c = g:sub(i,i)
      if c == ']' then
        -- ignored
      else
        p = p .. '[^'
        if not charset_end() then return false end
      end
    else
      p = p .. '['
      if not charset_end() then return false end
    end
    return true
  end

  -- Convert tokens.
  while 1 do
    i = i + 1; c = g:sub(i,i)
    if c == '' then
      p = p .. '$'
      break
    elseif c == '?' then
      p = p .. '.'
    elseif c == '*' then
      p = p .. '.*'
    elseif c == '[' then
      if not charset() then break end
    elseif c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = p .. '\\$'
        break
      end
      p = p .. escape(c)
    else
      p = p .. escape(c)
    end
  end
  return p
end

function M.SplitFilename(strFilename)
	-- Returns the Path, Filename, and Extension as 3 values
	if lfs.attributes(strFilename,"mode") == "directory" then
		local strPath = strFilename:gsub("[\\/]$","")
		return strPath.."\\","",""
	end
	strFilename = strFilename.."."
	return strFilename:match("^(.-)([^\\/]-%.([^\\/%.]-))%.?$")
end

function M.dir(filespec, incPath)

	incPath = incPath or false
	local ret = {}
	local path, file, extension, pattern
	
	path, file, extension = M.SplitFilename(filespec)
	if (file == "") then 
		file = "*" 
	end
	pattern = M.globtopattern(file)
    
    for file in lfs.dir ( path ) do
		if string.find(file, pattern) ~= nil then 
			if (incPath == true) then 
				table.insert(ret, path .. file)
			else 
				table.insert(ret, file)
			end
		end
    end
	return ret
end

function M.copy(src, dst)
	local dstPath, dstFile, dstExt = M.SplitFilename(dst)
	local dstIsDir = false;
	if (dstFile == "") then 
		dstIsDir = true
	end
	local srcFiles = M.dir(src, true)
	local scrFile
	local dst_file = nil
	local src_file_sz, dst_file_sz = 0, 0
	
	for _, scrFile in ipairs(srcFiles) do
		local src_file = io.open(scrFile, "rb")
		if dstIsDir == true then 
			local sPath, sFile, sExt = M.SplitFilename(scrFile)
			dstFile = dstPath .. sFile
			dst_file = io.open(dstFile, "wb")
		else 
			if dst_file == nil then
				dstFile = dst
				dst_file = io.open(dstFile, "wb")
			end
		end
		if not src_file or not dst_file then
			return false
		end
		while true do
			local block = src_file:read(2^13)
			if not block then 
				src_file_sz = src_file:seek( "end" )
				break
			end
			dst_file:write(block)
		end
		src_file:close()
		dst_file_sz = dst_file:seek( "end" )
		if dstIsDir == true then 
			dst_file:close()
			dst_file = nil
		end
	end
	if (dst_file ~= nil) then 
		dst_file:close()
		dst_file = nil
	end
	return dst_file_sz >= src_file_sz
end

function M.del(fileSpec)
	local files = {}
	local stat, msg

	files = M.dir(filespec, true)
	for _, file in ipairs(files) do
		stat, msg = os.remove(file)
		if stat ~= true then 
			return stat, msg
		end
	end
	return stat, msg
end

return M