import logging
import os
import json
import boto3
import datetime

LOGGER = logging.getLogger()
LOGGER.setLevel(os.environ.get("LOGLEVEL", "INFO").upper())

def lambda_handler(event, context):
    LOGGER.debug("Got event %s", json.dumps(event))
    action = event.get("action", "open")

    sns_topic = os.environ.get("SNS_TOPIC")
    if not sns_topic:
        raise Exception("No SNS Topic")

    close_msg = os.environ.get("CLOSE_MSG")
    if not close_msg:
        raise Exception("No Close Message")

    if action == "open":
        # Send open text

        open_msg = os.environ.get("OPEN_MSG")
        if not open_msg:
            raise Exception("No Close Message")
        
        sns = boto3.client("sns")
        sns.publish(
            TopicArn=sns_topic,
            Message=open_msg
        )

        schedule_name = os.environ.get("SCHEDULE_NAME")
        if not schedule_name:
            raise Exception("No schedule name")

        schedule_role_arn = os.environ.get("SCHEDULE_ROLE_ARN")
        if not schedule_role_arn:
            raise Exception("No schedule role arn")

        close_time = int(os.environ.get("CLOSE_TIME", "120"))

        # Schedule time until closed
        scheduler = boto3.client("scheduler")

        schedule_at_time = datetime.datetime.now(datetime.UTC) + datetime.timedelta(seconds=close_time)
        schedule_at_time = schedule_at_time.isoformat(timespec="seconds")

        LOGGER.debug("Scheduling close at %s UTC", schedule_at_time)

        # Reset schedule time
        scheduler.update_schedule(
            FlexibleTimeWindow={
                "Mode": "OFF"
            },
            Name=schedule_name,
            ScheduleExpression=f"at({schedule_at_time})",
            ScheduleExpressionTimezone="UTC",
            Target={
                "Arn": sns_topic,
                "Input": close_msg,
                "RoleArn": schedule_role_arn
            }
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/plain; charset=utf-8"
            },
            "body": "Opening gates"
        }
    elif action == "close":
        # Send close text

        sns = boto3.client("sns")
        sns.publish(
            TopicArn=sns_topic,
            Message=close_msg
        )

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/plain; charset=utf-8"
            },
            "body": "Closing gates"
        }
    else:
        raise Exception(f"Unknown action '{action}'")
    