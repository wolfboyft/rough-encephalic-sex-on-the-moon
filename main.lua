local program, programPointer
local memory, memoryPointer
local loops

function love.load(args)
	local filename = assert(args[1], "No program to run!")
	program, message = love.filesystem.read(filename)
	assert(program, message)
	programPointer = 1
	memory, memoryPointer = {}, 0
	
	loops = {}
	local loopStack, line, col = {}, 1, 1
	for i = 1, #program do
		local char = program:sub(i, i)
		if char == "[" then
			table.insert(loopStack, i)
		elseif char == "]" then
			local j = assert(table.remove(loopStack), "Unexpected ] at line " .. line .. ", col " .. col)
			loops[i], loops[j] = j, i
		end
		if char == "\n" then
			line = line + 1
			col = 1
		else
			col = col + 1
		end
	end
	local remaining = table.remove(loopStack)
	if remaining then
		error("Expected ] at EOF to close [ at " .. remaining)
	end
end

function love.update()
	local char = program:sub(programPointer, programPointer)
	local valueAtPointer = memory[memoryPointer] or 0
	if char == ">" then
		memoryPointer = memoryPointer + 1
	elseif char == "<" then
		memoryPointer = memoryPointer - 1
	elseif char == "+" then
		memory[memoryPointer] = (valueAtPointer + 1) % 256
	elseif char == "-" then
		memory[memoryPointer] = (valueAtPointer - 1) % 256
	elseif char == "." then
		io.write(string.char(valueAtPointer))
	elseif char == "," then
		memory[memoryPointer] = string.byte(io.read(1))
	elseif char == "[" then
		if valueAtPointer == 0 then
			programPointer = loops[programPointer]
		end
	elseif char == "]" then
		if valueAtPointer ~= 0 then
			programPointer = loops[programPointer]
		end
	end
	
	programPointer = programPointer + 1
end
