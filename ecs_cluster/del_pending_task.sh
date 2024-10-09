#!/bin/bash

CLUSTER_NAME="ecs-cluster01"

# List and stop all pending tasks
aws ecs list-tasks --cluster $CLUSTER_NAME | \
jq -r '.taskArns[]' | \
while read task_arn; do
    echo "Stopping task: $task_arn"
    aws ecs stop-task --cluster $CLUSTER_NAME --task $task_arn
done

echo "All pending tasks have been stopped."
