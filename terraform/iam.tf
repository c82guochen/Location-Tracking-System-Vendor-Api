# 给所有services做身份验证和attach policy

# role => a task execution role
data "aws_iam_policy_document" "assume_role_policy" {
    statement {
      actions = ["sts:AssumeRole"]
      effect="Allow"
      principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }
    }
}
# 定义一个假设角色策略 (assume_role_policy):
# 使用 aws_iam_policy_document 数据源定义一个策略文档，允许服务 lambda.amazonaws.com 执行 sts:AssumeRole 操作。这是创建 IAM 角色的第一步，定义了哪些 AWS 服务或账户可以扮演这个角色。

resource "aws_iam_role" "lambda_main" {
    name = "${var.app_name}-lambda"
    assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
# 使用 aws_iam_role 资源创建一个新的 IAM 角色，名字基于 var.app_name 变量，并且使用上一步定义的假设角色策略。这个角色将被 AWS Lambda 服务使用。

resource "aws_iam_role_policy_attachment" "attach_exec_role" {
    role = aws_iam_role.lambda_main.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# 使用 aws_iam_role_policy_attachment 资源将 AWS 提供的基本执行角色 AWSLambdaBasicExecutionRole 附加到刚创建的 IAM 角色上。这个策略允许 Lambda 函数写日志到 Amazon CloudWatch Logs。

# 对SQS,DynamoDB和API gateway进行policy的设置，给lambda相应的权限
data "aws_iam_policy_document" "lambda_ws" {
    statement {
      effect = "Allow"
      actions = [
        "lambda:CreateFunction",
        "execute-api:ManageConnections",
        # 在使用 Terraform 定义 AWS 资源时，如果你的 Lambda 函数需要与通过 API Gateway 建立的 WebSocket 连接交互，
        # 你需要确保 Lambda 函数的执行角色（aws_iam_role）具有这个权限。这样，Lambda 函数就能够响应连接请求、断开连接请求，并且向连接的客户端发送消息。
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:DescribeTable",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        "arn:aws:sqs:${var.aws_region}:${local.account_id}:${var.sqs_queue_name}",
        "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.websocket_table_name}",
        "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.vendor_table_name}",
        "${aws_apigatewayv2_api.websocket_cg.execution_arn}/*"
      ]
    }
}
# 再次使用 aws_iam_policy_document 数据源定义一个自定义策略文档，这个策略允许 Lambda 函数执行对 DynamoDB、SQS 和 API Gateway 的操作，
# 比如 PutItem、DeleteItem、GetItem、Scan、DescribeTable 对 DynamoDB，以及 ReceiveMessage、DeleteMessage、GetQueueAttributes 对 SQS 等操作。
# 这个策略覆盖了 Lambda 函数访问 DynamoDB 表、SQS 队列和未来将创建的 API Gateway 所需的权限。

# 创建 IAM 策略 (lambda_ws):
# 使用 aws_iam_policy 资源基于上一步定义的策略文档创建一个 IAM 策略。
resource "aws_iam_policy" "lambda_ws" {
    name = "${var.app_name}-lambda-ws"
    policy = data.aws_iam_policy_document.lambda_ws.json
}

# 将自定义策略附加到角色:
# 最后，使用 aws_iam_role_policy_attachment 资源将自定义 IAM 策略附加到之前创建的 IAM 角色上。这样，Lambda 函数就具有执行定义好的一系列操作的权限了。
resource "aws_iam_role_policy_attachment" "lambda_ws" {
    policy_arn = aws_iam_policy.lambda_ws.arn
    role = aws_iam_role.lambda_main.name   
}
