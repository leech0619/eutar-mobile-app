# Smart Academic Advisor Chatbot

## Overview
The Smart Academic Advisor Chatbot is a feature of the eUTAR mobile app that serves as a virtual academic advisor for university students. It uses Google's Gemini AI to provide guidance on:

- Course selection and planning
- Academic progress tracking
- Career guidance related to majors
- Study tips and resources
- University policies and procedures

## Features
- Interactive chat interface with an AI advisor
- PDF export of conversations
- Email sharing of conversation summaries
- Quick access from the home screen

## Setup Instructions

### 1. Gemini API Key
To use the chatbot, you need to obtain a Gemini API key:
1. Visit [Google AI Studio](https://makersuite.google.com/)
2. Create an account or sign in
3. Generate an API key
4. Create a `.env` file in the root directory with the following content:
   ```
   # Firebase Configuration
   FIREBASE_API_KEY=your_firebase_api_key
   FIREBASE_APP_ID=your_firebase_app_id
   FIREBASE_MESSAGING_SENDER_ID=your_firebase_messaging_sender_id
   FIREBASE_PROJECT_ID=your_firebase_project_id
   FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
   
   # Gemini API Configuration
   GEMINI_API_KEY=your_gemini_api_key
   ```
5. Replace `your_gemini_api_key` with your actual API key

### 2. Required Dependencies
The following dependencies are needed:
- google_generative_ai: ^0.2.0
- pdf: ^3.10.7
- flutter_email_sender: ^6.0.2
- share_plus: ^7.2.2
- permission_handler: ^11.3.0

Make sure these are added to your pubspec.yaml.

## Usage
1. From the Home screen, tap on "Smart Academic Advisor Chatbot"
2. Type your academic questions in the text field
3. The AI will respond with helpful advice
4. To export the conversation, tap the PDF icon in the app bar
5. You can either email the PDF or share it via other apps

## Example Conversations
- "What courses should I take for a Computer Science major?"
- "How do I prepare for next semester's registration?"
- "Can you help me create a 4-year academic plan?"
- "What are the requirements for graduating with honors?"
- "How can I improve my time management for coursework?"
