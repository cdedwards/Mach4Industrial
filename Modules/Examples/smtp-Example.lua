-- Replace the from and to addresses, as well as the mail server IP address, 
-- with something useful.

package.path = package.path .. ";./Modules/?.lua;"
package.cpath = package.cpath .. ";./Modules/?.dll;"

function email()

    -- load the smtp support
    local smtp = require("/socket.smtp")

    -- Connects to server "localhost" and sends a message to users
    -- "fulano@example.com",  "beltrano@example.com", 
    -- and "sicrano@example.com".
    -- Note that "fulano" is the primary recipient, "beltrano" receives a
    -- carbon copy and neither of them knows that "sicrano" received a blind
    -- carbon copy of the message.
    from = "<mailfrom@sendingdomain.com>"

    rcpt = {
        "<someuser@somedomain.com>"
    }

    mesgt = {
        headers = {
            to = "Some User <someuser@somedomain.com>",
            subject = "email test"
        },
        body = "This is a message from M300."
    }

    r, e = smtp.send{
        from = from,
        rcpt = rcpt, 
        source = smtp.message(mesgt),
        server = "192.168.1.25" -- mail server to use...  defaults to port 25.
    }
    r = r
end    

email()
