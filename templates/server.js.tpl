const express = require('express');
const cors = require('cors');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const mime = require('mime-types');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// AWS region and clients
const REGION = 'us-east-1';
const ddbClient = new DynamoDBClient({ region: REGION });
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);
const snsClient = new SNSClient({ region: REGION });
const s3Client = new S3Client({ region: REGION });

// Shared SNS topic
const SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:293926504711:Home-Work-Help-Submission';

// S3 bucket name
const BUCKET_NAME = 'physicstutors-homework-submissions';

// Root Route (Home Route)
app.get('/', (req, res) => {
  res.send('Welcome to the Physics Tutors API!');
});

// Feedback Route
const FEEDBACK_TABLE = 'FeedbackTable_1'; // Updated table name
app.post('/feedback', async (req, res) => {
  const { name, email, experience, suggestions } = req.body;

  if (!name || !email || !experience) {
    return res.status(400).json({ error: 'Missing required fields: name, email, or experience' });
  }

  const feedbackId = uuidv4();
  const signupTime = new Date().toISOString();

  try {
    await ddbDocClient.send(new PutCommand({
      TableName: FEEDBACK_TABLE,
      Item: {
        Email: email,
        SignupTime: signupTime,
        feedbackId,
        name,
        experience,
        suggestions: suggestions || '',
      },
    }));

    await snsClient.send(new PublishCommand({
      TopicArn: SNS_TOPIC_ARN,
      Subject: 'New Feedback Received',
      Message: `Feedback from ${name} (${email}):\n\nExperience: ${experience}\nSuggestions: ${suggestions || 'None'}`,
    }));

    res.status(200).json({ message: 'Feedback submitted successfully' });
  } catch (error) {
    console.error('Error submitting feedback:', error, error.stack);
    res.status(500).json({ error: 'Failed to submit feedback', details: error.message });
  }
});

// Signup Route
const SIGNUP_TABLE = 'SignupsTable_1'; // Updated table name
app.post('/signup', async (req, res) => {
  const { name, email, gradeLevel, subjectHelpNeeded } = req.body;

  if (!name || !email || !gradeLevel || !subjectHelpNeeded) {
    return res.status(400).json({ error: 'Missing required fields: name, email, gradeLevel, or subjectHelpNeeded' });
  }

  const signupId = uuidv4();
  const signupTime = new Date().toISOString();

  try {
    await ddbDocClient.send(new PutCommand({
      TableName: SIGNUP_TABLE,
      Item: {
        Email: email,
        SignupTime: signupTime,
        signupId,
        name,
        gradeLevel,
        subjectHelpNeeded,
      },
    }));

    await snsClient.send(new PublishCommand({
      TopicArn: SNS_TOPIC_ARN,
      Subject: 'New Signup Received',
      Message: `Signup from ${name} (${email}):\nGrade Level: ${gradeLevel}\nSubject Help Needed: ${subjectHelpNeeded}`,
    }));

    res.status(200).json({ message: 'Signup submitted successfully' });
  } catch (error) {
    console.error('Error submitting signup:', error, error.stack);
    res.status(500).json({ error: 'Failed to submit signup', details: error.message });
  }
});

// Generate Presigned URL for file upload
app.get('/generatePresignedUrl', async (req, res) => {
  const { filename } = req.query;

  if (!filename) {
    return res.status(400).json({ error: 'Filename is required' });
  }

  try {
    const contentType = mime.lookup(filename) || 'application/octet-stream';
    const params = {
      Bucket: BUCKET_NAME,
      Key: `homework-Uploads/${uuidv4()}-${filename}`,
      ContentType: contentType
    };

    console.log("Params for presigned URL:", params);

    const command = new PutObjectCommand(params);
    const url = await getSignedUrl(s3Client, command, { expiresIn: 3600 });

    console.log("Generated pre-signed URL:", url);

    res.json({ presignedUrl: url });
  } catch (error) {
    console.error('Error generating presigned URL:', error, error.stack);
    res.status(500).json({ error: 'Failed to generate presigned URL', details: error.message });
  }
});

// Homework Help Submission Route
app.post('/homeworkhelpsubmission', async (req, res) => {
  const { name, email, grade, description, filename, fileUrl, timestamp } = req.body;

  console.log('Homework submission request body:', req.body);

  if (!name || !email || !grade || !description || !filename || !fileUrl) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const homeworkId = uuidv4();
  const signupTime = timestamp || new Date().toISOString();

  try {
    console.log('Writing to DynamoDB:', { Email: email, SignupTime: signupTime, homeworkId, name, grade, description, filename, fileUrl });
    await ddbDocClient.send(new PutCommand({
      TableName: 'HomeworkUploadsTable_1', // Updated table name
      Item: {
        Email: email,
        SignupTime: signupTime,
        homeworkId,
        name,
        grade,
        description,
        filename,
        fileUrl,
      },
    }));

    console.log('Publishing to SNS:', { TopicArn: SNS_TOPIC_ARN });
    await snsClient.send(new PublishCommand({
      TopicArn: SNS_TOPIC_ARN,
      Subject: 'New Homework Help Submission',
      Message: `Homework submitted by ${name} (${email}):\nGrade Level: ${grade}\nDescription: ${description}\nFile: ${filename}\nURL: ${fileUrl}`,
    }));

    res.status(200).json({ message: 'Homework submitted successfully' });
  } catch (error) {
    console.error('Error submitting homework:', error, error.stack);
    res.status(500).json({ error: 'Failed to submit homework', details: error.message });
  }
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${port}`);
});
