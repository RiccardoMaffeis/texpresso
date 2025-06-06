const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_bhplGMkpm",
            "AppClientId": "3u2i929ahl1nha9i400jn283pe",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "us-east-1bhplgmkpm.auth.us-east-1.amazoncognito.com",
              "AppClientId": "3u2i929ahl1nha9i400jn283pe",
              "SignInRedirectURI": "tedxpresso://callback/",
              "SignOutRedirectURI": "tedxpresso://callback/",
              "Scopes": ["openid","email"]
            }
          }
        }
      }
    }
  }
}''';
