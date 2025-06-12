const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_GM7zn39Cg",
            "AppClientId": "4fd6vhkkp330jr04andvtg71uo",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "https://us-east-1_GM7zn39Cg.auth.us-east-1.amazoncognito.com",
              "AppClientId": "4fd6vhkkp330jr04andvtg71uo",
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
