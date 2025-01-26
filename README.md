Here is my attempt at creating a functional equivalent to the excellant 2010 Woodworker's screenset on Mach3. I was an early supporter of Mach4 so I recieved MacroB functionality under Regular Mach4 as well
as Mach4Industrial. I've based this on the Mach4Industrial Screenset.

Currently there are 2 setup screens. Eventually I'll remove one.
M6 Setup is the first. Settings is the second. There are a BUNCH of registers which need to be added to Mach4 for this to work and store things. So far I haven't discovered howto creata non-existant registers
but will work on this functionality. Use the machine.ini and look for 2025 register's to add to your machine.ini.

The fixed plate needs to be able to move down about 1/8in as I need to find a bug which moves it down instead of up.


