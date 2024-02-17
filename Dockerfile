# Connect
FROM amazon/aws-lambda-nodejs:18 AS connect
# 指定了基础镜像为 amazon/aws-lambda-nodejs:18，
# 这是 AWS 官方提供的包含 Node.js 18 运行时的 Lambda 基础镜像。
# AS connect代表当前的method

ARG FUNCTION_DIR="/var/task"
# 是 AWS Lambda 在执行时，函数代码存放的默认目录。

COPY package.json .

RUN npm install && npm install typescript -g

COPY . .

RUN tsc

RUN mkdir -p ${FUNCTION_DIR}

CMD ["build/connect.handler"]