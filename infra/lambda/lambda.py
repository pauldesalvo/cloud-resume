
import boto3

client = boto3.client('dynamodb')

def lambda_handler(event, context):
    """
    # Get result from dynamodb
    data = client.get_item(
        TableName="PageVisits",
        Key = {
            "PageVisits": {"S": "view-count"}
        }
    )
    """    
    #prevViewCount = data['Item']['Quantity']['N']
    
    response = client.update_item(
        TableName="PageVisits",
        Key = {
            "PageVisits": {
                "S": "view-count"
                }
        },
        UpdateExpression = "ADD Quantity :inc",
        ExpressionAttributeValues = {
            ":inc" : {
                "N": "1"
                }
            },
        ReturnValues = "UPDATED_NEW"
        )
    
    value = response["Attributes"]["Quantity"]["N"]
    
    return {      
            "statusCode": 200,
            "body": value,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow_origin": "*"
            }
        }