# xml-to-json-lambda/tests/test_handler.py
import pytest
import json
from unittest.mock import MagicMock
from handler import convert_xml_to_json


# Mock event structure for a Lambda Function URL POST request
def create_mock_event(body, content_type="application/xml", method="POST"):
    return {
        "version": "2.0",
        "routeKey": "$default",
        "rawPath": "/",
        "rawQueryString": "",
        "headers": {
            "content-type": content_type,
            "user-agent": "PostmanRuntime/7.28.4",
            "accept": "*/*",
            "cache-control": "no-cache",
            "postman-token": "...",
            "host": "...",
            "accept-encoding": "gzip, deflate, br",
            "connection": "keep-alive",
            "content-length": str(len(body)),
        },
        "requestContext": {
            "accountId": "...",
            "apiId": "...",
            "domainName": "...",
            "domainPrefix": "...",
            "http": {
                "method": method,
                "path": "/",
                "protocol": "HTTP/1.1",
                "sourceIp": "...",
                "userAgent": "PostmanRuntime/7.28.4",
            },
            "requestId": "...",
            "routeKey": "$default",
            "stage": "$default",
            "time": "...",
            "timeEpoch": 1678886400000,
        },
        "body": body,
        "isBase64Encoded": False,
    }


# Mock context object (not heavily used in this function, but good practice)
mock_context = MagicMock()


def test_valid_xml_conversion():
    xml_input = """
    <root>
        <data id="123">
            <item>Value1</item>
            <item attr="test">Value2</item>
        </data>
        <info>Some Info</info>
    </root>
    """
    expected_json_output = {
        "root": {
            "data": {
                "@id": "123",
                "item": ["Value1", {"@attr": "test", "#text": "Value2"}],
            },
            "info": "Some Info",
        }
    }

    event = create_mock_event(xml_input)
    response = convert_xml_to_json(event, mock_context)

    assert response["statusCode"] == 200
    assert response["headers"]["Content-Type"] == "application/json"
    assert json.loads(response["body"]) == expected_json_output


def test_invalid_xml_input():
    invalid_xml = "<root><data>Missing closing tag"
    event = create_mock_event(invalid_xml)
    response = convert_xml_to_json(event, mock_context)

    assert response["statusCode"] == 400
    assert response["headers"]["Content-Type"] == "application/json"
    assert "error" in json.loads(response["body"])
    assert "Invalid XML format" in json.loads(response["body"])["error"]


def test_empty_xml_body():
    empty_body = ""
    event = create_mock_event(empty_body)
    response = convert_xml_to_json(event, mock_context)

    assert response["statusCode"] == 400
    assert "error" in json.loads(response["body"])
    assert "No XML data provided" in json.loads(response["body"])["error"]


def test_non_xml_content_type():
    json_data = '{"key": "value"}'
    event = create_mock_event(json_data, content_type="application/json")
    response = convert_xml_to_json(event, mock_context)

    assert response["statusCode"] == 415
    assert "error" in json.loads(response["body"])
    assert "Unsupported Media Type" in json.loads(response["body"])["error"]


def test_get_method_unsupported():
    event = create_mock_event("<xml/>", method="GET")
    response = convert_xml_to_json(event, mock_context)

    assert response["statusCode"] == 405
    assert "error" in json.loads(response["body"])
    assert "Method Not Allowed" in json.loads(response["body"])["error"]


def test_xml_with_cdata():
    xml_input = """
    <root>
        <script><![CDATA[console.log("<test>");]]></script>
    </root>
    """
    expected_json_output = {"root": {"script": 'console.log("<test>");'}}
    event = create_mock_event(xml_input)
    response = convert_xml_to_json(event, mock_context)

    assert response["statusCode"] == 200
    assert json.loads(response["body"]) == expected_json_output
