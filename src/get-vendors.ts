import { marshall, unmarshall } from '@aws-sdk/util-dynamodb';
import { APIGatewayEvent, APIGatewayProxyResult } from 'aws-lambda';
import { AWSError, DynamoDB } from 'aws-sdk';
import { PromiseResult } from 'aws-sdk/lib/request';
import { dynamodbScanTable } from './aws';

export const handler = async (
  event: APIGatewayEvent
): Promise<APIGatewayProxyResult> => {
  // 该函数传递整个表的内容
  const tableName = process.env.AWS_VENDOR_TABLE_NAME ?? 'vendors';

  const pageLimit = event.queryStringParameters?.limit;

  const lastEvaluatedKey = event.queryStringParameters
    ?.lastEvaluatedKey
    // 尝试从 Lambda 函数接收到的事件对象中获取 queryStringParameters 属性下的 lastEvaluatedKey。这里使用了可选链（?.）操作符，意味着如果 queryStringParameters 不存在，表达式的值将直接为 undefined，而不会尝试访问 lastEvaluatedKey 属性，从而避免抛出错误。
    ? marshall(
      JSON.parse(event.queryStringParameters?.lastEvaluatedKey)
      // JSON.parse(...): 如果 lastEvaluatedKey 存在，代码会将其值（预期是一个 JSON 字符串）解析为 JavaScript 对象。
      )
    : undefined;
    // : undefined: 如果 lastEvaluatedKey 不存在，变量 lastEvaluatedKey 被设置为 undefined。

  let scanTableGen: AsyncGenerator<
    PromiseResult<DynamoDB.ScanOutput, AWSError>,
    void,
    unknown
    >;
    // 这行代码定义了一个变量 scanTableGen，它的类型是 AsyncGenerator。AsyncGenerator 是 TypeScript 中的一个泛型类型，用于表示异步生成器函数的返回类型。
    // PromiseResult<DynamoDB.ScanOutput, AWSError>: 这表示异步生成器每次 yield 的值类型。这里使用了 AWS SDK 的类型，DynamoDB.ScanOutput 表示 DynamoDB 扫描操作的输出结果，而 AWSError 表示可能的错误对象。
    // void: 这是生成器完成后的返回类型。在这个上下文中，生成器没有明确的返回值，所以使用 void。
    // unknown：这是传递给生成器 next() 方法的参数的类型。在这个上下文中，unknown 类型意味着我们不预期向 next() 方法传递任何特定类型的值。使用 unknown 类型提供了最大的灵活性，因为它是 TypeScript 类型系统中所有类型的顶级类型。
  try {
    scanTableGen = await dynamodbScanTable(
      tableName,
      Number(pageLimit),
      lastEvaluatedKey
    );
  } catch (e) {
    return {
      statusCode: 500,
      headers: {
        'content-type': 'text/plain; charset=utf-8',
        // 告诉客户端，响应体的内容类型是纯文本，并且字符集是 UTF-8。这意味着返回的错误消息或说明将是简单的文本格式。
        'Access-Control-Allow-Headers': 'Content-Type',
        // 这是跨源资源共享（CORS）的一部分，指示允许跨域请求时，请求头可以包含 Content-Type。
        'Access-Control-Allow-Origin': '*',
        // 这也是CORS策略的一部分，* 表示接受来自任何来源的请求。这对于公开的API或那些需要被不同域上的前端应用访问的服务特别有用。
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
        // 这指明了允许跨域请求的HTTP方法，包括OPTIONS、POST和GET。这是告诉浏览器这些方法对于来自任何源的请求是被允许的。
      },

      body:
        e instanceof Error
          ? e.message
          : 'dynamoDbScanTable returned an unknown error',
    };
  }

  const iterator = await scanTableGen?.next();

  if (iterator.value) {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
      },
      body: JSON.stringify({
        Items: iterator.value.Items,
        count: iterator.value.Count,
        lastEvaluatedKey: iterator.value.LastEvaluatedKey
          ? //   ? unmarshall(iterator.value.LastEvaluatedKey)
          // 所以unmarshall为什么不能再docker上使用？？？？？？？？？？？ ？？？？
            iterator.value.LastEvaluatedKey
          : null,
      }),
    };
  }

  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
    },
    body: JSON.stringify({
      Items: [],
      count: 0,
      lastEvaluatedKey: null,
    }),
  };
};