##TODO

* figure out how to limit 777 as much as possible


### CLI TODO 
consider if deploy.yaml should be updated from config.exs, values in 2 places sucks
prompt to complete INCOMPLETE, perhaps interactive setup
ensure web server is started


### CF deploy TODO

get stack update working
  
current deploy
  update s3 url in deploy.yaml
  update role in yaml
  run CF deploy
  find change set and execute it in the web console
  run lambda function

cleanup
  need CF update and delete stack
  need to get rid of log groups in cloud watch

working CF: 

aws s3 cp lambda_deploy.zip s3://schoch-lambda-deploy
aws cloudformation deploy --template-file deploy/deploy.yaml --stack-name exlam-test-app --profile exlam-deployer1

document lambda magic cloudformation thingy

send off on it's way and run some tests...
