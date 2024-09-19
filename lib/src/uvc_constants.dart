// Copyright (c) 2024 Larry Aasen. All rights reserved.

// ignore_for_file: constant_identifier_names

/// Success (no error)
const int UVC_SUCCESS = 0;

/// Input/output error
const int UVC_ERROR_IO = -1;

/// Invalid parameter
const int UVC_ERROR_INVALID_PARAM = -2;

/// Access denied
const int UVC_ERROR_ACCESS = -3;

/// No such device
const int UVC_ERROR_NO_DEVICE = -4;

/// Entity not found
const int UVC_ERROR_NOT_FOUND = -5;

/// Resource busy
const int UVC_ERROR_BUSY = -6;

/// Operation timed out
const int UVC_ERROR_TIMEOUT = -7;

/// Overflow
const int UVC_ERROR_OVERFLOW = -8;

/// Pipe error
const int UVC_ERROR_PIPE = -9;

/// System call interrupted
const int UVC_ERROR_INTERRUPTED = -10;

/// Insufficient memory
const int UVC_ERROR_NO_MEM = -11;

/// Operation not supported
const int UVC_ERROR_NOT_SUPPORTED = -12;

/// Device is not UVC-compliant
const int UVC_ERROR_INVALID_DEVICE = -50;

/// Mode not supported
const int UVC_ERROR_INVALID_MODE = -51;

/// Resource has a callback (can't use polling and async)
const int UVC_ERROR_CALLBACK_EXISTS = -52;

/// Undefined error
const int UVC_ERROR_OTHER = -99;

const int REQ_TYPE_SET = 0x21;
const int REQ_TYPE_GET = 0xa1;
