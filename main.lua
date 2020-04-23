do -- Monkeypatches
	function assertl(value, message, level)
		message = message or "Assertion failed!"
		if not value then
			error(message, level)
		end
		return value
	end

	function io.size(file)
		local pos = file:seek()
		local size = file:seek("end")
		file:seek("set", pos)
		return size
	end
end

local filename = assertl(select(1, ...), "No program to run!", 0)
local program = assertl(io.open(filename), "Program not found.", 0)

local loops = {}
do -- Preprocess square brackets
	local loopStack, line, col = {}, 1, 1
	repeat
		local i = program:seek()
		local char = program:read(1)
		if char == "[" then
			table.insert(loopStack, i)
		elseif char == "]" then
			local j = assertl(table.remove(loopStack), "Unexpected ] at line " .. line .. ", col " .. col, 0)
			loops[i], loops[j] = j, i
		end
		if char == "\n" then
			line = line + 1
			col = 1
		else
			col = col + 1
		end
	until char == nil
	local remaining = table.remove(loopStack)
	if remaining then
		error("Expected ] at EOF to close [ at " .. remaining, 0)
	end
end

local memory, pointer = {}, 0
local programLength = program:seek("end")
program:seek("set")
repeat
	local valueAtPointer = memory[pointer] or 0

	local pos = program:seek()
	local char = program:read(1)
	if char == ">" then
		pointer = pointer + 1
	elseif char == "<" then
		pointer = pointer - 1
	elseif char == "+" then
		memory[pointer] = (valueAtPointer + 1) % 256
	elseif char == "-" then
		memory[pointer] = (valueAtPointer - 1) % 256
	elseif char == "." then
		io.write(string.char(valueAtPointer))
	elseif char == "," then
		memory[pointer] = string.byte(io.read(1))
	elseif char == "[" then
		if valueAtPointer == 0 then
			program:seek("set", loops[pos])
		end
	elseif char == "]" then
		if valueAtPointer ~= 0 then
			program:seek("set", loops[pos])
		end
	end
until char == nil
