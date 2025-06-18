# xml_to_json/handler.py
import json
import logging
import os
from xml.parsers.expat import ExpatError  # Specific exception for malformed XML
import xmltodict

# --- Constants ---
# Centralize headers to avoid repetition and make them easy to update.
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST",
    "Access-Control-Allow-Headers": "Content-Type",
}

# --- Configuration ---
# Configure logging once at the top level.
logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())


# --- Helper Function ---
def create_response(status_code: int, body: dict or str) -> dict:
    """
    Creates a standard Lambda Function URL response object.

    Args:
        status_code: The HTTP status code for the response.
        body: The response body, as a dictionary (will be converted to JSON) or a string.

    Returns:
        A dictionary formatted for an AWS Lambda Function URL response.
    """
    # If the body is a dictionary, convert it to a JSON string.
    # Otherwise, assume it's already a formatted string (like our successful XML->JSON output).
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
    AWS Lambda handler to convert XML payload to JSON, invoked via Lambda Function URL.
    """
    try:
        logger.info(
            "Received event"
        )  # Avoid logging the full event body in production for PII reasons

        # 1. Input Validation (Guard Clauses)
        if event["requestContext"]["http"]["method"] != "POST":
            logger.warning("Unsupported HTTP method received.")
            return create_response(
                405, {"error": "Method Not Allowed. Only POST is supported."}
            )

        content_type = event.get("headers", {}).get("content-type", "").lower()
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
        json_output = json.dumps(parsed_dict, indent=2)  # indent for readability
        logger.info("Successfully converted XML to JSON.")

        # 3. Return Success Response
        return create_response(200, json_output)

    # 4. Specific and Generic Exception Handling
    except (ExpatError, xmltodict.ParsingInterrupted) as e:
        error_msg = f"Invalid XML format: {e}"
        logger.error(error_msg)
        return create_response(400, {"error": "Invalid XML format provided."})
    except Exception as e:
        # Catch any other unexpected errors
        logger.error(f"An unexpected error occurred: {e}", exc_info=True)
        return create_response(500, {"error": "An internal server error occurred."})
