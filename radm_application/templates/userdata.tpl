MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

sudo curl -s https://dev-rafay-controller.s3.us-west-1.amazonaws.com/radm/linux/radm-${controllerVersion} -o radm >> /tmp/rafay_radm_jump_server.log 2>&1

sudo chmod +x radm >> /tmp/rafay_radm_jump_server.log 2>&1

sudo cp radm /usr/bin >> /tmp/rafay_radm_jump_server.log 2>&1

aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID} >> /tmp/rafay_radm_jump_server.log 2>&1

aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY} >> /tmp/rafay_radm_jump_server.log 2>&1
 
aws configure set default.region ${region} >> /tmp/rafay_radm_jump_server.log 2>&1

aws eks update-kubeconfig --name ${cluster_name}  --region ${region} >> /tmp/rafay_radm_jump_server.log 2>&1

sudo radm database --host ${rds_hostname} --kubeconfig ~/.kube/config --port ${rds_port} --root-password '${rds_password}' --root-user ${rds_username} >> /tmp/rafay_radm_jump_server.log 2>&1

aws s3 cp /tmp/rafay_radm_jump_server.log s3://${s3_bucket_name}/rafay_radm_jump_server.log

sleep 2h

instance_id=`ec2-metadata --instance-id | cut -d ":" -f2`

aws ec2 terminate-instances --instance-ids $instance_id --region ${region}

--==MYBOUNDARY==--\

