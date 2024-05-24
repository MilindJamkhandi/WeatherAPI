# Weather Data API

This project provides a scalable API for retrieving and processing weather data from the OpenWeatherMap API. The API is built using AWS Lambda for backend processing, API Gateway for the interface, and S3 for storing the data. The infrastructure is defined and provisioned using Terraform.

## Features

- **GET /weather/{city}**: Returns the current weather data for the specified city.
- **GET /weather/history/{city}**: Returns historical weather data for the specified city.

## Architecture

- **AWS Lambda**: Backend processing.
- **AWS API Gateway**: RESTful API interface.
- **AWS S3**: Storage for request/response data.
- **Terraform**: Infrastructure as code.

## Prerequisites

- Node.js
- AWS CLI
- Terraform
- OpenWeatherMap API Key

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/weather-data-api.git
cd weather-data-api

cd lambdas/getWeather
npm install
cd ../getWeatherHistory
npm install

OPENWEATHERMAP_API_KEY=your_api_key_here
cd lambdas/getWeather
npx tsc
cd ../getWeatherHistory
npx tsc
cd lambdas/getWeather
zip -r function.zip .
aws lambda update-function-code --function-name getWeather --zip-file fileb://function.zip

cd ../getWeatherHistory
zip -r function.zip .
aws lambda update-function-code --function-name getWeatherHistory --zip-file fileb://function.zip
cd terraform
terraform init
terraform apply
cd lambdas/getWeather
zip -r function.zip .
aws lambda update-function-code --function-name getWeather --zip-file fileb://function.zip

cd ../getWeatherHistory
zip -r function.zip .
aws lambda update-function-code --function-name getWeatherHistory --zip-file fileb://function.zip
