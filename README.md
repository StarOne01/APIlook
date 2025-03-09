# APIlook

APIlook is a cross-platform Flutter application that allows users to create, test, and manage APIs with a user-friendly interface. It serves as a comprehensive development environment for API creation with built-in JavaScript runtime support.

## Features

- **API Creation**: Build APIs with custom JavaScript logic
- **Request Testing**: Test your APIs directly within the app
- **Local API Server**: Run and test your APIs locally
- **Multiple HTTP Methods**: Support for GET, POST, PUT, DELETE, and PATCH
- **Header Management**: Add and customize HTTP headers
- **Parameter Configuration**: Define and manage request parameters
- **JavaScript Runtime**: Write and execute JavaScript code for API logic
- **Responsive UI**: Works seamlessly across mobile, tablet, and desktop interfaces
- **Cloud Storage**: Save your APIs to Supabase for access anywhere

## Installation

### Prerequisites
- Flutter SDK (2.0.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile deployment)
- Git

### Setup

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/apilook.git
   cd apilook
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Supabase
   - Create a Supabase project
   - Update the `supabase_config.dart` file with your credentials

4. Run the application
   ```bash
   flutter run
   ```

## Usage

### Creating a New API
1. Navigate to the Create API page
2. Enter API details (name, description, URL)
3. Select HTTP method
4. Add headers and parameters as needed
5. Write your API logic in JavaScript
6. Test your API using the built-in testing tool
7. Save your API to access it later

### Running the API Server
The application includes a local API server that can host your created APIs for testing:

```dart
// Example of starting the server
final server = LocalAPIServer();
await server.start();
server.registerEndpoint(myApiEndpoint);
```

### JavaScript API
Write custom API logic using the JavaScript runtime:

```javascript
function handleRequest(request, response) {
  // Access request data
  const params = request.parameters;
  
  // Process data
  const result = { message: "Hello World", data: params };
  
  // Set response
  response.status = 200;
  response.headers['Content-Type'] = 'application/json';
  response.body = JSON.stringify(result);
}
```

## Project Structure

- lib: Main application code
- auth: Authentication functionality
- models: Data models
- pages: Application screens
- services: Backend services including API runtime
- providers: State management

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the [License Name] - see the LICENSE file for details.

## Acknowledgments

- Flutter and Dart team
- Supabase for backend infrastructure
- Contributors and supporters