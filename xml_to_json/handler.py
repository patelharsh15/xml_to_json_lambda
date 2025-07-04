# xml_to_json/handler.py
import json
import logging
import os
from xml.parsers.expat import ExpatError
import xmltodict
import base64

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


# --- Helper Function ---
def create_response(status_code: int, body: dict or str) -> dict:
    if isinstance(body, dict):
        body = json.dumps(body)
    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": body,
    }


# --- Main Handler ---
def convert_xml_to_json(event: dict, context: object) -> dict:
    try:
        if event.get("httpMethod") == "OPTIONS":
            return create_response(204, "")

        logger.info("Received event")

        # 1. Input Validation (remains mostly the same)
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

        # Check if API Gateway has Base64 encoded the body
        if event.get("isBase64Encoded", False):
            logger.info("Request body is Base64 encoded. Decoding...")
            try:
                # First, decode the Base64 string into bytes
                decoded_bytes = base64.b64decode(xml_data)
                # Then, decode the bytes into a standard UTF-8 string
                xml_data = decoded_bytes.decode("utf-8")
            except (base64.binascii.Error, UnicodeDecodeError) as e:
                logger.error(f"Base64 decoding failed: {e}")
                return create_response(
                    400, {"error": "Invalid Base64 encoding in request body."}
                )
        # ----------------------------------------------------

        # 2. Core Logic: Perform XML to JSON Conversion
        logger.info("Attempting to convert XML to JSON.")
        parsed_dict = xmltodict.parse(
            xml_data
        )  # Now xml_data is guaranteed to be a decoded string
        json_output = json.dumps(parsed_dict, indent=2)
        logger.info("Successfully converted XML to JSON.")

        # 3. Return Success Response
        return create_response(200, json_output)

    # 4. Exception Handling
    except (ExpatError, xmltodict.ParsingInterrupted) as e:
        error_msg = f"Invalid XML format: {e}"
        logger.error(error_msg)
        # Security Note: Be careful about returning raw input in error messages in production.
        return create_response(
            400, {"error": f"Invalid XML format provided. Details: {e}"}
        )
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}", exc_info=True)
        return create_response(500, {"error": "An internal server error occurred."})
