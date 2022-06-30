import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('') #pass db table name as a environement variable or SSM parameter


def lambda_handler(event, context):

    response = table.get_item(Key = {'PageVisits:': 'visitors', } )

    count = response["Item"]["VisitCount"]
    print("Get Response = ", response)
    print( "Count = ", count)

    # increment string version of VisitCount
    new_count = str(int(count)+1)
    response = table.update_item(
        Key={'PageVisits': 'visitors'},
        UpdateExpression='set VisitCount = :val',
        ExpressionAttributeValues={':val': new_count},
        ReturnValues='UPDATED_NEW'
        )

    print("Update Response =  ", response)
    return {
        'statusCode': 200,
        'body': new_count
    }
