#!/bin/bash
echo "Push to develop branch of all origins"
git push github develop && git push heroku develop && git push bitbucket develop
echo "Done"

