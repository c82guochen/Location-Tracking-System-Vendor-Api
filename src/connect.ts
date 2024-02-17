// AWS Lambda 函数，它通过 AWS API Gateway WebSocket API 触发。
// 目的是处理 WebSocket 连接请求，将连接ID保存到 DynamoDB 中，并返回相应的响应消息。
import { APIGatewayEvent, APIGatewayProxyResult } from 'aws-lambda';
// APIGatewayEvent 和 APIGatewayProxyResult 是 AWS Lambda 与 API Gateway 集成时用于类型定义的 TypeScript 接口。
import { dynamoDbAddConnection } from './aws';

// 函数名为handler（注意lambda函数结构：接受事件对象，返回相应的Promise）
export const handler = async (
  event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
  const tableName =
    process.env.AWS_TABLE_NAME ?? 'websocket-connections';

  // lambda func event
    const connectionId = event.requestContext.connectionId ?? '';
    // 从事件对象中获取 WebSocket 连接ID。这个ID是 API Gateway 管理 WebSocket 连接时自动生成的唯一标识符。

  console.log('attempt user:', connectionId);

  const res = await dynamoDbAddConnection(tableName, connectionId);

  if (res instanceof Error) {
    console.log('error', res.message);
    return {
      statusCode: 500,
      headers: {
        'content-type': 'text/plain; charset=utf-8',
      },
      body: res.message,
    };
  }

  console.log('connected');

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `User ${connectionId} connected!`,
    }),
    };
    // 连接ID成功保存到 DynamoDB，函数将返回一个状态码为 200 的 HTTP 响应，响应体是一个包含成功消息的 JSON 字符串。
};