const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/0.1.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_7zgMOljfF",
            "AppClientId": "4ncmm2kkqs7g5jb128gj8cbf2m",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "https://us-east-1_7zgMOljfF.auth.us-east-1.amazoncognito.com",
              "AppClientId": "4ncmm2kkqs7g5jb128gj8cbf2m",
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
