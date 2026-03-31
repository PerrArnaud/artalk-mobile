class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? pagination;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      pagination: json['pagination'] as Map<String, dynamic>?,
    );
  }
}
