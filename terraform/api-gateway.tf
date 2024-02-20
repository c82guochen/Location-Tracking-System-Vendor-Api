# # WEBSOCKET API GATEWAY
# resource "aws_apigatewayv2_api" "websocket_cg" {
#     name = "${var.app_name}-websocket"
#     protocol_type = "WEBSOCKET"
#     route_selection_expression = "$request.body.action"
#     // 这里没有allow method什么的是因为web socket没有method
# }

# # INTEGRATIONS
# # 有三个integrations：connect，disconenct和sendvendors
# resource "aws_apigatewayv2_integration" "connect" {
#   api_id = aws_apigatewayv2_api.websocket_cg.id
#   integration_uri = aws_lambda_function.connect.invoke_arn
#   integration_type = "AWS_PROXY"
#   integration_method = "POST"
# }
# # 这段 Terraform 配置定义了一个 AWS API Gateway V2 的集成，专门用于 WebSocket API。
# # 这个集成是连接 API Gateway 和后端 AWS Lambda 函数的桥梁。
# # 在这个例子中，它配置了当 WebSocket 客户端尝试建立连接时，如何触发一个名为 connect 的 Lambda 函数。
# # api_id指定了要集成的 API Gateway API 的 ID。这里使用 aws_apigatewayv2_api.websocket_cg.id 表示这个集成将关联到由 Terraform 管理的名为 websocket_cg 的 API Gateway V2 API 实例。
# # integration_uri: 指定了集成的目标 URI，这里是 Lambda 函数的 invoke_arn。这意味着当 API Gateway 接收到与此集成相关的请求时，它将触发 connect Lambda 函数。invoke_arn 是 AWS Lambda 函数的 Amazon Resource Name（ARN），用于唯一标识这个函数。
# # integration_type: 指定了集成类型。在这个例子中，使用了 "AWS_PROXY"，表示这是一个代理集成。代理集成允许 API Gateway 将客户端的请求直接转发给后端（这里是 Lambda 函数），并将后端的响应直接返回给客户端。这种集成方式简化了请求和响应的格式，使得后端服务能够接收到完整的请求信息，并控制返回给客户端的响应。
# # integration_method: 指定了请求使用的 HTTP 方法，这里是 "POST"。尽管 WebSocket 本身并不直接使用 HTTP 方法，这个设置是为了 API Gateway 与后端服务（Lambda 函数）之间的交互。Lambda 函数将接收到一个模拟的 HTTP POST 请求。

# # 通过配置这个 API Gateway V2 集成，你可以确保当 WebSocket 客户端尝试建立连接时（例如，客户端发送 WebSocket 连接请求到 API Gateway），API Gateway 将请求转发给指定的 Lambda 函数处理。

# resource "aws_apigatewayv2_integration" "disconnect" {
#   api_id = aws_apigatewayv2_api.websocket_cg.id
#   integration_uri = aws_lambda_function.disconnect.invoke_arn
#   integration_type = "AWS_PROXY"
#   integration_method = "POST"
# }

# resource "aws_apigatewayv2_integration" "sendvendor" {
#   api_id = aws_apigatewayv2_api.websocket_cg.id
#   integration_uri = aws_lambda_function.sendvendor.invoke_arn
#   integration_type = "AWS_PROXY"
#   integration_method = "POST"
# }

# # ROUTES
# # 也有对应的三条
# resource "aws_apigatewayv2_route" "_connect" {
#     # route的名称前要加下划线
#     api_id = aws_apigatewayv2_api.websocket_cg.id
#     route_key = "$connect"
#     # 定义了触发此路由的关键字。对于 WebSocket API，AWS 使用特殊的路由键来表示连接生命周期中的不同事件。在这个例子中，"$connect" 是一个保留的路由键，用于处理客户端尝试建立连接的请求。
#     target = "integrations/${aws_apigatewayv2_integration.connect.id}"
#     # 指定了处理请求的目标。在这里，目标设置为 "integrations/${aws_apigatewayv2_integration.connect.id}"，这表示请求将被路由到一个集成。具体来说，它引用了之前定义的 aws_apigatewayv2_integration.connect 集成的 ID。这个集成配置了当 $connect 路由被触发时，应该调用的后端服务，这里是一个 Lambda 函数。
# }
# # $connect、$disconnect 和 $default 是特殊的路由键（route key），它们分别用于处理连接、断开连接和默认的消息路由。这些特殊的路由键以美元符号（$）开头，以区分于开发者自定义的路由键。
# # $connect - 当客户端尝试建立与 WebSocket API 的连接时，API Gateway 会触发与 $connect 路由键关联的集成。这允许开发者在客户端成功连接之前执行自定义逻辑，例如身份验证、记录或初始化会话。

# resource "aws_apigatewayv2_route" "_disconnect" {
#     api_id = aws_apigatewayv2_api.websocket_cg.id
#     route_key = "$disconnect"
#     target = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
# }
# # $disconnect - 当客户端断开与 WebSocket API 的连接时，会触发与 $disconnect 路由键关联的集成。这为清理资源、记录断开连接的事件或更新应用状态提供了机会。

# resource "aws_apigatewayv2_route" "_sendvendor" {
#     api_id = aws_apigatewayv2_api.websocket_cg.id
#     route_key = "sendvendor"
#     target = "integrations/${aws_apigatewayv2_integration.sendvendor.id}"
# }

