# xml_to_json/handler.py
import json
import logging
import os
import uuid  # To generate unique IDs
import boto3  # AWS SDK
import base64  # For decoding the request body
from xml.parsers.expat import ExpatError
import xmltodict

# --- Constants ---
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
}

# --- Configuration ---
logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())

# Initialize DynamoDB client outside the handler for performance (connection reuse)
try:
    DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
    dynamodb_resource = boto3.resource("dynamodb")
    table = dynamodb_resource.Table(DYNAMODB_TABLE_NAME)
    logger.info(
        f"Successfully initialized DynamoDB table resource for: {DYNAMODB_TABLE_NAME}"
    )
except KeyError:
    logger.critical("FATAL: DYNAMODB_TABLE_NAME environment variable is not set.")
    table = None  # This will cause the handler to fail gracefully


# --- Helper Function ---
def create_response(status_code: int, body: dict or str) -> dict:
    if isinstance(body, dict):
        body = json.dumps(body, indent=2)  # Add indent for readability
    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": body,
    }


# --- Main Handler ---
def convert_xml_to_json(event: dict, context: object) -> dict:
    """
    Main Lambda handler: receives XML, converts to JSON, stores in DynamoDB, and returns JSON.
    """
    if not table:
        return create_response(
            500, {"error": "Server is misconfigured. Cannot connect to database."}
        )

    try:
        # Handle CORS pre-flight requests from browsers
        if event.get("httpMethod") == "OPTIONS":
            return create_response(204, "")

        logger.info("Received request to convert and store XML.")

        # 1. Input Validation
        if event.get("httpMethod") != "POST":
            return create_response(
                405, {"error": "Method Not Allowed. Only POST is supported."}
            )

        headers = {k.lower(): v for k, v in event.get("headers", {}).items()}
        content_type = headers.get("content-type", "").lower()
        if "application/xml" not in content_type and "text/xml" not in content_type:
            return create_response(
                415,
                {
                    "error": "Unsupported Media Type. Please send application/xml or text/xml."
                },
            )

        xml_data = event.get("body")
        if not xml_data:
            return create_response(
                400, {"error": "No XML data provided in the request body."}
            )

        # 2. Decode Body if necessary
        if event.get("isBase64Encoded", False):
            logger.info("Request body is Base64 encoded. Decoding...")
            try:
                xml_data = base64.b64decode(xml_data).decode("utf-8")
            except Exception as e:
                logger.error(f"Base64 decoding failed: {e}")
                return create_response(
                    400, {"error": "Invalid Base64 encoding in request body."}
                )

        # 3. Core Logic: XML to JSON Conversion
        logger.info("Attempting to convert XML to JSON.")
        parsed_dict = xmltodict.parse(xml_data)
        logger.info("Successfully converted XML to JSON.")

        # 4. Store in DynamoDB
        item_id = str(uuid.uuid4())
        item_to_store = {
            "id": item_id,  # Hash Key (Primary Key)
            "data": parsed_dict,  # The converted JSON data as a map
        }

        logger.info(f"Storing item {item_id} in DynamoDB.")
        table.put_item(Item=item_to_store)
        logger.info("Successfully stored item.")

        # 5. Return Success Response
        success_payload = {
            "message": "Successfully converted XML and stored in DynamoDB.",
            "itemId": item_id,
            "jsonData": parsed_dict,
        }
        return create_response(200, success_payload)

    # 6. Exception Handling
    except (ExpatError, xmltodict.ParsingInterrupted) as e:
        logger.error(f"Invalid XML format: {e}", exc_info=True)
        return create_response(400, {"error": "The provided XML is malformed."})
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}", exc_info=True)
        return create_response(500, {"error": "An internal server error occurred."})
