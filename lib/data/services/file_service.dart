import 'dart:io';
import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';

class FileService {
  final ApiClient _apiClient;

  FileService(this._apiClient);

  Future<FileUploadResponse> uploadFile({
    required String filePath,
    String? accessLevel,
    List<String>? tags,
    String? description,
    Function(int sent, int total)? onProgress,
  }) async {
    final response = await _apiClient.uploadFile(
      ApiConstants.uploadFile,
      filePath,
      accessLevel: accessLevel,
      tags: tags,
      description: description,
      onSendProgress: onProgress,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to upload file');
    }
  }

  Future<List<FileUploadResponse>> getFiles({
    int page = 1,
    int perPage = 20,
    String? fileType,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (fileType != null) queryParams['file_type'] = fileType;
    if (search != null) queryParams['search'] = search;

    final response = await _apiClient.get(
      ApiConstants.listFiles,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      final filesList = response.data['files'] as List;
      return filesList
          .map((json) => FileUploadResponse.fromJson(json))
          .toList();
    } else {
      throw ApiError(message: response.error ?? 'Failed to get files');
    }
  }

  Future<FileUploadResponse> getFileInfo(String fileId) async {
    final response = await _apiClient.get<FileUploadResponse>(
      '${ApiConstants.fileInfo}/$fileId',
      fromJson: (json) => FileUploadResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to get file info');
    }
  }

  Future<void> downloadFile({
    required String fileId,
    required String savePath,
    Function(int received, int total)? onProgress,
  }) async {
    await _apiClient.downloadFile(
      '${ApiConstants.downloadFile}/$fileId',
      savePath,
      onReceiveProgress: onProgress,
    );
  }

  Future<void> deleteFile(String fileId) async {
    final response =
        await _apiClient.delete('${ApiConstants.deleteFile}/$fileId');

    if (!response.isSuccess) {
      throw ApiError(message: response.error ?? 'Failed to delete file');
    }
  }

  Future<String> shareFile({
    required String fileId,
    required String accessLevel,
    DateTime? expiresAt,
  }) async {
    final requestData = <String, dynamic>{
      'access_level': accessLevel,
    };

    if (expiresAt != null) {
      requestData['expires_at'] = expiresAt.toIso8601String();
    }

    final response = await _apiClient.post(
      '${ApiConstants.shareFile}/$fileId/share',
      data: requestData,
    );

    if (response.isSuccess && response.data != null) {
      return response.data['share_url'];
    } else {
      throw ApiError(message: response.error ?? 'Failed to share file');
    }
  }

  Future<Map<String, dynamic>> getFileStatistics() async {
    final response = await _apiClient.get(ApiConstants.fileStatistics);

    if (response.isSuccess && response.data != null) {
      return response.data;
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get file statistics');
    }
  }

  // Utility methods
  String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  bool isImageFile(String filename) {
    final extension = getFileExtension(filename);
    return ApiConstants.allowedImageTypes.contains(extension);
  }

  bool isDocumentFile(String filename) {
    final extension = getFileExtension(filename);
    return ApiConstants.allowedDocumentTypes.contains(extension);
  }

  bool isAudioFile(String filename) {
    final extension = getFileExtension(filename);
    return ApiConstants.allowedAudioTypes.contains(extension);
  }

  bool isFileSizeValid(File file) {
    return file.lengthSync() <= ApiConstants.maxFileSize;
  }
}
