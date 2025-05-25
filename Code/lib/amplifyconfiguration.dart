const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_sMGSRfpLk",
            "AppClientId": "7m4tfgn20q6eoa08lov6obq39t",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "https://us-east-1smgsrfplk.auth.us-east-1.amazoncognito.com",
              "AppClientId": "7m4tfgn20q6eoa08lov6obq39t",
              "SignInRedirectURI": "tedxpresso://callback/",
              "SignOutRedirectURI": "tedxpresso://callback/",
              "Scopes": ["phone","openid","email"]
            }
          }
        }
      }
    }
  }
}''';
