return {
  name = "Skip Compile",
  description = "Forces the IDE to skip trying to compile the script when debugging.",
  author = "Steve Murphree",
  version = 0.1,
  dependencies = "1.20",

  onInterpreterLoad = function(self, interpreter) 
      --ide:Print(interpreter.name)
      if (interpreter.name == 'Mach4') then 
        interpreter.skipcompile = true
      end
  end,
}

