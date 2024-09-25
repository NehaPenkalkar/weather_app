
# Weather App

A simple iOS weather app built using Xcode 16.0. This app uses several third-party libraries (via CocoaPods) for added functionality such as data persistence, code linting, and dependency injection.

## Prerequisites

Before running the project, ensure you have the following installed:

- [Xcode 16.0](https://developer.apple.com/xcode/)
- [CocoaPods](https://cocoapods.org/) (to manage dependencies)
- OpenWeatherMap API key

### CocoaPods Dependencies
- RealmSwift: RealmSwift is a mobile database that simplifies data persistence. It allows you to store, query, and sync local data efficiently.
- SwiftLint: SwiftLint is a tool that enforces Swift style and conventions by checking your code against a set of predefined rules. It helps maintain a clean and consistent codebase.
- Resolver: Resolver is a dependency injection library for Swift. It simplifies the process of managing and injecting dependencies, improving code modularity and testability.

### Change the API key
Before running the application, replace the API_KEY in Development.xcconfig file

```bash
API_KEY = YOUR_API_KEY
```

### Installing CocoaPods

If you don't have CocoaPods installed, run the following command to install it:

```bash
sudo gem install cocoapods
```
Once installed, navigate to the project directory and run:

```bash
pod install
```
This will install the necessary dependencies listed in the Podfile.

### Project Setup
To get started, follow these steps:

Clone the repository and Navigate to the project folder:

Install the CocoaPods dependencies:

```bash
pod install
```
Open the project using the .xcworkspace file (not the .xcodeproj)

### Sonar Server Setup

Go to [Sonar Cloud](https://sonarcloud.io/projects) and create an account if you don’t have one.
Once signed in, create a new organization and a project for your iOS app. Before installing sonar scanner make sure Java is installed on your system.

If you don't have Sonar Scanner installed, run the following command to install it:

```bash
brew install sonar-scanner
```

SonarCloud recommends using SwiftLint for linting rules in Swift projects. Run the following command to install it:

```bash
brew install swiftlint
```

Replace the configuration with your own configuration in sonar-project.properties file.

```bash
sonar.projectKey=YOUR_PROJECT_KEY
sonar.organization=YOUR_ORGANISATION
sonar.projectName=YOUR_PROJECT_NAME
sonar.host.url=https://sonarcloud.io
sonar.language=swift
sonar.sources=.
sonar.swift.coverage.reportPaths=sonarqube-generic-coverage.xml
sonar.swift.swiftlint.reportPaths=swiftlint_report.xml
sonar.exclusions=**/Pods/**

# Disable analysis of C/C++/Objective-C files
sonar.c.file.suffixes=-
sonar.cpp.file.suffixes=-
sonar.objc.file.suffixes=-
```

Run the following command in your project directory to generate the reports on sonar server

```bash
sonar-scanner \
  -Dsonar.projectKey=YOUR_PROJECT_KEY \
  -Dsonar.organization=YOUR_ORGANISATION \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.login=YOUR_SONAR_TOKEN
```

After running the command you should be able to see the report on the sonar server dashboard.

### Running the App
After finishing the setp, you can build and run the app using Xcode. Make sure to open the .xcworkspace file instead of the .xcodeproj to ensure that the CocoaPods are correctly linked to the project.
