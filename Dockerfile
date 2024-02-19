# Connect
FROM amazon/aws-lambda-nodejs:18 AS connect
# 指定了基础镜像为 amazon/aws-lambda-nodejs:18，
# 这是 AWS 官方提供的包含 Node.js 18 运行时的 Lambda 基础镜像。
# AS connect代表当前的method，也是当前的构建阶段

ARG FUNCTION_DIR="/var/task"
# 是 AWS Lambda 在执行时，函数代码存放的默认目录。

COPY package.json .

RUN npm install && npm install typescript -g

COPY . .

RUN tsc

RUN mkdir -p ${FUNCTION_DIR}

CMD ["build/connect.handler"]

# Disconnect
FROM amazon/aws-lambda-nodejs:18 AS disconnect
# docker build：这是 Docker CLI 的一个命令，用于从 Dockerfile 构建新的 Docker 镜像。
# -t 选项用于指定镜像的标签（tag）。在这个例子中，disconnect 是分配给构建出的镜像的名称或标签。标签允许你在之后运行或引用镜像时使用一个易于记忆的名称，而不是默认的镜像 ID。
# --target connect：--target 选项用于指定多阶段构建中的目标构建阶段。
# 在一个包含多个阶段（使用多个 FROM 指令定义）的 Dockerfile 中，你可以使用 --target 来指定构建过程应该停止在哪个阶段。这允许从单个 Dockerfile 中生成不同用途的镜像，例如一个镜像用于构建/编译应用程序，另一个镜像用于运行应用程序。
# 在这个例子中，--target disconnect 指定了 Docker 应该构建到名为 disconnect 的阶段为止。这意味着 Dockerfile 中必须有一个以 AS disconnect 命名的构建阶段。
ARG FUNCTION_DIR="/var/task"

COPY package.json .

RUN npm install && npm install typescript -g

COPY . .

RUN tsc

RUN mkdir -p ${FUNCTION_DIR}

CMD ["build/disconnect.handler"]

# docker run -v $HOME/.aws:/root/.aws:ro -e AWS_ACCESS_KEY_ID -e AWS_CA_BUNDLE -e AWS_CLI_FILE_ENCODING -e AWS_CONFIG_FILE -e AWS_DEFAULT_OUTPUT -e AWS_DEFAULT_REGION -e AWS_PAGER -e AWS_PROFILE -e AWS_ROLE_SESSION_NAME -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_SHARED_CREDENTIALS_FILE -e AWS_STS_REGIONAL_ENDPOINTS -p 9001:8080 disconnect:latest

# Send Vendor
FROM amazon/aws-lambda-nodejs:18 AS sendvendor

ARG FUNCTION_DIR="/var/task"

COPY package.json .

RUN npm install && npm install typescript -g

COPY . .

RUN tsc

RUN mkdir -p ${FUNCTION_DIR}

CMD ["build/send-vendor.handler"]

# Get Vendors
FROM amazon/aws-lambda-nodejs:18 AS getvendors

ARG FUNCTION_DIR="/var/task"

COPY package.json .

RUN npm install && npm install typescript -g

COPY . .

RUN tsc

RUN mkdir -p ${FUNCTION_DIR}

CMD ["build/get-vendors.handler"]
# docker run -v $HOME/.aws:/root/.aws:ro -e AWS_ACCESS_KEY_ID -e AWS_CA_BUNDLE -e AWS_CLI_FILE_ENCODING -e AWS_CONFIG_FILE -e AWS_DEFAULT_OUTPUT -e AWS_DEFAULT_REGION -e AWS_PAGER -e AWS_PROFILE -e AWS_ROLE_SESSION_NAME -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_SHARED_CREDENTIALS_FILE -e AWS_STS_REGIONAL_ENDPOINTS -p 9003:8080 getvendors:latest
# curl -XPOST "http://localhost:9003/2015-03-31/functions/function/invocations" -d "{}"