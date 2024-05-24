import axios from 'axios';
import { APIGatewayProxyHandler } from 'aws-lambda';
import * as AWS from 'aws-sdk';

const s3 = new AWS.S3();

export const handler: APIGatewayProxyHandler  = async (event) => {
    const city = event.pathParameters?.city;
    if(!city) {
        return {
            statusCode: 400,
            body: JSON.stringify({message: 'City parameter is missing'}),
        };
    }
    try {
        const response = await axios.get(`http://api.openweathermap.org/data/2.5/weather?q=${city}&appid=YOUR_API_KEY`);
        const data = response.data;
        const params = {
            Bucket: 'weather-data-bucket',
            Key: `current/${city}-${Date.now()}.json`,
            Body: JSON.stringify(data),
          };
          await s3.putObject(params).promise();
        return {
            statusCode: 200,
            body: JSON.stringify(response.data),
        };
    } catch(error : any) {
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Error fetching weather data', error: error.message })
        }
    }
}


