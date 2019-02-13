## Script to generate an organization users git push information

### Set the following ENV variables
`GITHUB_USER` - to your github username

`GITHUB_ORG` - to organization name that you are willing to get the info and have access to it

`GITHUB_TOKEN` - Login and goto https://github.com/settings/tokens and generate a new token. (Don't give any write permissions while generating token)


### Run the script
`perl user_git_push.pl`

### See the output
open the html file `user_push.html` in a browser

DONE!


Note: Github events api gives only recent 300 events and so this script shows only last 300 events
