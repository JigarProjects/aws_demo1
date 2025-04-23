const mysql = require('mysql2/promise');
const fs = require('fs');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const secretClient = new SecretsManagerClient();

async function getDatabaseSecret() {
  const response = await secretClient.send(
    new GetSecretValueCommand({
      SecretId: process.env.DB_SECRET_ARN
    })
  );
  return JSON.parse(response.SecretString);
}

exports.handler = async (event) => {
  const secret = await getDatabaseSecret();
  
  const connection = await mysql.createConnection({
    host: process.env.RDS_ENDPOINT,
    user: process.env.DB_USERNAME,
    password: secret.password,
    database: process.env.DB_NAME
  });

    try {
        // Read and execute schema.sql
        const schema = fs.readFileSync('./schema.sql', 'utf8');
        await connection.query(schema);
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Schema executed successfully' })
        };
    } catch (error) {
        console.error('Error executing schema:', error);
        throw error;
    } finally {
        await connection.end();
    }
};