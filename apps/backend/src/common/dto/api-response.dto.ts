/**
 * Pagination metadata included in list responses.
 */
export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

/**
 * Error details in failed response.
 */
export interface ErrorDetail {
  code: string;
  message: string;
}

/**
 * Sealed envelope response type used for all API responses.
 * Ensures consistent response shape across the backend.
 *
 * @template T - The type of data being returned
 */
export class ApiResponse<T = unknown> {
  /**
   * Indicates whether the request was successful.
   */
  success: boolean;

  /**
   * The actual response data. Null if success is false.
   */
  data?: T;

  /**
   * Optional pagination metadata for list endpoints.
   */
  meta?: PaginationMeta;

  /**
   * Error details when success is false.
   */
  error?: ErrorDetail;

  constructor(
    success: boolean,
    data?: T,
    meta?: PaginationMeta,
    error?: ErrorDetail,
  ) {
    this.success = success;
    this.data = data;
    this.meta = meta;
    this.error = error;
  }

  /**
   * Create a successful response.
   */
  static ok<U>(data: U, meta?: PaginationMeta): ApiResponse<U> {
    return new ApiResponse(true, data, meta);
  }

  /**
   * Create a failed response.
   */
  static error(code: string, message: string): ApiResponse<null> {
    return new ApiResponse(false, null, undefined, { code, message });
  }
}
