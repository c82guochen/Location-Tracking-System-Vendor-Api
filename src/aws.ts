import { marshall, unmarshall } from '@aws-sdk/util-dynamodb';
import { AttributeValue } from 'aws-sdk/clients/dynamodb';
import AWS from 'aws-sdk';
import dotenv from 'dotenv';

dotenv.config();

AWS.config.update({ region: process.env.AWS_REGION });

const { DynamoDB, SQS } = AWS;

const dynamodb = new DynamoDB();
const sqs = new SQS();

// describe a table
export const dynamodbDescribeTable = async (tableName: string) => {
  try {
    const table = await dynamodb
      .describeTable({
        TableName: tableName,
      })
      .promise();
    console.log('Table retrieved', table);
    return table;
  } catch (e) {
    if (e instanceof Error) {
      throw e;
    }
    throw new Error(
      `dynamodbDescribeTable error object unknown type`
    );
  }
};

// scan a table
export const dynamodbScanTable = async function* (
  tableName: string,
  limit: number = 25,
  lastEvaluatedKey?: AWS.DynamoDB.Key
) {
  while (true) {
    const params: AWS.DynamoDB.ScanInput = {
      TableName: tableName,
      Limit: limit,
    };

    if (lastEvaluatedKey) {
      params.ExclusiveStartKey = lastEvaluatedKey;
    }

    try {
      const result = await dynamodb.scan(params).promise();
      if (!result.Count) {
        return;
      }

      lastEvaluatedKey = (result as AWS.DynamoDB.ScanOutput)
        .LastEvaluatedKey;
        result.Items = result.Items?.map((item) => item);
      yield result;
    } catch (e) {
      if (e instanceof Error) {
        throw e;
      }
      throw new Error('dynamodbScanTable unexpected error');
    }
  }
};

// scan all results
export const getAllScanResults = async <T>(
  tableName: string,
  limit: number = 25
) => {
  try {
    await dynamodbDescribeTable(tableName);

    const scanTableGen = await dynamodbScanTable(tableName, limit);

    const results: T[] = [];
    let isDone = false;

    while (!isDone) {
      const iterator = await scanTableGen.next();

      if (!iterator) {
        throw new Error('No iterator returned');
      }

      if (iterator.done || !iterator.value.LastEvaluatedKey) {
        isDone = true;
      }

      if (iterator.value) {
        iterator.value.Items!.forEach((result: any) =>
          results.push(result)
        );
      }
    }

    return results;
  } catch (e) {
    if (e instanceof Error) {
      throw e;
    }

    throw new Error(`getAllScanResults unexpected error`);
  }
};

// Add a connection
export const dynamoDbAddConnection = async (
  tableName: string,
  connectionId: string
) => {
  try {
    const params: AWS.DynamoDB.PutItemInput = {
      TableName: tableName,
      Item: marshall({ connectionId }),
    };

    const res = await dynamodb.putItem(params).promise();

    return res;
  } catch (e) {
    if (e instanceof Error) {
      return e;
    }
    return new Error(
      'dynamoDbAddConnection error object unknown type'
    );
  }
};

// const execAddConnection = async () => {
//   const res = await dynamoDbAddConnection(
//     'websocket-connections',
//     '123'
//   );
//   console.log(res);
// };

// execAddConnection();

// Remove a connection
export const dynamoDbRemoveConnection = async (
  tableName: string,
  connectionId: string
) => {
  try {
    const params: AWS.DynamoDB.DeleteItemInput = {
      TableName: tableName,
      Key: {
        connectionId: marshall(connectionId),
      },
    };

    const res = await dynamodb.deleteItem(params).promise();

    return res;
  } catch (e) {
    if (e instanceof Error) {
      return e;
    }
    return new Error(
      'dynamoDbRemoveConnection error object unkown type'
    );
  }
};

// const execRemoveConnection = async () => {
//   const res = await dynamoDbRemoveConnection(
//     'websocket-connections',
//     '123'
//   );
//   console.log(res);
// };

// execRemoveConnection();

export const sqsDeleteMessage = async (
    queueUrl: string,
    receiptHandle: string
  ) => {
    try {
      const params: AWS.SQS.DeleteMessageRequest = {
        ReceiptHandle: receiptHandle,
        QueueUrl: queueUrl,
      };
  
      const res = await sqs.deleteMessage(params).promise();
      console.log('Message deleted!');
      return res;
    } catch (e) {
      if (e instanceof Error) {
        return e;
      }
  
      return new Error(`sqsDeleteMessage error object unknown type`);
    }
  };
  
//   const execSqsDeleteMessage = async () => {
//     const receiptHandle =
//       'AQEBKnzjRVW5/37bFxoYetkf9Tr89s+Lfw/nj/IexuKqdjfqkQ66M3SC2mjT04FfZfkZFw/dMBCOg2l+ARatg+KKSPK+00ji0CxJ6Gwc/K2vp98w4dulehhp/iDyhxXCW/y/SLwYmn8r9+XKcXRKiJ5xReHx9sjVCKaN+Jjis45SuIzDADZEO4w8EaVA+tDCnstv+jj0+n63vmAKzTyjPhY6YLeJ33jKYpQ2HsL6bu1leUG+P/3D0XghTcVgvBW5wEhDlzkWQEfjqfFGMuurCFrzFK1L2FekGdF6dVRgcVxhgzOjiMBEf4EhsUHj09YwGMFoyLnH/pIzuUr7+j1H9/uk6mJ5wtkuM/lWuc35CWncB32+/UwNXPPgfPbggf9QLq7y30NubnLrrm4gfEo1QfQJxw==';
//     const res = await sqsDeleteMessage(
//       'https://sqs.us-east-1.amazonaws.com/656203730697/vendor-twitter-queue',
//       receiptHandle
//     );
//     console.log(res);
//   };
  
//   execSqsDeleteMessage();

// Broadcast Message
// broadcast 所需的四个参数
interface BroadcastMessageWebsocketProps {
  apiGateway: AWS.ApiGatewayManagementApi; //aws提供的固定参数
  connections: any[];
  message: string;
  tableName: string;
}

export const broadcastMessageWebsocket = async (
  props: BroadcastMessageWebsocketProps
) => {
  const { apiGateway, connections, message, tableName } = props;
  const sendVendorsCall = connections?.map(async (connection) => {
    const { connectionId } = connection;
    try {
      await apiGateway
        .postToConnection({
          ConnectionId: connectionId,
          Data: message,
        })
        .promise();
    } catch (e) {
      if ((e as any).statusCode === 410) {
        // stale connection
        console.log(`delete stale connection: ${connectionId}`);
        // 如果该connection Id不活跃的话就直接删掉
        const removeConnRes = await dynamoDbRemoveConnection(
          tableName,
          connectionId
        );
        if (removeConnRes instanceof Error) {
          return e;
        }
      } else {
        return e;
      }
    }
  });

  try {
    // 关于peomise的三种状态：.then{} - result/success情况
    //                      .catch{} - reject情况
    //                       pending状态，不可见
    // Promise.all()是由promise object形成的array，也有三个状态
    // 其中所有promise的状态都是result的时候它状态为result
    // 只要有一个promise的状态是reject，那整个都是reject
    const res = await Promise.all(sendVendorsCall);
    // 意味着所有的web socket都被connect到了，任意一个失败了broadcast就失败了
    // tips:存在Promise.race和Promise.all完全相反：状态为result if one of the promises is result
    return res;
  } catch (e) {
    if (e instanceof Error) {
      return e;
    }
    return new Error(
      `broadcastMessageWebsocket error object unknown type`
    );
  }
};
