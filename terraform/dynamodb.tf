// 通过Terraform来建立这张表
resource "aws_dynamodb_table" "websocket_table" {
    name = var.websocket_table_name
    read_capacity = 10
    write_capacity = 10
    // 决定主键
    hash_key = "connectionId"
    // 决定主键的名字和类型
    attribute {
      name = "connectionId"
      type = "S"
    }
}