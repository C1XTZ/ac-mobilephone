local bit		= bit
local error		= error
local ipairs	= ipairs
local string	= string
local table		= table
local unpack	= unpack

module( "utf8" )

--
-- Pattern that can be used with the string library to match a single UTF-8 byte-sequence.
-- This expects the string to contain valid UTF-8 data.
--
charpattern = "[%z\x01-\x7F\xC2-\xF4][\x80-\xBF]*"

--
-- Transforms indexes of a string to be positive.
-- Negative indices will wrap around like the string library's functions.
--
local function strRelToAbs( str, ... )

	local args = { ... }

	for k, v in ipairs( args ) do
		v = v > 0 and v or #str + v + 1

		if v < 1 or v > #str then
			error( "bad index to string (out of range)", 3 )
		end

		args[ k ] = v
	end

	return unpack( args )

end

-- Decodes a single UTF-8 byte-sequence from a string, ensuring it is valid
-- Returns the index of the first and last character of the sequence
--
local function decode( str, startPos )

	startPos = strRelToAbs( str, startPos or 1 )

	local b1 = str:byte( startPos, startPos )

	-- Single-byte sequence
	if b1 < 0x80 then
		return startPos, startPos
	end

	-- Validate first byte of multi-byte sequence
	if b1 > 0xF4 or b1 < 0xC2 then
		return nil
	end

	-- Get 'supposed' amount of continuation bytes from primary byte
	local contByteCount =	b1 >= 0xF0 and 3 or
							b1 >= 0xE0 and 2 or
							b1 >= 0xC0 and 1

	local endPos = startPos + contByteCount

	-- Validate our continuation bytes
	for _, bX in ipairs { str:byte( startPos + 1, endPos ) } do
		
		if bit.band( bX, 0xC0 ) ~= 0x80 then
			return nil
		end

	end

	return startPos, endPos 

end

--
-- Takes zero or more integers and returns a string containing the UTF-8 representation of each
--
function char( ... )

	local buf = {}

	for k, v in ipairs { ... } do

		if v < 0 or v > 0x10FFFF then
			error( "bad argument #" .. k .. " to char (out of range)", 2 )
		end

		local b1, b2, b3, b4 = nil, nil, nil, nil

		if v < 0x80 then -- Single-byte sequence

			table.insert( buf, string.char( v ) )

		elseif v < 0x800 then -- Two-byte sequence

			b1 = bit.bor( 0xC0, bit.band( bit.rshift( v, 6 ), 0x1F ) )
			b2 = bit.bor( 0x80, bit.band( v, 0x3F ) )

			table.insert( buf, string.char( b1, b2 ) )

		elseif v < 0x10000 then -- Three-byte sequence

			b1 = bit.bor( 0xE0, bit.band( bit.rshift( v, 12 ), 0x0F ) )
			b2 = bit.bor( 0x80, bit.band( bit.rshift( v, 6 ), 0x3F ) )
			b3 = bit.bor( 0x80, bit.band( v, 0x3F ) )

			table.insert( buf, string.char( b1, b2, b3 ) )

		else -- Four-byte sequence

			b1 = bit.bor( 0xF0, bit.band( bit.rshift( v, 18 ), 0x07 ) )
			b2 = bit.bor( 0x80, bit.band( bit.rshift( v, 12 ), 0x3F ) )
			b3 = bit.bor( 0x80, bit.band( bit.rshift( v, 6 ), 0x3F ) )
			b4 = bit.bor( 0x80, bit.band( v, 0x3F ) )

			table.insert( buf, string.char( b1, b2, b3, b4 ) )

		end

	end

	return table.concat( buf, "" )

end

--
-- Iterates over a UTF-8 string similarly to pairs
-- k = index of sequence, v = string value of sequence
--
function codes( str )

	local i = 1

	return function()

		-- Have we hit the end of the iteration set?
		if i > #str then
			return nil
		end

		local startPos, endPos = decode( str, i )

		if not startPos then
			error( "invalid UTF-8 code", 2 )
		end

		i = endPos + 1

		return startPos, str:sub( startPos, endPos )

	end

