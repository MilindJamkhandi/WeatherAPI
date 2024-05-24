provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_s3_bucket" "weather_data" {
  bucket = "weather-data-bucket"
}

resource "aws_lambda_function" "get_weather" {
  function_name = "getWeather"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "${path.module}/lambdas/getWeather/function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/getWeather/function.zip")
  role          = aws_iam_role.lambda_exec_role.arn
}

resource "aws_lambda_function" "get_weather_history" {
  function_name = "getWeatherHistory"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "${path.module}/lambdas/getWeatherHistory/function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/getWeatherHistory/function.zip")
  role          = aws_iam_role.lambda_exec_role.arn
}

resource "aws_api_gateway_rest_api" "weather_api" {
  name        = "Weather API"
  description = "API for retrieving weather data"
}

resource "aws_api_gateway_resource" "weather_resource" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_rest_api.weather_api.root_resource_id
  path_part   = "weather"
}

resource "aws_api_gateway_resource" "city_resource" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_resource.weather_resource.id
  path_part   = "{city}"
}

resource "aws_api_gateway_resource" "history_resource" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_resource.weather_resource.id
  path_part   = "history"
}

resource "aws_api_gateway_resource" "city_history_resource" {
  rest_api_id = aws_api_gateway_rest_api.weather_api.id
  parent_id   = aws_api_gateway_resource.history_resource.id
  path_part   = "{city}"
}

resource "aws_api_gateway_method" "get_weather_method" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.city_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_weather_history_method" {
  rest_api_id   = aws_api_gateway_rest_api.weather_api.id
  resource_id   = aws_api_gateway_resource.city_history_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_weather_integration" {
  rest_api_id             = aws_api_gateway_rest_api.weather_api.id
  resource_id             = aws_api_gateway_resource.city_resource.id
  http_method             = aws_api_gateway_method.get_weather_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_weather.invoke_arn
}

resource "aws_api_gateway_integration" "get_weather_history_integration" {
  rest_api_id             = aws_api_gateway_rest_api.weather_api.id
  resource_id             = aws_api_gateway_resource.city_history_resource.id
  http_method             = aws_api_gateway_method.get_weather_history_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_weather_history.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_weather.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.weather_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_history" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_weather_history.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.weather_api.execution_arn}/*/*"
}

output "api_url" {
  value = "${aws_api_gateway_rest_api.weather_api.execution_arn}"
}
