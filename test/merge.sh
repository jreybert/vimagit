set -xe

if [ "$TRAVIS_BRANCH" != "integration" ]; then
    echo 'Not an integration branch, no need to merge'
    exit 0;
fi

export GIT_COMMITTER_EMAIL='jreybert@gmail.com'
export GIT_COMMITTER_NAME='Jerome Reybert'

eval "$(ssh-agent -s)" #start the ssh agent
chmod 600 .travis/deploy_key.pem # this key should have push access
ssh-add .travis/deploy_key.pem

git fetch git@github.com:jreybert/vimagit.git master:master
git checkout master
git merge "$TRAVIS_COMMIT"
git push git@github.com:jreybert/vimagit.git master
