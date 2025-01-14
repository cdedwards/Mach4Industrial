package.path = package.path .. ";./Modules/?.lua;"
package.cpath = package.cpath .. ";./Modules/?.dll;"

mysql = require("luasql.mysql")
-- do some mysql stuff here...

