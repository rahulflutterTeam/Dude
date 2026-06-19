// lib/models/delete_account_response.dart
class DeleteAccountResponse {
  final bool status;
  final String message;

  DeleteAccountResponse({required this.status, required this.message});

  factory DeleteAccountResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? 'Something went wrong',
    );
  }
}
