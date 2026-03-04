# Tasks

- [ ] create a collection for the uids of administrators and set the rule to only accessible by admin sdk, and modify the rule for "feedback" collection that it can be read or write by when either uid is the current authenticated user or uid can be found as in the administrator collection. then create a python script in scripts to add or delete a user with certain email as administrator, also update ./GEMINI.md with instructions to use the script
- [ ] deleting feedback in dash does not work, check if this is a rules issue or implementation issue and fix it
- [ ] when the user submit a feedback in app, also include which screen is the user at when submitting the feedback