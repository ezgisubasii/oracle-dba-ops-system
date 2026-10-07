# RCA - ORA-12541 Listener down, database still running
## What happened
Clients could not connect to the database. Every new connection failed with this error.

    ORA-12541: Cannot connect. No listener at host 127.0.0.1 port 1521.

In this lab, I stopped the listener on purpose with `lsnrctl stop`.

## Impact
No application could open a new connection. The database itself kept running,
and sessions that were already connected were not affected.

## How I found the cause
I checked each layer from the network up to the database.

1. TCP. Port 1521 inside the container was closed, so nothing was listening.
2. Listener. `lsnrctl status` returned TNS-12541 and "Connection refused".
3. Client. A normal network connection failed with ORA-12541.
4. Database. A local connection with `/ as sysdba` worked and showed FREE as OPEN.

The database was healthy, so the problem was only in the listener.
Port 1521 must be checked inside the container. On the VM the port looks open,
because Docker itself listens on it and forwards the traffic.

## Root cause
The listener process was stopped. Without it, Oracle cannot accept connections
over the network, even when the database is open.

## Fix
    lsnrctl start
    ALTER SYSTEM REGISTER;

Right after the start, `lsnrctl status` showed "The listener supports no
services". ALTER SYSTEM REGISTER made the database register with the listener
at once instead of waiting up to 60 seconds. After that, the network connection
worked again.

## Prevention
- Monitor port 1521 from outside the database server and alert if it is closed.
- Start the listener automatically with the server, for example with systemd.
- Check the listener log after an outage to find out why it stopped.
- Keep listener.ora under version control, so a bad change can be found and undone.

