# Connect
resource "aws_lambda_function" "connect" {
  # 注意：泽丽配置的是名为connect的docker image
  function_name = "${var.app_name}-connect"
  role = aws_iam_role.lambda_main.arn
  # 这里的url是指在docker存到ecr中之后的image url（image_tag是被build出来的）
  image_uri = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/connect:${var.image_tag}"
  package_type = "Image"
  timeout = 30
  environment {
    variables = {
        AWS_TABLE_NAME = "${var.websocket_table_name}"
    }
  }
}

# 这里是关于resources的permission  
resource "aws_lambda_permission" "connect_permission" {
    # 有一些内容是默认的
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.connect.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_cg.execution_arn}/*/*"
}

# Disconnect
resource "aws_lambda_function" "disconnect" {
  function_name = "${var.app_name}-disconnect"
  role = aws_iam_role.lambda_main.arn
  image_uri = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/disconnect:${var.image_tag}"
  package_type = "Image"
  timeout = 30
  environment {
    variables = {
        AWS_TABLE_NAME = "${var.websocket_table_name}"
    }
  }
}

resource "aws_lambda_permission" "disconnect_permission" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.disconnect.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.websocket_cg.execution_arn}/*/*"
}

# sendvendor
resource "aws_lambda_function" "sendvendor" {
  function_name = "${var.app_name}-sendvendor"
  role = aws_iam_role.lambda_main.arn
  image_uri = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/sendvendor:${var.image_tag}"
  package_type = "Image"
  timeout = 30
  environment {
    variables = {
        AWS_TABLE_NAME = "${var.websocket_table_name}"
        AWS_SQS_URL = "https://sqs.us-east-1.amazonaws.com/656203730697/vendor-twitter-queue"
        # 因为需要在web socket里broadcast，所以需要web socket url
        AWS_WEBSOCKET_URL = "${aws_apigatewayv2_api.websocket_cg.api_endpoint}/${var.api_gateway_stage_name}"
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
    # trigger的对象
    event_source_arn = "arn:aws:sqs:${var.aws_region}:${local.account_id}:${var.sqs_queue_name}"
    function_name = aws_lambda_function.sendvendor.arn
}

resource "aws_lambda_permission" "sendvendor_permission" {
    statement_id = "AllowExecutionFromSQS"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.sendvendor.function_name
    principal = "sqs.amazonaws.com"
    source_arn = "arn:aws:sqs:${var.aws_region}:${local.account_id}:${var.sqs_queue_name}"
}

# getvendors
resource "aws_lambda_function" "getvendors" {
  function_name = "${var.app_name}-getvendors"
  role = aws_iam_role.lambda_main.arn
  image_uri = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/getvendors:${var.image_tag}"
  package_type = "Image"
  timeout = 30
  environment {
    variables = {
        AWS_VENDOR_TABLE_NAME = "${var.vendor_table_name}"
    }
  }
}

resource "aws_lambda_permission" "getvendors_permission" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.getvendors.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.http_cg.execution_arn}/*/*"
}