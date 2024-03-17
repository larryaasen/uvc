// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: non_constant_identifier_names

/// Success (no error)
int UVC_SUCCESS = 0;

/// Input/output error
int UVC_ERROR_IO = -1;

/// Invalid parameter
int UVC_ERROR_INVALID_PARAM = -2;

/// Access denied
int UVC_ERROR_ACCESS = -3;

/// No such device
int UVC_ERROR_NO_DEVICE = -4;

/// Entity not found
int UVC_ERROR_NOT_FOUND = -5;

/// Resource busy
int UVC_ERROR_BUSY = -6;

/// Operation timed out
int UVC_ERROR_TIMEOUT = -7;

/// Overflow
int UVC_ERROR_OVERFLOW = -8;

/// Pipe error
int UVC_ERROR_PIPE = -9;

/// System call interrupted
int UVC_ERROR_INTERRUPTED = -10;

/// Insufficient memory
int UVC_ERROR_NO_MEM = -11;

/// Operation not supported
int UVC_ERROR_NOT_SUPPORTED = -12;

/// Device is not UVC-compliant
int UVC_ERROR_INVALID_DEVICE = -50;

/// Mode not supported
int UVC_ERROR_INVALID_MODE = -51;

/// Resource has a callback (can't use polling and async)
int UVC_ERROR_CALLBACK_EXISTS = -52;

/// Undefined error
int UVC_ERROR_OTHER = -99;
