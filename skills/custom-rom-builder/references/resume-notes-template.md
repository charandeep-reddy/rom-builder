# Resume notes template (survives context compaction and new sessions)

Keep one notes file next to the source tree, for example `~/android/<project>-notes.md`. Update it at every milestone and before the user compacts the session. A future session reads it first.

Never put passwords, tokens or personal data in it. If the user shared a password in chat, record only that they did and that they should change it.

```markdown
# <Device> custom ROM: notes
Last updated: <date time from `date`>

## Goal and constraints
<what the ROM should be; rules such as "minimal, no bloat">

## Machine
<RAM, swap, disk, CPU; decisions such as -j value and why>

## Current state (what is true right now)
- Build: <running / finished / failed>, log path, last verified result line
- Outputs: <zip path, size, checksum, integrity checked?>
- Swap files / ccache / disk free
- Background watchers or scripts that exist

## Commands that work (copy-paste)
<the exact build command, how to resume, how to check status>

## Decisions and why
<dated list>

## Open questions / pending items
<ordered list, who must decide, what is blocked on what>

## Things that must NOT be done without asking
<flashing, relocking, deleting source, etc.>

## Gotchas hit (so they are not hit twice)
<short list with the real cause>
```
