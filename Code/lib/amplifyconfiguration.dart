const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_DRsIGawRO",
            "AppClientId": "2enbhg86siai6u0b00r394urk5",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "https://us-east-1drsigawro.auth.us-east-1.amazoncognito.com",
              "AppClientId": "2enbhg86siai6u0b00r394urk5",
              "SignInRedirectURI": "texpresso://callback/",
              "SignOutRedirectURI": "texpresso://callback/",
              "Scopes": ["openid","email"]
            }
          }
        }
      }
    }
  }
}''';