end

--
-- Returns an integer-representation of the UTF-8 sequence(s) in a string
-- startPos defaults to 1, endPos defaults to startPos
--
function codepoint( str, startPos, endPos )

	startPos, endPos = strRelToAbs( str, startPos or 1, endPos or startPos or 1 )

	local ret = {}

	repeat
		local seqStartPos, seqEndPos = decode( str, startPos )

		if not seqStartPos then
			error( "invalid UTF-8 code", 2 )
		end

		-- Increment current string index
		startPos = seqEndPos + 1

		-- Amount of bytes making up our sequence
		local len = seqEndPos - seqStartPos + 1

		if len == 1 then -- Single-byte codepoint

			table.insert( ret, str:byte( seqStartPos ) )

		else -- Multi-byte codepoint

			local b1 = str:byte( seqStartPos )
			local cp = 0

			for i = seqStartPos + 1, seqEndPos do

				local bX = str:byte( i )

				cp = bit.bor( bit.lshift( cp, 6 ), bit.band( bX, 0x3F ) )
				b1 = bit.lshift( b1, 1 )

			end

			cp = bit.bor( cp, bit.lshift( bit.band( b1, 0x7F ), ( len - 1 ) * 5 ) )

			table.insert( ret, cp )

		end
	until seqEndPos >= endPos

	return unpack( ret )

end

--
-- Returns the length of a UTF-8 string. false, index is returned if an invalid sequence is hit
-- startPos defaults to 1, endPos defaults to -1
--
function len( str, startPos, endPos )

	startPos, endPos = strRelToAbs( str, startPos or 1, endPos or -1 )

	local len = 0

	repeat
		local seqStartPos, seqEndPos = decode( str, startPos )

		-- Hit an invalid sequence?
		if not seqStartPos then
			return false, startPos
		end

		-- Increment current string pointer
		startPos = seqEndPos + 1

		-- Increment length
		len = len + 1
	until seqEndPos >= endPos

	return len

end

--
-- Returns the byte-index of the n'th UTF-8-character after the given byte-index (nil if none)
-- startPos defaults to 1 when n is positive and -1 when n is negative
-- If 0 is zero, this function instead returns the byte-index of the UTF-8-character startPos lies within.
--
function offset( str, n, startPos )

	startPos = strRelToAbs( str, startPos or ( n >= 0 and 1 ) or #str )

	-- Find the beginning of the sequence over startPos
	if n == 0 then

		for i = startPos, 1, -1 do
			local seqStartPos, seqEndPos = decode( str, i )

			if seqStartPos then
				return seqStartPos
			end
		end

		return nil

	end

	if not decode( str, startPos ) then
		error( "initial position is not beginning of a valid sequence", 2 )
	end

	local itStart, itEnd, itStep = nil, nil, nil

	if n > 0 then -- Find the beginning of the n'th sequence forwards

		itStart = startPos
		itEnd = #str
		itStep = 1

	else -- Find the beginning of the n'th sequence backwards

		n = -n
		itStart = startPos
		itEnd = 1
		itStep = -1

	end

	for i = itStart, itEnd, itStep do
		local seqStartPos, seqEndPos = decode( str, i )

		if seqStartPos then

			n = n - 1

			if n == 0 then
				return seqStartPos
			end

		end
	end

	return nil

end

--
-- Forces a string to contain only valid UTF-8 data.
-- Invalid sequences are replaced with U+FFFD.
--
function force( str )

	local buf = {}

	local curPos, endPos = 1, #str

	repeat
		local seqStartPos, seqEndPos = decode( str, curPos )

		if not seqStartPos then

			table.insert( buf, char( 0xFFFD ) )
			curPos = curPos + 1

		else

			table.insert( buf, str:sub( seqStartPos, seqEndPos ) )
			curPos = seqEndPos + 1

		end
	until curPos > endPos

	return table.concat( buf, "" )

end
