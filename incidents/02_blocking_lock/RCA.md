# RCA: Blocking session - web checkout waiting on an uncommitted update

## What happened
A web-checkout request tried to update order 42 and stopped responding.
There was no error message. The session was waiting on:

    enq: TX - row lock contention

## Impact
Only the requests for order 42 were stuck. Other orders worked normally.

## How I found the cause
1. V$SESSION showed web-checkout (sid 177) was blocked by sid 60.
2. The blocker was billing-batch with status INACTIVE: it was doing nothing
   but still holding the lock.
3. Its last SQL (PREV_SQL_ID in V$SQL) was:

       UPDATE prod_app.orders SET status = 'INVOICED' WHERE order_id = 42

## Root cause
The billing batch updated the row and never committed. The transaction stayed
open, so the row lock was never released.

## Fix
    ALTER SYSTEM KILL SESSION '60,11104' IMMEDIATE;

The blocked session continued right away. The first check right after the kill
still showed 1 blocked session, because the kill takes a moment. I added a
3-second wait before the check, and then it showed 0.

Killing a session rolls back its uncommitted work, so in production the
application owner must be informed first.

## Prevention
- Fix the batch job so every path ends with COMMIT or ROLLBACK.
- Monitor blocking sessions and alert if a session waits more than a few minutes.
- Use MAX_IDLE_BLOCKER_TIME to end idle sessions that block others.
- Make every application set MODULE, so the blocker can be identified quickly.

