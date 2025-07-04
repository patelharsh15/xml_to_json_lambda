# xml_to_json/handler.py
import json
import logging
import os
from xml.parsers.expat import ExpatError
import xmltodict

# --- Constants ---
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",  # Be more specific in production!
    "Access-Control-Allow-Methods": "POST, OPTIONS",  # OPTIONS is needed for browser pre-flight requests
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
}

# --- Configuration ---
logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())


# --- Helper Function ---
def create_response(status_code: int, body: dict or str) -> dict:
    """
    Creates a standard API Gateway proxy response object.
    """
    if isinstance(body, dict):
        body = json.dumps(body)

    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": body,
    }


# --- Main Handler ---
def convert_xml_to_json(event: dict, context: object) -> dict:
    """
    AWS Lambda handler to convert XML to JSON, invoked via API Gateway.
    """
    try:
        # For API Gateway, you might get a pre-flight OPTIONS request from browsers
        # This handles the CORS pre-flight check gracefully.
        if event.get("httpMethod") == "OPTIONS":
            return create_response(204, "")

        logger.info("Received event")

        # 1. Input Validation (Guard Clauses)
        # CHANGED: Access 'httpMethod' directly from the event root.
        if event.get("httpMethod") != "POST":
            logger.warning("Unsupported HTTP method received.")
            return create_response(
                405, {"error": "Method Not Allowed. Only POST is supported."}
            )

        # CHANGED: Headers are top-level and keys can be cased differently.
        # It's safer to normalize them to lowercase.
        headers = {k.lower(): v for k, v in event.get("headers", {}).items()}
        content_type = headers.get("content-type", "").lower()

        if "application/xml" not in content_type and "text/xml" not in content_type:
            logger.warning(f"Unsupported Content-Type: {content_type}")
            return create_response(
                415,
                {
                    "error": "Unsupported Media Type. Please send application/xml or text/xml."
                },
            )

        xml_data = event.get("body")
        if not xml_data:
            logger.error("No XML data found in request body.")
            return create_response(
                400, {"error": "No XML data provided in the request body."}
            )

        # 2. Core Logic: Perform XML to JSON Conversion
        logger.info("Attempting to convert XML to JSON.")
        parsed_dict = xmltodict.parse(xml_data)
        json_output = json.dumps(parsed_dict, indent=2)
        logger.info("Successfully converted XML to JSON.")

        # 3. Return Success Response
        return create_response(200, json_output)

    # 4. Exception Handling (remains the same)
    except (ExpatError, xmltodict.ParsingInterrupted) as e:
        error_msg = f"Invalid XML format: {e}"
        logger.error(error_msg)
        return create_response(400, {"error": "Invalid XML format provided."})
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}", exc_info=True)
        return create_response(500, {"error": "An internal server error occurred."})
