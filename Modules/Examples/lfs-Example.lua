package.path = package.path .. ";./Modules/?.lua;"
package.cpath = package.cpath .. ";./Modules/?.dll;"

lfs = require("lfs")
-- do some lfs stuff here...
local g = 0
g = g + 3

