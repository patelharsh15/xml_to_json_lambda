# xml-to-json-lambda/handler.py
import json
import logging
import os
import xmltodict

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())


def convert_xml_to_json(event, context):
    """
    AWS Lambda handler to convert XML payload to JSON.
    Invoked via Lambda Function URL.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    # 1. Input Validation: Check HTTP Method
    if event["requestContext"]["http"]["method"] != "POST":
        logger.warning(
            f"Unsupported HTTP method: {event['requestContext']['http']['method']}"
        )
        return {
            "statusCode": 405,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",  # Required for CORS if called from a browser
                "Access-Control-Allow-Methods": "POST",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps(
                {"error": "Method Not Allowed. Only POST is supported."}
            ),
        }

    # 2. Input Validation: Check Content-Type header
    content_type = event["headers"].get("content-type", "").lower()
    if not content_type.startswith("application/xml"):
        logger.warning(f"Unsupported Content-Type: {content_type}")
        return {
            "statusCode": 415,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps(
                {"error": "Unsupported Media Type. Please send application/xml."}
            ),
        }

    # 3. Extract XML Payload
    # Function URL event body is a string, and it's NOT base64 encoded for text types
    xml_data = event.get("body", "")

    if not xml_data:
        logger.error("No XML data found in request body.")
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({"error": "No XML data provided in the request body."}),
        }

    # 4. Perform XML to JSON Conversion
    json_output = {}
    try:
        # xmltodict.parse converts XML string to Python dictionary
        parsed_dict = xmltodict.parse(xml_data)
        # Convert the Python dictionary to a JSON string
        json_output = json.dumps(parsed_dict, indent=2)  # indent for readability
        logger.info("XML successfully converted to JSON.")
    except Exception as e:
        logger.error(f"Error converting XML to JSON: {e}", exc_info=True)
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps(
                {"error": f"Invalid XML format or conversion error: {str(e)}"}
            ),
        }

    # 5. Return JSON Response
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",  # Required for CORS if called from a browser
            "Access-Control-Allow-Methods": "POST",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json_output,
    }
