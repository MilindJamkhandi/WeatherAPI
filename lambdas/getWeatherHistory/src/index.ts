import axios from 'axios';
import { APIGatewayProxyHandler } from 'aws-lambda';
import * as AWS from 'aws-sdk';

const s3 = new AWS.S3();
const OPENWEATHERMAP_API_KEY = 'YOUR_API_KEY';

const getCoordinates = async (city: string): Promise<{ lat: number, lon: number }> => {
  const response = await axios.get(`http://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${OPENWEATHERMAP_API_KEY}`);
  const data = response.data;
  return { lat: data.coord.lat, lon: data.coord.lon };
};

const getHistoricalData = async (lat: number, lon: number): Promise<any> => {
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const oneDay = 86400; // Seconds in a day
  const historicalData = [];

  // Fetch data for the past 5 days
  for (let i = 1; i <= 5; i++) {
    const timestamp = currentTimestamp - (i * oneDay);
    const response = await axios.get(`https://api.openweathermap.org/data/2.5/onecall/timemachine?lat=${lat}&lon=${lon}&dt=${timestamp}&appid=${OPENWEATHERMAP_API_KEY}`);
    historicalData.push(response.data);
  }

  return historicalData;
};

export const handler: APIGatewayProxyHandler = async (event) => {
  const city = event.pathParameters?.city;
  if (!city) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: 'City parameter is missing' }),
    };
  }

  try {
    const { lat, lon } = await getCoordinates(city);
    const historicalData = await getHistoricalData(lat, lon);

    const params = {
      Bucket: 'weather-data-bucket',
      Key: `history/${city}-${Date.now()}.json`,
      Body: JSON.stringify(historicalData),
      ContentType: 'application/json',
    };
    await s3.putObject(params).promise();

    return {
      statusCode: 200,
      body: JSON.stringify(historicalData),
    };
  } catch (error: any) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error fetching historical weather data', error: error.message }),
    };
  }
};