# # STAGE
# resource "aws_apigatewayv2_stage" "primary_websocket" {
#     api_id = aws_apigatewayv2_api.websocket_cg.id
#     name = var.api_gateway_stage_name
#     auto_deploy = true
# }
# # 这段 Terraform 配置创建了一个名为 primary_websocket 的 AWS API Gateway V2 阶段资源。
# # 阶段（Stage）是 API 发布的特定快照，它允许你管理和访问 API 的不同版本。这个配置具体包括：
# # name：设置了阶段的名称，通过 var.api_gateway_stage_name 引用，这表示阶段名称是一个可配置的变量，允许在 Terraform 配置外部定义。
# # auto_deploy：设置为 true，意味着当你对这个 API 进行更改时，更改会自动部署到这个阶段，无需手动触发部署过程。
# # 通过定义阶段，你可以控制 API 的部署过程，为不同的开发、测试和生产环境提供灵活的管理和访问控制。auto_deploy = true 确保了 API 更新可以快速反映到这个阶段，从而简化了持续集成和持续部署（CI/CD）的流程。

# #HTTP API GATEWAY
# resource "aws_apigatewayv2_api" "http_cg" {
#     name = "${var.app_name}-http"
#     protocol_type = "HTTP"
#     cors_configuration {
#       allow_origins = ["*"]
#       allow_methods = ["POST", "GET", "OPTIONS"]
#       allow_headers = ["content-type"]
#     }
# }

# # INTEGRATIONS
# resource "aws_apigatewayv2_integration" "getvendors" {
#   api_id = aws_apigatewayv2_api.http_cg.id
#   integration_uri = aws_lambda_function.getvendors.invoke_arn
#   integration_type = "AWS_PROXY"
#   integration_method = "POST"
# }

# # ROUTES
# resource "aws_apigatewayv2_route" "_getvendors" {
#     api_id = aws_apigatewayv2_api.http_cg.id
#     route_key = "GET /vendors"
#     target = "integrations/${aws_apigatewayv2_integration.getvendors.id}"
# }
# # 当路由使用 "GET" 方法时，我们是在定义客户端如何请求你的 API。前端对你的 API 发送一个 "GET" 请求到 /vendors 路径。
# # 而集成使用 "POST" 方法，这里指的是 API Gateway 与后端服务（在这个例子中是 AWS Lambda 函数）之间的通信方式。
# # 无论客户端发起的是 "GET"、"POST"、还是其他 HTTP 方法的请求，当这个请求到达 API Gateway 并被路由到指定的集成时，API Gateway 总是使用 "POST" 方法来调用后端的 Lambda 函数。
# # 设计目的：
# # 这样设计的原因是 AWS Lambda 不直接处理 HTTP 请求；它处理的是由 AWS API Gateway 发送过来的事件。这个事件包含了原始 HTTP 请求的所有相关信息（如方法、路径、查询参数等），但这个过程本身是通过 "POST" 请求实现的，因为它是 API Gateway 向 Lambda 传递数据的一种方式。

# # STAGE
# resource "aws_apigatewayv2_stage" "primary_http" {
#     api_id = aws_apigatewayv2_api.http_cg.id
#     name = var.api_gateway_stage_name
#     auto_deploy = true
# }

# WEBSOCKET API GATEWAY
resource "aws_apigatewayv2_api" "websocket_gw" {
    name = "${var.app_name}-websocket"
    protocol_type = "WEBSOCKET"
    route_selection_expression = "$request.body.action"
}

# INTEGRATIONS
resource "aws_apigatewayv2_integration" "connect" {
  api_id = aws_apigatewayv2_api.websocket_gw.id
  integration_uri = aws_lambda_function.connect.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id = aws_apigatewayv2_api.websocket_gw.id
  integration_uri = aws_lambda_function.disconnect.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "sendvendor" {
  api_id = aws_apigatewayv2_api.websocket_gw.id
  integration_uri = aws_lambda_function.sendvendor.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

# ROUTES
resource "aws_apigatewayv2_route" "_connect" {
    api_id = aws_apigatewayv2_api.websocket_gw.id
    route_key = "$connect"
    target = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_route" "_disconnect" {
    api_id = aws_apigatewayv2_api.websocket_gw.id
    route_key = "$disconnect"
    target = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route" "_sendvendor" {
    api_id = aws_apigatewayv2_api.websocket_gw.id
    route_key = "sendvendor"
    target = "integrations/${aws_apigatewayv2_integration.sendvendor.id}"
}

# STAGE
resource "aws_apigatewayv2_stage" "primary_websocket" {
    api_id = aws_apigatewayv2_api.websocket_gw.id
    name = var.api_gateway_stage_name
    auto_deploy = true
}

#HTTP API GATEWAY
resource "aws_apigatewayv2_api" "http_gw" {
    name = "${var.app_name}-http"
    protocol_type = "HTTP"
    cors_configuration {
      allow_origins = ["*"]
      allow_methods = ["POST", "GET", "OPTIONS"]
      allow_headers = ["content-type"]
    }
}

# INTEGRATIONS
resource "aws_apigatewayv2_integration" "getvendors" {
  api_id = aws_apigatewayv2_api.http_gw.id
  integration_uri = aws_lambda_function.getvendors.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

# ROUTES
resource "aws_apigatewayv2_route" "_getvendors" {
    api_id = aws_apigatewayv2_api.http_gw.id
    route_key = "GET /vendors"
    target = "integrations/${aws_apigatewayv2_integration.getvendors.id}"
}

# STAGE
resource "aws_apigatewayv2_stage" "primary_http" {
    api_id = aws_apigatewayv2_api.http_gw.id
    name = var.api_gateway_stage_name
    auto_deploy = true
}