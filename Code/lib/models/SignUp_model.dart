class RegistrationModel {
  String nickname;
  String email;
  String password;
  String confirmPassword;
  String confirmationCode;
  String phoneConfirmationCode;
  String countryCode;
  String phoneNumber;
  bool isLoading;
  bool showConfirmationStep;
  bool showPhoneConfirmationStep;

  RegistrationModel({
    this.nickname = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.confirmationCode = '',
    this.phoneConfirmationCode = '',
    this.countryCode = '+39',
    this.phoneNumber = '',
    this.isLoading = false,
    this.showConfirmationStep = false,
    this.showPhoneConfirmationStep = false,
  });
}
