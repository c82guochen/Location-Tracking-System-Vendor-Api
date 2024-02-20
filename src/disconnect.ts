import { APIGatewayEvent, APIGatewayProxyResult } from 'aws-lambda';
import { dynamoDbRemoveConnection } from './aws';

// 和connect中lambda函数名一样没关系，在执行docker命令的时候标清楚不一样就行了
export const handler = async (
  event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
  const tableName =
    process.env.AWS_TABLE_NAME ?? 'websocket-connections';
  const connectionId = event.requestContext.connectionId ?? '';
  console.log('attempt user:', connectionId);

  const res = await dynamoDbRemoveConnection(tableName, connectionId);
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

  console.log('disconnected');

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: `User ${connectionId} disconnected!`,
    }),
  };
};